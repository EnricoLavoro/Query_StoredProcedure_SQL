USE [up_tecnoclean]
GO
/****** Object:  StoredProcedure [dbo].[ITsp_CalcLottoRiordino]    Script Date: 14/07/2022 15:27:11 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Enrico Piccin
-- Create date: 26 Aprile 2022
-- Description:	Cit/22/ Calcolo LeadTime MEDIO e ScortaMinima per TecnoClean
--							Lotto riordino = scortaMinima x lead time


--Modifiche:
--Claudia 17/5/22 tolto aggiornamento ArtbCSerPrprNLeadTime (che è il LT concordato con il fornitore, diverso dal LT medio calcolato qui )
-- Enrico 12 Maggio 2022 - Calcolo della quantitÃ  su ordini clienti e non su ordini fornitori 
-- Enrico 16 Maggio 2022 - Calcolo della quantitÃ  su DDT e non su ordini clienti + calcolo livello di riordino 
-- claudia 13/6/22 - esclusi articoli con attributo data inserimento > 01/01/1900 e <= @parNumMesiDaCalc
-- Enrico 13 Luglio 2022 - Reset a 0 di ScortaMinima e LivelloRiordino
-- Enrico 14 Luglio 2022 - Calcolo di ScortaMinima e LivelloRiordino anche per quegli articoli che presentano DDT ma non OrdiniFornitori
-- =============================================
ALTER PROCEDURE [dbo].[ITsp_CalcLottoRiordino] (@parNumMesiDaCalc AS INTEGER, @righeCalcolate AS INT OUTPUT)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	-- Enrico 13 Luglio 2022 - Selezione di Articoli e Fornitori di cui resettare il valore di ScortaMinima e LivelloRiordino
	SELECT ArtbCSer AS Articolo, ArtfCSerAncf AS Fornitore
	INTO #TabArticoliFornitori
	FROM ArticoliBase
	INNER JOIN TabTipoCopertura  WITH (NOLOCK) ON ArtbCSerTpcp = TpcpCSer
	INNER JOIN TabTipoArticolo  WITH (NOLOCK)ON ArtbCSerTpar = TparCSer
	LEFT JOIN ArticoliAttributi DT_INS_ART  WITH (NOLOCK) ON ArtaCSerArtb = ArtbCSer AND ArtaCSerAttr = 292 --DATA INS ART
	INNER JOIN ArticoliFornitori ON ArtbCSer = ArtfCSerArtb
	WHERE TpcpCTpcp <> 'KAN'			-- Escludo gli articoli che presentano tipo copertura KANBAN
	AND TparCTpar NOT LIKE '%OLD%'		-- Escludo gli articoli obsoleti
	-- ARTICOLO INSERITO DA ALMENO UNA 12 MESI (oppure Ã¨ un articolo vecchio per cui non ho specificato data inizio inserimento)
	AND ( ISNULL( DT_INS_ART.ArtaTValAtt, '19000101') = '19000101' OR  ISNULL( DT_INS_ART.ArtaTValAtt, '19000101') < DATEADD(MONTH,-@parNumMesiDaCalc,GETDATE()))

	-- Enrico 13 Luglio 2022 - Reset a 0 di ScortaMinima e LivelloRiordino
	UPDATE [dbo].[ArticoliFornitori]
	SET ArtfCSerPrprQLivRiord = 0,
	    ArtfCSerPrprQScortaMin = 0
	FROM ArticoliFornitori
	WHERE ArtfCSerArtb IN (SELECT Articolo FROM #TabArticoliFornitori) AND ArtfCSerAncf IN (SELECT Fornitore FROM #TabArticoliFornitori);

	-- Enrico 13 Luglio 2022 - Reset a 0 di ScortaMinima e LivelloRiordino
	UPDATE [dbo].[ArticoliBase]
	SET ArtbCSerPrprQLivRiord  = 0,
	    ArtbCSerPrprQScortaMin = 0
	FROM ArticoliBase
	WHERE ArtbCSer IN (SELECT Articolo FROM #TabArticoliFornitori);

    -- Ottenimento di LeadTime e QuantitaOrdinata degli articoli per ogni fornitore 
	SELECT Trighe.RbaisCRArtb AS Articolo,
	TMaster.MbaisCRAsog AS Fornitore,
	TMaster.MbaisCMbais AS Ordine,
	TMaster.MbaisTins AS DataRichiesta,
	IstBaseStOpMaster_DDT.MbaisTins AS DataArrivo,
	ABS(DATEDIFF(DAY, TMaster.MbaisTins, IstBaseStOpMaster_DDT.MbaisTins)) AS LeadTime
	INTO #TabOrdiniArticoloFornitore
	FROM IstBaseStOpMaster AS TMaster WITH (NOLOCK) 
	INNER JOIN IstBaseStOpRighe AS TRighe  WITH (NOLOCK) ON MbaisCSer = RbaisCRMbais
	INNER JOIN dbo.IstRifStOpRColl AS IstRifStOpRColl_ORC  WITH (NOLOCK) ON IstRifStOpRColl_ORC.HRIISCRRbaisPr = TRighe.RbaisCSer 
	LEFT OUTER JOIN IstBaseStOpRighe AS IstBaseStOpRighe_DDT  WITH (NOLOCK) ON IstBaseStOpRighe_DDT.RbaisCSer = IstRifStOpRColl_ORC.HRIISCser 
	LEFT OUTER JOIN IstBaseStOpMaster AS IstBaseStOpMaster_DDT  WITH (NOLOCK) ON IstBaseStOpMaster_DDT.MbaisCSer = IstBaseStOpRighe_DDT.RbaisCRMbais
	INNER JOIN ArticoliBase  WITH (NOLOCK) ON Trighe.RbaisCRArtb = ArtbCSer
	INNER JOIN TabTipoCopertura  WITH (NOLOCK) ON ArtbCSerTpcp = TpcpCSer
	INNER JOIN TabTipoArticolo  WITH (NOLOCK)ON ArtbCSerTpar = TparCSer
	LEFT JOIN ArticoliAttributi DT_INS_ART  WITH (NOLOCK) ON ArtaCSerArtb = ArtbCSer AND ArtaCSerAttr =292 --DATA INS ART
	WHERE TMaster.MbaisCRMcso=7		-- Considero solo gli ordini fornitori
	AND TpcpCTpcp <> 'KAN'			-- Escludo gli articoli che presentano tipo copertura KANBAN
	AND TparCTpar NOT LIKE '%OLD%'	-- Escludo gli articoli obsoleti
	AND TMaster.MbaisTins BETWEEN DATEADD(MONTH,-@parNumMesiDaCalc,GETDATE()) AND GETDATE()	-- Considero solamente gli ordini all'interno di un certo intervallo di tempo
	--ARTICOLO INSERITO DA ALMENO UNA @parNumMesiDaCalc MESI (oppure è un articolo vecchio per cui non ho specificato data inizio inserimento)
	AND ( ISNULL( DT_INS_ART.ArtaTValAtt, '19000101') = '19000101' OR  ISNULL( DT_INS_ART.ArtaTValAtt, '19000101') < DATEADD(MONTH,-@parNumMesiDaCalc,GETDATE()))
	GROUP BY TRighe.RbaisCRArtb, TMaster.MbaisCMbais, TMaster.MbaisTins, IstBaseStOpMaster_DDT.MbaisTins, TMaster.MbaisCRasog
	ORDER BY 4 ASC;

	SELECT RbaisCRArtb AS Articolo,
	MbaisCMbais AS Ordine,
	MbaisTins AS DataRichiesta,
	SUM(RbaisQoumge) AS QuantitaOrdinata --claudia 19/5/22 no qiumge ma qoumge
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
	SELECT TabMediaQuantita.Articolo, 
	-- Enrico 14 Luglio 2022 - Selezione del fornitore preferenziale per quegli articoli che presentano DDT ma non OrdiniFornitori
	CASE WHEN TabMediaLeadTime.Fornitore IS NULL THEN
		CASE WHEN EXISTS(SELECT ArtfCSerAncf FROM ArticoliFornitori WHERE ArtfCSerArtb = TabMediaQuantita.Articolo AND ArtfFTipoForn = 'P') THEN
			(SELECT TOP 1 ArtfCSerAncf FROM ArticoliFornitori WHERE ArtfCSerArtb = TabMediaQuantita.Articolo AND ArtfFTipoForn = 'P')
		ELSE
			(SELECT TOP 1 ArtfCSerAncf FROM ArticoliFornitori WHERE ArtfCSerArtb = TabMediaQuantita.Articolo)
		END
	ELSE
		TabMediaLeadTime.Fornitore
	END AS Fornitore,
	-- Enrico 14 Luglio 2022 - Utilizzo del LeadTime costante inserito a mano per quegli articoli che presentano DDT ma non OrdiniFornitori
	ISNULL(TotLeadTime,(SELECT ArtbCSerPrprNLeadTime FROM ArticoliBase WHERE ArtbCSer = TabMediaQuantita.Articolo)) AS TotLeadTime,
	ISNULL(MediaLeadTime,(SELECT ArtbCSerPrprNLeadTime FROM ArticoliBase WHERE ArtbCSer = TabMediaQuantita.Articolo)) AS MediaLeadTime, 
	TotQuantitaOrdinata, MediaQuantita
	INTO #TabMedia
	FROM
	(SELECT Articolo,
	 Fornitore,
	 COUNT(LeadTime) AS NumLeadTimeCampione,
	 SUM(LeadTime) AS TotLeadTIme,
	 SUM(LeadTime) / COUNT(LeadTime) AS MediaLeadTime
	 FROM #TabOrdiniArticoloFornitore
	 GROUP BY Articolo, Fornitore) AS TabMediaLeadTime 
	RIGHT JOIN 
	(SELECT Articolo,
	 COUNT(QuantitaOrdinata) AS NumQuantitaCampione,
	 -- DATEDIFF(day,MIN(DataRichiesta),MAX(DataRichiesta)) AS GiorniDifferenza,
	 SUM(QuantitaOrdinata) AS TotQuantitaOrdinata,
	
	-- SUM(QuantitaOrdinata)  COUNT(QuantitaOrdinata) AS MediaQuantita
	--calcolo media giornaliera
	CASE WHEN DATEDIFF(day,DATEADD(MONTH,-12,GETDATE()) , GETDATE()	) = 0 	THEN 0
	ELSE SUM(QuantitaOrdinata) /  DATEDIFF(day,DATEADD(MONTH,-12,GETDATE()) , GETDATE()) END AS MediaQuantita
	 FROM #TabOrdiniArticoloCliente
	 GROUP BY ArticolO) AS TabMediaQuantita ON TabMediaLeadTime.Articolo = TabMediaQuantita.Articolo;

	----------------------------------------------------------------------------------------------------------------------------------------------------------

	-- Calcolo della deviazione standard del LeadTime e della QuantitaOrdinata degli articoli per ogni fornitore 
	SELECT T2.Articolo, T2.Fornitore, ISNULL(T1.DeviazioneStandardLeadTime,0) AS DeviazioneStandardLeadTime, T2.DeviazioneStandardQuantita
	 INTO #TabDeviazioneStandard
	 FROM
	 (SELECT T.Articolo,
		T.Fornitore,
		SUM(POWER(LeadTime-MediaLeadTime,2)) AS SommaParzialeLeadTime,
		--SQRT(SUM(POWER(LeadTime-MediaLeadTime,2)) / COUNT(LeadTime)) AS DeviazioneStandardLeadTime
		STDEV(LeadTime) AS DeviazioneStandardLeadTime
	FROM #TabOrdiniArticoloFornitore AS T RIGHT JOIN #TabMedia ON T.Articolo = #TabMedia.Articolo 
	AND T.Fornitore = #TabMedia.Fornitore
	GROUP BY T.Articolo, T.Fornitore) AS T1
	-- Enrico 14 Luglio 2022 - RIGHT JOIN per tenere conto degli articoli che presentano DDT ma non OrdiniFornitori
	RIGHT JOIN 
	 (SELECT T.Articolo,
			 #TabMedia.Fornitore, -- Selezione del Fornitre da TabMedia anche per la quantità
		SUM(POWER(QuantitaOrdinata-MediaQuantita,2)) AS SommaParzialeQuantita,
		-- enrico 05/07/2022 - normalizzazione del calcolo della deviazione standard
		CASE WHEN DATEDIFF(day,DATEADD(MONTH,-12,GETDATE()) , GETDATE()	) = 0 	THEN 0
		ELSE 
			CASE WHEN STDEV(QuantitaOrdinata) IS NULL THEN 0
			ELSE STDEV(QuantitaOrdinata) / DATEDIFF(day,DATEADD(MONTH,-12,GETDATE()) , GETDATE()) 
			END
		END AS DeviazioneStandardQuantita
		--SQRT(SUM(POWER(QuantitaOrdinata-MediaQuantita,2)) / COUNT(QuantitaOrdinata)) AS DeviazioneStandardQuantita
		--CASE WHEN DATEDIFF(day,MIN(DataRichiesta),MAX(DataRichiesta)) = 0 
		--THEN SQRT(SUM(POWER(QuantitaOrdinata-MediaQuantita,2))) 
		--ELSE SQRT(SUM(POWER(QuantitaOrdinata-MediaQuantita,2)) / DATEDIFF(day,MIN(DataRichiesta),MAX(DataRichiesta))) END AS DeviazioneStandardQuantita
		-- INTO #TabDeviazioneStandard
		FROM #TabOrdiniArticoloCliente AS T INNER JOIN #TabMedia ON T.Articolo = #TabMedia.Articolo
		GROUP BY T.Articolo, Fornitore) AS T2 ON T1.Articolo = T2.Articolo
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
			--livello riordino= lead time articolo * media giornaliera
			ArtbCSerPrprNLeadTime * TMedia.MediaQuantita AS LivelloRiordino
	INTO #TabResult
	FROM #TabMedia AS TMedia INNER JOIN #TabDeviazioneStandard AS TDev ON TMedia.Articolo = TDev.Articolo AND TMedia.Fornitore = TDev.Fornitore
	INNER JOIN ArticoliFornitori ON TDev.Articolo = ArtfCSerArtb AND TDev.Fornitore = ArtfCSerAncf
	INNER JOIN ArticoliBase ON ArtbCSer = TMedia.Articolo;

	SELECT * FROM #TabOrdiniArticoloFornitore WHERE Articolo IN (25562,22635,43603);
	SELECT * FROM #TabOrdiniArticoloCliente WHERE Articolo IN (25562,22635,43603);
	SELECT * FROM #TabMedia WHERE Articolo IN (25562,22635,43603);
	SELECT * FROM #TabDeviazioneStandard WHERE Articolo IN (25562,22635,43603);
	SELECT * FROM #TabResult WHERE Articolo IN (25562,22635,43603);

	---------------------------------------- Aggiornamento del LivelloRiordino e della ScortaMinima ----------------------------------------

	UPDATE [dbo].[ArticoliFornitori]
	SET ArtfCSerPrprQLivRiord = T.LivelloRiordino,
	    ArtfCSerPrprQScortaMin = T.ScortaMinima
	FROM #TabResult AS T INNER JOIN ArticoliFornitori ON T.Articolo = ArtfCSerArtb AND T.Fornitore = ArtfCSerAncf;

	UPDATE [dbo].[ArticoliBase]
	SET ArtbCSerPrprQLivRiord  = T.LivelloRiordino,
	    ArtbCSerPrprQScortaMin = T.ScortaMinima
		/*, artbTdataIniPer = DATEDIFF(day,DATEADD(MONTH,-12,GETDATE())
		,artbTdataCalCon = getdate()
		,ArtbQconMg = MediaQuantita*/
	-- Enrico 14 Luglio 2022 - Selezione del fornitore preferenziale per quegli articoli che presentano DDT ma non OrdiniFornitori
	FROM #TabResult AS T INNER JOIN ArticoliBase ON T.Articolo = ArtbCSer AND T.Fornitore = 
	CASE WHEN EXISTS(SELECT ArtfCSerAncf FROM ArticoliFornitori WHERE ArtfCSerArtb = T.Articolo AND ArtfFTipoForn = 'P') THEN
		CASE WHEN (SELECT TOP 1 Fornitore FROM #TabResult AS TIN WHERE TIN.Articolo = T.Articolo) IN (SELECT ArtfCSerAncf FROM ArticoliFornitori WHERE ArtfCSerArtb = T.Articolo AND ArtfFTipoForn = 'P') THEN
			(SELECT TOP 1 Fornitore FROM #TabResult AS TIN WHERE TIN.Articolo = T.Articolo AND TIN.Fornitore IN (SELECT ArtfCSerAncf FROM ArticoliFornitori WHERE ArtfCSerArtb = T.Articolo AND ArtfFTipoForn = 'P'))
		ELSE
			(SELECT TOP 1 Fornitore FROM #TabResult AS TIN WHERE TIN.Articolo = T.Articolo)
		END
	ELSE
		(SELECT TOP 1 Fornitore FROM #TabResult AS TIN WHERE TIN.Articolo = T.Articolo)
	END

	-- Righe aggiornate
	SELECT @righeCalcolate = @@ROWCOUNT;

	SELECT @righeCalcolate;

	IF OBJECT_ID('tempdb..#TabArticoliFornitori')		IS NOT NULL DROP TABLE #TabArticoliFornitori;
	IF OBJECT_ID('tempdb..#TabOrdiniArticoloFornitore') IS NOT NULL DROP TABLE #TabOrdiniArticoloFornitore;
	IF OBJECT_ID('tempdb..#TabOrdiniArticoloCliente')	IS NOT NULL DROP TABLE #TabOrdiniArticoloCliente;
	IF OBJECT_ID('tempdb..#TabMedia')					IS NOT NULL DROP TABLE #TabMedia;
	IF OBJECT_ID('tempdb..#TabDeviazioneStandard')		IS NOT NULL DROP TABLE #TabDeviazioneStandard;
	IF OBJECT_ID('tempdb..#TabResult')					IS NOT NULL DROP TABLE #TabResult;
END
