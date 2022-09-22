USE [up_Disenia]
GO

/****** Object:  StoredProcedure [dbo].[ITsp_ALRM_BuchiProtocollo]    Script Date: 22/09/2022 17:24:01 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO



ALTER PROCEDURE [dbo].[ITsp_ALRM_BuchiProtocollo] @RetVal INTEGER OUTPUT, @RetStr VARCHAR(8000) OUTPUT AS
/*

@RetVal::	valore confrontato con "Valore per Allarme" per decidere se generare un allarme o una notifica
@RetStr::	stringa di ritorno con messaggio dell'allarme o della notifica

-- Enrico - 20/09/2022 - CIT202200383 - CTRL BUCHI PROTOCOLLO

---------------------------------------------------------------------------------------------------------------------------------------

-------------------------------------------------- Categoria StOp N° 1 --------------------------------------------------
-- DDT VENDITA
-- MbaisCRMcso = 2

-------------------------------------------------- Categoria StOp N° 2 --------------------------------------------------
-- DDT OMAGGIO -> MbaisCRTcso=61 AND MbaisCRMcso IN (2,25)
-- INNER JOIN TabCausaliStOp ON MbaisCRTcso = TcsoCSer
-- WHERE TcsoCTcso LIKE '%OMA%' AND MbaisCMbais LIKE '%DD%'

-------------------------------------------------- Categoria StOp N° 3 --------------------------------------------------
-- DDT CONTO/LAVORO
-- MbaisCRMcso = 25

-------------------------------------------------- Categoria StOp N° 4 --------------------------------------------------
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

-- FATTURE DI INTEGRAZIONE
-- MbaisCRMcso = 135

---------------------------------------------------------------------------------------------------------------------------------------

*/
BEGIN

DECLARE @diffAnni			VARCHAR(4) = '0'
DECLARE @NumCatStOp			INT = 4
DECLARE @RC					INT
-- Filtro per la parametrizzazione della clausola WHERE nelle sottoprocedure
DECLARE @Filtro				VARCHAR(2000)
-- Codice identificativo per le diverse categorie di StOp di cui individuare i buchi
DECLARE @BatchJobId			INT
DECLARE @MaxNumeroMancanti  INT = 999
DECLARE @numeroMancanti		INT
-- Tabella contenente, per ogni categoria di StOp, il numero di protocolli mancanti e quali essi sono
DECLARE @tabNumMan			TABLE (BatchJobId INT, numeroMancanti INT, esito VARCHAR(8000))
-- Contatore del ciclo while esterno
DECLARE @OutCursorID		INT = 1
-- Contatore del ciclo while interno
DECLARE @InCursorID			INT
-- Numero di protocolli mancanti per ogni riga della tabella StampaCodiciMancantiStop
DECLARE @numMancPerRig		INT
-- Estremo sinistro dell'intervallo di protocolli mancanti per ogni riga della tabella StampaCodiciMancantiStop
DECLARE @primCodPerRig		VARCHAR(2000)
-- Contatore della molteplicitÃ  (superiore a 1) di ogni riga della tabella StampaCodiciMancantiStop
DECLARE @numMoltepl			INT = 0
DECLARE @strOut				VARCHAR(8000) = ''

---------------------------------------- DDT VENDITA ----------------------------------------
SET @Filtro = 'AND MbaisCRMcso=2 AND DATEDIFF(YEAR,MbaisTins,GETDATE())='+@diffAnni
SET @BatchJobId = 1

EXECUTE @RC = [dbo].[__upCodiciMancantiStop] 
   @Filtro
  ,@BatchJobId
  ,@MaxNumeroMancanti
  ,@numeroMancanti OUTPUT

INSERT INTO @tabNumMan (BatchJobId,numeroMancanti) VALUES (@BatchJobId,@numeroMancanti)

---------------------------------------- DDT OMAGGIO ----------------------------------------
SET @Filtro = 'AND MbaisCRTcso=61 AND MbaisCRMcso IN (2,25) AND DATEDIFF(YEAR,MbaisTins,GETDATE())='+@diffAnni
SET @BatchJobId = 2

EXECUTE @RC = [dbo].[__upCodiciMancantiStop] 
   @Filtro
  ,@BatchJobId
  ,@MaxNumeroMancanti
  ,@numeroMancanti OUTPUT

INSERT INTO @tabNumMan (BatchJobId,numeroMancanti) VALUES (@BatchJobId,@numeroMancanti)

---------------------------------------- DDT CONTO/LAVORO ----------------------------------------
SET @Filtro = 'AND MbaisCRMcso=25 AND DATEDIFF(YEAR,MbaisTins,GETDATE())='+@diffAnni
SET @BatchJobId = 3

EXECUTE @RC = [dbo].[__upCodiciMancantiStop] 
   @Filtro
  ,@BatchJobId
  ,@MaxNumeroMancanti
  ,@numeroMancanti OUTPUT

INSERT INTO @tabNumMan (BatchJobId,numeroMancanti) VALUES (@BatchJobId,@numeroMancanti)

-------------------- FATTURE VENDITA (fatture vendita italia e estero â€“ tutte le note di credito e di addebito) --------------------
SET @Filtro = '(MbaisCRMcso IN (4,5,23,50,135) OR TcsoDTcso LIKE ''%ADDEBITO%'') AND DATEDIFF(YEAR,MbaisTins,GETDATE())='+@diffAnni
SET @BatchJobId = 4

EXECUTE @RC = [dbo].[ITsp_upCodiciMancantiStop] 
   @Filtro
  ,@BatchJobId
  ,@MaxNumeroMancanti
  ,@numeroMancanti OUTPUT

INSERT INTO @tabNumMan (BatchJobId,numeroMancanti) VALUES (@BatchJobId,@numeroMancanti)

---------------------------------------------------------------------------------------------------------------------------------------

SET @BatchJobId = 1

-- Ciclando per ogni categoria di StOp
WHILE @BatchJobId <= @NumCatStOp
BEGIN
	SET @strOut = 
	CASE 
		WHEN @BatchJobId = 1 THEN 'Le DDT VENDITA mancanti sono '
		WHEN @BatchJobId = 2 THEN 'Le DDT OMAGGIO mancanti sono '
		WHEN @BatchJobId = 3 THEN 'Le DDT C/LAVORO mancanti sono '
		WHEN @BatchJobId = 4 THEN 'Le FATTURE VENDITA mancanti sono '
	END+CONVERT(VARCHAR,(SELECT numeroMancanti FROM @tabNumMan WHERE BatchJobId=@BatchJobId))+'. In particolare: '+CHAR(13)+CHAR(10)

	-- Ciclando per il numero totale di protocolli mancanti di ogni categoria di StOp 
	WHILE @OutCursorID + @numMoltepl <= (SELECT numeroMancanti FROM @tabNumMan WHERE BatchJobId=@BatchJobId)
	BEGIN
		SET @numMancPerRig = (SELECT scmstNMancanti
		FROM StampaCodiciMancantiStop
		WHERE scmstCserRepRif=@BatchJobId AND scmstPrig=@OutCursorID)

		SET @primCodPerRig = (SELECT scmstCod1
		FROM StampaCodiciMancantiStop
		WHERE scmstCserRepRif=@BatchJobId AND scmstPrig=@OutCursorID)
	
		SET @InCursorID = 1

		WHILE @InCursorID <= @numMancPerRig
		BEGIN
			------------------------------------------------------------------------------------------------------------------------------------
			SET @strOut = @strOut+
				----- Costruzione del protocollo delle StOp mancanti a seconda della loro categoria 
				CASE WHEN @BatchJobId = 4 THEN
					LEFT(@primCodPerRig,CHARINDEX('/',@primCodPerRig))+
					CONVERT(VARCHAR,CONVERT(INT,SUBSTRING(@primCodPerRig,CHARINDEX('/',@primCodPerRig)+1,LEN(@primCodPerRig)-CHARINDEX('/',REVERSE(@primCodPerRig))-CHARINDEX('/',@primCodPerRig)))+@InCursorID)+
					RIGHT(@primCodPerRig,CHARINDEX('/',REVERSE(@primCodPerRig)))
				ELSE
					LEFT(@primCodPerRig,7)+ 
					RIGHT('000000000'+CONVERT(VARCHAR,
					CONVERT(INT,RIGHT(@primCodPerRig,9))+@InCursorID),9)
				END+CHAR(13)+CHAR(10)
			------------------------------------------------------------------------------------------------------------------------------------

			SET @InCursorID = @InCursorID + 1
		END

		SET @numMoltepl = @numMoltepl + @numMancPerRig - 1
		SET @OutCursorID = @OutCursorID + 1
	END

	UPDATE @tabNumMan SET esito=@strOut WHERE BatchJobId=@BatchJobId
	SET @BatchJobId = @BatchJobId + 1
	SET @OutCursorID = 1
	SET @numMoltepl = 0
END
	-- OUTPUT
	SET @RetVal = 0											-- =0 -> NO allarme "BUCHI PROTOCOLLI"
	SET @RetStr = 'NESSUN BUCO DI PROTOCOLLO'			    -- messaggio default
	IF (SELECT SUM(numeroMancanti) FROM @tabNumMan) <> 0
	BEGIN
		SET @RetVal = 1										-- =1 -> SI allarme "BUCHI PROTOCOLLI"
		SET @RetStr = ''
		WHILE @OutCursorID <= @NumCatStOp
		BEGIN
			SET @RetStr = @RetStr+ISNULL(CONVERT(VARCHAR(8000),(SELECT esito FROM @tabNumMan WHERE BatchJobId=@OutCursorID AND numeroMancanti<>0))+CHAR(13)+CHAR(10),'')
			SET @OutCursorID = @OutCursorID + 1
		END
	END
END
GO
