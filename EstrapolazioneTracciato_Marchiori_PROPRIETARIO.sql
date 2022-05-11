USE up_marchioricontino;

IF OBJECT_ID('tempdb..#TabContratti') IS NOT NULL DROP TABLE #TabContratti;

SELECT DISTINCT MbaisCSer, MbaisCMbais, MbaisCRAsog, TacaCRAsog, T.Attr1, T.Val1, T.Attr2, T.Val2,
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
'+' AS SegnoMovimento,
YEAR(MbaisTins) AS APerCompetenza,
'M' AS TPerCompetenza,
12 AS NPerCompetenza,
TaliCTali AS CodIVAxPlus,
AscoCAsco AS CodContPartxPlus,
CASE WHEN ArtbCCodEsterno IS NOT NULL AND ArtbCCodEsterno <> ''
	THEN ArtbCCodEsterno
	ELSE ArtbCArtb
END AS CodArtxPlus
INTO #TabContratti
FROM IstBaseStOpMaster
INNER JOIN IstBaseStOpRighe ON MbaisCSer = RbaisCRMbais
INNER JOIN TabUnitaMisura ON RbaisCRTums = TumsCSer
INNER JOIN IstAttrStOpRColl ON RbaisCSer = HatisCRRBais
INNER JOIN IstCComAtStOpRColl ON RbaisCSer = HCAISCser
INNER JOIN IstContStOpRColl ON HatisCser = HCOISCser
INNER JOIN TabAliquoteIVA ON HCOISCRTali = TaliCser
INNER JOIN SottoConti ON HCOISCRCpart = AscoCSer
INNER JOIN Attributi ON AttrCSer = HatisCRAttr
INNER JOIN TabAttComm ON MbaisCRTaca = TacaCser
INNER JOIN ArticoliBase ON ArtbCSer = RbaisCRArtb
INNER JOIN (SELECT T1.MbaisCSer AS Serial, T1.TgrsCTgrs AS Attr1, T1.RgrsCRgrs AS Val1, T2.TgrsCTgrs AS Attr2, T2.RgrsCRgrs AS Val2
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
	WHERE T1.TgrsCTgrs='CTISA' AND T2.TgrsCTgrs='TUISA') T ON MbaisCSer = T.Serial
WHERE MbaisCRMcso=23 AND AttrCAttr='VCI';

SELECT * FROM #TabContratti;

---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

SELECT ROW_NUMBER() OVER(ORDER BY M.MbaisCSer ASC) AS Progressivo,
NULL AS Nullo,
LEFT(TcsoCTcso,1) AS CausaleDocumento, 
'P_'+RIGHT(M.MbaisCMbais,13) AS NumeroDocumento,
M.MbaisTins AS DataEsportazione,
NULL AS SerieDocumento,
'SEDEP' AS SedeEmissione,
SogControparte.Val1 AS TipoSoggetto,
SogControparte.AsogCSer AS CodiceCliente,
SogControparte.Desc1 AS DescrizioneCliente,
SogClienti.AsogCSer AS CodiceControparte,
R1.RgrsDrgrs AS DescrizioneControparte,
TabC.MbaisCMbais AS RiferimentoContratto,
NULL AS AnnotazioneTestata,
MbaisCRMmoc AS CodicePagamento,
SUBSTRING(SogClienti.AsogDatIBANBE,5,5) AS CodiceABI,
SUBSTRING(SogClienti.AsogDatIBANBE,10,5) AS CodiceCAB,
SogClienti.AsogDatIBANBE AS CodiceIBAN,
CASE WHEN TabC.CodArtxPlus = 'CAN'
	THEN TabC.PrezzoUnitario
	ELSE (SELECT PrezzoUnitario FROM #TabContratti WHERE #TabContratti.MbaisCRAsog = SogClienti.AsogCSer AND #TabContratti.TacaCRAsog = SogControparte.AsogCSer AND #TabContratti.CodArtxPlus = 'CAN') 
END AS ValoreAffittoISA,
TabC.Val1 AS ConteggiaTrattativaISA,
TabC.Val2 AS TrattativaUnilateraleISA,
NULL AS NonUtilizzato,
NULL AS NonUtilizzato,
ROW_NUMBER() OVER(PARTITION BY M.MbaisCSer, M.MbaisCMbais ORDER BY M.MbaisCSer ASC) AS NumeroRiga,
TABC.CodArtxPlus AS CodArtxPlus,
TabC.Desc1 AS DescMov1,
TabC.Desc2 AS DescMov2,
TabC.UMisura,
TabC.Qta,
TabC.PrezzoUnitario,
TabC.Sconto1,
TabC.Sconto2,
TabC.SegnoMovimento,
TabC.APerCompetenza,
TabC.TPerCompetenza,
TabC.NPerCompetenza,
TabC.CodIVAxPlus,
TabC.CodContPartxPlus,
CASE WHEN T.SogRit IS NULL THEN 'N' ELSE T.SogRit END AS SogRit,
TabC.Qta * TabC.PrezzoUnitario * SogControparte.Val2 / 100 AS Compenso

FROM IstBaseStOpMaster AS M
INNER JOIN TabCausaliStOp ON M.MbaisCRTcso = TcsoCSer
INNER JOIN TabAttComm AS TabAtt  ON M.MbaisCRTaca = TabAtt.TacaCSer
INNER JOIN IstGrStatStOpMColl    ON KgsisCRMbais = MbaisCSer
INNER JOIN TabGruppiStatistici   AS TG0 ON TG0.TgrsCSer = KgsisCRgrs
INNER JOIN GruppiStatisticiRighe AS R0  ON R0.RgrsCSer = KgsisCRvgrs

INNER JOIN Soggetti AS SogClienti ON MbaisCRAsog = SogClienti.AsogCSer
INNER JOIN LegSoggettiGruppiStat AS L1 ON SogClienti.AsogCSer = L1.LsgsCRifAsog
INNER JOIN TabGruppiStatistici AS TG1 ON TG1.TgrsCSer = L1.LsgsCRifGrs
INNER JOIN GruppiStatisticiRighe AS R1 ON R1.RgrsCSer = L1.LsgsCRifVgrs

INNER JOIN (SELECT T1.AsogCSer, T1.Attr1, T1.Val1, T1.Desc1, T2.Attr2, T2.Val2
	FROM
	( SELECT AsogCSer, TG2.TgrsCTgrs AS Attr1, R2.RgrsCRgrs AS Val1, R2.RgrsDRgrs AS Desc1
	 FROM Soggetti AS SogControparte
	 INNER JOIN LegSoggettiGruppiStat AS L2 ON SogControparte.AsogCSer = L2.LsgsCRifAsog
	 INNER JOIN TabGruppiStatistici AS TG2 ON TG2.TgrsCSer = L2.LsgsCRifGrs
	 INNER JOIN GruppiStatisticiRighe AS R2 ON R2.RgrsCSer = L2.LsgsCRifVgrs) T1
	 INNER JOIN
	(SELECT AsogCSer, TG2.TgrsCTgrs AS Attr2, R2.RgrsCRgrs AS Val2
	FROM Soggetti AS SogControparte
	 INNER JOIN LegSoggettiGruppiStat AS L2 ON SogControparte.AsogCSer = L2.LsgsCRifAsog
	 INNER JOIN TabGruppiStatistici AS TG2 ON TG2.TgrsCSer = L2.LsgsCRifGrs
	 INNER JOIN GruppiStatisticiRighe AS R2 ON R2.RgrsCSer = L2.LsgsCRifVgrs) T2
	ON T1.AsogCSer = T2.AsogCSer
	WHERE T1.Attr1='TSO' AND T2.Attr2='COM') AS SogControparte ON TabAtt.TacaCRAsog = SogControparte.AsogCSer

LEFT JOIN (SELECT AsogCSer, RgrsCRgrs AS SogRit 
	FROM 
	Soggetti INNER JOIN LegSoggettiGruppiStat ON AsogCSer = LsgsCRifAsog
	INNER JOIN TabGruppiStatistici ON TgrsCSer = LsgsCRifGrs
	INNER JOIN GruppiStatisticiRighe ON RgrsCSer = LsgsCRifVgrs
	WHERE TgrsCTgrs='SOGRIT') AS T ON SogControparte.AsogCSer = T.AsogCSer

INNER JOIN #TabContratti AS TabC ON TabC.MbaisCRAsog = SogClienti.AsogCSer AND TabC.TacaCRAsog = SogControparte.AsogCSer

WHERE MbaisCRMcso = 25 AND TG0.TgrsCTgrs = 'EXPLUS' AND R0.RgrsCRgrs = 'S' AND TG1.TgrsCTgrs='TSO' 
-- AND M.MbaisTins BETWEEN DataDa AND DataA;

IF OBJECT_ID('tempdb..#TabContratti') IS NOT NULL DROP TABLE #TabContratti;