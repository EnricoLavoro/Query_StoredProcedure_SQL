DECLARE @DaData2 DATETIME = '20/09/2021'
DECLARE @AData2 DATETIME  = '24/09/2021'
DECLARE @DaData1 DATETIME = '19/09/2022'
DECLARE @AData1 DATETIME  = '23/09/2022'

IF OBJECT_ID('tempdb..#ATT')					IS NOT NULL DROP TABLE #ATT;
IF OBJECT_ID('tempdb..#PREC')					IS NOT NULL DROP TABLE #PREC;
IF OBJECT_ID('tempdb..#A')						IS NOT NULL DROP TABLE #A;
IF OBJECT_ID('tempdb..#B')						IS NOT NULL DROP TABLE #B;

SELECT ISNULL(AageDAage,'(NESSUN AGENTE)') AS Agente,
ISNULL(DescForn,'(NESSUN FORNITORE)') AS DescFornitore,
SUM(ISNULL(PrezzoNetto,0)) AS PrezzoTotale
INTO #ATT
FROM ITV_Doc_Righe AS T1 with (nolock) LEFT OUTER JOIN IstBaseStOpMaster 
ON CAST(MbaisCMbais AS VARCHAR) = SUBSTRING(CAST(TipoDoc AS VARCHAR), 1, 
	CASE WHEN CHARINDEX(' ', CAST(TipoDoc AS VARCHAR)) - 1 > 0 THEN 
		CHARINDEX(' ', CAST(TipoDoc AS VARCHAR)) - 1 ELSE 
			LEN(CAST(TipoDoc AS VARCHAR)) 
		END) + CAST(YEAR(DataDoc) AS VARCHAR) + CAST(LEFT('000000000',LEN(CAST(NumDoc AS VARCHAR))-1) AS VARCHAR) + CAST(NumDoc AS VARCHAR)
LEFT OUTER JOIN dbo.IstClAgeStOpMColl WITH (nolock) ON dbo.IstClAgeStOpMColl.KAGISCRMbais = dbo.IstBaseStOpMaster.MbaisCSer 
LEFT OUTER JOIN dbo.Agenti WITH (nolock) ON dbo.IstClAgeStOpMColl.KAGISCRAage = dbo.Agenti.AageCSer
WHERE
T1.datadoc between @DaData1 and @AData1 and left(T1.tipodoc,3) = 'DDC'
GROUP BY AageDAage, DescForn

SELECT ISNULL(AageDAage,'(NESSUN AGENTE)') AS Agente,
ISNULL(DescForn,'(NESSUN FORNITORE)') AS DescFornitore,
SUM(ISNULL(PrezzoNetto,0)) AS PrezzoTotale
INTO #PREC
FROM ITV_Doc_Righe AS T1 with (nolock) LEFT OUTER JOIN IstBaseStOpMaster 
ON CAST(MbaisCMbais AS VARCHAR) = SUBSTRING(CAST(TipoDoc AS VARCHAR), 1, 
	CASE WHEN CHARINDEX(' ', CAST(TipoDoc AS VARCHAR)) - 1 > 0 THEN 
		CHARINDEX(' ', CAST(TipoDoc AS VARCHAR)) - 1 ELSE 
			LEN(CAST(TipoDoc AS VARCHAR)) 
		END) + CAST(YEAR(DataDoc) AS VARCHAR) + CAST(LEFT('000000000',LEN(CAST(NumDoc AS VARCHAR))-1) AS VARCHAR) + CAST(NumDoc AS VARCHAR)
LEFT OUTER JOIN dbo.IstClAgeStOpMColl WITH (nolock) ON dbo.IstClAgeStOpMColl.KAGISCRMbais = dbo.IstBaseStOpMaster.MbaisCSer 
LEFT OUTER JOIN dbo.Agenti WITH (nolock) ON dbo.IstClAgeStOpMColl.KAGISCRAage = dbo.Agenti.AageCSer
WHERE
T1.datadoc between @DaData2 and @AData2 and left(T1.tipodoc,3) = 'DDC'
GROUP BY AageDAage, DescForn

------------------------------------------------------------------------------------------------------------------------------------------------------

SELECT
		ATT.Agente AS [Agente],
		ATT.DescFornitore AS [Fornitore Articolo],
		ISNULL(ATT.PrezzoTotale,0)   AS [Fatturato Periodo 1],
		ISNULL(PREC.PrezzoTotale,0)  AS [Fatturato Periodo 2],
		ISNULL(ATT.PrezzoTotale,0) - ISNULL(PREC.PrezzoTotale,0) AS [Differenza],
		CASE WHEN ISNULL(ATT.PrezzoTotale,0) = 0 THEN 0
		ELSE ROUND(((ATT.PrezzoTotale - ISNULL(PREC.PrezzoTotale,0))/ATT.PrezzoTotale)*100,2) / 100 END  AS [Differenza %]
INTO #A
FROM #ATT AS ATT LEFT JOIN #PREC AS PREC ON PREC.Agente = ATT.Agente AND PREC.DescFornitore = ATT.DescFornitore
WHERE (ATT.Agente LIKE '%Trieste%' AND NOT(ISNULL(ATT.PrezzoTotale,0)=0 AND ISNULL(PREC.PrezzoTotale,0)=0)) --tolgo le righe dei clienti per i quali in entrambi periodi non ho avuto fatturato

SELECT
		PREC.Agente AS [Agente],
		PREC.DescFornitore AS [Fornitore Articolo],
		ISNULL(ATT.PrezzoTotale,0)   AS [Fatturato Periodo 1],
		ISNULL(PREC.PrezzoTotale,0)  AS [Fatturato Periodo 2],
		ISNULL(ATT.PrezzoTotale,0) - ISNULL(PREC.PrezzoTotale,0) AS [Differenza],
		CASE WHEN ISNULL(ATT.PrezzoTotale,0) = 0 THEN 0
		ELSE ROUND(((ATT.PrezzoTotale - ISNULL(PREC.PrezzoTotale,0))/ATT.PrezzoTotale)*100,2) / 100 END  AS [Differenza %]
INTO #B
FROM #PREC AS PREC LEFT JOIN #ATT AS ATT ON PREC.Agente = ATT.Agente AND PREC.DescFornitore = ATT.DescFornitore
WHERE (PREC.Agente LIKE '%Trieste%' AND NOT(ISNULL(ATT.PrezzoTotale,0)=0 AND ISNULL(PREC.PrezzoTotale,0)=0)) --tolgo le righe dei clienti per i quali in entrambi periodi non ho avuto fatturato

SELECT CASE WHEN #A.Agente IS NULL THEN #B.Agente ELSE #A.Agente END							AS [Agente],
	   T.FornArt																				AS [Fornitore Articolo],
	   ISNULL(#A.[Fatturato Periodo 1],0)														AS [Fatturato Periodo 1],
	   ISNULL(#B.[Fatturato Periodo 2],0)														AS [Fatturato Periodo 2],
	   CASE WHEN #A.Differenza IS NULL THEN #B.Differenza ELSE #A.Differenza END				AS [Differenza],
	   CASE WHEN #A.[Differenza %] IS NULL THEN #B.[Differenza %] ELSE #A.[Differenza %] END	AS [Differenza %]
FROM
(SELECT DISTINCT TIN.[Fornitore Articolo] AS FornArt
FROM 
(SELECT [Fornitore Articolo]
FROM #A 
UNION ALL
SELECT [Fornitore Articolo]
FROM #B) AS TIN) AS T 
LEFT JOIN #A ON T.FornArt = #A.[Fornitore Articolo]
LEFT JOIN #B ON T.FornArt = #B.[Fornitore Articolo]

IF OBJECT_ID('tempdb..#ATT')					IS NOT NULL DROP TABLE #ATT;
IF OBJECT_ID('tempdb..#PREC')					IS NOT NULL DROP TABLE #PREC;
IF OBJECT_ID('tempdb..#A')						IS NOT NULL DROP TABLE #A;
IF OBJECT_ID('tempdb..#B')						IS NOT NULL DROP TABLE #B;
