USE [up_Disenia]
GO

/****** Object:  StoredProcedure [dbo].[ITsp_upCodiciMancantiStop]    Script Date: 22/09/2022 17:47:31 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

 /*
	 Enrico - 21/09/2022 - CIT202200383 - CTRL BUCHI PROTOCOLLO
 */

ALTER PROCEDURE [dbo].[ITsp_upCodiciMancantiStop]
						@Filtro VARCHAR(2000),
				  		@BatchJobId INTEGER,
				  		@MaxNumeroMancanti INTEGER,
						@numeroMancanti INTEGER OUTPUT
AS
-- Numero di iterazioni complessive del ciclo
DECLARE @numIt INT
-- Contatore del ciclo
DECLARE @c INT = 1
-- Progressivo di riga della tabella StampaCodiciMancantiStop
DECLARE @Prig INT = 1
-- Progressivo di confronto per verificare se ci sono buchi di protocollo
DECLARE @prog INT
DECLARE @maxIterazioni INT
SET     @maxIterazioni = 40
SET		@numeroMancanti = 0

IF @MaxNumeroMancanti > 40 and @MaxNumeroMancanti < 1000
	SET     @maxIterazioni = @MaxNumeroMancanti

IF OBJECT_ID('tempdb..#Tab')   IS NOT NULL DROP TABLE #Tab;
DELETE FROM StampaCodiciMancantiStop WHERE scmstCserRepRif = @BatchJobId

-- Creazione della tabella contenente tutti i buchi di protocollo individuati rispetto al filtro selezionato
CREATE TABLE #Tab (NRiga INT, ProtSec VARCHAR(8000), ProgProtSec INT)
EXEC('INSERT INTO #Tab SELECT ROW_NUMBER() OVER(ORDER BY CONVERT(INT,SUBSTRING(RIGHT(RpriCProRegIVA,9), PATINDEX(''%[1-9]%'',RIGHT(RpriCProRegIVA,9)), 10 - PATINDEX(''%[1-9]%'',RIGHT(RpriCProRegIVA,9)))) ASC) AS NRiga, LEFT(RIGHT(RpriCProRegIVA,13),4)+''/''+ SUBSTRING(RIGHT(RpriCProRegIVA,9), PATINDEX(''%[1-9]%'',RIGHT(RpriCProRegIVA,9)), 10 - PATINDEX(''%[1-9]%'',RIGHT(RpriCProRegIVA,9))) + ''/'' + TregCTreg AS ProtSec,
CONVERT(INT,SUBSTRING(RIGHT(RpriCProRegIVA,9), PATINDEX(''%[1-9]%'',RIGHT(RpriCProRegIVA,9)), 10 - PATINDEX(''%[1-9]%'',RIGHT(RpriCProRegIVA,9)))) AS ProgProtSec
FROM IstBaseStOpMaster
INNER JOIN TabCausaliStOp			  ON MbaisCRTcso = TcsoCSer
INNER JOIN MasterMovContabile		  ON MbaisCRMmoc = MmocCSer
INNER JOIN RigheProtocolliIVA		  ON RpriCRifMmoc = MmocCSer
INNER JOIN TabRegistri			      ON RpriCRifTreg = TregCSer
WHERE TregCSer=6 AND ' + @Filtro + ' ORDER BY 3 ASC')

--EXEC('INSERT INTO #Tab SELECT ROW_NUMBER() OVER(ORDER BY MbaisCprotsec ASC) AS NRiga, MbaisCprotsec AS ProtSec,
--	   CONVERT(INT,RIGHT(MbaisCprotsec,9)) AS ProgProtSec
--	   FROM IstBaseStOpMaster WHERE ' + @Filtro + ' ORDER BY MbaisCprotsec ASC')

SELECT * FROM #Tab

SET @numIt = @@ROWCOUNT
SET @prog  = (SELECT ProgProtSec FROM #Tab WHERE NRiga = @c)

-- Ciclando per il numero complessivo di buchi di protocollo trovati
WHILE @c <= @numIt
BEGIN
	-- Se viene individuato un progressivo non in linea con quello previsto
	IF @prog <> (SELECT ProgProtSec FROM #Tab WHERE NRiga = @c)
	BEGIN
		INSERT INTO StampaCodiciMancantiStop 
					(scmstCserRepRif, scmstPrig, scmstCod1, scmstCod2, scmstDesc, scmstNmancanti, scmstFErrore) VALUES
					(@BatchJobId, @Prig, (SELECT ProtSec FROM #Tab WHERE ProgProtSec = @prog-1), 
					(SELECT ProtSec FROM #Tab WHERE NRiga = @c),'',(SELECT ProgProtSec FROM #Tab WHERE NRiga = @c)-@prog,'')
		
		SET @numeroMancanti = @numeroMancanti + (SELECT ProgProtSec FROM #Tab WHERE NRiga = @c)-@prog
		SET @prog = (SELECT ProgProtSec FROM #Tab WHERE NRiga = @c)
		SET @Prig = @Prig + 1
	END
	SET @prog = @prog + 1
	SET @c    = @c + 1
END

IF OBJECT_ID('tempdb..#Tab')   IS NOT NULL DROP TABLE #Tab;
GO
