USE [up_Mosian]
GO

DECLARE @RC int
DECLARE @nometabella varchar(40) = 'TabAttComm' --Nome della Tabella da cui prendere l'ultimo seriale
DECLARE @incremento int = 1 -- Numero dei seriali 
DECLARE @valore float

-- TODO: impostare qui i valori dei parametri.

EXECUTE @RC = [dbo].[ProtocolloSerialTabellaGetNext] 
   @nometabella
  ,@incremento
  ,@valore OUTPUT

SELECT @valore;



