SELECT TOP (100) PERCENT
    dbo.MovFinanziariMaster.MmfiCMmfi,
    dbo.Soggetti.AsogCAsog                             AS CodCli,
    dbo.Soggetti.AsogDAsog                             AS DescCli,
    dbo.MovFinanziariMaster.MmfiCMmfi                  AS CodMovFin,
    dbo.MovFinanziariMaster.MmfiIStatoMmfi             AS Stato,
    dbo.MovFinanziariMaster.MmfiTScad                  AS DataScad,
    CASE
        WHEN RmfiCRifTtpi = 3
            THEN 'RIB'
        ELSE
            TtpiCTtpi
    END                                                AS TipoPag,
    dbo.RigheRiferimentiPartCPart.RRPCDrifEst          AS NumDoc,
    dbo.RigheRiferimentiPartCPart.RRPCTrifEst          AS DataDoc,
    ISNULL(dbo.AnaDistinteBan.adibTpres, '01/01/2000') AS DataPres,
    SUM(dbo.MovFinanziariRighe.RmfiCRifImpVQImpValuta) AS Importo,
    TOT.Importo                                        AS ImportoNetto,
    CASE
        WHEN MmfiIStatoMmfi = 'C'
            THEN DATAPAG.RmfiTOpFin
        ELSE
            ''
    END                                                AS DataPag,
    TMPASCAD.TmpaDTmpa                                 AS ModPag,
    dbo.MasterMovContabile.MmocTreg                    AS DataReg,
    dbo.MovFinanziariRighe.RmfiTDataIns                AS DataIns
FROM
    dbo.MovFinanziariMaster				WITH (nolock)
    INNER JOIN dbo.Soggetti				WITH (nolock) ON dbo.Soggetti.AsogCSer = dbo.MovFinanziariMaster.MmfiCRifAsog
    INNER JOIN dbo.MovFinanziariRighe	WITH (nolock) ON dbo.MovFinanziariMaster.MmfiCSer = dbo.MovFinanziariRighe.RmfiCRifMmfi
    INNER JOIN dbo.TabModPagInc			WITH (nolock) ON dbo.TabModPagInc.TmpaCSer = dbo.MovFinanziariRighe.RmfiCRifTmpa
		AND NOT EXISTS (SELECT
                            RmfiCSer,
                            RmfiCRifMmfi,
                            RmfiPRig,
                            RmfiIClasseRRtC,
                            RmfiCRifRRPC,
                            RmfiTOpFin,
                            RmfiCRifTmpa,
                            RmfiCRifTtpi,
                            RmfiDRifEst,
                            RmfiCRifTazi,
                            RmfiCRifAsog,
                            RmfiIClRRtCSer,
                            RmfiCRifImpVCRifTmon,
                            RmfiCRifImpVQImpLire,
                            RmfiCRifImpVQImpValLoc,
                            RmfiCRifImpVQImpValuta,
                            RmfiNAddSpese,
                            RmfiCRAscoSpese,
                            RmfiImpSpeseQImpLire,
                            RmfiImpSpeseQImpValLoc,
                            RmfiPercInteressi,
                            RmfiTDecInter,
                            RmfiCTipo,
                            RmfiNRifSpezzamento,
                            RmfiNColleg,
                            RmfiBNonIncassato,
                            RmfiTDataIns
                        FROM
                            dbo.MovFinanziariRighe AS A WITH (nolock)
                        WHERE
                            (dbo.MovFinanziariRighe.RmfiCRifMmfi = RmfiCRifMmfi)
                            AND (RmfiPRig < dbo.MovFinanziariRighe.RmfiPRig))
    INNER JOIN dbo.RigModPagInc			WITH (nolock) ON dbo.RigModPagInc.RmpaCRifTmpa = dbo.TabModPagInc.TmpaCSer
       AND NOT EXISTS (SELECT
							RmpaCSer,
							RmpaCRifTmpa,
							RmpaIIniCalcolo,
							RmpaNggPrima,
							RmpaITipoCalcolo,
							RmpaNQtaCalcolo,
							RmpaNggDopo,
							RmpaNggFisso,
							RmpaIBaseCalcolo,
							RmpaNNumFrazCalc,
							RmpaNDenFrazCalc,
							RmpaCRifTtpi,
							RmpaCRifTspi,
							RmpaPRmpa,
							RmpaISniCalcolo,
							RmpaISipoCalcolo,
							RmpaISaseCalcolo,
							RmpaIIniCalcCedCSer,
							RmpaIIniCalcCedCAzione,
							RmpaNggPrimaCed,
							RmpaNQtaCalcoloCed,
							RmpaITipoCalcCedCSer,
							RmpaITipoCalcCedCAzione,
							RmpaNggDopoCed,
							RmpaNggFissoCed,
							RmpaXIStampaSospCSer,
							RmpaXIStampaSospCAzione
						FROM
							dbo.RigModPagInc AS B WITH (nolock)
						WHERE
							(dbo.RigModPagInc.RmpaCRifTmpa = RmpaCRifTmpa)
							AND (RmpaPRmpa < dbo.RigModPagInc.RmpaPRmpa))
    
	INNER JOIN dbo.TabTipiPagInc				WITH (nolock) ON dbo.RigModPagInc.RmpaCRifTtpi = dbo.TabTipiPagInc.TtpiCSer
    INNER JOIN dbo.RigheRiferimentiPartCPart	WITH (nolock) ON dbo.RigheRiferimentiPartCPart.RRPCCSer = dbo.MovFinanziariRighe.RmfiCRifRRPC
       AND NOT EXISTS (SELECT
                            RmfiCSer,
                            RmfiCRifMmfi,
                            RmfiPRig,
                            RmfiIClasseRRtC,
                            RmfiCRifRRPC,
                            RmfiTOpFin,
                            RmfiCRifTmpa,
                            RmfiCRifTtpi,
                            RmfiDRifEst,
                            RmfiCRifTazi,
                            RmfiCRifAsog,
                            RmfiIClRRtCSer,
                            RmfiCRifImpVCRifTmon,
                            RmfiCRifImpVQImpLire,
                            RmfiCRifImpVQImpValLoc,
                            RmfiCRifImpVQImpValuta,
                            RmfiNAddSpese,
                            RmfiCRAscoSpese,
                            RmfiImpSpeseQImpLire,
                            RmfiImpSpeseQImpValLoc,
                            RmfiPercInteressi,
                            RmfiTDecInter,
                            RmfiCTipo,
                            RmfiNRifSpezzamento,
                            RmfiNColleg,
                            RmfiBNonIncassato,
                            RmfiTDataIns
                        FROM
                            dbo.MovFinanziariRighe AS C WITH (nolock)
                        WHERE
                            (dbo.MovFinanziariRighe.RmfiCRifMmfi = RmfiCRifMmfi)
                            AND (RmfiPRig < dbo.MovFinanziariRighe.RmfiPRig))
    INNER JOIN		dbo.RigheMovContabile	WITH (nolock) ON dbo.RigheMovContabile.RmocCSer = dbo.RigheRiferimentiPartCPart.RRPCCrifRmoc
    INNER JOIN		dbo.MasterMovContabile	WITH (nolock) ON dbo.MasterMovContabile.MmocCSer = dbo.RigheMovContabile.RmocCRifMmoc
    LEFT OUTER JOIN dbo.OperazioniBanMaster	WITH (nolock) ON dbo.OperazioniBanMaster.MmobCSer = dbo.MovFinanziariMaster.MMFiCrMmob
    LEFT OUTER JOIN	dbo.AnaDistinteBan		WITH (nolock) ON dbo.AnaDistinteBan.AdibCSer = dbo.OperazioniBanMaster.MmobCRAdib
    LEFT OUTER JOIN (SELECT
						RmfiTOpFin,
						RmfiCRifMmfi
					 FROM dbo.MovFinanziariRighe AS MovFinanziariRighe_2 WITH (nolock)
					 WHERE NOT EXISTS (SELECT 1 AS Expr1 FROM dbo.MovFinanziariRighe AS B WITH (nolock)
						   WHERE (MovFinanziariRighe_2.RmfiCRifMmfi = RmfiCRifMmfi) AND (RmfiPRig > MovFinanziariRighe_2.RmfiPRig))
					GROUP BY RmfiCRifMmfi, RmfiTOpFin)AS DATAPAG
					ON DATAPAG.RmfiCRifMmfi = dbo.MovFinanziariRighe.RmfiCRifMmfi
    
	LEFT OUTER JOIN dbo.TabModPagInc AS TMPASCAD WITH (nolock) ON TMPASCAD.TmpaCSer = dbo.MovFinanziariRighe.RmfiCRifTmpa
    LEFT OUTER JOIN (SELECT MovFinanziariMaster_1.MmfiCSer, SUM(MovFinanziariRighe_1.RmfiCRifImpVQImpValuta) AS Importo
					 FROM dbo.MovFinanziariMaster		AS MovFinanziariMaster_1	WITH (nolock)
					 INNER JOIN dbo.Soggetti			AS Soggetti_1				WITH (nolock) ON Soggetti_1.AsogCSer = MovFinanziariMaster_1.MmfiCRifAsog
					 INNER JOIN dbo.MovFinanziariRighe	AS MovFinanziariRighe_1		WITH (nolock) ON MovFinanziariMaster_1.MmfiCSer = MovFinanziariRighe_1.RmfiCRifMmfi
					 WHERE (MovFinanziariMaster_1.MmfiIClasseMmfi = 'P') AND (MovFinanziariMaster_1.MmfiITipoMmfi = 'D')
					 GROUP BY
						MovFinanziariMaster_1.MmfiCSer,
						Soggetti_1.AsogCAsog,
						Soggetti_1.AsogDAsog,
						MovFinanziariMaster_1.MmfiCMmfi,
						MovFinanziariMaster_1.MmfiIStatoMmfi,
						MovFinanziariMaster_1.MmfiTScad) AS TOT ON TOT.MmfiCSer = dbo.MovFinanziariMaster.MmfiCSer

WHERE (dbo.MovFinanziariMaster.MmfiIClasseMmfi = 'P') AND (dbo.MovFinanziariMaster.MmfiITipoMmfi = 'D')

GROUP BY
    dbo.MovFinanziariMaster.MmfiCMmfi,
    dbo.Soggetti.AsogCAsog,
    dbo.Soggetti.AsogDAsog,
    dbo.MovFinanziariMaster.MmfiCMmfi,
    dbo.MovFinanziariMaster.MmfiIStatoMmfi,
    dbo.MovFinanziariMaster.MmfiTScad,
    CASE
        WHEN RmfiCRifTtpi = 3
            THEN 'RIB'
        ELSE
            TtpiCTtpi
    END,
    dbo.RigheRiferimentiPartCPart.RRPCDrifEst,
    dbo.RigheRiferimentiPartCPart.RRPCTrifEst,
    dbo.AnaDistinteBan.adibTpres,
    CASE
        WHEN MmfiIStatoMmfi = 'C'
            THEN DATAPAG.RmfiTOpFin
        ELSE
            ''
    END,
    TMPASCAD.TmpaDTmpa,
    TOT.Importo,
    dbo.MasterMovContabile.MmocTreg,
    dbo.MovFinanziariRighe.RmfiTDataIns
ORDER BY
    DescCli,
    DataScad
