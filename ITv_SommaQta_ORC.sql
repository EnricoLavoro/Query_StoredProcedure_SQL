USE [up_Emac]
GO

/****** Object:  View [dbo].[ITv_SommaQta_ORC]    Script Date: 27/09/2022 14:29:49 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

ALTER VIEW [dbo].[ITv_SommaQta_ORC] as

/*
	CREATA IL 04/02/2022 da PAOLO
	DESCRIZIONE: restituisce per ogni Ordine Cliente la somma della qta ordinata
	USATA DA: StOp_P_ORC.rpt

	MODIFICHE: 
	-aggiunto modello e somma mq, aggiunti ordini fornitori
	-Claudia 17/3/22 aggiunto OJT ser 222
	-Enrico - 27/09/2022 - Aggiunto OCE, seriale 200001003
*/

SELECT RbaisCRMbais,
       ISNULL(VlatDVlat, '') AS Modello,
       SUM(rbaisqoum) AS QtaTot,
       ROUND(SUM(((LNF.HatisNValAtt * LRF.HatisNValAtt * RbaisQoum) / 1000000)), 2) AS Mq
  FROM IstBASeStOpRighe
  LEFT JOIN IstAttrStOpMColl
    ON KatisCRMbais     = RbaisCRMbais
   AND KatisCRattr      = (SELECT AttrCser FROM Attributi WHERE AttrCAttr = 'MODCLI')
  LEFT JOIN ValoriAttributo
    ON VlatCSer         = KatisCRvlat
  LEFT JOIN IstAttrStOpRColl LNF
    ON LNF.HatisCRRBais = RbaisCSer
   AND LNF.HatisCRAttr  = (SELECT AttrCser FROM Attributi WHERE AttrCAttr = 'LNF')
  LEFT JOIN IstAttrStOpRColl LRF
    ON LRF.HatisCRRBais = RbaisCSer
   AND LRF.HatisCRAttr  = (SELECT AttrCser FROM Attributi WHERE AttrCAttr = 'LRF')
   -- Enrico - 27/09/2022 - Aggiunto OCE, seriale 200001003
 WHERE RbaisCRMcso IN (SELECT McsoCSer FROM ClassiStOpMaster WHERE MCSOCMCSO IN ('ORC','ORF','OJT','OCE'))
 GROUP BY RbaisCRMbais, ISNULL(VlatDVlat, '')
GO
