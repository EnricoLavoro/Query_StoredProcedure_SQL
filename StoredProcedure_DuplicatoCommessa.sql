-- ================================================
-- Template generated from Template Explorer using:
-- Create Procedure (New Menu).SQL
--
-- Use the Specify Values for Template Parameters 
-- command (Ctrl-Shift-M) to fill in the parameter 
-- values below.
--
-- This block of comments will not be included in
-- the definition of the procedure.
-- ================================================
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Enrico Piccin
-- Create date: 1 Marzo 2022
-- Description:	Copia di una commessa tramite procedura automatica
-- =============================================
ALTER PROCEDURE ITsp_InsCopiaCommessa (@parCSer int, @parCodProt varchar(20))
	-- Add the parameters for the stored procedure here
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	DECLARE @RC int
	DECLARE @valore float
	DECLARE @varCncomCRMtpro int
	DECLARE @parCTaca int

-- TODO: impostare qui i valori dei parametri.

	EXECUTE @RC = [dbo].[ProtocolloSerialTabellaGetNext] 
	   'TabAttComm'
	  ,1
	  ,@valore OUTPUT

	 SELECT @valore;
	 SELECT @parCTaca;
	 SET @varCncomCRMtpro =	(SELECT CncomCRMtpro FROM TabAttComm INNER JOIN CommesseTipi ON TacaCRTcom = TcomCser INNER JOIN ConfProtCommesse ON TcomCRCncom = CncomCSer);
	 SET @parCodProt = (SELECT CONCAT(@parCodProt,':',@varCncomCRMtpro,':',YEAR(getdate())));

	-- TODO: impostare qui i valori dei parametri.

	EXECUTE @RC = [dbo].[ProtocolloGetNext] 
		 @parCodProt
		,'U'
		,0
		,1
		, NULL
		,@parCTaca OUTPUT

	 BEGIN TRY
		IF EXISTS(SELECT 1 FROM [dbo].[TabAttComm] WITH(NOLOCK)
          WHERE TacaCSer = @parCSer)
		BEGIN
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
			  SELECT @valore, @parCTaca
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
go