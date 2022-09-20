USE up_tecnoclean
SELECT ArtaTValAtt, ArtbCArtb, ArtbDArtb, artbXNGiacenza, artbXBCheckGiacenza, ArtbCSerPrprQLivRiord, ArtbCSerPrprQScortaMin, TpcpCTpcp, TparCTpar
FROM ArticoliBase
INNER JOIN TabTipoCopertura  WITH (NOLOCK) ON ArtbCSerTpcp = TpcpCSer
INNER JOIN TabTipoArticolo   WITH (NOLOCK) ON ArtbCSerTpar = TparCSer
INNER JOIN ArticoliAttributi WITH (NOLOCK) ON ArtaCSerArtb = ArtbCSer
INNER JOIN Attributi         WITH (NOLOCK) ON ArtaCSerAttr = AttrCSer
WHERE ArtbCArtb IN ('CVSS2000010', 'CVCR1000087') and AttrCAttr = 'DT_INS_ART'
 
 --SELECT ArtbCArtb, ArtbDArtb, TssoCTsso, TssoDTsso, RbaisQoum, RbaisQium, T.MbaisTins, *
 --FROM IstBaseStOpMaster AS T
 --INNER JOIN IstBaseStOpRighe ON MbaisCSer   = RbaisCRMbais
 --INNER JOIN TabStatiStOp	 ON RbaisCRTsso = TssoCSer
 --INNER JOIN ArticoliBase	 ON RbaisCRArtb = ArtbCSer
 --WHERE MbaisCMbais LIKE '%ORF%' AND ArtbCArtb IN ('CVSS2000010', 'CVCR1000087') AND TssoCTsso NOT LIKE '%EVA%'
 --ORDER BY T.MbaisTins DESC

 SELECT ArtbCArtb, ArtbDArtb, TssoCTsso, TssoDTsso, RbaisQoum, RbaisQoumge, RbaisQium, RbaisQiumge, T.MbaisTins, *
 FROM IstBaseStOpMaster AS T
 LEFT JOIN IstBaseStOpRighe ON MbaisCSer   = RbaisCRMbais
 LEFT JOIN TabStatiStOp	 ON RbaisCRTsso = TssoCSer
 LEFT JOIN ArticoliBase	 ON RbaisCRArtb = ArtbCSer
 WHERE MbaisCMbais LIKE '%%' AND 
	ArtbCArtb IN ('CVCR1000087') -- AND TssoCTsso NOT LIKE '%EVA%'
 ORDER BY T.MbaisTins DESC

 select ElmcTIniz as Inizio,ElmcDElmc as DescrizioneAnalisi,
	ArtEl.ArtbCArtb as [Codice Art.], ArtEl.ArtbDArtb as Descrizione,
	MrpElQimp, MrpElQOrd, MrpElQGia
	--AsogCAsog as [Codice Forn.], AsogDAsog as Fornitore
	--TumsCTums as UM,
	--cast(cast(PrapQRdA as float) as varchar(20)) as Qta,
	--(case when PrapQTotGiacenza<0 then cast(cast(PrapQTotGiacenza as float) as varchar(20)) else '' end) as Giacenza, 
	--'' as GiacenzaEff, ''as QtaOrd, 4 as Ord
from ElaborazioneMancanti
inner join MRPElaborati on MrpElCRElmc = ElmcCser
inner join ArticoliBase AS ArtEl ON MrpElCRArtb = ArtbCSer

--inner join ProposteApprovvigionamento on ElmcCser=PrapCRElmc
--left join AnaDispParametriMaster FAB on ElmcCRAdpm = FAB.AdpmCser
--left join AnaDispParametriMaster SCO on ElmcCRAdpmScorta = SCO.AdpmCser
--inner join ArticoliBase AS ArtPrap on PrapCRArtb=ArtPrap.ArtbCSer
--inner join Soggetti on PrapCRAsog=Asogcser
--inner join TabUnitaMisura on TumsCSer=PrapCRUm
where -- cast(ElmcTIniz as date) = cast(getdate() as date)
	--and ElmcDElmc like '%17:00%'
	-- FAB.AdpmCadpm='ACQ'
	-- and SCO.AdpmCadpm is null
	-- and ElmcFStatoCAzione = 'C'
	ArtEl.ArtbCArtb  IN ('CVCR1000087') -- and MrpElQOrd <> 0
ORDER BY ElmcTIniz DESC--, MrpElQimp DESC
