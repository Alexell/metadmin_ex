timer.Simple(1,function()
	if metadmin then
		local pr = ulx.command(metadmin.category, "ulx pr", metadmin.profile, "!pr")
		pr:defaultAccess(ULib.ACCESS_ALL)
		pr:addParam{type=ULib.cmds.PlayerArg, ULib.cmds.optional}
		pr:help("Профиль игрока.\nPlayer profile.")

		local prid = ulx.command(metadmin.category, "ulx prid", metadmin.profile, "!prid")
		prid:defaultAccess(ULib.ACCESS_ALL)
		prid:addParam{ type=ULib.cmds.StringArg, hint="SteamID", ULib.cmds.takeRestOfLine}
		prid:help("Профиль игрока.\nPlayer profile.")

		local st = ulx.command(metadmin.category, "ulx setrank", metadmin.setrank, "!setrank")
		st:defaultAccess(ULib.ACCESS_SUPERADMIN)
		st:addParam{type=ULib.cmds.PlayerArg}
		st:addParam{type=ULib.cmds.StringArg, hint="RANK",completes=table.GetKeys(metadmin.ranks), ULib.cmds.restrictToCompletes}
		st:addParam{type=ULib.cmds.StringArg, hint="REASON",ULib.cmds.optional}
		st:help("Установка ранга.\nSet rank.")

		local stid = ulx.command(metadmin.category, "ulx setrankid", metadmin.setrank, "!setrankid")
		stid:defaultAccess(ULib.ACCESS_SUPERADMIN)
		stid:addParam{type=ULib.cmds.StringArg, hint="PLAYER"}
		stid:addParam{type=ULib.cmds.StringArg, hint="RANK",completes=table.GetKeys(metadmin.ranks), ULib.cmds.restrictToCompletes}
		stid:addParam{type=ULib.cmds.StringArg, hint="REASON",ULib.cmds.optional}
		stid:help("Установка ранга.\nSet rank.")
	end
end)