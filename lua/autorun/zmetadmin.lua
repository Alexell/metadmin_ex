if game.SinglePlayer() then return end
if not Metrostroi or not Metrostroi.Version or Metrostroi.Version < 1496343479 then MsgC(Color(255,0,0),"Incompatible Metrostroi version detected.\nMetadmin can not be loaded.\n") return end
metadmin = metadmin or {}
metadmin.category = "MetAdmin" -- Категория в ulx
metadmin.version = "01/04/2019 WORKSHOP"
if (SERVER) then
	AddCSLuaFile("metadmin/client.lua")

	include("metadmin/server.lua")
else
	include("metadmin/client.lua")
end