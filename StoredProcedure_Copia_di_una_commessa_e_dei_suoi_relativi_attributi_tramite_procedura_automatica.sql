USE [up_Mosian]
GO
/****** Object:  StoredProcedure [dbo].[ITsp_InsCopiaCommessaAttributi]    Script Date: 03/03/2022 14:18:31 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
ALTER PROCEDURE [dbo].[ITsp_InsCopiaCommessaAttributi] (@parCSer int)
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
	DECLARE @varCTaca varchar(20)		  -- TacaCTaca della commessa copiata
	DECLARE @tempCodiceCnCOM varchar(40)  -- Temporanea

	 BEGIN TRY
		IF EXISTS(SELECT 1 FROM [dbo].[TabAttComm] WITH(NOLOCK)
          WHERE TacaCSer = @parCSer)
		BEGIN
		
		-- Creazione della stringa CncomCRMtpro per la ricerca del codice protocllo
		SELECT @tempCodiceCnCOM = CONCAT('Cncom:',(SELECT CncomCRMtpro FROM TabAttComm INNER JOIN CommesseTipi ON TacaCRTcom = TcomCser INNER JOIN ConfProtCommesse ON TcomCRCncom = CncomCser WHERE [TacaCSer] = @parCSer),':',YEAR(getdate()));

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
		SELECT @varCTaca = CONCAT(YEAR(getdate()), RIGHT(CONCAT('000000000', @varProtCSer),9));
		SELECT @varCTaca AS 'Codice';

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

		 -- Aggiornamento seriale attriuto [AComCSer] e codice commessa associato [AComCRTaca]
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
				   ,[TacaAbilRicalcAna])
			  SELECT @valoreTacaCser, @varCTaca
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
			  ,[TacaAbilRicalcAna]
			FROM [dbo].[TabAttComm] WHERE TacaCSer = @parCSer;

			-- Copia della degli attributi della commessa
			INSERT INTO [dbo].[CommesseAttributi]
				SELECT *
				FROM #TempAttributiCommesseDaCopiare;
		END
		ELSE
			BEGIN
			 PRINT 'La commessa non esiste'
			END
	 END TRY
		BEGIN CATCH
		  SELECT
			ERROR_NUMBER() AS ErrorNumber,
			ERROR_STATE() AS ErrorState,
			ERROR_SEVERITY() AS ErrorSeverity,
			ERROR_PROCEDURE() AS ErrorProcedure,
			ERROR_LINE() AS ErrorLine,
			ERROR_MESSAGE() AS ErrorMessage;
		END CATCH;
END
