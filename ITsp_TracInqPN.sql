USE [up_marchioricontino]
GO
/****** Object:  StoredProcedure [dbo].[ITsp_TracInqPN]    Script Date: 23/05/2022 13:58:25 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Enrico Piccin
-- Create date: 12 Maggio 2022
-- =============================================
ALTER PROCEDURE [dbo].[ITsp_TracInqPN] (@parDaData AS DATE, @parAData AS DATE, @par_path AS VARCHAR(50), @outEsito AS VARCHAR(100) OUTPUT)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	IF OBJECT_ID('tempdb..#TabContratti')   IS NOT NULL DROP TABLE #TabContratti;
	IF OBJECT_ID('tempdb..##OutputResult')	IS NOT NULL DROP TABLE ##OutputResult;

	SELECT DISTINCT MbaisCMbais, MbaisCRTaca, MbaisTrichiesta, T.Attr1, T.Val1, T.Attr2, T.Val2, T.Attr3, T.Val3
	INTO #TabContratti
	FROM IstBaseStOpMaster
	INNER JOIN (SELECT T1.MbaisCSer AS Serial, T1.TgrsCTgrs AS Attr1, T1.RgrsCRgrs AS Val1, T2.TgrsCTgrs AS Attr2, T2.RgrsCRgrs AS Val2, T3.AttrCAttr AS Attr3, T3.KatisNvalatt AS Val3
		FROM
		(SELECT MbaisCSer, TgrsCTgrs, RgrsCRgrs
		FROM IstBaseStopMaster
		INNER JOIN IstGrStatStOpMColl AS KGSIS1 ON KGSIS1.KgsisCRMbais = MbaisCSer
		RIGHT JOIN TabGruppiStatistici AS TGRS1 ON TGRS1.TgrsCSer = KGSIS1.KgsisCRgrs
		LEFT JOIN GruppiStatisticiRighe AS RGRS1 ON RGRS1.RgrsCSer = KGSIS1.KgsisCRvgrs) T1
		INNER JOIN
		(SELECT MbaisCSer, TgrsCTgrs, RgrsCRgrs
		FROM IstBaseStopMaster
		INNER JOIN IstGrStatStOpMColl AS KGSIS1 ON KGSIS1.KgsisCRMbais = MbaisCSer
		RIGHT JOIN TabGruppiStatistici AS TGRS1 ON TGRS1.TgrsCSer = KGSIS1.KgsisCRgrs
		LEFT JOIN GruppiStatisticiRighe AS RGRS1 ON RGRS1.RgrsCSer = KGSIS1.KgsisCRvgrs) T2
		ON T1.MbaisCSer = T2.MbaisCSer
		INNER JOIN 
		(SELECT MbaisCSer, KatisNvalatt, AttrCAttr
		FROM IstBaseStOpMaster INNER JOIN IstAttrStOpMColl ON KatisCRMbais = MbaisCSer
		INNER JOIN Attributi ON AttrCSer = KatisCRattr) T3
		ON T2.MbaisCSer = T3.MbaisCSer
		WHERE T1.TgrsCTgrs='CTISA' AND T2.TgrsCTgrs='TUISA' AND T3.AttrCAttr = 'VAISA') T ON MbaisCSer = T.Serial
	WHERE MbaisCRMcso=23;

	---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

	SELECT ROW_NUMBER() OVER(ORDER BY M.MbaisCSer ASC) AS Progressivo,
	NULL AS Nullo,
	LEFT(TcsoCTcso,1) AS CausaleDocumento, 
	'P_'+RIGHT(M.MbaisCMbais,13) AS NumeroDocumento,
	CONVERT(VARCHAR(10), M.MbaisTins, 111) AS DataEsportazione,
	NULL AS SerieDocumento,
	'SEDEP' AS SedeEmissione,
	CASE WHEN R1.RgrsCRgrs = 'I' THEN 'Q' ELSE R1.RGrsCRgrs END AS TipoSoggetto,
	SogClienti.AsogCAsog AS CodiceCliente,
	SogClienti.AsogDAsog AS DescrizioneCliente,
	SogControparte.AsogCAsog AS CodiceControparte,
	SogControparte.AsogDAsog AS DescrizioneControparte,
	TabC.MbaisCMbais AS RiferimentoContratto,
	NULL AS AnnotazioneTestata,
	TmpaCTmpa AS CodicePagamento,
	CASE WHEN SUBSTRING(SogClienti.AsogDatIBANBE,5,5) IS NULL OR SUBSTRING(SogClienti.AsogDatIBANBE,5,5) = ''
	THEN NULL
	ELSE SUBSTRING(SogClienti.AsogDatIBANBE,5,5)
	END AS CodiceABI,
	CASE WHEN SUBSTRING(SogClienti.AsogDatIBANBE,10,5) IS NULL OR SUBSTRING(SogClienti.AsogDatIBANBE,10,5) = ''
	THEN NULL
	ELSE SUBSTRING(SogClienti.AsogDatIBANBE,10,5)
	END AS CodiceCAB,
	CASE WHEN SogClienti.AsogDatIBANBE IS NULL OR SogClienti.AsogDatIBANBE = ''
	THEN NULL
	ELSE SogClienti.AsogDatIBANBE
	END AS CodiceIBAN,
	TabC.Val3 AS ValoreAffittoISA,
	--CASE WHEN TabC.CodArtxPlus = 'CAN'
	--	THEN TabC.PrezzoUnitario
	--	ELSE (SELECT PrezzoUnitario FROM #TabContratti WHERE #TabContratti.MbaisCRAsog = SogClienti.AsogCSer AND #TabContratti.TacaCRAsog = SogControparte.AsogCSer AND #TabContratti.CodArtxPlus = 'CAN') 
	--END AS ValoreAffittoISA,
	TabC.Val1 AS ConteggiaTrattativaISA,
	TabC.Val2 AS TrattativaUnilateraleISA,
	NULL AS NonUtilizzato1,
	NULL AS NonUtilizzato2,
	ROW_NUMBER() OVER(PARTITION BY M.MbaisCSer, M.MbaisCMbais ORDER BY M.MbaisCSer ASC) AS NumeroRiga,
	CASE WHEN ArtbCCodEsterno IS NOT NULL AND ArtbCCodEsterno <> ''
		THEN ArtbCCodEsterno
		ELSE ArtbCArtb
	END AS CodArtxPlus,
	CASE WHEN CHARINDEX('CANONE AFFITTO',RbaisDaart) > 0 THEN 
			'CANONE AFFITTO'
		ELSE CASE WHEN CHARINDEX('SPESE  CONDOMINIALI',RbaisDaart) > 0 THEN
			'SPESE CONDOMINIALI'
		ELSE
			RbaisDaart
		END
	END AS Desc1,
	CASE WHEN CHARINDEX('CANONE AFFITTO',RbaisDaart) > 0 THEN 
			RIGHT(RbaisDaart,LEN(RbaisDaart)-LEN('CANONE AFFITTO'))
		ELSE CASE WHEN CHARINDEX('SPESE  CONDOMINIALI',RbaisDaart) > 0 THEN
			RIGHT(RbaisDaart,LEN(RbaisDaart)-LEN('SPESE  CONDOMINIALI'))
		ELSE
			''
		END
	END AS Desc2,
	TumsCTums AS UMisura,
	RbaisQoum AS Qta,
	HCAISCRprzQImpValLoc AS PrezzoUnitario,
	0 AS Sconto1,
	0 AS Sconto2,
	'-' AS SegnoMovimento,
	YEAR(MbaisTins) AS APerCompetenza,
	'M' + CASE WHEN MONTH(M.MbaisTins) < 10
	THEN '0' + CONVERT(VARCHAR(2),MONTH(M.MbaisTins))
	ELSE CONVERT(VARCHAR(2),MONTH(M.MbaisTins))
	END + ' ' + UPPER(SUBSTRING(DATENAME(month,M.MbaisTins),1,1)) + SUBSTRING(DATENAME(month,M.MbaisTins),2,LEN(DATENAME(month,M.MbaisTins))-1) AS TPerCompetenza,
	12 AS NPerCompetenza,
	TaliCTali AS CodIVAxPlus,
	AscoCAsco AS CodContPartxPlus,
	CASE WHEN T.SogRit IS NULL THEN 'N' ELSE T.SogRit END AS SogRit,
	NULL AS AnnotRiga,
	NULL AS Vuoto1,
	NULL AS Vuoto2, 
	NULL AS UtenteCreazione,
	NULL AS DataCreazione,
	NULL AS UtenteUltMod,
	NULL AS DataUltMod,
	NULL AS Vuoto3,
	NULL AS Vuoto4
	INTO ##OutputResult
	FROM IstBaseStOpMaster AS M
	INNER JOIN IstBaseStOpRighe ON MbaisCSer = RbaisCRMbais
	INNER JOIN TabUnitaMisura ON RbaisCRTums = TumsCSer
	INNER JOIN IstCComAtStOpRColl ON RbaisCSer = HCAISCser
	INNER JOIN IstContStOpRColl ON RbaisCSer = HCOISCser
	INNER JOIN TabAliquoteIVA ON HCOISCRTali = TaliCser
	INNER JOIN SottoConti ON HCOISCRCpart = AscoCSer
	INNER JOIN TabAttComm ON M.MbaisCRTaca = TacaCser
	INNER JOIN ArticoliBase ON ArtbCSer = RbaisCRArtb

	INNER JOIN IstCComAtStOpMColl ON M.MbaisCSer = KCAISCser
	INNER JOIN TabModPagInc ON KCAISCRTmpi=TmpaCSer
	INNER JOIN TabCausaliStOp ON M.MbaisCRTcso = TcsoCSer
	INNER JOIN TabAttComm AS TabAtt  ON M.MbaisCRTaca = TabAtt.TacaCSer
	INNER JOIN IstGrStatStOpMColl    ON KgsisCRMbais = MbaisCSer
	INNER JOIN TabGruppiStatistici   AS TG0 ON TG0.TgrsCSer = KgsisCRgrs
	INNER JOIN GruppiStatisticiRighe AS R0  ON R0.RgrsCSer = KgsisCRvgrs

	INNER JOIN Soggetti AS SogClienti ON MbaisCRAsog = SogClienti.AsogCSer
	INNER JOIN LegSoggettiGruppiStat AS L1 ON SogClienti.AsogCSer = L1.LsgsCRifAsog
	INNER JOIN TabGruppiStatistici AS TG1 ON TG1.TgrsCSer = L1.LsgsCRifGrs
	INNER JOIN GruppiStatisticiRighe AS R1 ON R1.RgrsCSer = L1.LsgsCRifVgrs

	INNER JOIN Soggetti AS SogControparte ON TabAtt.TacaCRAsog = SogControparte.AsogCSer
	INNER JOIN LegSoggettiGruppiStat AS L2 ON SogControparte.AsogCSer = L2.LsgsCRifAsog
	INNER JOIN TabGruppiStatistici AS TG2 ON TG2.TgrsCSer = L2.LsgsCRifGrs
	INNER JOIN GruppiStatisticiRighe AS R2 ON R2.RgrsCSer = L2.LsgsCRifVgrs

	LEFT JOIN (SELECT AsogCSer, RgrsCRgrs AS SogRit 
		FROM 
		Soggetti INNER JOIN LegSoggettiGruppiStat ON AsogCSer = LsgsCRifAsog
		INNER JOIN TabGruppiStatistici ON TgrsCSer = LsgsCRifGrs
		INNER JOIN GruppiStatisticiRighe ON RgrsCSer = LsgsCRifVgrs
		WHERE TgrsCTgrs='SOGRIT') AS T ON SogClienti.AsogCSer = T.AsogCSer

	INNER JOIN #TabContratti AS TabC ON TabC.MbaisCRTaca = M.MbaisCRTaca AND M.MbaisTrichiesta = TabC.MbaisTrichiesta

	WHERE MbaisCRMcso IN (25,29,31,33) AND TG0.TgrsCTgrs = 'EXPLUS' AND R0.RgrsCRgrs = 'S' AND TG1.TgrsCTgrs='TSO' AND TG2.TgrsCTgrs='TSO'
	AND M.MbaisTins BETWEEN @parDaData AND @parAData
	ORDER BY 1 ASC, SogControparte.AsogCSer ASC;

	SELECT * FROM #TabContratti;
	SELECT * FROM ##OutputResult;

	DECLARE @command varchar(4000)
	DECLARE @server_name varchar(200)
	DECLARE @db_name varchar(20)
	DECLARE @user_name varchar(20)
	DECLARE @pwd_name varchar(20)
	DECLARE	@return_value int
	DECLARE @esito TABLE (esito NVARCHAR(4000));

	SET @server_name = @@servername
	SET @db_name = db_name()
	SET @user_name = 'grupposga'
	SET @pwd_name = 'agsoppurg'

	SET @command = 'bcp "SET QUOTED_IDENTIFIER  ON; SELECT * FROM ##OutputResult"'
	SET @command = REPLACE(REPLACE(@command, CHAR(10), ''), CHAR(13), ' ') +   ' queryout  "' + @par_path + 'Tracciato_Inquilini.txt" -S "' + @server_name + '" -U "' + @user_name + '" -P "' + @pwd_name + '" -c -C ACP -t "|"'
	print @command
	
	INSERT INTO @esito
	EXEC @return_value = master..xp_cmdshell @command

	DELETE FROM @esito WHERE esito IS NULL

	SELECT * FROM @esito;

	-- WHILE (SELECT COUNT(*) FROM @esito) > 0
	BEGIN
		SELECT TOP 1 @outEsito = esito FROM @esito
		IF @outEsito LIKE '%Error%'
		BEGIN
		  SET @outEsito = 'Errore inatteso nella procedura: ' + @outEsito
		  RAISERROR(@outEsito, 16, 1)
		END
		ELSE
		BEGIN
			SET @outEsito = 'Generazione del tracciato INQUILINI avvenuta con successo!'
		END
	END

	IF OBJECT_ID('tempdb..#TabContratti')	IS NOT NULL DROP TABLE #TabContratti;
	IF OBJECT_ID('tempdb..##OutputResult')	IS NOT NULL DROP TABLE ##OutputResult;
END

