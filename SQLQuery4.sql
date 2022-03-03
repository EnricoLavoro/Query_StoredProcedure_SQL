SELECT 
	TAC.TacaCSer,
	TAC.TacaCTaca,
	TAC.TacaDTaca,
	TAC.TacaCRTcom,
	CT.TcomCTcom,
	CT.TcomDTcom,
	CT.TcomCRFSogg,
	TAC.TacaCodRif,
	TAC.TacaCRStato,
	CM.SComCSCom,
	CM.SComDSCom,
	TAC.TacaFAttivoSer,
	TAC.TacaFAttivoAzione,
	TAC.TacaTCrea,
	TAC.TacaCRAsog
FROM TabAttComm TAC LEFT OUTER JOIN CommesseTipi CT ON TAC.TacaCRTcom = CT.TcomCser
LEFT OUTER JOIN CommesseStati CM ON TAC.TacaCRStato = CM.SComCser;

SELECT * FROM TabAttComm;

SELECT *
FROM CommesseTipi CT;