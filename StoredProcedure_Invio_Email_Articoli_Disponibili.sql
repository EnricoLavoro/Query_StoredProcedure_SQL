USE [up_tecnoclean]
GO

/****** Object:  StoredProcedure [dbo].[ITsp_Job_Mail_Articoli_DDF_Disponibili]    Script Date: 26/08/2022 16:26:24 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

-- *************************************************************************************************************************************************** --
-- * Author:		Enrico Piccin																													 * --
-- * Create date: 11/08/2022																														 * --
-- * Description:	CIT202200357 - ALLARME ARTICOLI DDF DISPONIBILI - PROCEDURA CHE INVIA MAIL CON L'ESTRAPOLAZIONE DEGLI ARTICOLI DDF DISPONIBILI	 * --
-- *************************************************************************************************************************************************** --

ALTER PROCEDURE [dbo].[ITsp_Job_Mail_Articoli_DDF_Disponibili] (@Orario AS VARCHAR(5))
AS
BEGIN
	
	SET NOCOUNT ON;
	
	-- Dichiarazione elementi di composizione e-mail
	DECLARE @body	 AS VARCHAR(3000)
	DECLARE @subject AS VARCHAR(3000)
	DECLARE @recipients AS VARCHAR(2000)
	DECLARE @referent AS VARCHAR(200)

	-- Valorizzazione elementi di composizione e-mail
	SET @subject	= 'ARTICOLI DDF DISPONIBILI ALLE ORE ' + @Orario
	SET @body		= 'In allegato quanto in oggetto, secondo l''analisi di articoli DDF disponibili per l''evasione.'
	SET @recipients = 'enrico.piccin@info-team.net'

	-- Stampa elementi di composizione e-mail
	PRINT @subject
	PRINT @body

	-- Dichiarazione parametri di file da allegare
	DECLARE @command	 AS VARCHAR(4000)
	DECLARE @server_name AS VARCHAR(20)
	DECLARE @db_name	 AS VARCHAR(20)
	DECLARE @user_name	 AS VARCHAR(20)
	DECLARE @pwd_name	 AS VARCHAR(20)
	DECLARE @out_path	 AS VARCHAR(1000)
	DECLARE @iRis		 AS INT
	DECLARE @data		 AS DATE

	-- Valorizzazione parametri di file da allegare
	SET @server_name = @@SERVERNAME
	SET @db_name	 = DB_NAME()
	SET @user_name	 = 'grupposga'
	SET @pwd_name	 = 'agsoppurg'
	SET @out_path	 = '\\vmtecnoclean\NetPortal\up\ARTICOLI_DDF_DISPONIBILI_' + LEFT(@Orario,2) + '.CSV'
	--SET @out_path	 = '\\x3650\UP\stat-excel\ARTICOLI_DDF_DISPONIBILI_' + LEFT(@Orario,2) + '.CSV'
	SET @data		 = GETDATE()
	SET @command	 = 'bcp "SELECT Giacenza FROM ' + @db_name + '.dbo.ITv_JOB_Articoli_DDF_Disponibili"'
	SET @command	 = REPLACE(REPLACE(@command, CHAR(10), ''), CHAR(13), ' ') +   ' queryout  "' + @out_path + '" -S "' + @server_name + '" -U "' + @user_name + '" -P "' + @pwd_name + '" -c -C ACP -t ";"'
	PRINT @command

	-- Stampa parametri di file da allegare
	PRINT @out_path
	
	-- Prima elaborazione
	EXEC @iRis = master..xp_cmdshell @command
	
	EXEC msdb.dbo.sp_send_dbmail 
	@profile_name	   = 'gestionale', --claudia 28/12/21 sostituito account aruba che si blocca se 200 mail in 20 min , --Claudia 13/12/21 'up' non funziona più non arrivano le mail
	@recipients		   = @recipients,
	@subject		   = @subject,
	@body			   = @body,
	@file_attachments  = @out_path;
END
GO


