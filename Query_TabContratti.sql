use up_marchioricontino;

SELECT DISTINCT MbaisCSer, MbaisCMbais, MbaisCRAsog, TacaCRAsog, T.Attr1, T.Val1, T.Attr2, T.Val2,
CASE WHEN CHARINDEX('CANONE AFFITTO',RbaisDaart) > 0 THEN 
		'CANONE AFFITTO'
	ELSE CASE WHEN CHARINDEX('SPESE CONDOMINIALI',RbaisDaart) > 0 THEN
		'SPESE CONDOMINIALI'
	ELSE
		RbaisDaart
	END
END AS Desc1,
CASE WHEN CHARINDEX('CANONE AFFITTO',RbaisDaart) > 0 THEN 
		RIGHT(RbaisDaart,LEN(RbaisDaart)-LEN('CANONE AFFITTO'))
	ELSE CASE WHEN CHARINDEX('SPESE CONDOMINIALI',RbaisDaart) > 0 THEN
		RIGHT(RbaisDaart,LEN(RbaisDaart)-LEN('SPESE CONDOMINIALI'))
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
'M' AS TPerCompetenza,
12 AS NPerCompetenza,
TaliCTali AS CodIVAxPlus,
AscoCAsco AS CodContPartxPlus,
CASE WHEN ArtbCCodEsterno IS NOT NULL AND ArtbCCodEsterno <> ''
	THEN ArtbCCodEsterno
	ELSE ArtbCArtb
END AS CodArtxPlus
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

-- AND TGRS1.TgrsCTgrs = 'CTISA' AND TGRS2.TgrsCTgrs = 'TUISA';