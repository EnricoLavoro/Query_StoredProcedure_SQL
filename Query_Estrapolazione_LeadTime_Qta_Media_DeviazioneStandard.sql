USE up_tecnoclean;
--DROP TABLE #TabOrdiniArticolo;
--DROP TABLE #TabMedia;
--DROP TABLE #TabDeviazioneStandard;

SELECT Trighe.RbaisCRArtb AS Articolo,
	   TMaster.MbaisCMbais AS Ordine,
	   TMaster.MbaisTins AS DataRichiesta,
	   IstBaseStOpMaster_DDT.MbaisTins AS DataArrivo,
	   TMaster.MbaisCRAsog AS Fornitore,
	   SUM(TRighe.RbaisQiumge) AS QuantitaOrdinata,
	   ABS(DATEDIFF(DAY, TMaster.MbaisTins, IstBaseStOpMaster_DDT.MbaisTins)) AS LeadTime
INTO #TabOrdiniArticolo
FROM IstBaseStOpMaster AS TMaster
INNER JOIN IstBaseStOpRighe AS TRighe ON MbaisCSer = RbaisCRMbais
INNER JOIN dbo.IstRifStOpRColl AS IstRifStOpRColl_ORC ON IstRifStOpRColl_ORC.HRIISCRRbaisPr = TRighe.RbaisCSer 
LEFT OUTER JOIN IstBaseStOpRighe AS IstBaseStOpRighe_DDT ON IstBaseStOpRighe_DDT.RbaisCSer = IstRifStOpRColl_ORC.HRIISCser 
LEFT OUTER JOIN IstBaseStOpMaster AS IstBaseStOpMaster_DDT ON IstBaseStOpMaster_DDT.MbaisCSer = IstBaseStOpRighe_DDT.RbaisCRMbais
WHERE TMaster.MbaisCRMcso=7
GROUP BY TRighe.RbaisCRArtb, TMaster.MbaisCMbais, TMaster.MbaisTins, IstBaseStOpMaster_DDT.MbaisTins, TMaster.MbaisCRasog
ORDER BY 1;

----------------------------------------------------------------------------------------------------------------------------------------------------------

SELECT Articolo,
	   Fornitore,
	   MIN(DataRichiesta) AS MinDataRichiesta, 
	   MAX(DataRichiesta) AS MaxDataRichiesta, 
	   DATEDIFF(day,MIN(DataRichiesta),MAX(DataRichiesta)) AS GiorniDifferenza,
	   COUNT(LeadTime) AS NumLeadTimeCampione,
	   SUM(QuantitaOrdinata) AS TotQuantitaOrdinata,
	   SUM(LeadTime) AS TotLeadTIme,
	   CASE WHEN DATEDIFF(day,MIN(DataRichiesta),MAX(DataRichiesta)) = 0 
	   THEN SUM(QuantitaOrdinata) 
	   ELSE SUM(QuantitaOrdinata) / DATEDIFF(day,MIN(DataRichiesta),MAX(DataRichiesta)) END AS MediaQuantita,
	   SUM(LeadTime) / COUNT(LeadTime) AS MediaLeadTime
INTO #TabMedia
FROM #TabOrdiniArticolo
GROUP BY Articolo, Fornitore
ORDER BY 1;

----------------------------------------------------------------------------------------------------------------------------------------------------------

SELECT T.Articolo,
	   T.Fornitore,
	   SUM(POWER(QuantitaOrdinata-MediaQuantita,2)) AS SommaParzialeQuantita,
	   SUM(POWER(LeadTime-MediaLeadTime,2)) AS SommaParzialeLeadTime,
	   CASE WHEN DATEDIFF(day,MIN(DataRichiesta),MAX(DataRichiesta)) = 0 
	   THEN SQRT(SUM(POWER(QuantitaOrdinata-MediaQuantita,2))) 
	   ELSE SQRT(SUM(POWER(QuantitaOrdinata-MediaQuantita,2)) / DATEDIFF(day,MIN(DataRichiesta),MAX(DataRichiesta))) END AS DeviazioneStandardQuantita,
	   SQRT(SUM(POWER(LeadTime-MediaLeadTime,2)) / COUNT(LeadTime)) AS DeviazioneStandardLeadTime
INTO #TabDeviazioneStandard
FROM #TabOrdiniArticolo AS T INNER JOIN #TabMedia ON T.Articolo = #TabMedia.Articolo 
AND T.Fornitore = #TabMedia.Fornitore
GROUP BY T.Articolo, T.Fornitore
ORDER BY 1;

----------------------------------------------------------------------------------------------------------------------------------------------------------
SELECT * FROM #TabMedia;

SELECT TDev.Articolo,
	   TDev.Fornitore,
	   1.96 * SQRT(TMedia.MediaLeadTime * POWER(TDev.DeviazioneStandardQuantita,2) + POWER(TDev.DeviazioneStandardLeadTime,2) * POWER(TMedia.MediaQuantita,2)) AS ScortaMinima
FROM #TabMedia AS TMedia INNER JOIN #TabDeviazioneStandard AS TDev ON TMedia.Articolo = TDev.Articolo 
AND TMedia.Fornitore = TDev.Fornitore;

DROP TABLE #TabOrdiniArticolo;
DROP TABLE #TabMedia;
DROP TABLE #TabDeviazioneStandard;