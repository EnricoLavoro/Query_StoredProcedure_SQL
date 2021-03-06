USE [up_it]
GO
/****** Object:  StoredProcedure [dbo].[ITsp_InsCopiaCommessa]    Script Date: 26/04/2022 14:22:47 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Enrico Piccin
-- Create date: 1 Marzo 2022
-- Description:	Copia di una commessa tramite procedura automatica
-- Update 1:	Enrico Piccin - 22 Aprile 2022
-- =============================================
ALTER PROCEDURE [dbo].[ITsp_InsCopiaCommessa] (@parCSer int, @parUtente as varchar(40)='import', @outEsitoCopia as VARCHAR(40) OUTPUT, @outCTacaNew as varchar(40) OUTPUT )
	-- Add the parameters for the stored procedure here
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	DECLARE @RC int
	DECLARE @valoreTacaCser float         -- Nuovo seriale per la commessa
	DECLARE @valoreAComCSer float		  -- Nuovo seriale per l'attributo commessa

	-- 
	DECLARE @varNumAtt int                -- Numero di attributi copiati
	DECLARE @tempCodiceCnCOM varchar(40)  -- Temporanea

	 BEGIN TRY
		IF EXISTS(SELECT 1 FROM [dbo].[TabAttComm] WITH(NOLOCK)
          WHERE TacaCSer = @parCSer)
		BEGIN
		
		-- Creazione della stringa CncomCRMtpro per la ricerca del codice protocllo
		SELECT @tempCodiceCnCOM = 'Cncom:' + 
		CONVERT(VARCHAR(40), ISNULL(
		(SELECT CncomCRMtpro FROM TabAttComm INNER JOIN CommesseTipi ON TacaCRTcom = TcomCser INNER JOIN ConfProtCommesse ON TcomCRCncom = CncomCser WHERE [TacaCSer] = @parCSer)
		,'')) +
		+':CIT'+
		CONVERT(VARCHAR(40), ISNULL(YEAR(getdate()),''));

		-- Ottenimento del nuovo seriale protocollo
		DECLARE @varProtCSer float
		EXECUTE @RC = [dbo].[ProtocolloGetNext] 
			 @tempCodiceCnCOM
			,'U'
			,0
			,1
			,0
			,@varProtCSer OUTPUT

		-- Creazione del TacaCTaca della nuova commessa
		SELECT @outCTacaNew = 'CIT'+CONVERT(VARCHAR(40), ISNULL(YEAR(getdate()),''))+RIGHT('000000000'+CONVERT(VARCHAR(40), ISNULL(@varProtCSer,'')),5);
		-- SELECT @outCTacaNew AS 'Codice';

		-- Nuovo Seriale commessa
		EXECUTE @RC = [dbo].[ProtocolloSerialTabellaGetNext] 
		   'TabAttComm'
		  ,1
		  ,@valoreTacaCser OUTPUT

		-- Ottenimento degli attributi della commessa da copiare
		 SELECT * 
		 INTO #TempAttributiCommesseDaCopiare
		 FROM CommesseAttributi WHERE AComCRTaca = @parCSer;

		 -- Numero di attributi copiati
		 SELECT @varNumAtt = @@ROWCOUNT;

		 -- Aggiornamento seriale attributo [AComCSer] e codice commessa associato [AComCRTaca]
		 DECLARE @cntAttrComm int = 1;
		 WHILE @cntAttrComm <= @varNumAtt
			BEGIN
			   EXECUTE @RC = [dbo].[ProtocolloSerialTabellaGetNext] 
			   'CommesseAttributi'
			   ,1
			   ,@valoreAComCSer OUTPUT

			   UPDATE #TempAttributiCommesseDaCopiare
			   SET AComCSer = @valoreAComCSer, AComCRTaca = @valoreTacaCser
			   WHERE @cntAttrComm = AComPRiga;
 
			   SET @cntAttrComm += 1
			END
			
			-- Copia della commessa
			INSERT INTO [dbo].[TabAttComm]
			   ([TacaCSer]
			   ,[TacaCTaca]
			   ,[TacaDTaca]
			   ,[TacaNVar]
			   ,[TacaCodRif]
			   ,[TacaCRTcom]
			   ,[TacaCRStato]
			   ,[TacaCRAsog]

			   ,[TacaTCrea]
			   ,[TacaTinizioRich]
			   ,[TacaTinizioPrev]
			   ,[TacaTinizioEff]
			   ,[TacaTfineRich]
			   ,[TacaTfinePrev]
			   ,[TacaTfineEff]

			   ,[TacaFAttivoSer]
			   ,[TacaFAttivoAzione]
			   ,[TacaCRTaca_ca]
			   ,[TacaXNTrasf]
			   ,[TacaXDPriorita]
			   ,[TacaXVopportunita]
			   ,[TacaXTopportunita]
			   ,[TacaXVpreventivo]
			   ,[TacaXTpreventivo]
			   ,[TacaXVconsuntivo]
			   ,[TacaXTconsuntivo]
			   ,[TacaXDRisolutore]

			   ,[TacaXNhPrevTec]
			   ,[TacaXNhPrevCom]
			   ,[TacaXNhConsTec]
			   ,[TacaXNhConsCom]

			   ,[TacaXDCommerciale]
			   ,[TacaXFGiorniAConsegna]
			   ,[TacaXNhDeltaCommerciali]
			   ,[TacaXNhDeltaTecnici]

			   ,[TacaXDUtenteIns] -- Da sostituire con l'utente che esegue la copia della commessa

			   ,[TacaXCRArtb]
			   ,[TacaAbilRicalcAna])
		 SELECT @valoreTacaCser, @outCTacaNew
			   ,[TacaDTaca]
			   ,[TacaNVar]
			   ,[TacaCodRif]
			   ,[TacaCRTcom]
			   ,[TacaCRStato]
			   ,[TacaCRAsog]

			   ,GETDATE()
				,GETDATE()
				,GETDATE()
				,GETDATE()
				,DATEADD(MONTH,1,GETDATE())
				,DATEADD(MONTH,1,GETDATE())
				,DATEADD(MONTH,1,GETDATE())

			   ,[TacaFAttivoSer]
			   ,[TacaFAttivoAzione]
			   ,@valoreTacaCser
			   ,[TacaXNTrasf]
			   ,[TacaXDPriorita]
			   ,[TacaXVopportunita]
			   ,[TacaXTopportunita]
			   ,[TacaXVpreventivo]
			   ,[TacaXTpreventivo]
			   ,[TacaXVconsuntivo]
			   ,[TacaXTconsuntivo]
			   ,[TacaXDRisolutore]

			   ,0
			   ,0
			   ,0
			   ,0

			   ,[TacaXDCommerciale]
			   ,[TacaXFGiorniAConsegna]
			   ,[TacaXNhDeltaCommerciali]
			   ,[TacaXNhDeltaTecnici]

			   ,@parUtente -- Sostituito con l'utente che esegue la copia della commessa

			   ,[TacaXCRArtb]
			   ,[TacaAbilRicalcAna]
			FROM [dbo].[TabAttComm] WHERE TacaCSer = @parCSer;


			-- Copia della degli attributi della commessa
			INSERT INTO [dbo].[CommesseAttributi]
				SELECT *
				FROM #TempAttributiCommesseDaCopiare;

			-- Se la copia è andata a buon fine, assegnazione del nuovo codice commessa al parametro di output @outEsitoCopia
			SELECT @outEsitoCopia = CAST(@valoreTacaCser as varchar(40));
		END
		ELSE
			BEGIN
			 -- Se la copia NON è andata a buon fine, assegnazione dell'errore al parametro di output @outEsitoCopia
			 SELECT @outEsitoCopia = 'La commessa da copiare non esiste'
			END
	 END TRY
		BEGIN CATCH
		  -- Se la copia NON è andata a buon fine, assegnazione dell'errore al parametro di output @outEsitoCopia
		  SELECT @outEsitoCopia = CONVERT(VARCHAR(40), ISNULL(ERROR_NUMBER(),'')) + '-' +
			CONVERT(VARCHAR(40), ISNULL(ERROR_STATE(),'')) + '-' +
			CONVERT(VARCHAR(40), ISNULL(ERROR_SEVERITY(),'')) + '-' +
			CONVERT(VARCHAR(40), ISNULL(ERROR_PROCEDURE(),'')) + '-' +
			CONVERT(VARCHAR(40), ISNULL(ERROR_LINE(),'')) + '-' +
			CONVERT(VARCHAR(40), ISNULL(ERROR_MESSAGE(),'')) + '-' +
			CONVERT(VARCHAR(40), ISNULL(GETDATE(),''), 101);
		END CATCH;
END
