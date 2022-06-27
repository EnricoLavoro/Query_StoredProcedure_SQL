SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Enrico Piccin
-- Create date: 27 Giugno 2022
-- Description: CIT202200296 - DATA INSERIMENTO PRODOTTO
-- =============================================
ALTER PROCEDURE ITsp_AggiungiDataInserimentoProdotto (@parArtbCSer INT, @Risultato INT OUTPUT) AS

BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    SELECT ArtbCArtb, AttrCAttr, VlatCVlat
	FROM ArticoliBase
	INNER JOIN ArticoliAttributi ON ArtaCSerArtb = ArtbCSer
	INNER JOIN Attributi ON ArtaCSerAttr = AttrCSer
	INNER JOIN ValoriAttributo ON ArtaCSerVlat = VlatCSer
	WHERE ArtbCSer = @parArtbCSer AND AttrCAttr = 'DINS';

	IF(@@ROWCOUNT = 0)
	BEGIN 
		DECLARE @varArtaCSer INT
		DECLARE @varVlatCSer INT
		DECLARE @prig INT
		DECLARE @varDIns DATETIME

		EXEC ProtocolloSerialTabellaGetNext 'ArticoliAttributi', 1 , @varArtaCSer OUTPUT
		EXEC ProtocolloSerialTabellaGetNext 'ValoriAttributo',   1 , @varVlatCSer OUTPUT
		
		SELECT @prig = MAX(VlatPrig) from ValoriAttributo where VlatCSerAttr = (SELECT AttrCSer FROM Attributi WHERE AttrCAttr = 'DINS')
		IF @prig is null SET @prig = 1 
		ELSE SET @prig = @prig+1

		SET @varDIns = FORMAT (GETDATE(), 'dd/MM/yyyy HH:mm:ss')

		SELECT @varArtaCSer, @varVlatCSer, @prig, @varDIns

		INSERT INTO [dbo].[ArticoliAttributi]
				   ([ArtaCSer]
				   ,[ArtaCSerArtb]
				   ,[ArtaCSerAttr]
				   ,[ArtaCSerVlat]
				   ,[ArtaDValAttr]
				   ,[ArtaPRig]
				   ,[ArtaDValAtt]
				   ,[ArtaTValAtt]
				   ,[ArtaNValAtt]
				   ,[ArtaIAttrCSer]
				   ,[ArtaIAttrCAzione]
				   ,[ArtaFAddStopCSer]
				   ,[ArtaFAddStopCAzione]
				   ,[ArtaCRTpCon])
			 VALUES
				   (@varArtaCSer
				   ,@parArtbCSer
				   ,(SELECT AttrCSer FROM Attributi WHERE AttrCAttr = 'DINS')
				   ,@varVlatCSer
				   ,NULL
				   ,1
				   ,''
				   ,@varDIns
				   ,0
				   ,226
				   ,'N'
				   ,1796
				   ,'N'
				   ,0)
		

		INSERT INTO [dbo].[ValoriAttributo]
				([VlatCSer]
				,[VlatPrig]
				,[VlatCSerAttr]
				,[VlatCVlat]
				,[VlatDVlat]
				,[VlatDBreveVlat]
				,[VlatDBitMap]
				,[VlatAsiaId])
			VALUES
				(@varVlatCSer
				,@prig
				,(SELECT AttrCSer FROM Attributi WHERE AttrCAttr = 'DINS')
				,@varDIns
				,'Data inserimento articolo'
				,''
				,''
				,0)
		END
	ELSE
		BEGIN
			SET @varDIns = GETDATE()

			UPDATE [dbo].[ValoriAttributo]
			   SET [VlatCVlat] = @varDIns
			 WHERE VlatCSer = (SELECT ArtaCSerVlat FROM ArticoliAttributi WHERE ArtaCSerAttr = @parArtbCSer)
		END
END
