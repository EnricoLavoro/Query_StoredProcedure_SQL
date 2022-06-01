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
-- Author:		Enrico
-- Create date: 1 Giugno 2022
-- Description:	Prova creazione tracciato che contiene anche le righe delle note di accredito emesse nel periodo selezionato 
-- =============================================
ALTER PROCEDURE [dbo].[ITsp_ExpDocFDC_DAO_UpdateEnrico] (@codSoggetto as varchar(40),@DaData as date,@AData as date,@parExpPath as varchar(255)) 
AS
BEGIN

declare @server_db_name varchar (200)
declare @user_name varchar (100)
declare @pwd_name varchar (100)
declare @outdoc_path varchar(100)
declare @server_name varchar (200)


set @server_db_name='[GESTIONALE1\UP].up_NuovaDist'
set @user_name='grupposga'
set @pwd_name='agsoppurg'
SET @server_name = @@SERVERNAME

--creo il nome per il file a seconda della tabella
SELECT @outdoc_path = 'NU' + right(cast(YEAR(getdate()) as varchar),2) +  right('00' + cast(MONTH(getdate()) as varchar),2) 
		+ right('00' + cast(DAY(getdate()) as varchar),2) + '_' + @codSoggetto + '.txt'


declare @DaDataStr as varchar(10)
declare @ADataStr as varchar(10)
set @DaDataStr=right(cast(YEAR(@DaData) as varchar),2) +  right('00' + cast(MONTH(@DaData) as varchar),2) 
		+ right('00' + cast(DAY(@DaData) as varchar),2)
set @ADataStr=right(cast(YEAR(@AData) as varchar),2) +  right('00' + cast(MONTH(@AData) as varchar),2) 
		+ right('00' + cast(DAY(@AData) as varchar),2)


--imposto il percorso corretto del file	
	IF RIGHT(@parExpPath,1) = '\'
	BEGIN
		set  @outdoc_path = @parExpPath + @outdoc_path
	END
	ELSE
	BEGIN
	    set  @outdoc_path = @parExpPath + '\' + @outdoc_path
	END
	
	

	declare @Command varchar(8000)

	set @command =  'bcp "Select Recordx + RIGHT(''00000'' + CAST(row_number() OVER(ORDER BY IDDoc, IDDocProgr) AS VARCHAR(5)),5) + Record 								
							FROM 								
							( 								
							SELECT DISTINCT
								CASE WHEN DDT.MbaisCSer IS NOT NULL
									THEN DDT.MbaisCSer
									ELSE ''       '' END AS IDDoc,
								''0'' AS IDDocProgr,								   
								''10'' AS Recordx,
								'' '' 									
								+ RIGHT(''000000'' + cast(cast(right(FDC.mbaiscprotsec,6) AS int) AS varchar),6) 									
								+ RIGHT(cast(YEAR(FDC.mbaistins) AS varchar),2) + right(''00'' + cast(MONTH(FDC.mbaistins) AS varchar),2) + right(''00'' + cast(DAY(FDC.mbaistins) AS varchar),2) 	
								+ CASE WHEN DDT.mbaiscmbais IS NOT NULL
									THEN RIGHT(''000000'' + cast(cast(right(DDT.mbaiscmbais,9) AS int) AS varchar),6)
									ELSE ''      '' END
								+ CASE WHEN DDT.MbaisTins IS NOT NULL
									THEN RIGHT(cast(YEAR(DDT.mbaistins) AS varchar),2) + right(''00'' + cast(MONTH(DDT.mbaistins) AS varchar),2) + right(''00'' + cast(DAY(DDT.mbaistins) AS varchar),2)
									ELSE ''      '' END
								+ LEFT(''160432'' + ''                                      '', 25) 									 
								+ LEFT(CL.AsogXDCodPuntoVendita + ''                                                                                                            '', 65) 									 
								+ CASE WHEN DDT.mbaiscmbais IS NOT NULL 
									THEN RIGHT(''00000'' + cast(cast(right(DDT.mbaiscmbais,9) AS int) AS varchar),5)
									ELSE ''     '' END
								+ ''.'' AS Record
							FROM '+ @server_db_name + '.dbo.istbasestopmaster FDC 								
							INNER JOIN '+ @server_db_name + '.dbo.IstBaseStOpRighe FDC_R		on FDC.MbaisCSer=FDC_R.RbaisCRMbais 								
							INNER JOIN '+ @server_db_name + '.dbo.IstCComAtStOpMColl			on KCAISCser=MbaisCSer 								
							INNER JOIN '+ @server_db_name + '.dbo.Soggetti CL				on FDC.MbaisCRasog=CL.AsogCSer 								
							INNER JOIN '+ @server_db_name + '.dbo.Soggetti CL_F				on KCAISCRAsogf=CL_F.AsogCSer 								
							INNER JOIN '+ @server_db_name + '.dbo.IstRifStOpRColl			on HRIISCRRbais=FDC_R.RbaisCser 								
							INNER JOIN  '+ @server_db_name + '.dbo.IstBaseStOpMaster DDT		on HRIISCRMbaisPr=DDT.mbaiscser 								
							INNER JOIN  '+ @server_db_name + '.dbo.IstBaseStOpRighe  DDT_R	on DDT_R.RbaisCRMbais=DDT.mbaiscser 								
							WHERE FDC.mbaistins between '''+ @DaDataStr +''' and ''' + @ADataStr + ''' 									 
							and CL_F.AsogCAsog =''' +  @codSoggetto + ''' 									  
							and FDC.mbaiscrmcso in (4,5)   								

							UNION ALL   								

							SELECT
								CASE WHEN DDT_R.Rbaiscrmbais IS NOT NULL
									THEN DDT_R.Rbaiscrmbais
									ELSE ''       '' END AS IDDoc,
								CASE WHEN DDT_R.RbaisPRig IS NOT NULL
									THEN DDT_R.RbaisPRig
									ELSE ''  '' END AS IDDocProgr,									   
								''20'' AS Recordx, 									   
								LEFT(ArtbCArtb + ''               '', 15) 									
								+ LEFT(FDC_R.RbaisDaart + ''                              '',30) 									
								+ RIGHT(''  '' + Tumsctums,2)  									 
								+ RIGHT(''000000'' + CAST(CONVERT(INT,FDC_R.RbaisQoum) AS VARCHAR),6) 									 
								+ LEFT(REPLACE(CAST(FDC_R.RbaisQoum-CONVERT(INT,FDC_R.RbaisQoum) AS VARCHAR),''0.'','''') + ''000'',3) 									
								+ RIGHT(''000000'' + CAST(CONVERT(INT,(HCAISCRprzQImpValuta-HCAISCRvscuQImpValuta)) AS VARCHAR),6) 									
								+ LEFT(REPLACE(CAST((HCAISCRprzQImpValuta-HCAISCRvscuQImpValuta)-CONVERT(INT,(HCAISCRprzQImpValuta-HCAISCRvscuQImpValuta)) AS VARCHAR),''0.'','''') + ''000'',3) 									 
								+ RIGHT(''0000000'' + CAST(CONVERT(INT,HCAISCRvipQImpValuta) AS VARCHAR),7) 									 
								+ LEFT(REPLACE(CAST(HCAISCRvipQImpValuta-CONVERT(INT,HCAISCRvipQImpValuta) AS VARCHAR),''0.'','''') + ''00'',2) 									 
								+ ''0000'' 									 + '' '' 									 
								+ right(''  '' + cast(TaliPAliDet AS varchar(2)),2)
								+ CASE WHEN DDT.MBAISCRMCSO = 4 THEN ''2'' ELSE ''1'' END 									
								+ CASE WHEN DDT_R.RBAISCRTTSO = 1 THEN '' '' WHEN DDT_R.RBAISCRTTSO = 2 THEN ''4'' WHEN DDT_R.RBAISCRTTSO = 3 THEN ''4'' END  									 
								+ ''             ''  									 + '' '' 									 + ''     ''  									 
								+ ''     '' 									 + ''        '' 									 + RIGHT(''00000'' + cast(cast(right(DDT.mbaiscmbais,9) AS int) AS varchar),5) 									
								+ ''.'' AS Record 								
							FROM '+ @server_db_name + '.dbo.istbasestopmaster FDC 								
							INNER JOIN '+ @server_db_name + '.dbo.IstBaseStOpRighe FDC_R		on FDC.MbaisCSer=FDC_R.RbaisCRMbais 								
							INNER JOIN '+ @server_db_name + '.dbo.IstCComAtStOpRColl			on FDC_R.RbaisCSer=HCAISCser 								
							INNER JOIN '+ @server_db_name + '.dbo.ArticoliBase				on FDC_R.RbaisCRArtb=Artbcser 								
							INNER JOIN '+ @server_db_name + '.dbo.TabUnitaMisura				on FDC_R.RbaisCRTums=TumsCser 								
							INNER JOIN '+ @server_db_name + '.dbo.IstContStOpRColl			on HCAISCser=HCOISCser 								
							INNER JOIN '+ @server_db_name + '.dbo.TabAliquoteIVA				on Talicser=HCOISCRTali 								
							INNER JOIN '+ @server_db_name + '.dbo.IstRifStOpRColl			on HRIISCRRbais=FDC_R.RbaisCser 								
							INNER JOIN '+ @server_db_name + '.dbo.IstBaseStOpMaster DDT		on HRIISCRMbaisPr=DDT.mbaiscser 								
							INNER JOIN '+ @server_db_name + '.dbo.IstBaseStOpRighe DDT_R		on HRIISCRRbaisPr=DDT_R.rbaiscser 								
							INNER JOIN '+ @server_db_name + '.dbo.IstCComAtStOpMColl			on KCAISCser=FDC.MbaisCSer 								
							INNER JOIN '+ @server_db_name + '.dbo.Soggetti CL				on FDC.MbaisCRasog=CL.AsogCSer 								
							INNER JOIN '+ @server_db_name + '.dbo.Soggetti CL_F				on KCAISCRAsogf=CL_F.AsogCSer 								
							WHERE FDC.mbaistins between '''+ @DaDataStr +''' and ''' + @ADataStr + ''' 									
							and CL_F.AsogCAsog = ''' +  @codSoggetto + ''' 									
							and FDC.mbaiscrmcso in (4,5) 								
							) TRACCIATO 								
							ORDER BY TRACCIATO.IDDoc,TRACCIATO.IDDocProgr'

	SET @command = REPLACE(REPLACE(@command, CHAR(10), ''), CHAR(13), ' ') +   '" queryout  "' + @outdoc_path + '" -S "' + @server_name + '" -U "' + @user_name + '" -P "' + @pwd_name + '" -k -c -C ACP -t "|"'
	print @command
	exec master..xp_cmdshell @command
END
