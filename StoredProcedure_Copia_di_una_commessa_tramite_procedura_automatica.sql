USE [up_Mosian]
GO
/****** Object:  StoredProcedure [dbo].[ITsp_InsCopiaCommessa]    Script Date: 02/03/2022 14:02:06 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Enrico Piccin
-- Create date: 1 Marzo 2022
-- Description:	Copia di una commessa tramite procedura automatica
-- =============================================
ALTER PROCEDURE [dbo].[ITsp_InsCopiaCommessa] (@parCSer int)
	-- Add the parameters for the stored procedure here
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	DECLARE @RC int
	DECLARE @valore float
	DECLARE @varNumAtt int                -- Numero di attributi copiati
	DECLARE @varCTaca varchar(20)		  -- TacaCTaca della commessa copiata
	DECLARE @tempCodiceCnCOM varchar(40)  -- Temporanea

	 BEGIN TRY
		IF EXISTS(SELECT 1 FROM [dbo].[TabAttComm] WITH(NOLOCK)
          WHERE TacaCSer = @parCSer)
		BEGIN

		EXECUTE @RC = [dbo].[ProtocolloSerialTabellaGetNext] 
		   'TabAttComm'
		  ,1
		  ,@valore OUTPUT

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
			  SELECT @valore, @varCTaca
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
			  ,@valore
			  ,[TacaAbilRicalcAna]
			FROM [dbo].[TabAttComm] WHERE TacaCSer = @parCSer;
		END
		ELSE
			BEGIN
			 PRINT 'Il record non esiste'
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
