-- SELECT StampaMStOp.SSM01SconFinComp, StampaMStOp.SSM01SconComp1Comp, StampaMStOp.SSM01SconComp2Comp FROM StampaMStOp;
-- SELECT * FROM TabNazioni
-- SELECT * FROM TabGruppiStatistici;
-- SELECT * FROM TabNazioni;
-- SELECT * FROM TabGruppiStatistici;
-- SELECT * FROM LegNazioniGruppiStat;
-- SELECT * FROM TabProtocolli WHERE ProtCProtocollo LIKE '%GruppiStatisticiRighe%';
SELECT * FROM LegNazioniGruppiStat INNER JOIN TabNazioni ON LngsCRTnaz = TnazCser INNER JOIN TabGruppiStatistici ON TgrsCSer = LngsCRifGrs INNER JOIN GruppiStatisticiRighe ON RgrsCSer = LngsCRifVgrs;

DECLARE @newSerialLegNazGrupStat float  -- Nuovo seriale per il legame
DECLARE @newSerialGrupStatRighe  float  -- Nuovo seriale per il gruppo statistico righe
DECLARE @RC int

EXECUTE @RC = [dbo].[ProtocolloSerialTabellaGetNext] 
	'GruppiStatisticiRighe'
	,1
	,@newSerialGrupStatRighe OUTPUT


INSERT INTO [dbo].[GruppiStatisticiRighe]
           ([RgrsCSer]
           ,[RgrsCRifTgrs]
           ,[RgrsPRig]
           ,[RgrsCRgrs]
           ,[RgrsDRgrs]
           ,[RgrsBgrvGerCAzione]
           ,[RgrsBgrvGerCSer]
           ,[RgrsCrRgrsv])
     VALUES
           (@newSerialGrupStatRighe
           ,52
           ,3
           ,'S'
           ,'Sì'
           ,'N'
           ,1796
           ,0)

EXECUTE @RC = [dbo].[ProtocolloSerialTabellaGetNext] 
	'LegNazioniGruppiStat'
	,1
	,@newSerialLegNazGrupStat OUTPUT

INSERT INTO [dbo].[LegNazioniGruppiStat]
           ([LngsCSer]
           ,[LngsCRTnaz]
           ,[LngsPRig]
           ,[LngsCRifGrs]
           ,[LngsCRifVgrs])
     VALUES
           (@newSerialLegNazGrupStat
           ,34
           ,1
           ,52
           ,@newSerialGrupStatRig)
