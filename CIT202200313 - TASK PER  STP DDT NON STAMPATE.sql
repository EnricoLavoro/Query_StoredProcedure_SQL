USE [up_NuovaDist]
GO
/****** Object:  StoredProcedure [dbo].[ITsp_StampaDDC]    Script Date: 11/07/2022 16:51:32 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Enrico Piccin
-- Create date: 11 Luglio 2022
-- Description:	CIT202200313 - TASK PER  STP DDT NON STAMPATE
-- =============================================
ALTER PROCEDURE [dbo].[ITsp_StampaDDC]
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	DECLARE @command VARCHAR(4000)
	DECLARE @ddcCod  VARCHAR(200)
	DECLARE @CursorTestID INT = 1;
	DECLARE @RowCnt BIGINT = 0;

	IF OBJECT_ID('tempdb..#TabDCC')   IS NOT NULL DROP TABLE #TabDCC;

	SELECT ROW_NUMBER() OVER(ORDER BY T.MbaisCSer ASC) AS Progressivo, T.MbaisCMbais 
	INTO #TabDCC
	FROM IstBaseStOpMaster T
	INNER JOIN IstSpedStOpMColl ON T.MbaisCSer = KSPISCser
	WHERE MbaisCRMcso = 2
	AND DATEDIFF(DAY,KSPISTinitr,GETDATE()) = 0
	AND MbaisBStampato = 0
	AND DATEDIFF(MINUTE,KSPISMinitr,GETDATE()) > 30

	-- Numero totale di DDC da stampare
	SET @RowCnt = @@ROWCOUNT
 
	WHILE @CursorTestID <= @RowCnt
	BEGIN
	   SET @ddcCod = (SELECT MbaisCMbais FROM #TabDCC WHERE Progressivo = @CursorTestID)

	   SET @command = 'BatchUp.exe "C:\Program Files (x86)\NetPortal\UP\Bin\StampaDDC.xml" /p "' + @ddcCod + '" "' + SUBSTRING(@ddcCod,6,2) + '" "' + 
	   SUBSTRING(RIGHT(@ddcCod,9),PATINDEX('%[1-9]%',RIGHT(@ddcCod,9)),LEN(RIGHT(@ddcCod,9)) - PATINDEX('%[1-9]%',RIGHT(@ddcCod,9)) + 1) + '"';

	   EXEC master..xp_cmdshell @command;

	   SET @CursorTestID = @CursorTestID + 1;
	END

	IF OBJECT_ID('tempdb..#TabDCC')   IS NOT NULL DROP TABLE #TabDCC;
END
