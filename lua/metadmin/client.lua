local function T(phrase,...)
	return string.format(Metrostroi.GetPhrase(phrase),...)
end

metadmin.rights = metadmin.rights or {}
net.Receive("metadmin.rights", function()
	metadmin.rights = net.ReadTable()
end)
net.Receive("metadmin.settings", function()
	local tab = net.ReadTable()
	for k,v in pairs(tab) do
		metadmin[k] = v
	end
end)
net.Receive("metadmin.settings.mysql", function()
	local tab = {
		host = net.ReadString(),
		database = net.ReadString(),
		user = net.ReadString(),
		port = net.ReadInt(17)
	}
	local Frame = vgui.Create("DFrame")
	Frame:SetSize(225,195)
	Frame:SetTitle(T("metadmin.Menu.MySQL.Settings"))
	Frame:SetDraggable(true)
	Frame:Center()
	Frame:MakePopup()
	Frame.btnMaxim:SetVisible(false)
	Frame.btnMinim:SetVisible(false)
	local DPanel = vgui.Create("DPanel",Frame)
	DPanel:SetPos(5,30)
	DPanel:SetSize(215,160)

	local hosttext = vgui.Create("DLabel",DPanel)
	hosttext:SetTextColor(Color(0,0,0,255))
	hosttext:SetPos(5,10)
	hosttext:SetText(T("metadmin.Menu.MySQL.Host"))
	hosttext:SizeToContents()
	local host = vgui.Create("DTextEntry",DPanel)
	host:SetPos(70,5)
	host:SetSize(140,20)
	host:SetText(tab.host)

	local dbtext = vgui.Create("DLabel",DPanel)
	dbtext:SetTextColor(Color(0,0,0,255))
	dbtext:SetPos(5,35)
	dbtext:SetText(T("metadmin.Menu.MySQL.DB"))
	dbtext:SizeToContents()
	local db = vgui.Create("DTextEntry",DPanel)
	db:SetPos(70,30)
	db:SetSize(140,20)
	db:SetText(tab.database)

	local porttext = vgui.Create("DLabel",DPanel)
	porttext:SetTextColor(Color(0,0,0,255))
	porttext:SetPos(5,60)
	porttext:SetText(T("metadmin.Menu.MySQL.Port"))
	porttext:SizeToContents()
	local port = vgui.Create("DTextEntry",DPanel)
	port:SetPos(70,55)
	port:SetSize(140,20)
	port:SetText(tab.port)

	local usertext = vgui.Create("DLabel",DPanel)
	usertext:SetTextColor(Color(0,0,0,255))
	usertext:SetPos(5,85)
	usertext:SetText(T("metadmin.Menu.MySQL.User"))
	usertext:SizeToContents()
	local user = vgui.Create("DTextEntry",DPanel)
	user:SetPos(70,80)
	user:SetSize(140,20)
	user:SetText(tab.user)

	local passwordtext = vgui.Create("DLabel",DPanel)
	passwordtext:SetTextColor(Color(0,0,0,255))
	passwordtext:SetPos(5,110)
	passwordtext:SetText(T("metadmin.Menu.MySQL.Password"))
	passwordtext:SizeToContents()
	local password = vgui.Create("DTextEntry",DPanel)
	password:SetPos(70,105)
	password:SetSize(140,20)
	password:SetTooltip(T("metadmin.Menu.MySQL.PasswordTT"))

	local save = vgui.Create("DButton",DPanel)
	save:SetPos(5,135)
	save:SetText(T("metadmin.Menu.Save"))
	save:SetSize(205,20)
	save.DoClick = function()
		local tab2 = {}
		local updated
		tab["pass"] = ""
		for k,v in pairs({host=host:GetValue(),database=db:GetValue(),pass=password:GetValue(),user=user:GetValue(),port=tonumber(port:GetValue())}) do
			if tab[k] ~= v then tab2[k] = v updated = true end
		end
		if updated then
			if metadmin.provider == "mysql" then
				Derma_Message(T("metadmin.Menu.WarningInfo"),T("metadmin.Menu.Warning"),T("metadmin.Menu.WarningOK"))
			end
			net.Start("metadmin.settings.mysql")
				net.WriteBool(false)
				net.WriteTable(tab2)
			net.SendToServer()
			Frame:Close()
		end
	end
end)
net.Receive("metadmin.profile", function()
	local tab = net.ReadTable()
	tab.SID = net.ReadString()
	tab.nick = net.ReadString()
	tab.rank = net.ReadString()
	tab.synch = net.ReadBool()
	metadmin.profile(tab)
end)
net.Receive("metadmin.questions", function()
	metadmin.question(net.ReadTable(),net.ReadInt(32))
end)
net.Receive("metadmin.viewanswers", function()
	metadmin.viewanswers(net.ReadTable())
end)
metadmin.questions = metadmin.questions or {}
local quest_wait
net.Receive("metadmin.questionstab", function()
	metadmin.questions = net.ReadTable()
	if quest_wait then metadmin.questionslist() end
end)
net.Receive("metadmin.checkpermissions",function()
	local permissions = net.ReadTable()
	local Frame = vgui.Create("DFrame")
	Frame:SetSize(200,40+#permissions*20)
	Frame:SetTitle("Права")
	Frame.btnMaxim:SetVisible(false)
	Frame.btnMinim:SetVisible(false)
	Frame:SetDraggable(true)
	Frame:Center()
	Frame:MakePopup()
	local DPanel = vgui.Create("DPanel",Frame)
	DPanel:SetPos(5,30)
	DPanel:SetSize(190,5+#permissions*20)
	for k,v in pairs(permissions) do
		local icon = vgui.Create("DImage",DPanel)
		icon:SetPos(5,5 + (k-1)*20)
		icon:SetSize(16,16)
		if v[3] and v[4] then
			icon:SetImage("icon16/tick.png")
		elseif v[3] or v[4] then
			icon:SetImage("icon16/error.png")
		else
			icon:SetImage("icon16/cross.png")
		end
		local right = vgui.Create("DLabel",DPanel)
		right:SetTextColor(Color(0,0,0,255))
		right:SetPos(25,8 + (k-1)*20)
		right:SetText(v[1])
		right:SizeToContents()
		right:SetMouseInputEnabled(true)
		right:SetTooltip(v[2].."\n\nСервер: "..(v[3] and "✔" or "❌").."\nСайт: "..(v[4] and "✔" or "❌"))
	end
end)


local function T2(tab)
	for k,v in pairs(tab) do
		if istable(v) and not IsColor(v) then
			v = T2(v)
			tab[k] = T(unpack(v))
		end
	end
	return tab
end

net.Receive("metadmin.notify", function()
	local tab = T2(net.ReadTable())
	chat.AddText(unpack(tab))
end)

local metadmin_preview = CreateClientConVar("metadmin_preview",1,true,false)
local metadmin_menubutton = CreateClientConVar("metadmin_menubutton",KEY_F4,true,false)
function metadmin.Right(right)
	return table.HasValue(metadmin.rights,right)
end

local function FormatDate(t)
	return os.date("%X %d.%m.%Y",t)
end

local function HasPermission(permission)
	local ply = LocalPlayer()
	if ULib then
		return ULib.ucl.query(ply,permission)
	end
	if evolve then
		return ply:EV_HasPrivilege(permission)
	end
	return ply:IsSuperAdmin()
end

local function CheckUserGroup(group)
	if evolve then
		return evolve.ranks[group]
	end
	if CAMI then
		return tobool(CAMI.GetUsergroup(group))
	end
	return true
end


local menuopen = false
function metadmin.menu()
	menuopen = true
	local tabs = vgui.Create("DPropertySheet")
	tabs:SetPos(0,0)
	tabs:SetSize(800,260)
	tabs:MakePopup()
	tabs:Center()

	local playerslist = vgui.Create("DListView",tabs)
	playerslist:SetMultiSelect(false)
	local menu
	playerslist.OnClickLine = function(panel,line)
		if IsValid(menu) then menu:Remove() end
		line:SetSelected(true)
		menu = DermaMenu()
		local header = menu:AddOption(line:GetValue(1))
		header:SetTextInset(10,0)
		header.PaintOver = function(self,w,h) surface.SetDrawColor(0,0,0,50) surface.DrawRect(0,0,w,h) end

		menu:AddOption(T("metadmin.Menu.Profile"), function()
			RunConsoleCommand("metadmin.profile",line:GetValue(3))
			tabs:Remove()
		end):SetIcon("icon16/vcard.png")

		menu:AddOption(T("metadmin.Menu.ProfileSite"), function()
			gui.OpenURL("https://metrostroi.net/profile/"..line:GetValue(3))
			tabs:Remove()
		end):SetIcon("icon16/world_link.png")

		if HasPermission("ma.order_plombs") or HasPermission("ma.order_denial_signal") then
			local sub, row = menu:AddSubMenu(T("metadmin.Menu.Orders"))
			row:SetIcon("icon16/application_error.png")
				if HasPermission("ma.order_plombs") then
					local sub2, row = sub:AddSubMenu(T("metadmin.Menu.Plombs"))
					row:SetTextInset(10,0)
						for k,v in pairs(metadmin.plombs) do
							sub2:AddOption(v, function()
								net.Start("metadmin.order")
									net.WriteEntity(line.ply)
									net.WriteBool(true)
									net.WriteString(k)
								net.SendToServer()
								tabs:Remove()
							end):SetTextInset(10,0)
						end
				end
				if HasPermission("ma.order_denial_signal") then
					sub:AddOption(T("metadmin.Menu.restrictive_semiauto"), function()
							net.Start("metadmin.order")
								net.WriteEntity(line.ply)
								net.WriteBool(false)
								net.WriteString("semiauto")
							net.SendToServer()
						tabs:Remove()
					end):SetTextInset(10,0)
					sub:AddOption(T("metadmin.Menu.restrictive_auto"), function()
							net.Start("metadmin.order")
								net.WriteEntity(line.ply)
								net.WriteBool(false)
								net.WriteString("auto")
							net.SendToServer()
						tabs:Remove()
					end):SetTextInset(10,0)
				end
		end

		if HasPermission("ma.starttest") and LocalPlayer() ~= line.ply and not line.ply:GetNWBool("anstoques") and #metadmin.questions > 0 then
			local sub, row = menu:AddSubMenu(T("metadmin.Menu.StartTest"))
			for k,v in pairs(metadmin.questions) do
				if v.enabled == 1 then
					sub:AddOption(v.name, function()
						if metadmin_preview:GetBool() then
							metadmin.questions2(k,false,{nick = line:GetValue(1),sid = line:GetValue(3)})
						else
							net.Start("metadmin.action")
								net.WriteString(sid)
								net.WriteInt(3,5)
								net.WriteString(k)
							net.SendToServer()
						end
						tabs:Remove()
					end):SetTextInset(10,0)
				end
			end
			row:SetIcon("icon16/help.png")
		end
		if HasPermission("ma.viewresults") and line.ply:GetNWBool("anstoques") then
			menu:AddOption(T("metadmin.Menu.ViewBlank"), function()
				net.Start("metadmin.viewblank")
					net.WriteBool(true)
					net.WriteEntity(line.ply)
				net.SendToServer()
				tabs:Remove()
			end):SetIcon("icon16/help.png")
		end
		menu:AddOption(T("metadmin.Menu.Cancel")):SetIcon("icon16/cancel.png")

		menu.OnRemove = function()
			if IsValid(line) then
				line:SetSelected(false)
			end
		end
		menu:Open()
	end
	playerslist:AddColumn(T("metadmin.Menu.Nick_Column")):SetFixedWidth(410)
	playerslist:AddColumn(T("metadmin.Menu.Rank")):SetFixedWidth(220)
	playerslist:AddColumn("SteamID")
	for k,v in pairs(player.GetAll()) do
		local line = playerslist:AddLine(v:Nick(),metadmin.ranks[v:GetUserGroup()],v:SteamID())
		line.ply = v
	end
	tabs:AddSheet(T("metadmin.Menu.Online"),playerslist,"icon16/user.png")

	if HasPermission("ma.offmenu") then
		local DPanel = vgui.Create("DPanel",tabs)
		local ranks = vgui.Create("DListView",DPanel)
		ranks:SetMultiSelect(false)
		ranks:SetSize(150,225)
		ranks:AddColumn(T("metadmin.Menu.Ranks"))
		for k,v in pairs(metadmin.ranks) do
			if k == "user" then continue end
			local li = ranks:AddLine(v)
			li.k = k
		end
		ranks.OnRowSelected = function(self,rowIndex,row)
			net.Start("metadmin.allplayers")
				net.WriteString(row.k)
			net.SendToServer()
		end

		metadmin.allplayers = vgui.Create("DListView",DPanel)
		metadmin.allplayers:SetMultiSelect(false)
		metadmin.allplayers:SetPos(150,0)
		metadmin.allplayers:SetSize(634,225)
		metadmin.allplayers:AddColumn(T("metadmin.Menu.Nick_Column")):SetFixedWidth(410)
		metadmin.allplayers:AddColumn("SteamID")
		local menu
		metadmin.allplayers.OnClickLine = function(panel,line)
			if IsValid(menu) then menu:Remove() end
			line:SetSelected(true)
			menu = DermaMenu()
			local header = menu:AddOption(line:GetValue(1))
			header:SetTextInset(10,0)
			header.PaintOver = function(self,w,h) surface.SetDrawColor(0,0,0,50) surface.DrawRect(0,0,w,h) end

			menu:AddOption(T("metadmin.Menu.Profile"), function()
				RunConsoleCommand("metadmin.profile",line:GetValue(2))
				tabs:Remove()
			end):SetIcon("icon16/vcard.png")

			menu:AddOption(T("metadmin.Menu.ProfileSite"), function()
				gui.OpenURL("https://metrostroi.net/profile/"..line:GetValue(2))
				tabs:Remove()
			end):SetIcon("icon16/world_link.png")

			menu:AddOption(T("metadmin.Menu.Cancel")):SetIcon("icon16/cancel.png")

			menu.OnRemove = function()
				if IsValid(line) then
					line:SetSelected(false)
				end
			end
			menu:Open()
		end
		tabs:AddSheet(T("metadmin.Menu.Offline"),DPanel,"icon16/user_gray.png")
	end

	if HasPermission("ma.viewresults") then
		local DPanel = vgui.Create("DPanel",tabs)
		local tests = vgui.Create("DListView",DPanel)
		tests:Dock(FILL)

		tests:SetMultiSelect(false)
		local menu
		tests.OnClickLine = function(panel,line)
			if IsValid(menu) then menu:Remove() end
			line:SetSelected(true)
			menu = DermaMenu()
			local header = menu:AddOption(line:GetValue(1))
			header:SetTextInset(10,0)
			header.PaintOver = function(self,w,h) surface.SetDrawColor(0,0,0,50) surface.DrawRect(0,0,w,h) end

			menu:AddOption(T("metadmin.Menu.Profile"), function()
				RunConsoleCommand("metadmin.profile",line.SID)
				tabs:Remove()
			end):SetIcon("icon16/vcard.png")

			menu:AddOption(T("metadmin.Menu.view"), function()
				net.Start("metadmin.action")
					net.WriteString(line.SID)
					net.WriteInt(4,5)
					net.WriteString(line.id)
				net.SendToServer()
				tabs:Remove()
			end):SetIcon("icon16/help.png")

			menu:AddOption(T("metadmin.Menu.Cancel")):SetIcon("icon16/cancel.png")

			menu.OnRemove = function()
				if IsValid(line) then
					line:SetSelected(false)
				end
			end
			menu:Open()
		end
		tests:AddColumn(T("metadmin.Menu.Test_Column")):SetFixedWidth(410)
		tests:AddColumn(T("metadmin.Menu.Nick_Column")):SetFixedWidth(220)
		tests:AddColumn(T("metadmin.Menu.Date_Column"))
		tests:SetVisible(false)

		local GetTests = vgui.Create("DButton",DPanel)
		GetTests:SetPos(289.5,82)
		GetTests:SetSize(205,60)
		GetTests:SetText(T("metadmin.Menu.DownloadTests"))
		GetTests.DoClick = function()
			GetTests:SetEnabled(false)
			DPanel:SetCursor("waitarrow")
			GetTests:SetCursor("waitarrow")
			net.Start("metadmin.getuncheckedtests")
			net.SendToServer()
		end

		net.Receive("metadmin.getuncheckedtests", function()
			if not IsValid(tests) or not IsValid(GetTests) then return end
			local tab = net.ReadTable()
			for k,v in pairs(tab) do
				local line = tests:AddLine(metadmin.questions[tonumber(v.questions)] and metadmin.questions[tonumber(v.questions)].name or "ERROR",v.nick,FormatDate(v.date))
				line.id = v.id
				line.SID = v.SID
			end
			tests:SetVisible(true)
			GetTests:Remove()
			DPanel:SetCursor("none")
		end)

		tabs:AddSheet(T("metadmin.Menu.UncheckedTests"),DPanel,"icon16/page_red.png")
	end

	if HasPermission("ma.settings") then
		local DPanel = vgui.Create("DPanel",tabs)
		local DListView = vgui.Create("DListView",DPanel)
		DListView:SetMultiSelect(false)
		DListView:SetSize(100,240)
		DListView:AddColumn("")
		local lists = {}
		DListView.OnRowSelected = function(self,rowIndex,row)
			for k,v in pairs(lists) do
				v:SetVisible(false)
			end
			row.panel:SetVisible(true)
		end

		if true then
			local DPanel = vgui.Create("DPanel",DPanel)
			DPanel:SetPos(100,0)
			DPanel:SetSize(385,240)

			local showserver = vgui.Create("DCheckBoxLabel",DPanel)
			showserver:SetTextColor(Color(0,0,0,255))
			showserver:SetPos(10,10)
			showserver:SetText(T("metadmin.Menu.showserver"))
			showserver:SetChecked(metadmin.showserver)
			showserver:SetTooltip(T("metadmin.Menu.showserver_desc"))
			showserver.OnChange = function(self, value)
				net.Start("metadmin.settings")
					net.WriteTable({showserver=value})
				net.SendToServer()
			end
			showserver:SizeToContents()

			local voice = vgui.Create("DCheckBoxLabel",DPanel)
			voice:SetTextColor(Color(0,0,0,255))
			voice:SetPos(10,35)
			voice:SetText(T("metadmin.Menu.VC"))
			voice:SetChecked(metadmin.voice)
			voice:SetTooltip(T("metadmin.Menu.VC_desc"))
			voice.OnChange = function(self, value)
				net.Start("metadmin.settings")
					net.WriteTable({voice=value})
				net.SendToServer()
			end
			voice:SizeToContents()

			local synch = vgui.Create("DCheckBoxLabel",DPanel)
			synch:SetTextColor(Color(0,0,0,255))
			synch:SetPos(10,60)
			synch:SetText(T("metadmin.Menu.sync"))
			synch:SetChecked(metadmin.synch)
			synch:SetTooltip(T("metadmin.Menu.sync_desc"))
			synch.OnChange = function(self, value)
				net.Start("metadmin.settings")
					net.WriteTable({synch=value})
				net.SendToServer()
			end
			synch:SizeToContents()

			local groupwrite = vgui.Create("DCheckBoxLabel",DPanel)
			groupwrite:SetTextColor(Color(0,0,0,255))
			groupwrite:SetPos(10,85)
			groupwrite:SetText(T("metadmin.Menu.rankrewrite"))
			groupwrite:SetChecked(metadmin.groupwrite)
			groupwrite:SetTooltip(T("metadmin.Menu.autorank"))
			groupwrite.OnChange = function(self, value)
				net.Start("metadmin.settings")
					net.WriteTable({groupwrite=value})
				net.SendToServer()
			end
			groupwrite:SizeToContents()

			local provider = vgui.Create("DComboBox",DPanel)
			provider:SetPos(135,10)
			provider:SetSize(105,20)
			provider:SetValue(metadmin.provider)
			for k,v in pairs(metadmin.providers) do
				provider:AddChoice(k)
			end
			provider.OnSelect = function(self,index,value)
				Derma_Message(T("metadmin.Menu.WarningInfo"),T("metadmin.Menu.Warning"),T("metadmin.Menu.WarningOK"))
				net.Start("metadmin.settings")
					net.WriteTable({provider=value})
				net.SendToServer()
			end

			local mysqlsettings = vgui.Create("DButton",DPanel)
			mysqlsettings:SetPos(135,35)
			mysqlsettings:SetSize(105,20)
			mysqlsettings:SetText(T("metadmin.Menu.MySQL.Settings"))
			mysqlsettings.DoClick = function()
				tabs:Remove()
				net.Start("metadmin.settings.mysql")
					net.WriteBool(true)
				net.SendToServer()
			end

			local server = vgui.Create("DButton",DPanel)
			server:SetPos(135,60)
			server:SetSize(105,20)
			server:SetText(T("metadmin.Menu.sv_name"))
			server.DoClick = function()
				local frame = vgui.Create("DFrame")
				frame:SetSize(150,75)
				frame:SetTitle(T("metadmin.Menu.server_name"))
				frame:SetDraggable(true)
				frame:Center()
				frame:MakePopup()
				frame.btnMaxim:SetVisible(false)
				frame.btnMinim:SetVisible(false)
				local text = vgui.Create("DTextEntry",frame)
				text:SetPos(5,30)
				text:SetSize(140,20)
				text:SetText(metadmin.server)
				local send = vgui.Create("DButton",frame)
				send:SetPos(5,50)
				send:SetText(T("metadmin.Menu.Save"))
				send:SetSize(140,20)
				send.DoClick = function()
					net.Start("metadmin.settings")
						net.WriteTable({server=text:GetValue()})
					net.SendToServer()
					frame:Close()
				end
			end

			DPanel:SetVisible(false)
			DListView:AddLine(T("metadmin.Menu.MainSettings")).panel = DPanel
			lists.main = DPanel
		end

		if metadmin.ranks then
			local DPanel = vgui.Create("DPanel",DPanel)
			DPanel:SetPos(100,0)
			DPanel:SetSize(385,240)
			local list = vgui.Create("DListView",DPanel)
			list:SetPos(0,0)
			list:SetSize(385,210)
			list:SetMultiSelect(false)
			list:AddColumn("usergroup")
			list:AddColumn("Name")

			for k,v in pairs(metadmin.ranks) do
				local l = list:AddLine(k,v)
				l.enabled = CheckUserGroup(k)
				l.Paint = function(self,w,h)
					surface.SetDrawColor(self.enabled and Color(0,255,0,200) or Color(255,0,0,200))
					surface.DrawRect(0,0,w,h)
				end
			end
			local menu
			list.OnClickLine = function(panel,line)
				if IsValid(menu) then menu:Remove() end
				line:SetSelected(true)
				menu = DermaMenu()
				local header = menu:AddOption(line:GetValue(1).." - "..line:GetValue(2))
				header:SetTextInset(10,0)
				header.PaintOver = function(self,w,h) surface.SetDrawColor(0,0,0,50) surface.DrawRect(0,0,w,h) end

				menu:AddOption(T("metadmin.Menu.Edit"), function()
					local Frame2 = vgui.Create("DFrame")
					Frame2:SetSize(200,100)
					Frame2:SetTitle(line:GetValue(1).." - "..line:GetValue(2))
					Frame2:SetDraggable(true)
					Frame2.btnMaxim:SetVisible(false)
					Frame2.btnMinim:SetVisible(false)
					Frame2:MakePopup()
					Frame2:Center()
					local text1 = vgui.Create("DTextEntry",Frame2)
					text1:SetPos(5,30)
					text1:SetText(line:GetValue(1))
					text1:SetSize(190,20)
					local text2 = vgui.Create("DTextEntry",Frame2)
					text2:SetPos(5,50)
					text2:SetText(line:GetValue(2))
					text2:SetSize(190,20)
					local edit = vgui.Create("DButton", Frame2)
					edit:SetPos(5,75)
					edit:SetText(T("metadmin.Menu.Edit"))
					edit:SetSize(190,20)
					edit.DoClick = function()
						line:SetValue(1,text1:GetValue())
						line:SetValue(2,text2:GetValue())
						Frame2:Close()
					end
				end):SetIcon("icon16/pencil.png")

				menu:AddOption(T("metadmin.Menu.Delete"), function()
					panel:RemoveLine(line:GetID())
				end):SetIcon("icon16/delete.png")

				menu:AddOption(T("metadmin.Menu.Cancel")):SetIcon("icon16/cancel.png")

				menu.OnRemove = function()
					if IsValid(line) then
						line:SetSelected(false)
					end
				end
				menu:Open()
			end

			local add = vgui.Create("DButton",DPanel)
			add:SetPos(5,215)
			add:SetText(T("metadmin.Menu.Add"))
			add:SetSize(180,20)
			add.DoClick = function()
				list:AddLine(T("metadmin.Menu.new_mal"),T("metadmin.Menu.rank"))
			end

			local save = vgui.Create("DButton",DPanel)
			save:SetPos(200,215)
			save:SetText(T("metadmin.Menu.Save"))
			save:SetSize(180,20)
			save.DoClick = function()
				local tab = {}
				tab.ranks = {}
				for k,v in pairs(list.Lines) do
					tab.ranks[v:GetValue(1)] = v:GetValue(2)
				end
				net.Start("metadmin.settings")
					net.WriteTable(tab)
				net.SendToServer()
				tabs:Remove()
			end

			DPanel:SetVisible(false)
			DListView:AddLine(T("metadmin.Menu.Ranks")).panel = DPanel
			lists.ranks = DPanel
		end

		if metadmin.prom then
			local DPanel = vgui.Create("DPanel",DPanel)
			DPanel:SetPos(100,0)
			DPanel:SetSize(385,240)
			local list = vgui.Create("DListView",DPanel)
			list:SetPos(0,0)
			list:SetSize(385,210)
			list:SetMultiSelect(false)
			list:AddColumn(T("metadmin.Menu.prev_rank"))
			list:AddColumn(T("metadmin.Menu.next_rank"))

			for k,v in pairs(metadmin.prom) do
				list:AddLine(k,v)
			end
			local menu
			list.OnClickLine = function(panel,line)
				if IsValid(menu) then menu:Remove() end
				line:SetSelected(true)
				menu = DermaMenu()
				local header = menu:AddOption(line:GetValue(1).." - "..line:GetValue(2))
				header:SetTextInset(10,0)
				header.PaintOver = function(self,w,h) surface.SetDrawColor(0,0,0,50) surface.DrawRect(0,0,w,h) end

				menu:AddOption(T("metadmin.Menu.Edit"), function()
					local Frame2 = vgui.Create("DFrame")
					Frame2:SetSize(200,100)
					Frame2:SetTitle(line:GetValue(1).." - "..line:GetValue(2))
					Frame2:SetDraggable(true)
					Frame2.btnMaxim:SetVisible(false)
					Frame2.btnMinim:SetVisible(false)
					Frame2:MakePopup()
					Frame2:Center()
					local text1 = vgui.Create("DTextEntry",Frame2)
					text1:SetPos(5,30)
					text1:SetText(line:GetValue(1))
					text1:SetSize(190,20)
					local text2 = vgui.Create("DTextEntry",Frame2)
					text2:SetPos(5,50)
					text2:SetText(line:GetValue(2))
					text2:SetSize(190,20)
					local edit = vgui.Create("DButton", Frame2)
					edit:SetPos(5,75)
					edit:SetText(T("metadmin.Menu.Edit"))
					edit:SetSize(190,20)
					edit.DoClick = function()
						line:SetValue(1,text1:GetValue())
						line:SetValue(2,text2:GetValue())
						Frame2:Close()
					end
				end):SetIcon("icon16/pencil.png")

				menu:AddOption(T("metadmin.Menu.Delete"), function()
					panel:RemoveLine(line:GetID())
				end):SetIcon("icon16/delete.png")

				menu:AddOption(T("metadmin.Menu.Cancel")):SetIcon("icon16/cancel.png")

				menu.OnRemove = function()
					if IsValid(line) then
						line:SetSelected(false)
					end
				end
				menu:Open()
			end

			local add = vgui.Create("DButton",DPanel)
			add:SetPos(5,215)
			add:SetText(T("metadmin.Menu.Add"))
			add:SetSize(180,20)
			add.DoClick = function()
				list:AddLine(T("metadmin.Menu.new_mal"),T("metadmin.Menu.rank"))
			end

			local save = vgui.Create("DButton",DPanel)
			save:SetPos(200,215)
			save:SetText(T("metadmin.Menu.Save"))
			save:SetSize(180,20)
			save.DoClick = function()
				local tab = {}
				tab.prom = {}
				for k,v in pairs(list.Lines) do
					tab.prom[v:GetValue(1)] = v:GetValue(2)
				end
				net.Start("metadmin.settings")
					net.WriteTable(tab)
				net.SendToServer()
				tabs:Remove()
			end

			DPanel:SetVisible(false)
			DListView:AddLine(T("metadmin.Menu.promotions")).panel = DPanel
			lists.prom = DPanel
		end

		if metadmin.dem then
			local DPanel = vgui.Create("DPanel",DPanel)
			DPanel:SetPos(100,0)
			DPanel:SetSize(385,240)
			local list = vgui.Create("DListView",DPanel)
			list:SetPos(0,0)
			list:SetSize(385,210)
			list:SetMultiSelect(false)
			list:AddColumn(T("metadmin.Menu.prev_rank"))
			list:AddColumn(T("metadmin.Menu.next_rank"))

			for k,v in pairs(metadmin.dem) do
				list:AddLine(k,v)
			end
			local menu
			list.OnClickLine = function(panel,line)
				if IsValid(menu) then menu:Remove() end
				line:SetSelected(true)
				menu = DermaMenu()
				local header = menu:AddOption(line:GetValue(1).." - "..line:GetValue(2))
				header:SetTextInset(10,0)
				header.PaintOver = function(self,w,h) surface.SetDrawColor(0,0,0,50) surface.DrawRect(0,0,w,h) end

				menu:AddOption(T("metadmin.Menu.Edit"), function()
					local Frame2 = vgui.Create("DFrame")
					Frame2:SetSize(200,100)
					Frame2:SetTitle(line:GetValue(1).." - "..line:GetValue(2))
					Frame2:SetDraggable(true)
					Frame2.btnMaxim:SetVisible(false)
					Frame2.btnMinim:SetVisible(false)
					Frame2:MakePopup()
					Frame2:Center()
					local text1 = vgui.Create("DTextEntry",Frame2)
					text1:SetPos(5,30)
					text1:SetText(line:GetValue(1))
					text1:SetSize(190,20)
					local text2 = vgui.Create("DTextEntry",Frame2)
					text2:SetPos(5,50)
					text2:SetText(line:GetValue(2))
					text2:SetSize(190,20)
					local edit = vgui.Create("DButton", Frame2)
					edit:SetPos(5,75)
					edit:SetText(T("metadmin.Menu.Edit"))
					edit:SetSize(190,20)
					edit.DoClick = function()
						line:SetValue(1,text1:GetValue())
						line:SetValue(2,text2:GetValue())
						Frame2:Close()
					end
				end):SetIcon("icon16/pencil.png")

				menu:AddOption(T("metadmin.Menu.Delete"), function()
					panel:RemoveLine(line:GetID())
				end):SetIcon("icon16/delete.png")

				menu:AddOption(T("metadmin.Menu.Cancel")):SetIcon("icon16/cancel.png")

				menu.OnRemove = function()
					if IsValid(line) then
						line:SetSelected(false)
					end
				end
				menu:Open()
			end

			local add = vgui.Create("DButton",DPanel)
			add:SetPos(5,215)
			add:SetText(T("metadmin.Menu.Add"))
			add:SetSize(180,20)
			add.DoClick = function()
				list:AddLine(T("metadmin.Menu.new_mal"),T("metadmin.Menu.rank"))
			end

			local save = vgui.Create("DButton",DPanel)
			save:SetPos(200,215)
			save:SetText(T("metadmin.Menu.Save"))
			save:SetSize(180,20)
			save.DoClick = function()
				local tab = {}
				tab.dem = {}
				for k,v in pairs(list.Lines) do
					tab.dem[v:GetValue(1)] = v:GetValue(2)
				end
				net.Start("metadmin.settings")
					net.WriteTable(tab)
				net.SendToServer()
				tabs:Remove()
			end

			DPanel:SetVisible(false)
			DListView:AddLine(T("metadmin.Menu.demotions")).panel = DPanel
			lists.dem = DPanel
		end

		if metadmin.plombs then
			local DPanel = vgui.Create("DPanel",DPanel)
			DPanel:SetPos(100,0)
			DPanel:SetSize(385,240)
			local list = vgui.Create("DListView",DPanel)
			list:SetPos(0,0)
			list:SetSize(385,210)
			list:AddColumn(T("metadmin.Menu.eng"))
			list:AddColumn(T("metadmin.Menu.rus"))
			for k,v in pairs(metadmin.plombs) do
				list:AddLine(k,v)
			end

			local menu
			list.OnClickLine = function(panel,line)
				if IsValid(menu) then menu:Remove() end
				line:SetSelected(true)
				menu = DermaMenu()
				local header = menu:AddOption(line:GetValue(1).." - "..line:GetValue(2))
				header:SetTextInset(10,0)
				header.PaintOver = function(self,w,h) surface.SetDrawColor(0,0,0,50) surface.DrawRect(0,0,w,h) end

				menu:AddOption(T("metadmin.Menu.Edit"), function()
					local Frame2 = vgui.Create("DFrame")
					Frame2:SetSize(200,100)
					Frame2:SetTitle(line:GetValue(1).." - "..line:GetValue(2))
					Frame2:SetDraggable(true)
					Frame2.btnMaxim:SetVisible(false)
					Frame2.btnMinim:SetVisible(false)
					Frame2:MakePopup()
					Frame2:Center()
					local text1 = vgui.Create("DTextEntry",Frame2)
					text1:SetPos(5,30)
					text1:SetText(line:GetValue(1))
					text1:SetSize(190,20)
					local text2 = vgui.Create("DTextEntry",Frame2)
					text2:SetPos(5,50)
					text2:SetText(line:GetValue(2))
					text2:SetSize(190,20)
					local edit = vgui.Create("DButton", Frame2)
					edit:SetPos(5,75)
					edit:SetText(T("metadmin.Menu.Edit"))
					edit:SetSize(190,20)
					edit.DoClick = function()
						line:SetValue(1,text1:GetValue())
						line:SetValue(2,text2:GetValue())
						Frame2:Close()
					end
				end):SetIcon("icon16/pencil.png")

				menu:AddOption(T("metadmin.Menu.Delete"), function()
					panel:RemoveLine(line:GetID())
				end):SetIcon("icon16/delete.png")

				menu:AddOption(T("metadmin.Menu.Cancel")):SetIcon("icon16/cancel.png")

				menu.OnRemove = function()
					if IsValid(line) then
						line:SetSelected(false)
					end
				end
				menu:Open()
			end

			local add = vgui.Create("DButton",DPanel)
			add:SetPos(5,215)
			add:SetText(T("metadmin.Menu.Add"))
			add:SetSize(180,20)
			add.DoClick = function()
				list:AddLine(T("metadmin.Menu.new_fem"),T("metadmin.Menu.plomb"))
			end

			local save = vgui.Create("DButton",DPanel)
			save:SetPos(200,215)
			save:SetText(T("metadmin.Menu.Save"))
			save:SetSize(180,20)
			save.DoClick = function()
				local tab = {}
				tab.plombs = {}
				for k,v in pairs(list.Lines) do
					tab.plombs[v:GetValue(1)] = v:GetValue(2)
				end
				net.Start("metadmin.settings")
					net.WriteTable(tab)
				net.SendToServer()
				tabs:Remove()
			end

			DPanel:SetVisible(false)
			DListView:AddLine(T("metadmin.Menu.Plombs")).panel = DPanel
			lists.plombs = DPanel
		end

		if metadmin.pogona then
			local DPanel = vgui.Create("DPanel",DPanel)
			DPanel:SetPos(100,0)
			DPanel:SetSize(385,240)
			local list = vgui.Create("DListView",DPanel)
			list:SetPos(0,0)
			list:SetSize(385,210)
			list:AddColumn(T("metadmin.Menu.Rank"))
			list:AddColumn(T("metadmin.Menu.Path"))
			for k,v in pairs(metadmin.pogona) do
				list:AddLine(k,v)
			end

			local menu
			list.OnClickLine = function(panel,line)
				if IsValid(menu) then menu:Remove() end
				line:SetSelected(true)
				menu = DermaMenu()
				local header = menu:AddOption(line:GetValue(1).." - "..line:GetValue(2))
				header:SetTextInset(10,0)
				header.PaintOver = function(self,w,h) surface.SetDrawColor(0,0,0,50) surface.DrawRect(0,0,w,h) end

				menu:AddOption(T("metadmin.Menu.Edit"), function()
					local Frame2 = vgui.Create("DFrame")
					Frame2:SetSize(200,100)
					Frame2:SetTitle(line:GetValue(1).." - "..line:GetValue(2))
					Frame2:SetDraggable(true)
					Frame2.btnMaxim:SetVisible(false)
					Frame2.btnMinim:SetVisible(false)
					Frame2:MakePopup()
					Frame2:Center()
					local text1 = vgui.Create("DTextEntry",Frame2)
					text1:SetPos(5,30)
					text1:SetText(line:GetValue(1))
					text1:SetSize(190,20)
					local text2 = vgui.Create("DTextEntry",Frame2)
					text2:SetPos(5,50)
					text2:SetText(line:GetValue(2))
					text2:SetSize(190,20)
					local edit = vgui.Create("DButton", Frame2)
					edit:SetPos(5,75)
					edit:SetText(T("metadmin.Menu.Edit"))
					edit:SetSize(190,20)
					edit.DoClick = function()
						line:SetValue(1,text1:GetValue())
						line:SetValue(2,text2:GetValue())
						Frame2:Close()
					end
				end):SetIcon("icon16/pencil.png")

				menu:AddOption(T("metadmin.Menu.Delete"), function()
					panel:RemoveLine(line:GetID())
				end):SetIcon("icon16/delete.png")

				menu:AddOption(T("metadmin.Menu.Cancel")):SetIcon("icon16/cancel.png")

				menu.OnRemove = function()
					if IsValid(line) then
						line:SetSelected(false)
					end
				end
				menu:Open()
			end
			local add = vgui.Create("DButton",DPanel)
			add:SetPos(5,215)
			add:SetText(T("metadmin.Menu.Add"))
			add:SetSize(180,20)
			add.DoClick = function()
				list:AddLine(T("metadmin.Menu.new_fem"),T("metadmin.Menu.strap"))
			end
			local save = vgui.Create("DButton",DPanel)
			save:SetPos(200,215)
			save:SetText(T("metadmin.Menu.Save"))
			save:SetSize(180,20)
			save.DoClick = function()
				local tab = {}
				tab.pogona = {}
				for k,v in pairs(list.Lines) do
					tab.pogona[v:GetValue(1)] = v:GetValue(2)
				end
				net.Start("metadmin.settings")
					net.WriteTable(tab)
				net.SendToServer()
				tabs:Remove()
			end
			DPanel:SetVisible(false)
			DListView:AddLine(T("metadmin.Menu.straps")).panel = DPanel
			lists.straps = DPanel
		end

		if metadmin.disps then
			local DPanel = vgui.Create("DPanel",DPanel)
			DPanel:SetPos(100,0)
			DPanel:SetSize(385,240)
			local list = vgui.Create("DListView",DPanel)
			list:SetPos(0,0)
			list:SetSize(385,210)
			list:AddColumn(T("metadmin.Menu.Rank"))
			for k,v in pairs(metadmin.disps) do
				list:AddLine(k,v)
			end

			local menu
			list.OnClickLine = function(panel,line)
				if IsValid(menu) then menu:Remove() end
				line:SetSelected(true)
				menu = DermaMenu()
				local header = menu:AddOption(line:GetValue(1))
				header:SetTextInset(10,0)
				header.PaintOver = function(self,w,h) surface.SetDrawColor(0,0,0,50) surface.DrawRect(0,0,w,h) end

				menu:AddOption(T("metadmin.Menu.Edit"), function()
					local Frame2 = vgui.Create("DFrame")
					Frame2:SetSize(200,75)
					Frame2:SetTitle(line:GetValue(1))
					Frame2:SetDraggable(true)
					Frame2.btnMaxim:SetVisible(false)
					Frame2.btnMinim:SetVisible(false)
					Frame2:MakePopup()
					Frame2:Center()
					local text1 = vgui.Create("DTextEntry",Frame2)
					text1:SetPos(5,30)
					text1:SetText(line:GetValue(1))
					text1:SetSize(190,20)
					local edit = vgui.Create("DButton", Frame2)
					edit:SetPos(5,50)
					edit:SetText(T("metadmin.Menu.Edit"))
					edit:SetSize(190,20)
					edit.DoClick = function()
						line:SetValue(1,text1:GetValue())
						Frame2:Close()
					end
				end):SetIcon("icon16/pencil.png")

				menu:AddOption(T("metadmin.Menu.Delete"), function()
					panel:RemoveLine(line:GetID())
				end):SetIcon("icon16/delete.png")

				menu:AddOption(T("metadmin.Menu.Cancel")):SetIcon("icon16/cancel.png")

				menu.OnRemove = function()
					if IsValid(line) then
						line:SetSelected(false)
					end
				end
				menu:Open()
			end
			local add = vgui.Create("DButton",DPanel)
			add:SetPos(5,215)
			add:SetText(T("metadmin.Menu.Add"))
			add:SetSize(180,20)
			add.DoClick = function()
				list:AddLine(T("metadmin.Menu.new_group"))
			end
			local save = vgui.Create("DButton",DPanel)
			save:SetPos(200,215)
			save:SetText(T("metadmin.Menu.Save"))
			save:SetSize(180,20)
			save.DoClick = function()
				local tab = {}
				for k,v in pairs(list.Lines) do
					tab[v:GetValue(1)] = true
				end
				net.Start("metadmin.settings")
					net.WriteTable({disps=tab})
				net.SendToServer()
				tabs:Remove()
			end
			DPanel:SetVisible(false)
			DListView:AddLine(T("metadmin.Menu.dispatchers")).panel = DPanel
			lists.disps = DPanel
		end
		DListView:SelectFirstItem()
		tabs:AddSheet(T("metadmin.Menu.ServerSettings"),DPanel,"icon16/cog.png").Tab.Size = {500,275}
	end

	local questlist
	if HasPermission("ma.questionsmenu") then
		questlist = vgui.Create("DImageButton",tabs)
		questlist:SetPos(748,3)
		questlist:SetSize(16,16)
		questlist:SetImage("icon16/table.png")
		questlist:SetTooltip(T("metadmin.Menu.Questions"))
		questlist.DoClick = function()
			metadmin.questionslist()
			tabs:Remove()
		end
	end
	local settings = vgui.Create("DImageButton",tabs)
	settings:SetPos(764,3)
	settings:SetSize(16,16)
	settings:SetImage("icon16/bullet_wrench.png")
	settings:SetTooltip(T("metadmin.Menu.Settings"))
	settings.DoClick = function()
		metadmin.settings()
		tabs:Remove()
	end

	local cls = vgui.Create("DImageButton",tabs)
	cls:SetPos(780,3)
	cls:SetSize(16,16)
	cls:SetImage("icon16/cross.png")
	cls:SetTooltip(T("metadmin.Menu.Close"))
	cls.DoClick = function()
		tabs:Remove()
	end

	tabs.OnActiveTabChanged = function(self,old,new)
		if new.Size then
			self:SetSize(new.Size[1],new.Size[2])
			if questlist then
				questlist:SetPos(new.Size[1] - 52,3)
			end
			settings:SetPos(new.Size[1] - 36,3)
			cls:SetPos(new.Size[1] - 20,3)
		else
			self:SetSize(800,260)
			if questlist then
				questlist:SetPos(748,3)
			end
			settings:SetPos(764,3)
			cls:SetPos(780,3)
		end
		self:Center()
	end
	tabs.OnRemove = function()
		metadmin.allplayers = nil
		menuopen = false
	end
end
net.Receive("metadmin.allplayers", function()
	if metadmin.allplayers then
		metadmin.allplayers:Clear()
		for k,v in pairs(net.ReadTable()) do
			metadmin.allplayers:AddLine(v.nick,v.SID)
		end
	end
end)

function metadmin.settings()
	local Frame = vgui.Create("DFrame")
	Frame:SetSize(220,85)
	Frame:SetTitle(T("metadmin.Menu.Settings"))
	Frame:SetDraggable(true)
	Frame.btnMaxim:SetVisible(false)
	Frame.btnMinim:SetVisible(false)
	Frame:MakePopup()
	Frame:Center()
	local DPanel = vgui.Create("DPanel",Frame)
	DPanel:SetPos(5,30)
	DPanel:SetSize(210,50)
	local preview = vgui.Create("DCheckBoxLabel",Frame)
	preview:SetTextColor(Color(0,0,0,255))
	preview:SetPos(10,35)
	preview:SetText(T("metadmin.Menu.preview_start_test"))
	preview:SetConVar("metadmin_preview")
	preview:SizeToContents()
	local buttontext = vgui.Create("DLabel",Frame)
	buttontext:SetTextColor(Color(0,0,0,255))
	buttontext:SetPos(10,60)
	buttontext:SetText(T("metadmin.Menu.menukey"))
	buttontext:SizeToContents()
	local binder = vgui.Create("DBinder",Frame)
	binder:SetPos(165,55)
	binder:SetSize(40,20)
	binder:SetConVar("metadmin_menubutton")
end

local wait = 0
hook.Add("PlayerButtonUp","MetAdmin.buttonmenu",function(ply,key)
	if not IsFirstTimePredicted() then return end
	if key == metadmin_menubutton:GetInt() then
		if HasPermission("ma.pl") then
			if menuopen then return end
			metadmin.menu()
		elseif HasPermission("ulx prid") and wait < CurTime() then
			wait = CurTime() + 2
			RunConsoleCommand("metadmin.profile")
		end
	end
end)

local menu
function metadmin.playeract(nick,sid,rank,synch,talon,norms_promote,nodata,Frame)
	if IsValid(menu) then menu:Remove() end
	menu = DermaMenu()
	if HasPermission("ma.violationgive") then
		menu:AddOption(T("metadmin.Menu.add_violation"), function()
			local frame = vgui.Create("DFrame")
			frame:SetSize(585,165)
			frame:SetTitle(T("metadmin.Menu.adding_violation"))
			frame:SetDraggable(true)
			frame:Center()
			frame:MakePopup()
			frame.btnMaxim:SetVisible(false)
			frame.btnMinim:SetVisible(false)
			local right = (synch and GetGlobalBool("metadmin.partner",false) and metadmin.Right("warn") and not nodata)
			local type = vgui.Create("DCheckBoxLabel",frame)
			type:SetPos(5,30)
			type:SetText(T("metadmin.Menu.Global"))
			type:SetChecked(right)
			type:SetEnabled(right)
			type:SizeToContents()
			local text = vgui.Create("DTextEntry",frame)
			text:SetPos(5,50)
			text:SetSize(575,85)
			text:SetMultiline(true)
			text:SetText(T("metadmin.Menu.Violation"))
			local send = vgui.Create("DButton",frame)
			send:SetPos(5,140)
			send:SetText(T("metadmin.Menu.Send"))
			send:SetSize(575,20)
			send.DoClick = function()
				net.Start("metadmin.violations")
					net.WriteBool(true)
					net.WriteString(sid)
					net.WriteString(text:GetValue())
					net.WriteBool(type:GetChecked())
				net.SendToServer()
				frame:Close()
			end
			Frame:Close()
		end):SetIcon("icon16/error_add.png")
	end
	local function can(right)
		return (not synch or (synch and GetGlobalBool("metadmin.partner",false) and metadmin.Right(right) and not nodata))
	end
	if (can("give_coupon")) then
		if HasPermission("ma.givetalon") and talon > 1 then
			menu:AddOption(T("metadmin.Menu.return_token"), function()
				net.Start("metadmin.action")
					net.WriteString(sid)
					net.WriteInt(7,5)
				net.SendToServer()
				Frame:Close()
			end):SetIcon("icon16/tag_blue_add.png")
		end
		if HasPermission("ma.taketalon") and talon <= 3 then
			menu:AddOption(T("metadmin.Menu.take_token"), function()
				local frame2 = vgui.Create("DFrame")
				frame2:SetSize(400, 60)
				frame2:SetTitle(T("metadmin.Menu.reason"))
				frame2:Center()
				frame2.btnMaxim:SetVisible(false)
				frame2.btnMinim:SetVisible(false)
				local text = vgui.Create("DTextEntry",frame2)
				text:StretchToParent(5,29,5,5)
				text.OnEnter = function()
					net.Start("metadmin.action")
						net.WriteString(sid)
						net.WriteInt(8,5)
						net.WriteString(text:GetValue())
					net.SendToServer()
					frame2:Close()
				end
				text:RequestFocus()
				frame2:MakePopup()
				Frame:Close()
			end):SetIcon("icon16/tag_blue_delete.png")
		end
	end
	if HasPermission("ma.promote") and can("promote") and metadmin.prom[rank] and HasPermission("ma.prom"..metadmin.prom[rank]) and (not (synch and GetGlobalBool("metadmin.partner",false)) or norms_promote) then
		menu:AddOption(T("metadmin.Menu.promote"), function()
			local Frame2 = vgui.Create("DFrame")
			Frame2:SetSize(210,165)
			Frame2:SetTitle(T("metadmin.Menu.promote"))
			Frame2:SetDraggable(true)
			Frame2:Center()
			Frame2:MakePopup()
			Frame2.btnMaxim:SetVisible(false)
			Frame2.btnMinim:SetVisible(false)
			local DPanel = vgui.Create("DPanel",Frame2)
			DPanel:SetPos(5,30)
			DPanel:SetSize(200,130)
			local nick_text = vgui.Create("DLabel",DPanel)
			nick_text:SetTextColor(Color(0,0,0,255))
			nick_text:SetPos(5,5)
			nick_text:SetText(T("metadmin.Menu.Nick",nick))
			nick_text:SizeToContents()
			local rank_text = vgui.Create("DLabel",DPanel)
			rank_text:SetTextColor(Color(0,0,0,255))
			rank_text:SetPos(5,25)
			rank_text:SetText(T("metadmin.Menu.Rank")..":")
			rank_text:SizeToContents()
			local rank_choice = vgui.Create("DComboBox",DPanel)
			rank_choice:SetPos(35,25)
			rank_choice:SetSize(160,20)
			rank_choice:SetValue(metadmin.ranks[metadmin.prom[rank]])
			rank_choice:SetEnabled(false)
			local note_text = vgui.Create("DLabel",DPanel)
			note_text:SetTextColor(Color(0,0,0,255))
			note_text:SetPos(5,50)
			note_text:SetText(T("metadmin.Menu.note")..":")
			note_text:SizeToContents()
			local note = vgui.Create("DTextEntry",DPanel)
			note:SetPos(5,70)
			note:SetSize(190,30)
			note:SetMultiline(true)
			local promote = vgui.Create("DButton",Frame2)
			promote:SetPos(10,135)
			promote:SetText(T("metadmin.Menu.promote"))
			promote:SetSize(190,20)
			promote:SetEnabled(false)
			note:SetUpdateOnType(true)
			note.OnValueChange = function(self,value)
				promote:SetEnabled((utf8.len(value) >= 5 and utf8.len(value) <= 255))
			end
			promote.DoClick = function()
				net.Start("metadmin.action")
					net.WriteString(sid)
					net.WriteInt(1,5)
					net.WriteString(note:GetValue())
				net.SendToServer()
				Frame2:Close()
			end
			Frame:Close()
		end):SetIcon("icon16/arrow_up.png")
	end
	if HasPermission("ma.demote") and metadmin.dem[rank] and can("demote") then
		menu:AddOption(T("metadmin.Menu.demote"), function()
			local Frame2 = vgui.Create("DFrame")
			Frame2:SetSize(210,165)
			Frame2:SetTitle(T("metadmin.Menu.demote"))
			Frame2:SetDraggable(true)
			Frame2:Center()
			Frame2:MakePopup()
			Frame2.btnMaxim:SetVisible(false)
			Frame2.btnMinim:SetVisible(false)
			local DPanel = vgui.Create("DPanel",Frame2)
			DPanel:SetPos(5,30)
			DPanel:SetSize(200,130)
			local nick_text = vgui.Create("DLabel",DPanel)
			nick_text:SetTextColor(Color(0,0,0,255))
			nick_text:SetPos(5,5)
			nick_text:SetText(T("metadmin.Menu.Nick",nick))
			nick_text:SizeToContents()
			local rank_text = vgui.Create("DLabel",DPanel)
			rank_text:SetTextColor(Color(0,0,0,255))
			rank_text:SetPos(5,25)
			rank_text:SetText(T("metadmin.Menu.Rank")..":")
			rank_text:SizeToContents()
			local rank_choice = vgui.Create("DComboBox",DPanel)
			rank_choice:SetPos(35,25)
			rank_choice:SetSize(160,20)
			rank_choice:SetValue(metadmin.ranks[metadmin.dem[rank]])
			rank_choice:SetEnabled(false)
			local note_text = vgui.Create("DLabel",DPanel)
			note_text:SetTextColor(Color(0,0,0,255))
			note_text:SetPos(5,50)
			note_text:SetText(T("metadmin.Menu.note")..":")
			note_text:SizeToContents()
			local note = vgui.Create("DTextEntry",DPanel)
			note:SetPos(5,70)
			note:SetSize(190,30)
			note:SetMultiline(true)
			local demote = vgui.Create("DButton",Frame2)
			demote:SetPos(10,135)
			demote:SetText(T("metadmin.Menu.demote"))
			demote:SetSize(190,20)
			demote:SetEnabled(false)
			note:SetUpdateOnType(true)
			note.OnValueChange = function(self,value)
				demote:SetEnabled((utf8.len(value) >= 5 and utf8.len(value) <= 255))
			end
			demote.DoClick = function()
				net.Start("metadmin.action")
					net.WriteString(sid)
					net.WriteInt(2,5)
					net.WriteString(note:GetValue())
				net.SendToServer()
				Frame2:Close()
			end
			Frame:Close()
		end):SetIcon("icon16/arrow_down.png")
	end
	if HasPermission("ulx setrankid") and (can("change_group")) then
		local sub, row = menu:AddSubMenu(T("metadmin.Menu.SetRank"))
		row:SetIcon("icon16/lightning_go.png")
		row:SetTextInset(10,0)
		for k,v in pairs(metadmin.ranks) do
			if rank == k then continue end
			sub:AddOption(v, function()
				local Frame2 = vgui.Create("DFrame")
				Frame2:SetSize(210,165)
				Frame2:SetTitle(T("metadmin.Menu.SetRank"))
				Frame2:SetDraggable(true)
				Frame2:Center()
				Frame2:MakePopup()
				Frame2.btnMaxim:SetVisible(false)
				Frame2.btnMinim:SetVisible(false)
				local DPanel = vgui.Create("DPanel",Frame2)
				DPanel:SetPos(5,30)
				DPanel:SetSize(200,130)
				local nick_text = vgui.Create("DLabel",DPanel)
				nick_text:SetTextColor(Color(0,0,0,255))
				nick_text:SetPos(5,5)
				nick_text:SetText(T("metadmin.Menu.Nick",nick))
				nick_text:SizeToContents()
				local rank_text = vgui.Create("DLabel",DPanel)
				rank_text:SetTextColor(Color(0,0,0,255))
				rank_text:SetPos(5,25)
				rank_text:SetText(T("metadmin.Menu.Rank")..":")
				rank_text:SizeToContents()
				local rank_choice = vgui.Create("DComboBox",DPanel)
				rank_choice:SetPos(35,25)
				rank_choice:SetSize(160,20)
				for k2, v2 in pairs(metadmin.ranks) do
					if rank == k2 then continue end
					rank_choice:AddChoice(v2,k2)
				end
				rank_choice:SetValue(metadmin.ranks[k])
				local note_text = vgui.Create("DLabel",DPanel)
				note_text:SetTextColor(Color(0,0,0,255))
				note_text:SetPos(5,50)
				note_text:SetText(T("metadmin.Menu.note")..":")
				note_text:SizeToContents()
				local note = vgui.Create("DTextEntry",DPanel)
				note:SetPos(5,70)
				note:SetSize(190,30)
				note:SetMultiline(true)
				local setrank = vgui.Create("DButton",Frame2)
				setrank:SetPos(10,135)
				setrank:SetText(T("metadmin.Menu.SetRank"))
				setrank:SetSize(190,20)
				setrank:SetEnabled(false)
				note:SetUpdateOnType(true)
				note.OnValueChange = function(self,value)
					setrank:SetEnabled((utf8.len(value) >= 5 and utf8.len(value) <= 255))
				end
				setrank.DoClick = function()
					local key = rank_choice:GetSelected()
					net.Start("metadmin.action")
						net.WriteString(sid)
						net.WriteInt(0,5)
						net.WriteString(key or k)
						net.WriteString(note:GetValue())
					net.SendToServer()
					Frame2:Close()
				end
				Frame:Close()
			end):SetTextInset(10,0)
		end
	end
	if player.GetBySteamID(sid) and HasPermission("ma.starttest") and #metadmin.questions > 0 --[[and LocalPlayer() ~= target]] then
		local sub, row = menu:AddSubMenu(T("metadmin.Menu.StartTest"))
		for k,v in pairs(metadmin.questions) do
			if v.enabled == 1 then
				sub:AddOption(v.name, function()
					if metadmin_preview:GetBool() then
						metadmin.questions2(k,false,{nick = nick,sid = sid})
					else
						net.Start("metadmin.action")
							net.WriteString(sid)
							net.WriteInt(3,5)
							net.WriteString(k)
						net.SendToServer()
					end
					Frame:Close()
				end):SetTextInset(10,0)
			end
		end
		row:SetIcon("icon16/help.png")
	end
	menu:AddOption(T("metadmin.Menu.Cancel")):SetIcon("icon16/cancel.png")
	menu:Open()
end

surface.CreateFont("ma.font1", {
	size = 17,
	weight = 800,
	extended = true
})

surface.CreateFont("ma.font2", {
	size = 30,
	weight = 800,
	extended = true
})

surface.CreateFont("ma.font3", {
	size = 24,
	weight = 800,
	extended = true
})

surface.CreateFont("ma.font4", {
	size = 20,
	weight = 800,
	italic = true,
	extended = true
})

surface.CreateFont("ma.font5", {
	size = 20,
	weight = 800,
	extended = true
})


function metadmin.profile(tab)
	local creatabs = (tab.violations or tab.exam or tab.exam_answers or tab.status or tab.trains or tab.norm)
	local Frame = vgui.Create("DFrame")
	Frame:SetSize(600,creatabs and 500 or 115)
	Frame:SetTitle(T("metadmin.Menu.Profile").." "..tab.nick.." ("..tab.SID..")")
	Frame.btnMaxim:SetVisible(false)
	Frame.btnMinim:SetVisible(false)
	Frame:SetDraggable(true)
	Frame:Center()
	Frame:MakePopup()
	Frame:SetIcon("icon16/vcard.png")
	Frame.imgIcon:SetMouseInputEnabled(true)
	local DPanel = vgui.Create("DPanel",Frame)
	DPanel:SetPos(5,30)
	DPanel:SetSize(590,80)
	DPanel:SetBackgroundColor(Color( 255,255,255, 255 ))
	if not tab.preview then
		local pos = 504
		if HasPermission("ma.pl") then
			local actions = vgui.Create("DButton",Frame)
			actions:SetPos(pos,3)
			actions:SetText(T("metadmin.Menu.actions"))
			actions:SetSize(60,18)
			actions.DoClick = function()
				metadmin.playeract(tab.nick,tab.SID,tab.rank,tab.synch,(tab.status and tab.status.nom or 1),tab.norms_promote,tab.nodata,Frame)
			end
			pos = pos-60
		end
		pos = pos-20
		local report = vgui.Create("DButton",Frame)
		report:SetPos(pos,3)
		report:SetText(T("metadmin.Menu.report"))
		report:SetSize(80,18)
		report:SetEnabled(GetGlobalBool("metadmin.partner",false) and (tab.SID ~= LocalPlayer():SteamID()) and not tab.nodata)
		report.DoClick = function()
			local frame = vgui.Create("DFrame")
			frame:SetSize(585,140)
			frame:SetTitle(T("metadmin.Menu.reporting_on",tab.nick))
			frame:SetDraggable(true)
			frame:Center()
			frame:MakePopup()
			frame.btnMaxim:SetVisible(false)
			frame.btnMinim:SetVisible(false)
			local text = vgui.Create("DTextEntry",frame)
			text:SetPos(5,25)
			text:SetSize(575,85)
			text:SetMultiline(true)
			text:SetText("")
			local send = vgui.Create("DButton",frame)
			send:SetPos(5,115)
			send:SetText(T("metadmin.Menu.Send"))
			send:SetSize(575,20)
			send:SetEnabled(false)
			text:SetUpdateOnType(true)
			text.OnValueChange = function(self,value)
				send:SetEnabled((utf8.len(value) >= 10 and utf8.len(value) <= 255))
			end
			send.DoClick = function()
				net.Start("metadmin.report")
					net.WriteTable({SID = tab.SID,reason = text:GetValue()})
				net.SendToServer()
				frame:Close()
			end
			Frame:Close()
		end
		pos = pos - 20
		local synch = vgui.Create("DImageButton",Frame)
		synch:SetPos(pos,4)
		synch:SetSize(16,16)
		synch:SetImage(tab.synch and "icon16/world_go.png" or "icon16/world_delete.png")
		synch:SetTooltip(tab.synch and T("metadmin.Menu.sync_on") or T("metadmin.Menu.sync_off"))
		if HasPermission("ma.synch") or HasPermission("ma.refsynch") then
			synch.DoClick = function()
				if IsValid(menu) then menu:Remove() end
				menu = DermaMenu()
				if not tab.synch then
					menu:AddOption(T("metadmin.Menu.preview"), function()
						metadmin.profilesite(tab.SID)
						Frame:Close()
					end):SetIcon("icon16/information.png")
				end
				if HasPermission("ma.synch") then
					 menu:AddOption(T("metadmin.Menu.sync_on_off",(tab.synch and T("metadmin.Menu.disable") or T("metadmin.Menu.enable"))), function()
						net.Start("metadmin.synch")
							net.WriteBool(false)
							net.WriteString(tab.SID)
						net.SendToServer()
						Frame:Close()
					end):SetIcon(tab.synch and "icon16/delete.png" or "icon16/accept.png")
				end
				if HasPermission("ma.refsynch") then
					menu:AddOption(T("metadmin.Menu.update_data"), function()
						net.Start("metadmin.synch")
							net.WriteBool(true)
							net.WriteString(tab.SID)
						net.SendToServer()
						Frame:Close()
					end):SetIcon("icon16/arrow_rotate_anticlockwise.png")
				end
				menu:AddOption(T("metadmin.Menu.Cancel")):SetIcon("icon16/cancel.png")
				menu:Open()
			end
		end
	end
	local nick = vgui.Create("DLabel",DPanel)
	nick:SetTextColor(Color(0,0,0,255))
	nick:SetPos(75,5)
	nick:SetText(T("metadmin.Menu.Nick",tab.nick))
	nick:SizeToContents()

	local x,_ = nick:GetSize()
	for k,v in pairs(tab.icons) do
		if not istable(v) or not v.id then continue end
		v.id = tonumber(v.id)
		if not v.id or v.id == 0 or v.id == "" then continue end
		local icon = vgui.Create("DHTML",DPanel)
		icon:SetPos(75+x,0)
		icon:SetSize(21,21)
		icon:OpenURL("https://api.metrostroi.net/icon_view/"..v.id..(v.icon and "/"..v.icon or "").."?lang="..Metrostroi.ChoosedLang)
		if v.name then
			icon:SetTooltip(v.name)
		else
			icon:AddFunction("icon","SetTooltip",function(s)
				icon:SetTooltip(s)
			end)
		end
		x = x + 20
	end

	local steamid = vgui.Create("DLabel",DPanel)
	steamid:SetTextColor(Color(0,0,0,255))
	steamid:SetPos(75,20)
	steamid:SetText("STEAMID:")
	steamid:SizeToContents()

	local steamid2 = vgui.Create("DLabel",DPanel)
	steamid2:SetTextColor(Color(0,0,0,255))
	steamid2:SetPos(125,20)
	steamid2:SetText(tab.SID)
	steamid2:SetTextColor(Color(0, 0, 255))
	steamid2:SetTooltip(T("metadmin.Menu.Copy"))
	steamid2:SizeToContents()
	steamid2:SetMouseInputEnabled(true)
	steamid2.DoClick = function()
		SetClipboardText(tab.SID)
	end

	function steamid2:OnCursorEntered()
		self:SetCursor("hand")
	end
	function steamid2:OnCursorExited()
		self:SetCursor("none")
	end

	local rank = vgui.Create("DLabel",DPanel)
	rank:SetTextColor(Color(0,0,0,255))
	rank:SetPos(75,35)
	rank:SetText(T("metadmin.Menu.Rank")..": "..(metadmin.ranks[tab.rank] and metadmin.ranks[tab.rank] or tab.rank))
	rank:SizeToContents()
	if tab.nvio then
		local nvoiol = vgui.Create("DLabel",DPanel)
		nvoiol:SetTextColor(Color(0,0,0,255))
		nvoiol:SetPos(75,50)
		nvoiol:SetText(T("metadmin.Menu.violations_num",tab.nvio))
		nvoiol:SizeToContents()
	end
	local Avatar = vgui.Create("AvatarImage",DPanel)
	Avatar:SetSize(64,64)
	Avatar:SetPos(5,7)
	Avatar:SetSteamID(util.SteamIDTo64(tab.SID),64)
	function Avatar:OnCursorEntered()
		self:SetCursor("hand")
	end
	function Avatar:OnCursorExited()
		self:SetCursor("none")
	end
	local menu
	function Avatar:OnMouseReleased(code)
		if (code == MOUSE_LEFT) then
			if IsValid(menu) then menu:Remove() end
			menu = DermaMenu()
			menu:AddOption(T("metadmin.Menu.ProfileSteam"), function()
				gui.OpenURL("https://steamcommunity.com/profiles/"..util.SteamIDTo64(tab.SID))
				Frame:Close()
			end):SetIcon("games/16/all.png")
			menu:AddOption(T("metadmin.Menu.ProfileSite"), function()
				gui.OpenURL("https://metrostroi.net/profile/"..tab.SID)
				Frame:Close()
			end):SetIcon("icon16/world_link.png")
			menu:AddOption(T("metadmin.Menu.Cancel")):SetIcon("icon16/cancel.png")
			menu:Open()
		end
	end

	if metadmin.pogona[tab.rank] then
		local pogona = vgui.Create("DImage",DPanel)
		pogona:SetImage(metadmin.pogona[tab.rank])
		pogona:SetSize(140,78)
		pogona:SetPos(450,1)
	elseif tab.synch and GetGlobalBool("metadmin.partner",false) then
		local pogona = vgui.Create("HTML",DPanel)
		pogona:SetSize(140,78)
		pogona:SetPos(450,1)
		pogona:OpenURL("https://api.metrostroi.net/pogona_view/"..tab.rank)
	end

	if not creatabs then return end
	local tabs = vgui.Create("DPropertySheet",Frame)
	tabs:SetPos(0,110)
	tabs:SetSize(600,390)

	local ProfileData = {
		["violations"] = {
			order = 1,
			T("metadmin.Menu.Violations"),
			"icon16/exclamation.png",
			T("metadmin.Menu.reputation_clear"),
			function(data,tab,n,DPanel)
				DPanel:SetPos(0,80*n)
				DPanel:SetSize(584,75)
				if data.id then
					DPanel:SetBackgroundColor(Color(217,237,248))
					if HasPermission("ma.violationremove") then
						local menu
						function DPanel:OnMouseReleased()
							if IsValid(menu) then menu:Remove() end
							menu = DermaMenu()
							menu:AddOption(T("metadmin.Menu.Delete"), function()
								net.Start("metadmin.violations")
									net.WriteBool(false)
									net.WriteString(tab.SID)
									net.WriteString(data.id)
								net.SendToServer()
								Frame:Close()
							end):SetIcon("icon16/error_delete.png")
							menu:AddOption(T("metadmin.Menu.Cancel")):SetIcon("icon16/cancel.png")
							menu:Open()
						end
					end
				end
				local info = vgui.Create("DLabel",DPanel)
				info:SetTextColor(Color(0,0,0,255))
				info:SetSize(574,15)
				info:SetPos(5,5)
				info:SetText(T("metadmin.Menu.date",FormatDate(data.date)).." | "..T("metadmin.Menu.given_by",data.nick ~= "NULL" and data.nick or data.admin)..(metadmin.showserver and (not data.id and " | "..T("metadmin.Menu.server",data.server) or " | "..T("metadmin.Menu.LOCAL")) or ""))
				local reason = vgui.Create("DTextEntry",DPanel)
				reason:SetPos(5,25)
				reason:SetSize(574,45)
				reason:SetText(data.violation)
				reason:SetMultiline(true)
				function reason:OnChange() reason:SetText(data.violation) end
			end
		},
		["exam"] = {
			order = 2,
			T("metadmin.Menu.exam_results"),
			"icon16/layout_edit.png",
			T("metadmin.Menu.noexams"),
			function(data,tab,n,DPanel)
				DPanel:SetPos(0,65*n)
				DPanel:SetSize(584,60)
				data.type = tonumber(data.type)
				DPanel:SetBackgroundColor((data.type == 1 and Color(46,139,87)) or (data.type == 2 and Color(250,128,114)) or (data.type == 3 and Color(255,255,150)) or (data.type == 4 and Color(217,237,248)) or (data.type == 5 and Color(182,87,87)) or Color(176,176,176))
				local info = vgui.Create("DLabel",DPanel)
				info:SetTextColor(Color(0,0,0,255))
				info:SetSize(574,15)
				info:SetPos(5,5)
				info:SetText(((data.type == 5) and T("metadmin.Menu.failed_practice") or (metadmin.ranks[data.rank] or data.rank)).." | "..T("metadmin.Menu.date",FormatDate(data.date)).." | "..T("metadmin.Menu.exam_by",data.nick ~= "NULL" and data.nick or data.examiner)..(metadmin.showserver and " | "..T("metadmin.Menu.server",data.server) or ""))
				local note = vgui.Create("DTextEntry",DPanel)
				note:SetPos(5,25)
				note:SetSize(574,30)
				note:SetText(data.note)
				note:SetMultiline(true)
				function note:OnChange() note:SetText(data.note) end
			end
		},
		["exam_answers"] = {
			order = 3,
			T("metadmin.Menu.tests_results"),
			"icon16/page_edit.png",
			T("metadmin.Menu.notests"),
			function(data,tab,n,DPanel)
				DPanel:SetPos(0,30*n)
				DPanel:SetSize(584,25)
				if metadmin.questions[data.questions] and (HasPermission("ma.viewresults") or HasPermission("ma.setstattest")) and not data.site then
					local menu
					function DPanel:OnMouseReleased()
						if IsValid(menu) then menu:Remove() end
						menu = DermaMenu()
						if HasPermission("ma.viewresults") then
							menu:AddOption(T("metadmin.Menu.view"), function()
								net.Start("metadmin.action")
									net.WriteString(tab.SID)
									net.WriteInt(4,5)
									net.WriteString(data.id)
								net.SendToServer()
								Frame:Close()
							end):SetIcon("icon16/information.png")
						end
						if HasPermission("ma.setstattest") then
							local sub, row = menu:AddSubMenu(T("metadmin.Menu.status"))
							row:SetIcon(data.status == 1 and "icon16/tick.png" or data.status == 2 and "icon16/cross.png" or "icon16/help.png")
							sub:AddOption(T("metadmin.Menu.exam_pass"), function()
								net.Start("metadmin.action")
									net.WriteString(tab.SID)
									net.WriteInt(5,5)
									net.WriteString(data.id)
									net.WriteInt(1,3)
								net.SendToServer()
								Frame:Close()
							end):SetIcon("icon16/tick.png")
							sub:AddOption(T("metadmin.Menu.exam_fail"), function()
								net.Start("metadmin.action")
									net.WriteString(tab.SID)
									net.WriteInt(5,5)
									net.WriteString(data.id)
									net.WriteInt(2,3)
								net.SendToServer()
								Frame:Close()
							end):SetIcon("icon16/cross.png")
							sub:AddOption(T("metadmin.Menu.exam_review"), function()
								net.Start("metadmin.action")
									net.WriteString(tab.SID)
									net.WriteInt(5,5)
									net.WriteString(data.id)
									net.WriteInt(0,3)
								net.SendToServer()
								Frame:Close()
							end):SetIcon("icon16/help.png")
						end
						menu:AddOption(T("metadmin.Menu.Cancel")):SetIcon("icon16/cancel.png")
						menu:Open()
					end
				end
				local img = vgui.Create("DImage",DPanel)
				img:SetPos(5,5)
				img:SetSize(16,16)
				img:SetImage(data.status == 1 and "icon16/tick.png" or data.status == 2 and "icon16/cross.png" or "icon16/help.png")
				img:SetTooltip(data.status == 1 and T("metadmin.Menu.exam_pass") or data.status == 2 and T("metadmin.Menu.exam_fail") or T("metadmin.Menu.exam_review"))
				img:SetMouseInputEnabled(true)
				local info = vgui.Create("DLabel",DPanel)
				info:SetTextColor(Color(0,0,0,255))
				info:SetSize(574,15)
				info:SetPos(25,5)
				info:SetText("| "..(metadmin.questions[data.questions] and metadmin.questions[data.questions].name or "ERROR").." | "..T("metadmin.Menu.date",FormatDate(data.date))..((data.site and " | Metrostroi.net" or ((data.admin ~= "") and " | "..T("metadmin.Menu.given_by",data.admin) or "")))..(data.ssadmin ~= "" and " | "..T("metadmin.Menu.review_by",data.ssadmin) or ""))
			end
		}
	}

	local wait = os.time()
	local sended
	for k,v in SortedPairsByMemberValue(ProfileData, "order") do
		if tab[k] then
			local DPanel = vgui.Create("DPanel",tabs)
			DPanel:SetBackgroundColor(Color(128,128,128))
			if #tab[k] <= 0 then
				DPanel.PaintOver = function(self,w,h)
					draw.SimpleText(v[3], "ma.font3", w/2, 20, Color(50,50,50), TEXT_ALIGN_CENTER)
				end
			else
				local Vio_DScrollPanel = vgui.Create("DScrollPanel",DPanel)
				Vio_DScrollPanel:SetSize(600,355)
				Vio_DScrollPanel:SetPos(0,0)
				Vio_DScrollPanel.OnMouseWheeled = function(self,dlta)
					local _,y = self:GetCanvas():GetSize()
					local _,y2 = self:GetCanvas():GetPos()
					if y-355==(y2*-1) and not sended and wait < os.time() then
						net.Start("metadmin.profile2")
							net.WriteString(tab.SID)
							net.WriteString(k)
							net.WriteInt(#tab[k],32)
						net.SendToServer()
						wait = os.time() + 0.5
						sended = true
						print("sended")
					end
					return self.VBar:OnMouseWheeled(dlta)
				end
				v.Panel = Vio_DScrollPanel
				local n = 0
				for k2,v2 in SortedPairsByMemberValue(tab[k], "date", true) do
					local DPanel = vgui.Create("DPanel",Vio_DScrollPanel)
					v[4](v2,tab,n,DPanel)
					n = n + 1
				end
			end
			tabs:AddSheet(v[1],DPanel,v[2])
		end
	end

	if not tab.preview then
		net.Receive("metadmin.profile2", function()
			sended = false
			local SID = net.ReadString()
			if SID ~= tab.SID then return end
			local what = net.ReadString()
			local tab2 = net.ReadTable()
			if ProfileData[what] then
				local info = ProfileData[what]
				local n = #tab[what]
				for k,v in SortedPairsByMemberValue(tab2, "date", true) do
					local DPanel = vgui.Create("DPanel",info.Panel)
					info[4](v,tab,n,DPanel)
					n = n + 1
				end
				table.Add(tab["what"],tab2)
			end
		end)

		if (metadmin.Right("norms") or tab.SID == LocalPlayer():SteamID() or LocalPlayer():IsAdmin()) and tab.synch and GetGlobalBool("metadmin.partner",false) and metadmin.profile_norm then
			local norm = vgui.Create("DPanel",tabs)
			norm:SetBackgroundColor(Color(128,128,128))
			metadmin.profile_norm(tab,norm,tabs)
			tabs:AddSheet("Нормативы",norm,"icon16/table.png")
		end
	end

	if tab.status then
		local talon = vgui.Create("DPanel",tabs)
		talon:SetBackgroundColor(Color(255,228,181))
		talon.PaintOver = function(self,w,h)
			surface.SetDrawColor(tab.status.nom == 1 and Color(3,111,35) or tab.status.nom == 2 and Color(255,255,0) or tab.status.nom == 3 and Color(178,34,34) or Color(255,127,127))
			draw.NoTexture()
			surface.DrawPoly({{ x = 0, y = 0 },{ x = 40, y = 0 },{ x = w, y = h },{ x = w-40, y = h }})
			draw.SimpleText(GetHostName(), "ma.font1", w/2, 20, Color(50,50,50), TEXT_ALIGN_CENTER)
			draw.SimpleText(T("metadmin.Menu.warning_token")..tab.status.nom, "ma.font2", w/2, 55, Color(50,50,50), TEXT_ALIGN_CENTER)
			draw.SimpleText(T("metadmin.Menu.token_desc"), "ma.font3", w/2, 90, Color(50,50,50), TEXT_ALIGN_CENTER)
			draw.SimpleText(tab.nick, "ma.font4", w/2, h/2, Color(50,50,50), TEXT_ALIGN_CENTER)
			draw.SimpleText(tab.SID, "ma.font4", w/2, h/2 + 20, Color(50,50,50), TEXT_ALIGN_CENTER)
			draw.SimpleText(T("metadmin.Menu.token_given",FormatDate(tab.status.date)), "ma.font5", w/2, tab.status.admin ~= "" and 310 or 330, Color(50,50,50), TEXT_ALIGN_CENTER)//(600,390)
			if tab.status.admin ~= "" then draw.SimpleText(tab.status.admin, "ma.font5", w/2, 330, Color(50,50,50), TEXT_ALIGN_CENTER) end
		end
		tabs:AddSheet(T("metadmin.Menu.token"),talon,"icon16/vcard.png")
	end
	if tab.trains then
		local trains = vgui.Create("DPanel",tabs)
		trains:SetBackgroundColor(Color(128,128,128))
		local DScrollPanel = vgui.Create("DScrollPanel",trains)
		DScrollPanel:SetSize(600,355)
		DScrollPanel:SetPos(0,0)
		local num = 0
		for k,v in pairs(tab.trains) do
			local DPanel = vgui.Create("DPanel",DScrollPanel)
			DPanel:SetPos(0,143*num)
			DPanel:SetSize(584,138)
			for k2,v2 in pairs(v) do
				local Image = vgui.Create("DImage",DPanel)
				Image:SetPos(5 + (k2-1)*133,5)
				Image:SetSize(128,128)
				Image:SetMaterial(Material("VGUI/entities/"..v2))
				Image:SetMouseInputEnabled(true)
				Image:SetTooltip(T("Entities."..v2..".Name"))
			end
			num = num + 1
		end
		tabs:AddSheet(T("metadmin.Menu.Trains"),trains,"icon16/transmit_blue.png")
	end
end

function metadmin.profilesite(sid)
	http.Post("https://api.metrostroi.net/user",{SID=sid},function(body,len,headers,code)
		if code ~= 200 then return end
		if body == "" then
			chat.AddText(Color(129,207,224),T("metadmin.Menu.DB.player_404"))
			return
		end
		local tab = util.JSONToTable(body)
		if not metadmin.ranks[tab.rank] then
			chat.AddText(Color(129,207,224),T("metadmin.Menu.DB.norank", tab.rank))
			return
		end
		tab.preview = true
		tab.nvio = #tab.violations
		local target = player.GetBySteamID(sid)
		if target and target:Nick() ~= tab.nick then
			tab.nick = target:Nick()
		end
		metadmin.profile(tab)
	end)
end

function metadmin.questionslist()
	quest_wait = false
	local Frame = vgui.Create("DFrame")
	Frame:SetSize(200,260)
	Frame:SetTitle(T("metadmin.Menu.template_list"))
	Frame:SetDraggable(true)
	Frame.btnMaxim:SetVisible(false)
	Frame.btnMinim:SetVisible(false)
	Frame:MakePopup()
	Frame:Center()
	if HasPermission("ma.questionscreate") then
		local add = vgui.Create("DButton",Frame)
		add:SetPos(103,2.5)
		add:SetText(T("metadmin.Menu.Add"))
		add:SetSize(60,20)
		add.DoClick = function()
			local frame2 = vgui.Create("DFrame")
			frame2:SetSize(400,60)
			frame2:SetTitle(T("metadmin.Menu.template_name"))
			frame2:Center()
			frame2.btnMaxim:SetVisible(false)
			frame2.btnMinim:SetVisible(false)
			local text = vgui.Create("DTextEntry",frame2)
			text:StretchToParent(5,29,5,5)
			text.OnEnter = function()
				Frame:Close()
				local value = text:GetValue()
				net.Start("metadmin.qaction")
					net.WriteInt(4,5)
					net.WriteInt(0,32)
					net.WriteString(value)
				net.SendToServer()
				frame2:Remove()
				quest_wait = true
			end
			text:RequestFocus()
			frame2:MakePopup()
		end
	end
	local questionlist = vgui.Create("DListView",Frame)
	questionlist:SetPos(10,30)
	questionlist:SetSize(180,220)
	questionlist:SetMultiSelect(false)
	local menu
	questionlist.OnClickLine = function(panel,line)
		if IsValid(menu) then menu:Remove() end
		line:SetSelected(true)
		menu = DermaMenu()
		local header = menu:AddOption(line:GetValue(1))
		header:SetTextInset(10,0)
		header.PaintOver = function(self,w,h) surface.SetDrawColor(0,0,0,50) surface.DrawRect(0,0,w,h) end

		menu:AddOption(T("metadmin.Menu.view_questions"), function()
			metadmin.questions2(line.id)
			Frame:Close()
		end):SetIcon("icon16/table.png")
		if HasPermission("ma.questionsedit") then
			local sub, row = menu:AddSubMenu(T("metadmin.Menu.Edit"))
			row:SetIcon("icon16/table_edit.png")
				sub:AddOption(T("metadmin.Menu.name"), function()
					local frame = vgui.Create("DFrame")
					frame:SetSize(150,75)
					frame:SetTitle(T("metadmin.Menu.template_name"))
					frame:SetDraggable(true)
					frame:Center()
					frame:MakePopup()
					frame.btnMaxim:SetVisible(false)
					frame.btnMinim:SetVisible(false)
					local text = vgui.Create("DTextEntry",frame)
					text:SetPos(5,30)
					text:SetSize(140,20)
					text:SetText(line:GetValue(1))
					local send = vgui.Create("DButton",frame)
					send:SetPos(5,50)
					send:SetText(T("metadmin.Menu.Save"))
					send:SetSize(140,20)
					local id = line.id
					send.DoClick = function()
						Frame:Close()
						net.Start("metadmin.qaction")
							net.WriteInt(5,5)
							net.WriteInt(id,32)
							net.WriteString(text:GetValue())
						net.SendToServer()
						frame:Close()
						quest_wait = true
					end
				end):SetTextInset(10,0)
				local timelimit = line.timelimit
				sub:AddOption(T("metadmin.Menu.recom_time"), function()
					local frame = vgui.Create("DFrame")
					frame:SetSize(150,75)
					frame:SetTitle(T("metadmin.Menu.recom_time")..T("metadmin.Menu.seconds"))
					frame:SetDraggable(true)
					frame:Center()
					frame:MakePopup()
					frame.btnMaxim:SetVisible(false)
					frame.btnMinim:SetVisible(false)
					local text = vgui.Create("DTextEntry",frame)
					text:SetPos(5,30)
					text:SetSize(140,20)
					text:SetText(timelimit)
					local send = vgui.Create("DButton",frame)
					send:SetPos(5,50)
					send:SetText(T("metadmin.Menu.Save"))
					send:SetSize(140,20)
					local id = line.id
					send.DoClick = function()
						Frame:Close()
						net.Start("metadmin.qaction")
							net.WriteInt(6,5)
							net.WriteInt(id,32)
							net.WriteInt(text:GetValue(),32)
						net.SendToServer()
						frame:Close()
						quest_wait = true
					end
				end):SetTextInset(10,0)
				sub:AddOption(T("metadmin.Menu.template"), function()
					metadmin.questions2(line.id,true)
					Frame:Close()
				end):SetTextInset(10,0)
		end
		if HasPermission("ma.questionsimn") then
			menu:AddOption(line.enabled == 0 and T("metadmin.Menu.enable") or T("metadmin.Menu.disable"), function()
				net.Start("metadmin.qaction")
					net.WriteInt(1,5)
					net.WriteInt(line.id,32)
				net.SendToServer()
				Frame:Close()
				quest_wait = true
			end):SetIcon(line.enabled == 0 and "icon16/table_row_insert.png"or"icon16/table_row_delete.png")
		end
		if HasPermission("ma.questionsremove") then
			local name = line:GetValue(1)
			menu:AddOption(T("metadmin.Menu.Delete"), function()
				local id = line.id
				Derma_Query(T("metadmin.Menu.confirm_prompt", name), T("metadmin.Menu.template_rem"),
					T("metadmin.yes"), function()
						net.Start("metadmin.qaction")
							net.WriteInt(2,5)
							net.WriteInt(id,32)
						net.SendToServer()
						quest_wait = true
					end,
					T("metadmin.no"), metadmin.questionslist
				)
				Frame:Close()
			end):SetIcon("icon16/table_delete.png")
		end

		menu:AddOption(T("metadmin.Menu.Cancel")):SetIcon("icon16/cancel.png")

		menu.OnRemove = function()
			if IsValid(line) then
				line:SetSelected(false)
			end
		end
		menu:Open()
	end
	questionlist:AddColumn(T("metadmin.Menu.name_full"))
	for k,v in pairs(metadmin.questions) do
		local line = questionlist:AddLine(v.name)
		line.id = k
		line.timelimit = v.timelimit
		line.enabled = v.enabled
		line.Paint = function(self,w,h)
			surface.SetDrawColor(v.enabled==1 and Color(0,255,0,200) or Color(160,160,160,200))
			surface.DrawRect(0,0,w,h)
		end
	end
end

function metadmin.question(tab,timelimit)
	if timelimit == 0 then timelimit = false end
	local starttime = os.time()
	local answer = {}
	local maxn = #tab
	local Frame = vgui.Create("DFrame")
	Frame:SetSize(800,math.min(600,80+40*maxn))
	Frame:SetTitle(T("metadmin.Menu.Questions").." ("..maxn..")")
	Frame:ShowCloseButton(false)
	Frame:SetDraggable(true)
	Frame:Center()
	Frame:MakePopup()
	Frame:SetRenderInScreenshots(false)
	local time = vgui.Create("DLabel",Frame)
	time:SetSize(115,20)
	time:SetPos(342,2)
	time.UpdateColours = function( label, skin )
		label:SetTextStyleColor( skin.Colours.Window.TitleActive )
	end
	time.Think = function(self)
		local time = (os.time()-starttime)
		if timelimit and time > timelimit then
			self:SetColor(Color(255,0,0))
		end
		self:SetText(T("metadmin.Menu.curtime",string.ToMinutesSeconds(time)))
	end
	if timelimit then
		local recomtime = vgui.Create("DLabel",Frame)
		recomtime:SetSize(150,20)
		recomtime:SetPos(645,2)
		recomtime.UpdateColours = function( label, skin )
			label:SetTextStyleColor( skin.Colours.Window.TitleActive )
		end
		recomtime:SetText(T("metadmin.Menu.rectime",string.ToMinutesSeconds(timelimit)))
	end
	local DScrollPanel = vgui.Create("DScrollPanel",Frame)
	DScrollPanel:SetSize(790,math.min(540,60+40*maxn))
	DScrollPanel:SetPos(1,25)
	local DPanel = vgui.Create("DPanel",DScrollPanel)
	DPanel:SetPos(5,5)
	DPanel:SetSize(790, 20+40*maxn)
	local num = 0
	for k, v in pairs(tab) do
		local question = vgui.Create("DLabel",DPanel)
		question:SetTextColor(Color(0,0,0,255))
		question:SetSize(760,20)
		question:SetPos(5,5+num*40)
		question:SetText((isstring(v) and v or v.question)..": ")
		if istable(v) then
			answer[k] = vgui.Create("DComboBox",DPanel)
			answer[k]:SetColor(color_black)
			answer[k]:SetPos(5,25+num*40)
			answer[k]:SetSize(760,20)
			for k2, v2 in pairs(v.answers) do
				answer[k]:AddChoice(v2)
			end
		else
			answer[k] = vgui.Create("DTextEntry",DPanel)
			answer[k]:SetPos(5,25+num*40)
			answer[k]:SetSize(760,20)
			answer[k]:SetUpdateOnType(true)
			answer[k].OnValueChange = function(self,value)
				net.Start("metadmin.answers")
					net.WriteBool(true)
					net.WriteTable({k,value})
				net.SendToServer()
			end
		end
		num = num+1
	end
	local send = vgui.Create("DButton",Frame)
	send:SetPos(5,math.min(575,55+40*maxn))
	send:SetText(T("metadmin.Menu.Send"))
	send:SetSize(790,20)
	send.DoClick = function()
		local answers = {}
		for k, v in pairs(answer) do
			answers[k] = answer[k]:GetValue()
		end
		net.Start("metadmin.answers")
			net.WriteBool(false)
			net.WriteTable(answers)
		net.SendToServer()
		Frame:Close()
	end
end

function metadmin.viewanswers(tab)
	if not tab then return end
	local maxn = #tab.questions
	local Frame = vgui.Create("DFrame")
	Frame:SetSize(800,math.min(600,80+40*maxn))
	Frame:SetTitle(T("metadmin.Menu.player_answers", tab.nick, tab.sid))
	Frame.btnMaxim:SetVisible(false)
	Frame.btnMinim:SetVisible(false)
	Frame:SetDraggable(true)
	Frame:Center()
	Frame:MakePopup()
	Frame:SetIcon(tab.answerstab.status == 1 and "icon16/tick.png" or tab.answerstab.status == 2 and "icon16/cross.png" or "icon16/help.png")
	Frame.imgIcon:SetTooltip(tab.answerstab.status == 1 and T("metadmin.Menu.exam_pass") or tab.answerstab.status == 2 and T("metadmin.Menu.exam_fail") or T("metadmin.Menu.exam_review"))
	Frame.imgIcon:SetMouseInputEnabled(true)
	function Frame.imgIcon:OnCursorEntered()
		self:SetCursor("hand")
	end
	function Frame.imgIcon:OnCursorExited()
		self:SetCursor("none")
	end
	if HasPermission("ma.setstattest") then
		local menu
		function Frame.imgIcon:OnMouseReleased(code)
			if (code == MOUSE_LEFT) then
				if IsValid(menu) then menu:Remove() end
				menu = DermaMenu()
				menu:AddOption(T("metadmin.Menu.exam_pass"), function()
					net.Start("metadmin.action")
						net.WriteString(tab.sid)
						net.WriteInt(5,5)
						net.WriteString(tab.answerstab.id)
						net.WriteInt(1,3)
					net.SendToServer()
					Frame:Close()
				end):SetIcon("icon16/tick.png")
				menu:AddOption(T("metadmin.Menu.exam_fail"), function()
					net.Start("metadmin.action")
						net.WriteString(tab.sid)
						net.WriteInt(5,5)
						net.WriteString(tab.answerstab.id)
						net.WriteInt(2,3)
					net.SendToServer()
					Frame:Close()
				end):SetIcon("icon16/cross.png")
				menu:AddOption(T("metadmin.Menu.exam_review"), function()
					net.Start("metadmin.action")
						net.WriteString(tab.sid)
						net.WriteInt(5,5)
						net.WriteString(tab.answerstab.id)
						net.WriteInt(0,3)
					net.SendToServer()
					Frame:Close()
				end):SetIcon("icon16/help.png")
			end
			menu:Open()
		end
	end
	local time = vgui.Create("DLabel",Frame)
	time:SetSize(115,20)
	time:SetPos(342,2)
	time:SetText(T("metadmin.Menu.player_time",string.ToMinutesSeconds(tab.answerstab.time)))
	time.UpdateColours = function(label,skin)
		label:SetTextStyleColor(skin.Colours.Window.TitleActive)
	end
	if not tab.timelimit or tab.timelimit == 0 then tab.timelimit = false end
	if tab.timelimit then
		if tab.timelimit < tab.answerstab.time then
			time:SetColor(Color(255,0,0))
		end
		local recomtime = vgui.Create("DLabel",Frame)
		recomtime:SetSize(150,20)
		recomtime:SetPos(610,2)
		recomtime.UpdateColours = function(label,skin)
			label:SetTextStyleColor(skin.Colours.Window.TitleActive)
		end
		recomtime:SetText(T("metadmin.Menu.rectime",string.ToMinutesSeconds(tab.timelimit)))
	end
	local DScrollPanel = vgui.Create("DScrollPanel",Frame)
	DScrollPanel:SetSize(790,math.min(540,60+40*maxn))
	DScrollPanel:SetPos(1,25)
	local DPanel = vgui.Create("DPanel",DScrollPanel)
	DPanel:SetPos(5,5)
	DPanel:SetSize(790,20+40*maxn)
	local num = 0
	for k=1,maxn do
		local question = vgui.Create("DLabel",DPanel)
		question:SetTextColor(Color(0,0,0,255))
		question:SetSize(760,20)
		question:SetPos(5,5+num*40)
		local quest = tab.questions[k]
		question:SetText((isstring(quest) and quest or quest.question)..": ")
		local answer = vgui.Create("DTextEntry",DPanel)
		answer:SetPos(5,25+num*40)
		answer:SetSize(760,20)
		answer:SetText(tab.answers[k] or T("metadmin.Error"))
		function answer:OnChange() answer:SetText(tab.answers[k] or T("metadmin.Error")) end
		num = num+1
	end
	local send = vgui.Create("DButton",Frame)
	send:SetPos(5,math.min(575,55+40*maxn))
	send:SetText(T("metadmin.Menu.return_to_profile"))
	send:SetSize(790,20)
	send.DoClick = function()
		Frame:Close()
		RunConsoleCommand("metadmin.profile",tab.sid)
	end
end

metadmin.blank = {}
function metadmin.viewblank(tab)
	if not tab or IsValid(metadmin.blank.Frame) then return end
	metadmin.blank.answers = {}
	local maxn = #tab.questions
	metadmin.blank.Frame = vgui.Create("DFrame")
	metadmin.blank.Frame:SetSize(800,math.min(580,60+40*maxn))
	metadmin.blank.Frame:SetTitle(T("metadmin.Menu.player_answers", tab.nick, tab.sid))
	metadmin.blank.Frame.btnMaxim:SetVisible(false)
	metadmin.blank.Frame.btnMinim:SetVisible(false)
	metadmin.blank.Frame:SetDraggable(true)
	metadmin.blank.Frame:Center()
	metadmin.blank.Frame:MakePopup()
	function metadmin.blank.Frame:OnClose()
		if IsValid(metadmin.target) then
			net.Start("metadmin.viewblank")
				net.WriteBool(false)
				net.WriteEntity(metadmin.target)
			net.SendToServer()
		end
	end
	if not tab.timelimit or tab.timelimit == 0 then tab.timelimit = false end
	local time = vgui.Create("DLabel",metadmin.blank.Frame)
	time:SetSize(115,20)
	time:SetPos(342,2)
	time.UpdateColours = function(label,skin)
		label:SetTextStyleColor(skin.Colours.Window.TitleActive)
	end
	time.Think = function(self)
		local time = (os.time()-tab.starttime)
		if tab.timelimit and time > tab.timelimit then
			self:SetColor(Color(255,0,0))
		end
		self:SetText(T("metadmin.Menu.curtime",string.ToMinutesSeconds(time)))
	end
	if tab.timelimit then
		local recomtime = vgui.Create("DLabel",metadmin.blank.Frame)
		recomtime:SetSize(150,20)
		recomtime:SetPos(615,2)
		recomtime.UpdateColours = function(label,skin)
			label:SetTextStyleColor(skin.Colours.Window.TitleActive)
		end
		recomtime:SetText(T("metadmin.Menu.rectime",string.ToMinutesSeconds(tab.timelimit)))
	end
	local DScrollPanel = vgui.Create("DScrollPanel",metadmin.blank.Frame)
	DScrollPanel:SetSize(790,math.min(540,60+40*maxn))
	DScrollPanel:SetPos(1,25)
	local DPanel = vgui.Create("DPanel",DScrollPanel)
	DPanel:SetPos(5,5)
	DPanel:SetSize(790,20+40*maxn)
	local num = 0
	for k=1,maxn do
		local question = vgui.Create("DLabel",DPanel)
		question:SetTextColor(Color(0,0,0,255))
		question:SetSize(760,20)
		question:SetPos(5,5+num*40)
		local quest = tab.questions[k]
		question:SetText((isstring(quest) and quest or quest.question)..": ")
		metadmin.blank.answers[k] = vgui.Create("DTextEntry",DPanel)
		metadmin.blank.answers[k]:SetPos(5,25+num*40)
		metadmin.blank.answers[k]:SetSize(760,20)
		metadmin.blank.answers[k]:SetEditable(false)
		num = num+1
	end
end

net.Receive("metadmin.viewblank", function()
	local bool = net.ReadBool()
	if bool then
		if IsValid(metadmin.blank.Frame) then metadmin.blank.Frame:Close() end
		return
	end
	local tab = net.ReadTable()
	if not IsValid(metadmin.blank.Frame) then
		if not tab.questions then return end
		metadmin.target = net.ReadEntity()
		metadmin.viewblank(tab)
	end
	for k,v in pairs(tab.answers) do
		metadmin.blank.answers[k]:SetText(v)
	end
end)

function metadmin.questions2(id,edit,ply)
	local tab = metadmin.questions[id].questions
	if not tab then return end
	local maxn = #tab
	local questions2 = {}
	local Frame = vgui.Create("DFrame")
	Frame:SetSize(800,math.min(600,70+20*maxn))
	Frame:SetTitle(T(edit and "metadmin.Menu.edit_template" or "metadmin.Menu.view_template",metadmin.questions[id].name))
	Frame.btnMaxim:SetVisible(false)
	Frame.btnMinim:SetVisible(false)
	Frame:SetDraggable(true)
	Frame:Center()
	Frame:MakePopup()
	local DScrollPanel = vgui.Create("DScrollPanel",Frame)
	DScrollPanel:SetSize(790,math.min(540,45+20*maxn))
	DScrollPanel:SetPos(1,25)
	local DPanel = vgui.Create("DPanel",DScrollPanel)
	DPanel:SetPos(5,5)
	DPanel:SetSize(790,20+20*maxn)
	local num = 0
	for k, v in pairs(tab) do
		if edit then
			questions2[k] = vgui.Create("DTextEntry",DPanel)
			questions2[k]:SetSize(760,20)
			questions2[k]:SetPos(5,5+num*20)
			questions2[k]:SetText(isstring(v) and v or v.question)
		else
			local question = vgui.Create("DLabel",DPanel)
			question:SetTextColor(Color(0,0,0,255))
			question:SetSize(760,20)
			question:SetPos(5,5+num*20)
			question:SetText(k..". "..(isstring(v) and v or v.question))
			if istable(v) then
				for k2,v2 in pairs(v.answers) do
					local answer = vgui.Create("DLabel",DPanel)
					answer:SetTextColor(Color(0,0,0,255))
					answer:SetSize(760,20)
					answer:SetPos(15,25+num*20)
					answer:SetText(k2.."."..v2)
					num = num + 1
				end
			end
		end
		num = num+1
	end
	Frame:SetSize(800,math.min(600,70+20*num))
	DScrollPanel:SetSize(790,math.min(540,50+20*num))
	DPanel:SetSize(790,10+20*num)
	local send = vgui.Create("DButton",Frame)
	send:SetPos(5,math.min(575,45+20*num))
	send:SetText(edit and T("metadmin.Menu.Save") or ply and T("metadmin.Menu.send_to_player",ply.nick) or T("metadmin.Menu.return_to_menu"))
	send:SetSize(790,20)
	if edit then
		local DPanel2 = vgui.Create("DPanel",Frame)
		DPanel2:SetPos(718,2)
		DPanel2:SetSize(37,18)
		local add = vgui.Create("DImageButton",DPanel2)
		add:SetPos(1,1)
		add:SetSize(16,16)
		add:SetImage("icon16/add.png")
		add:SetTooltip(T("metadmin.Menu.Add"))
		add.DoClick = function()
			local k = #questions2 + 1
			Frame:SetSize( 800, math.min(600,80+20*k) )
			DScrollPanel:SetSize( 790, math.min(540,60+20*k) )
			DPanel:SetSize( 790, 20+20*k )
			send:SetPos( 5, math.min(575,55+20*k))
			questions2[k] = vgui.Create("DTextEntry",DPanel)
			questions2[k]:SetSize(760,20)
			questions2[k]:SetPos(5,5+(k-1)*20)
			questions2[k]:SetText(T("metadmin.Menu.new_line"))
		end

		local rem = vgui.Create("DImageButton",DPanel2)
		rem:SetPos(20,1)
		rem:SetSize(16,16)
		rem:SetImage("icon16/delete.png")
		rem:SetTooltip(T("metadmin.Menu.Delete"))
		rem.DoClick = function()
			local k = #questions2 -1
			if IsValid(questions2[k+1]) then
				Frame:SetSize(800,math.min(600,80+20*k))
				DScrollPanel:SetSize(790,math.min(540,60+20*k))
				DPanel:SetSize(790,20+20*k)
				send:SetPos(5,math.min(575,55+20*k))
				questions2[k+1]:Remove()
				questions2[k+1] = nil
			end
		end
	end
	send.DoClick = function()
		if edit then
			local tab2 = {}
			for k, v in pairs(questions2) do
				tab2[k] = v:GetValue()
			end
			net.Start("metadmin.qaction")
				net.WriteInt(3,5)
				net.WriteInt(id,32)
				net.WriteTable(tab2)
			net.SendToServer()
			quest_wait = true
		else
			if ply then
				net.Start("metadmin.action")
					net.WriteString(ply.sid)
					net.WriteInt(3,5)
					net.WriteString(id)
				net.SendToServer()
			else
				metadmin.questionslist()
			end
		end
		Frame:Close()
	end
end