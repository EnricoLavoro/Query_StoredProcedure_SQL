USE [up_Disenia]
GO

/****** Object:  StoredProcedure [dbo].[ITsp_ALRM_BuchiProtocollo]    Script Date: 20/09/2022 14:12:43 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

ALTER PROCEDURE [dbo].[ITsp_ALRM_BuchiProtocollo] @RetVal INTeger OUTPUT, @RetStr varchar(8000) OUTPUT AS
/*

@RetVal::	valore confrontato con "Valore per Allarme" per decidere se generare un allarme o una notifica
@RetStr::	stringa di ritorno con messaggio dell'allarme o della notifica

-- Enrico - 20/09/2022 - CIT202200383 - CTRL BUCHI PROTOCOLLO

---------------------------------------------------------------------------------------------------------------------------------------

-- DDT VENDITA
-- MbaisCRMcso = 2

-- DDT OMAGGIO -> MbaisCRTcso=61 AND MbaisCRMcso IN (2,25)
-- INNER JOIN TabCausaliStOp ON MbaisCRTcso = TcsoCSer
-- WHERE TcsoCTcso LIKE '%OMA%' AND MbaisCMbais LIKE '%DD%'

-- DDT CONTO/LAVORO
-- MbaisCRMcso = 25

-- FATTURE VENDITA ITALIA E ESTERO
-- MbaisCRMcso IN (4,23)

-- NOTE DI CREDITO
-- MbaisCRMcso IN (50,5) -- 5 = NCC, 50 = NCE

-- NOTE DI ADDEBITO -> MbaisCRTcso IN (41,39,40,42)
	41 = NOTA DI ADDEBITO Clienti Italia
	39 = NOTA DI ADDEBITO Clienti IntraCEE
	40 = NOTA DI ADDEBITO Clienti ExtraCEE
	42 = NOTA DI ADDEBITO AGENTI
-- INNER JOIN TabCausaliStOp ON MbaisCRTcso = TcsoCSer
-- WHERE TcsoDTcso LIKE '%ADDEBITO%'

---------------------------------------------------------------------------------------------------------------------------------------

*/
BEGIN

DECLARE @RC INT
DECLARE @Filtro VARCHAR(2000)
DECLARE @BatchJobId INT
DECLARE @MaxNumeroMancanti INT = 100
DECLARE @numeroMancanti INT
DECLARE @tabNumMan TABLE (BatchJobId INT, numeroMancanti INT, esito VARCHAR(8000))
DECLARE @numBatchJobId INT = 1
DECLARE @OutCursorID INT = 1
DECLARE @InCursorID INT
DECLARE @numMancPerRig INT
DECLARE @primCodPerRig VARCHAR(2000)
DECLARE @numMoltepl INT = 0
DECLARE @strOut VARCHAR(8000) = ''

---------------------------------------------------------------------------------------------------------------------------------------

-- DDT VENDITA
SET @Filtro = 'AND MbaisCRMcso=2 AND DATEDIFF(YEAR,MbaisTins,GETDATE())=2'
SET @BatchJobId = 1

EXECUTE @RC = [dbo].[__upCodiciMancantiStop] 
   @Filtro
  ,@BatchJobId
  ,@MaxNumeroMancanti
  ,@numeroMancanti OUTPUT

INSERT INTO @tabNumMan (BatchJobId,numeroMancanti) VALUES (@BatchJobId,@numeroMancanti)

-- DDT OMAGGIO
SET @Filtro = 'AND MbaisCRTcso=61 AND MbaisCRMcso IN (2,25) AND DATEDIFF(YEAR,MbaisTins,GETDATE())=2'
SET @BatchJobId = 2

EXECUTE @RC = [dbo].[__upCodiciMancantiStop] 
   @Filtro
  ,@BatchJobId
  ,@MaxNumeroMancanti
  ,@numeroMancanti OUTPUT

INSERT INTO @tabNumMan (BatchJobId,numeroMancanti) VALUES (@BatchJobId,@numeroMancanti)

-- DDT CONTO/LAVORO
SET @Filtro = 'AND MbaisCRMcso=25 AND DATEDIFF(YEAR,MbaisTins,GETDATE())=2'
SET @BatchJobId = 3

EXECUTE @RC = [dbo].[__upCodiciMancantiStop] 
   @Filtro
  ,@BatchJobId
  ,@MaxNumeroMancanti
  ,@numeroMancanti OUTPUT

INSERT INTO @tabNumMan (BatchJobId,numeroMancanti) VALUES (@BatchJobId,@numeroMancanti)

-- FATTURE VENDITA (fatture vendita italia e estero – tutte le note di credito e di addebito)
SET @Filtro = '(MbaisCRMcso IN (4,5,23,50) OR TcsoDTcso LIKE ''%ADDEBITO%'') AND DATEDIFF(YEAR,MbaisTins,GETDATE())=2'
SET @BatchJobId = 4

EXECUTE @RC = [dbo].[ITsp_upCodiciMancantiStop] 
   @Filtro
  ,@BatchJobId
  ,@MaxNumeroMancanti
  ,@numeroMancanti OUTPUT

INSERT INTO @tabNumMan (BatchJobId,numeroMancanti) VALUES (@BatchJobId,@numeroMancanti)

---------------------------------------------------------------------------------------------------------------------------------------

WHILE @numBatchJobId <= 4
BEGIN
	SET @strOut = 
	CASE 
		WHEN @numBatchJobId = 1 THEN 'Le DDT VENDITA mancanti sono '
		WHEN @numBatchJobId = 2 THEN 'Le DDT OMAGGIO mancanti sono '
		WHEN @numBatchJobId = 3 THEN 'Le DDT C/LAVORO mancanti sono '
		WHEN @numBatchJobId = 4 THEN 'Le FATTURE VENDITA mancanti sono '
	END+CONVERT(VARCHAR,(SELECT numeroMancanti FROM @tabNumMan WHERE BatchJobId=@numBatchJobId))+'. In particolare: '+CHAR(13)+CHAR(10)

	WHILE @OutCursorID + @numMoltepl <= (SELECT numeroMancanti FROM @tabNumMan WHERE BatchJobId=@numBatchJobId)
	BEGIN
		SET @numMancPerRig = (SELECT scmstNMancanti
		FROM StampaCodiciMancantiStop
		WHERE scmstCserRepRif=@numBatchJobId AND scmstPrig=@OutCursorID)

		SET @primCodPerRig = (SELECT scmstCod1
		FROM StampaCodiciMancantiStop
		WHERE scmstCserRepRif=@numBatchJobId AND scmstPrig=@OutCursorID)
	
		SET @InCursorID = 1

		WHILE @InCursorID <= @numMancPerRig
		BEGIN
			------------------------------------------------------------------------------------------------------------------------------------
			SET @strOut = 
				CASE WHEN @numBatchJobId = 4 THEN
					@strOut+(SELECT LEFT(@primCodPerRig,CHARINDEX('/',@primCodPerRig)))+
					CONVERT(VARCHAR,CONVERT(INT,(SELECT SUBSTRING(@primCodPerRig,CHARINDEX('/',@primCodPerRig)+1,LEN(@primCodPerRig)-CHARINDEX('/',REVERSE(@primCodPerRig))-CHARINDEX('/',@primCodPerRig))))+@InCursorID)+
					(SELECT RIGHT(@primCodPerRig,CHARINDEX('/',REVERSE(@primCodPerRig))))
					+CHAR(13)+CHAR(10)
				ELSE
					@strOut+LEFT(@primCodPerRig,7)+ 
					RIGHT('000000000'+CONVERT(VARCHAR,
					(SELECT CONVERT(INT,RIGHT(@primCodPerRig,9))+@InCursorID)),9)+CHAR(13)+CHAR(10)
				END
			------------------------------------------------------------------------------------------------------------------------------------

			SET @InCursorID = @InCursorID + 1
		END

		SET @numMoltepl = @numMoltepl + @numMancPerRig - 1
		SET @OutCursorID = @OutCursorID + 1
	END

	UPDATE @tabNumMan SET esito=@strOut WHERE BatchJobId=@numBatchJobId
	SET @numBatchJobId = @numBatchJobId + 1
	SET @OutCursorID = 1
	SET @numMoltepl = 0
END
	-- OUTPUT
	SET @RetVal = 0											-- =0 -> NO allarme "BUCHI PROTOCOLLI"
	SET @RetStr = 'NESSUN BUCO DI PROTOCOLLO'			    -- messaggio default
	IF (SELECT SUM(numeroMancanti) FROM @tabNumMan) <> 0
	BEGIN
		SET @RetVal = 1										-- =1 -> SI allarme "BUCHI PROTOCOLLI"
		SET @RetStr = 
		ISNULL(CONVERT(VARCHAR(8000),(SELECT esito FROM @tabNumMan WHERE BatchJobId=1 AND numeroMancanti<>0)),'')+CHAR(13)+CHAR(10)+
		ISNULL(CONVERT(VARCHAR(8000),(SELECT esito FROM @tabNumMan WHERE BatchJobId=2 AND numeroMancanti<>0)),'')+CHAR(13)+CHAR(10)+
		ISNULL(CONVERT(VARCHAR(8000),(SELECT esito FROM @tabNumMan WHERE BatchJobId=3 AND numeroMancanti<>0)),'')+CHAR(13)+CHAR(10)+
		ISNULL(CONVERT(VARCHAR(8000),(SELECT esito FROM @tabNumMan WHERE BatchJobId=4 AND numeroMancanti<>0)),'')+CHAR(13)+CHAR(10)
	END
END
GO
