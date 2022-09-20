USE Up_ColombinoEPolano

SELECT 
	MmocTreg	 AS "Data Reg.",
	MmocTLiqIVA  AS "Data Liq. IVA", 
	LEFT(RIGHT(RpriCProRegIVA,13),4) + '/'
	+ SUBSTRING(RIGHT(RpriCProRegIVA,9), PATINDEX('%[1-9]%',RIGHT(RpriCProRegIVA,9)), 10 - PATINDEX('%[1-9]%',RIGHT(RpriCProRegIVA,9))) + '/'
	+ TregCTreg  AS "Prot. IVA",
	McmcCMcmc	 AS "Cod. Causale",
	McmcDMcmc	 AS "Descr. Causale",
	MmocTDataDoc AS "Data Doc.",
	MmocCNumDoc  AS "Num. Doc.",
	AsogDAsog	 AS "Descr. Soggetto",
	AsogDpiva	 AS "Partita IVA Soggetto",
	AsogDcodfisc AS "Codice Fiscale Soggetto",
	(SELECT 
		CASE WHEN McmcDMcmc LIKE '%ACCREDITO%'
			THEN -SUM(RmocCRifImpvQImpValLoc)
			ELSE SUM(RmocCRifImpvQImpValLoc)
		END
	 FROM RigheMovContabile WHERE RmocCRifMmoc = TOUT.MmocCSer AND RmocISegno = 'A') AS Importo,
	(SELECT SUM(RivaCRifImpsImpQImpValLoc)
	 FROM RigheIVA WHERE RivaCRifMmoc = TOUT.MmocCSer) AS Imponibile,
	(SELECT SUM(RivaCRifImpsImoQImpValLoc)
	 FROM RigheIVA WHERE RivaCRifMmoc = TOUT.MmocCSer) AS IVA,
	MmocTComp   AS "Data Comp.",
	(SELECT AscoDAsco
	FROM RigheMovContabile INNER JOIN SottoConti ON RmocCRifAsco = AscoCSer
	WHERE RmocCRifMmoc = MmocCSer AND RmocCRifAsog = 0 AND RmocPRmoc = (SELECT MIN(RmocPRmoc)
	FROM RigheMovContabile INNER JOIN SottoConti ON RmocCRifAsco = AscoCSer
	WHERE RmocCRifMmoc = MmocCSer AND RmocCRifAsog = 0)) AS "Prima Controp",
	MmocXNIdSdi AS "ID Sdi",
	MmocXTDataSDI AS "Data Sdi",
	CASE WHEN (SELECT COUNT(MovoCser) FROM MasterMovContabile AS TIN INNER JOIN MasterMovContabileOggetti ON TIN.MmocCSer = MovoCRMMoc WHERE TIN.MmocCSer = TOUT.MmocCSer) > 0
		THEN 1
		ELSE 0
	END AS Allegati
	FROM MasterMovContabile AS TOUT	     WITH (nolock) 
	INNER JOIN MasterCausaliMovContabili WITH (nolock) ON MmocCRifMcmc = McmcCSer
	INNER JOIN RigheMovContabile		 WITH (nolock) ON RmocCRifMmoc = MmocCSer
	INNER JOIN Soggetti					 WITH (nolock) ON RmocCRifAsog = AsogCSer
	INNER JOIN RigheProtocolliIVA		 WITH (nolock) ON RpriCRifMmoc = MmocCSer
	INNER JOIN TabRegistri				 WITH (nolock) ON RpriCRifTreg = TregCSer
	INNER JOIN IstBaseStOpMaster		 WITH (nolock) ON MmocCrMbais  = MbaisCSer
	LEFT JOIN ClassiStOpMaster			 WITH (nolock) ON MbaisCRMcso  = MCSOCSer 
	LEFT JOIN IstTotStOpMColl			 WITH (nolock) ON KTTISCSer    = MbaisCSer
	WHERE MmocTreg BETWEEN '20190701' AND '20190731'-- AND McmcCMcmc LIKE '%'+@parCausale+'%'

--SELECT * FROM SottoConti
