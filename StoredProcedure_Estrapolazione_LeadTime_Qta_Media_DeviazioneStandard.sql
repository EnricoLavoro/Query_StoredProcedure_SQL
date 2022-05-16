USE [up_tecnoclean]
GO
/****** Object:  StoredProcedure [dbo].[ITsp_CalcLottoRiordino]    Script Date: 12/05/2022 16:35:20 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Enrico Piccin
-- Create date: 26 Aprile 2022
-- Description:	Calcolo LeadTime e ScortaMinima per TecnoClean
-- Modification: 12 Maggio 2022 - Calcolo della quantità su ordini clienti e non su ordini fornitori 
-- Modification: 16 Maggio 2022 - Calcolo della quantità su DDT e non su ordini clienti + calcolo livello di riordino 
-- =============================================
ALTER PROCEDURE [dbo].[ITsp_CalcLottoRiordino] (@parNumMesiDaCalc AS INTEGER, @righeCalcolate AS INT OUTPUT)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Ottenimento di LeadTime e QuantitaOrdinata degli articoli per ogni fornitore 
	SELECT Trighe.RbaisCRArtb AS Articolo,
	TMaster.MbaisCRAsog AS Fornitore,
	TMaster.MbaisCMbais AS Ordine,
	TMaster.MbaisTins AS DataRichiesta,
	IstBaseStOpMaster_DDT.MbaisTins AS DataArrivo,
	ABS(DATEDIFF(DAY, TMaster.MbaisTins, IstBaseStOpMaster_DDT.MbaisTins)) AS LeadTime
	INTO #TabOrdiniArticoloFornitore
	FROM IstBaseStOpMaster AS TMaster
	INNER JOIN IstBaseStOpRighe AS TRighe ON MbaisCSer = RbaisCRMbais
	INNER JOIN dbo.IstRifStOpRColl AS IstRifStOpRColl_ORC ON IstRifStOpRColl_ORC.HRIISCRRbaisPr = TRighe.RbaisCSer 
	LEFT OUTER JOIN IstBaseStOpRighe AS IstBaseStOpRighe_DDT ON IstBaseStOpRighe_DDT.RbaisCSer = IstRifStOpRColl_ORC.HRIISCser 
	LEFT OUTER JOIN IstBaseStOpMaster AS IstBaseStOpMaster_DDT ON IstBaseStOpMaster_DDT.MbaisCSer = IstBaseStOpRighe_DDT.RbaisCRMbais
	INNER JOIN ArticoliBase ON Trighe.RbaisCRArtb = ArtbCSer
	INNER JOIN TabTipoCopertura ON ArtbCSerTpcp = TpcpCSer
	INNER JOIN TabTipoArticolo ON ArtbCSerTpar = TparCSer
	WHERE TMaster.MbaisCRMcso=7		-- Considero solo gli ordini fornitori
	AND TpcpCTpcp <> 'KAN'			-- Escludo gli articoli che presentano tipo copertura KANBAN
	AND TparCTpar NOT LIKE '%OLD%'	-- Escludo gli articoli obsoleti
	AND TMaster.MbaisTins BETWEEN DATEADD(MONTH,-@parNumMesiDaCalc,GETDATE()) AND GETDATE()	-- Considero solamente gli ordini all'interno di un certo intervallo di tempo
	GROUP BY TRighe.RbaisCRArtb, TMaster.MbaisCMbais, TMaster.MbaisTins, IstBaseStOpMaster_DDT.MbaisTins, TMaster.MbaisCRasog
	ORDER BY 4 ASC;

	SELECT RbaisCRArtb AS Articolo,
	MbaisCMbais AS Ordine,
	MbaisTins AS DataRichiesta,
	SUM(RbaisQiumge) AS QuantitaOrdinata
	INTO #TabOrdiniArticoloCliente
	FROM IstBaseStOpMaster INNER JOIN  IstBaseStOpRighe ON MbaisCSer = RbaisCRMbais
	INNER JOIN ArticoliBase ON RbaisCRArtb = ArtbCSer
	INNER JOIN TabTipoCopertura ON ArtbCSerTpcp = TpcpCSer
	INNER JOIN TabTipoArticolo ON ArtbCSerTpar = TparCSer
	WHERE MbaisCRMcso=2         	-- Considero solo le DDT
	AND TpcpCTpcp <> 'KAN'			-- Escludo gli articoli che presentano tipo copertura KANBAN
	AND TparCTpar NOT LIKE '%OLD%'	-- Escludo gli articoli obsoleti
	AND MbaisTins BETWEEN DATEADD(MONTH,-@parNumMesiDaCalc,GETDATE()) AND GETDATE()	-- Considero solamente gli ordini all'interno di un certo intervallo di tempo
	GROUP BY RbaisCRArtb, MbaisCMbais, MbaisTins
	ORDER BY 3 ASC;

	----------------------------------------------------------------------------------------------------------------------------------------------------------

	-- Calcolo della media di LeadTime e di QuantitaOrdinata degli articoli per ogni fornitore 
	SELECT TabMediaLeadTime.Articolo, Fornitore, TotLeadTime, MediaLeadTime, TotQuantitaOrdinata, MediaQuantita
	INTO #TabMedia
	FROM
	(SELECT Articolo,
	 Fornitore,
	 COUNT(LeadTime) AS NumLeadTimeCampione,
	 SUM(LeadTime) AS TotLeadTIme,
	 SUM(LeadTime) / COUNT(LeadTime) AS MediaLeadTime
	 FROM #TabOrdiniArticoloFornitore
	 GROUP BY Articolo, Fornitore) AS TabMediaLeadTime 
	INNER JOIN 
	(SELECT Articolo,
	 COUNT(QuantitaOrdinata) AS NumQuantitaCampione,
	 -- DATEDIFF(day,MIN(DataRichiesta),MAX(DataRichiesta)) AS GiorniDifferenza,
	 SUM(QuantitaOrdinata) AS TotQuantitaOrdinata,
	 SUM(QuantitaOrdinata) / COUNT(QuantitaOrdinata) AS MediaQuantita
	 -- CASE WHEN DATEDIFF(day,MIN(DataRichiesta),MAX(DataRichiesta)) = 0 
	 -- THEN SUM(QuantitaOrdinata) 
	 -- ELSE SUM(QuantitaOrdinata) / DATEDIFF(day,MIN(DataRichiesta),MAX(DataRichiesta)) END AS MediaQuantita
	 FROM #TabOrdiniArticoloCliente
	 GROUP BY ArticolO) AS TabMediaQuantita ON TabMediaLeadTime.Articolo = TabMediaQuantita.Articolo;

	----------------------------------------------------------------------------------------------------------------------------------------------------------

	-- Calcolo della deviazione standard del LeadTime e della QuantitaOrdinata degli articoli per ogni fornitore 
	SELECT T1.Articolo, T1.Fornitore, T1.DeviazioneStandardLeadTime, T2.DeviazioneStandardQuantita
	 INTO #TabDeviazioneStandard
	 FROM
	 (SELECT  T.Articolo,
		T.Fornitore,
		SUM(POWER(LeadTime-MediaLeadTime,2)) AS SommaParzialeLeadTime,
		SQRT(SUM(POWER(LeadTime-MediaLeadTime,2)) / COUNT(LeadTime)) AS DeviazioneStandardLeadTime
	-- INTO #TabDeviazioneStandard
	FROM #TabOrdiniArticoloFornitore AS T INNER JOIN #TabMedia ON T.Articolo = #TabMedia.Articolo 
	AND T.Fornitore = #TabMedia.Fornitore
	GROUP BY T.Articolo, T.Fornitore) AS T1
	INNER JOIN 
	 (SELECT	T.Articolo,
		SUM(POWER(QuantitaOrdinata-MediaQuantita,2)) AS SommaParzialeQuantita,
		SQRT(SUM(POWER(QuantitaOrdinata-MediaQuantita,2)) / COUNT(QuantitaOrdinata)) AS DeviazioneStandardQuantita
		--CASE WHEN DATEDIFF(day,MIN(DataRichiesta),MAX(DataRichiesta)) = 0 
		--THEN SQRT(SUM(POWER(QuantitaOrdinata-MediaQuantita,2))) 
		--ELSE SQRT(SUM(POWER(QuantitaOrdinata-MediaQuantita,2)) / DATEDIFF(day,MIN(DataRichiesta),MAX(DataRichiesta))) END AS DeviazioneStandardQuantita
		-- INTO #TabDeviazioneStandard
		FROM #TabOrdiniArticoloCliente AS T INNER JOIN #TabMedia ON T.Articolo = #TabMedia.Articolo
		GROUP BY T.Articolo) AS T2 ON T1.Articolo = T2.Articolo
	ORDER BY 1;

	----------------------------------------------------------------------------------------------------------------------------------------------------------

	-- Visualizzazione dei risultati ottenuti e calclolo della ScortaMinima degli articoli per ogni fornitore 
	SELECT DISTINCT TDev.Articolo,
			TDev.Fornitore,
			TMedia.MediaQuantita,
			TMedia.MediaLeadTime,
			TDev.DeviazioneStandardQuantita,
			TDev.DeviazioneStandardLeadTime,
			artfXCoeffCop * SQRT(TMedia.MediaLeadTime * POWER(TDev.DeviazioneStandardQuantita,2) + POWER(TDev.DeviazioneStandardLeadTime,2) * POWER(TMedia.MediaQuantita,2)) AS ScortaMinima,
			ArtbCSerPrprNLeadTime * artfXCoeffCop * SQRT(TMedia.MediaLeadTime * POWER(TDev.DeviazioneStandardQuantita,2) + POWER(TDev.DeviazioneStandardLeadTime,2) * POWER(TMedia.MediaQuantita,2)) AS LivelloRiordino
	INTO #TabResult
	FROM #TabMedia AS TMedia INNER JOIN #TabDeviazioneStandard AS TDev ON TMedia.Articolo = TDev.Articolo AND TMedia.Fornitore = TDev.Fornitore
	INNER JOIN ArticoliFornitori ON TDev.Articolo = ArtfCSerArtb AND TDev.Fornitore = ArtfCSerAncf
	INNER JOIN ArticoliBase ON ArtbCSer = TMedia.Articolo;

	---------------------------------------- Aggiornamento del LivelloRiordino e della ScortaMinima ----------------------------------------

	UPDATE [dbo].[ArticoliFornitori]
	SET ArtfCSerPrprQLivRiord = T.LivelloRiordino,
	    ArtfCSerPrprQScortaMin = T.ScortaMinima
	FROM #TabResult AS T INNER JOIN ArticoliFornitori ON T.Articolo = ArtfCSerArtb AND T.Fornitore = ArtfCSerAncf;

	UPDATE [dbo].[ArticoliBase]
	SET ArtbCSerPrprQLivRiord  = T.LivelloRiordino,
	    ArtbCSerPrprQScortaMin = T.ScortaMinima
	FROM #TabResult AS T INNER JOIN ArticoliBase ON T.Articolo = ArtbCSer;

	-- Righe aggiornate
	SELECT @righeCalcolate = @@ROWCOUNT;

	SELECT @righeCalcolate;

	IF OBJECT_ID('tempdb..#TabOrdiniArticoloFornitore') IS NOT NULL DROP TABLE #TabOrdiniArticoloFornitore;
	IF OBJECT_ID('tempdb..#TabOrdiniArticoloCliente')	IS NOT NULL DROP TABLE #TabOrdiniArticoloCliente;
	IF OBJECT_ID('tempdb..#TabMedia')					IS NOT NULL DROP TABLE #TabMedia;
	IF OBJECT_ID('tempdb..#TabDeviazioneStandard')		IS NOT NULL DROP TABLE #TabDeviazioneStandard;
	IF OBJECT_ID('tempdb..#TabResult')					IS NOT NULL DROP TABLE #TabResult;
END
