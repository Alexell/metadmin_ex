metadmin.unique_id = metadmin.unique_id or "0"
metadmin.senduser = {"ranks","prom","dem","plombs","pogona"}
metadmin.sendadm = {"provider","server","groupwrite","disps","showserver","voice","synch"}

metadmin.mysql = {["host"]="127.0.0.1",["database"]="",["port"]=3306,["user"]="root",["pass"]=""}

metadmin.providers = {}
for k,v in pairs(file.Find("metadmin/providers/*","LUA")) do
	metadmin.providers[string.StripExtension(v)] = true
end

--Дефолтные настройки
metadmin.defprovider = "sql"
metadmin.defserver = "SERVER"
metadmin.defgroupwrite = false
metadmin.defdisps = {["traindispather"]=true}
metadmin.defshowserver = false
metadmin.defvoice = false
metadmin.defsynch = false
metadmin.defranks = {
	["driver"] = "Машинист (б/к)",
	["driver3class"] = "Машинист 3 класса",
	["driver2class"] = "Машинист 2 класса",
	["driver1class"] = "Машинист 1 класса",
	["user"] = "Помощник машиниста",
	["auditor"] = "Ревизор",
	["chiefinstructor"] = "Старший инструктор",
	["instructor"] = "Машинист инструктор",
	["actinstructor"] = "ИО Машиниста-инструктора",
	["superadmin"] = "Начальник метрополитена",
	["developer"] = "Разработчик"
}
metadmin.defprom = {
	["user"] = "driver",
	["driver"] = "driver3class",
	["driver3class"] = "driver2class",
	["driver2class"] = "driver1class"
}
metadmin.defdem = {
	["driver"] = "user",
	["driver3class"] = "driver",
	["driver2class"] = "driver3class",
	["driver1class"] = "driver2class"
}
metadmin.defplombs = {
	["ALS"] = "АЛС",
	["A5"] = "А5",
	["RCARS"] = "РЦ-АРС",
	["BARSBlock"] = "Блокировка БАРС",
	["UOS"] = "РЦ-УОС",
	["OtklAVU"] = "Откл. АВУ",
	["KAH"] = "КАХ",
	["BUD"] = "БУД",
	["RST"] = "РСТ",
	["VRU"] = "ВРУ",
	["K9"] = "РВТБ",
	["BPS"] = "РЦ-БПС",
	["VAH"] = "ВАХ",
	["EmergencyBrakeTPlusK"] = "Аварийный тормоз Т+",
	["UAVA"] = "УАВА",
	["BARSMode"] = "Режимы БАРС",
	["PantSC"] = "Токоприёмники и короткозамыкатель",
	["VAD"] = "ВАД",
	["EmergencyRadioPower"] = "Аварийное питание радиостанции",
	["RC1"] = "РЦ-1"
}
metadmin.defpogona = {}

function metadmin.GetSetting(name)
	local result = sql.Query("SELECT * FROM `ma_settings` WHERE name="..sql.SQLStr(name))
	if not result then return false end
	if not result[1] then return false end
	return result[1]
end

function metadmin.AddSetting(name,value,json)
	sql.Query("INSERT INTO `ma_settings` (`name`,`value`,`json`) VALUES ("..sql.SQLStr(name)..","..sql.SQLStr(value)..","..sql.SQLStr(json)..")")
end

function metadmin.EditSetting(name,value,json)
	sql.Query("UPDATE `ma_settings` SET `value` = "..sql.SQLStr(value)..", `json` = "..sql.SQLStr(json).." WHERE `name`="..sql.SQLStr(name))
end

function metadmin.RemoveSetting(name)
	sql.Query("DELETE FROM `ma_settings` WHERE `name`="..sql.SQLStr(name))
end

do
	if not file.Exists("metadmin","DATA") then
		file.CreateDir("metadmin")
	end

	--Версия
	if not file.Exists("metadmin/version.txt","DATA") then
		file.Write("metadmin/version.txt",metadmin.version)
	else
		local version = file.Read("metadmin/version.txt","DATA")
		if version ~= metadmin.version then
			metadmin.updated = true
			file.Write("metadmin/version.txt",metadmin.version)
		end
	end

	--Настройки
	sql.Query([[CREATE TABLE IF NOT EXISTS `ma_settings` (
	`name` text NOT NULL UNIQUE,
	`value` text NOT NULL,
	`json` int(1)
	)]])
	for k,v in pairs(metadmin.senduser) do
		local setting = metadmin.GetSetting(v)
		if setting then
			local value = setting.value
			if tonumber(setting.json) == 1 then value = util.JSONToTable(value) end
			metadmin[v] = value
		else
			local value = metadmin["def"..v]
			metadmin[v] = value
			local json = 0
			if istable(value) then value = util.TableToJSON(value) json = 1 end
			metadmin.AddSetting(v,value,json)
		end
	end
	for k,v in pairs(metadmin.sendadm) do
		local setting = metadmin.GetSetting(v)
		if setting then
			local value = setting.value
			if tonumber(setting.json) == 1 then value = util.JSONToTable(value) end
			if value == "false" or value == "true" then value = tobool(value) end
			metadmin[v] = value
		else
			local value = metadmin["def"..v]
			metadmin[v] = value
			local json = 0
			if istable(value) then value = util.TableToJSON(value) json = 1 end
			metadmin.AddSetting(v,value,json)
		end
	end
	for k,v in pairs(metadmin.pogona) do
		resource.AddFile(v)
	end

	if file.Exists("bin/gmsv_metadmin_win32.dll","LUA") and file.Exists("data.ma","DATA") then require("metadmin") end

	if not metadmin.providers[metadmin.provider] then
		metadmin.print("Wrong Provider \""..metadmin.provider.."\", switching to SQL...",true)
		metadmin.provider = "sql"
	end

	local setting_mysql = metadmin.GetSetting("mysql")
	if setting_mysql then
		metadmin.mysql = util.JSONToTable(setting_mysql.value)
		if metadmin.provider == "mysql" then
			if not file.Exists("bin/gmsv_mysqloo_win32.dll","LUA") then
				metadmin.print("MySQL module not found!",true)
				metadmin.provider = "sql"
			end
			for k,v in pairs(metadmin.mysql) do
				if v == "" then
					print(k.."=='"..v.."'")
					metadmin.provider = "sql"
					break
				end
			end
		end
	else
		if metadmin.provider == "mysql" then
			metadmin.print("MySQL settings not found, switching to SQL...",true)
			metadmin.provider = "sql"
		end
		metadmin.AddSetting("mysql",[[{"host":"127.0.0.1","database":"","pass":"","user":"root","port":3306}]],1)
	end
	local path = "metadmin/providers/"..metadmin.provider..".lua"
	if not file.Exists(path, "LUA") then
		error("Not found. "..path)
	end
	include(path)
end

function metadmin.print(str,err)
	MsgC((err and color_red or Color(255,0,255)),"[MetAdmin]"..(err and "[ERROR] " or " ")..str.."\n")
end

util.AddNetworkString("metadmin.rights")
util.AddNetworkString("metadmin.profile")
util.AddNetworkString("metadmin.violations")
util.AddNetworkString("metadmin.questions")
util.AddNetworkString("metadmin.answers")
util.AddNetworkString("metadmin.viewanswers")
util.AddNetworkString("metadmin.action")
util.AddNetworkString("metadmin.qaction")
util.AddNetworkString("metadmin.questionstab")
util.AddNetworkString("metadmin.notify")
util.AddNetworkString("metadmin.order")
util.AddNetworkString("metadmin.settings")
util.AddNetworkString("metadmin.settings.mysql")
util.AddNetworkString("metadmin.report")
util.AddNetworkString("metadmin.allplayers")
util.AddNetworkString("metadmin.synch")
util.AddNetworkString("metadmin.viewblank")
util.AddNetworkString("metadmin.profile2")
util.AddNetworkString("metadmin.checkpermissions")
util.AddNetworkString("metadmin.getuncheckedtests")


metadmin.questions = metadmin.questions or {}

local function HasPermission(ply,permission)
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

local function SendQuestions(ply)
	if HasPermission(ply,"ma.pl") then
		net.Start("metadmin.questionstab")
			net.WriteTable(metadmin.questions)
		net.Send(ply)
	end
end

local function UpdateQuestions()
	metadmin.GetQuestions(
		function(data)
			metadmin.questions = {}
			for k, v in pairs(data) do
				metadmin.questions[tonumber(v.id)] = {
					name = v.name,
					questions = util.JSONToTable(v.questions),
					timelimit = tonumber(v.timelimit),
					enabled = tonumber(v.enabled)
				}
			end
			for k, v in pairs(player.GetAll()) do
				SendQuestions(v)
			end
		end
	)
end

metadmin.Permissions = {
	["ma.pl"] = "Возможность открывать меню с игроками.\nAccess to open players list.",
	["ma.offmenu"] = "Возможность открывать меню с оффлайн игроками.\nAccess to open offline players list.",
	["ma.questionsmenu"] = "Возможность открывать меню вопросов.\nAccess to open questions list.",
	["ma.questionscreate"] = "Создание шаблона с вопросами.\nCreate question template.",
	["ma.questionsedit"] = "Редактирование шаблона с вопросами'.\nEdit question template.",
	["ma.questionsremove"] = "Удаление шаблона с вопросами.\nRemove question template.",
	["ma.questionsimn"] = "Добавление/удаление шаблона из меню.\nManage template in menu.",
	["ma.starttest"] = "Доступ к 'Начать тест'.\nAccess to \"Start test\".",
	["ma.viewresults"] = "Просмотр рельзутатов теста.\nView test results.",
	["ma.examinfo"] = "Просмотр информации о экзаменах.\nView exams info.",
	["ma.promote"] = "Повышение ранга игрока.\nPromote player.",
	["ma.demote"] = "Понижение ранга игрока.\nDemote player.",
	["ma.viewviolations"] = "Просмотр нарушений игрока.\nView player's violations.",
	["ma.violationgive"] = "Выдача нарушения игроку.\nIssue an violation to player.",
	["ma.violationremove"] = "Удаление нарушения игроку.\nRemove violation from player.",
	["ma.viewtalon"] = "Просмотр талона.\nView token.",
	["ma.taketalon"] = "Отбор талона.\nReturn token.",
	["ma.givetalon"] = "Возврат талона.\nTake token.",
	["ma.setstattest"] = "Установка статуса теста.\nChange test status.",
	["ma.forcesetstattest"] = "Установка статуса теста.(Без проверки)\nChange test status. (Without check)",
	["ma.order_plombs"] = "Доступ к приказам (пломбы).\nAccess to orders (plombs).",
	["ma.order_denial_signal"] = "Доступ к приказам (запрещающий сигнал).\nAccess to orders (denial signal).",
	["ma.settings"] = "Доступ к настройкам сервера.\nAccess to server settings.",
	["ma.synch"] = "Включение/выключение синхронизации игрока с сайтом.\nEnable/Disable player web-sync.",
	["ma.refsynch"] = "Обновить данные игрока с сайта.\nUpdate player data from web DB.",
	["ma.viewtrains"] = "Просмотр доступных для вождения составов.\nView trains available for drive.",
	["ma.hideviols"] = "Право на нарушения без уведомлений.\nPrivilege for 'silent' violations.",
	["ma.plombbroke"] = "Право на срыв пломб.\nPrivilege for plomb broke.",
	["ulx pr"] = "Профиль игрока.\nPlayer profile.",
	["ulx prid"] = "Профиль игрока.\nPlayer profile. (SID)",
	["ulx setrank"] = "Установка ранга.\nSet rank.",
	["ulx setrankid"] = "Установка ранга.\nSet rank. (SID)",
}

hook.Add("InitPostEntity","MetAdminInit",function()
	CreateConVar("metadmin_version","",{FCVAR_NOTIFY,FCVAR_REPLICATED,FCVAR_CHEAT,FCVAR_UNLOGGED}):SetString(metadmin.version)
	CreateConVar("metadmin_start",0,{FCVAR_NOTIFY,FCVAR_REPLICATED,FCVAR_CHEAT,FCVAR_UNLOGGED}):SetInt(os.time())
	for k, v in pairs(metadmin.prom) do
		local rank_name = metadmin.ranks[v]
		if not rank_name then continue end
		metadmin.Permissions["ma.prom"..v] = "Доступ к выдаче ранга \""..rank_name.."\".\nAccess to set rank \""..rank_name.."\"."
	end
	for k,v in pairs(metadmin.Permissions) do
		if ULib then
			ULib.ucl.registerAccess(k,"superadmin",v,metadmin.category) -- Регистрируя через CAMI нельзя добавить описания к праву, поэтому мы будем добавлять сами в ULib, если он присутствует.
		elseif CAMI then
			CAMI.RegisterPrivilege({Name=k,MinAccess="superadmin"})
		end
	end
	timer.Simple(2.5,UpdateQuestions)
	timer.Simple(2,function()
		local function ws() for k,v in pairs(engine.GetAddons())do if v.title=="metadmin"then return v.wsid end end return 0 end
		local tab = {ip=game.GetIPAddress(),hostname=GetConVar("hostname"):GetString(),version=metadmin.version,ws=tostring(ws()),port=GetConVar("hostport"):GetString()}
		http.Post("https://api.metrostroi.net/start",tab,
			function(body,len,headers,code)
				if code == 200 then
					body = util.JSONToTable(body)
					if metadmin.version ~= body.version then
						metadmin.notifver = body.version
						metadmin.print("Update available.")
					else
						metadmin.print("You use last version.")
					end
					metadmin.unique_id = body.unique_id
				else
					local str = "Request error 'start'. (Code = "..code..")"
					metadmin.print(str,true)
					metadmin.Log(str)
				end
			end
		)
	end)
end)

gameevent.Listen("player_changename")
hook.Add("player_changename","metadmin",function(data)
	timer.Simple(1,function()
		local ply = Player(data.userid)
		if not IsValid(ply) then return end
		metadmin.UpdateNick(ply)
		metadmin.players[ply:SteamID()].nick = data.newname
	end)
end)

function metadmin.IsValidSID(sid)
	if not sid then return false end
	return (string.match(sid,"(STEAM_[0-5]:[01]:%d+)") ~= nil)
end

function metadmin.Notify(target,...)
	if IsEntity(target) and not IsValid(target) then return end
	net.Start("metadmin.notify")
		net.WriteTable({...})
	if not target then
		net.Broadcast()
	else
		net.Send(target)
	end
end

function metadmin.Log(str)
	file.Append("metadmin/log.txt","["..os.date("%X - %d/%m/%Y",os.time()).."] "..str.."\r\n")
end

hook.Add("MetrostroiPassedRed", "MetAdmin", function(train,ply,mode,arsback)
	if not IsValid(train) or not IsValid(ply) then return end
	if ply.pasred then
		ply.pasred = nil
	else
		if (ULib.ucl.query(ply,"ma.hideviols")) then return true end
		local signame = arsback.Name
		if not signame then return end
		metadmin.Notify(false,Color(129,207,224),{"metadmin.denial_signal_violation",ply:Nick(),signame})
		metadmin.Log(ply:Nick().." passed denial signal "..signame.." without dispatcher approvement.")
		metadmin.AddViolation(ply:SteamID(),nil,"Проехал запрещающий сигнал "..signame.." без разрешения диспетчера.\nPassed denial signal "..signame.." without dispatcher approvement.")
		metadmin.GetViolations(ply:SteamID(), function(data)
			metadmin.players[ply:SteamID()].localviolations = data
		end)
	end
	return true
end)


hook.Add("MetrostroiPlombBroken", "MetAdmin", function(train,but,ply)
	if not IsValid(train) or not IsValid(ply) then return end
	if (ULib.ucl.query(ply,"ma.hideviols")) then return true end
	if (ULib.ucl.query(ply,"ma.plombbroke")) then
		if metadmin.plombs and metadmin.plombs[but] then
			local plomb = metadmin.plombs[but]
			if ply.plombs[but] then
				ply.plombs[but] = nil
				metadmin.Notify(false,Color(129,207,224),{"metadmin.seal_broken_byplayer",ply:Nick(),plomb})
				metadmin.Log(ply:Nick().." broken seal \""..plomb.."\".")
			else
				metadmin.Notify(false,Color(129,207,224),{"metadmin.seal_broken_byplayer_without",ply:Nick(),plomb})
				metadmin.Log(ply:Nick().." broken seal \""..plomb.."\" without dispatcher approvement.")
				metadmin.AddViolation(ply:SteamID(),nil,"Cорвал пломбу с \""..plomb.."\" без разрешения диспетчера.")
				metadmin.GetViolations(ply:SteamID(), function(data)
					metadmin.players[ply:SteamID()].localviolations = data
				end)
			end
			return true
		end
	else
		ply:ChatPrint("Вам запрещено срывать пломбы!")
		return true,true
	end
end)

function metadmin.SendRights(ply)
	if not IsValid(ply) then return end
	local sid = ply:SteamID()
	if metadmin.players[sid] and metadmin.players[sid].rights then
		net.Start("metadmin.rights")
			net.WriteTable(metadmin.players[sid].rights)
		net.Send(ply)
	end
end

function metadmin.SendSettings(ply)
	if not IsValid(ply) then return end
	local tab = {}
	for k,v in pairs(metadmin.senduser) do
		tab[v] = metadmin[v]
	end
	if HasPermission(ply,"ma.settings") then
		for k,v in pairs(metadmin.sendadm) do
			tab[v] = metadmin[v]
		end
		tab["providers"] = metadmin.providers
	end
	net.Start("metadmin.settings")
		net.WriteTable(tab)
	net.Send(ply)
end

hook.Add("PlayerInitialSpawn", "MetAdmin.Spawn", function(ply)
	metadmin.GetDataSID(ply:SteamID(),false,false,true)
	SendQuestions(ply)
	metadmin.SendSettings(ply)
	ply.plombs = {}
	if ply:IsAdmin() and metadmin.notifver then
		timer.Simple(2,function()
			if not IsValid(ply) then return end
			metadmin.Notify(ply,Color(129,207,224),{"metadmin.update_available"})
			metadmin.Notify(ply,Color(129,207,224),{"metadmin.current_ver"},Color(0,102,255),metadmin.version)
			metadmin.Notify(ply,Color(129,207,224),{"metadmin.actual_ver"},Color(0,102,255),metadmin.notifver)
		end)
	end
end)

function metadmin.GetNick(sid,def)
	local nick = (ULib.ucl.users[sid] and ULib.ucl.users[sid].name) or def
	local ply = player.GetBySteamID(sid)
	if ply then
		nick = ply:Nick()
	end
	return nick
end

local status = {[0]="metadmin.Menu.exam_review","metadmin.Menu.exam_pass","metadmin.Menu.exam_fail"}
net.Receive("metadmin.action", function(len,ply)
	if not HasPermission(ply,"ma.pl") then metadmin.Notify(ply,Color(129,207,224),{"metadmin.insufficient_permissions"}) return end
	local sid = net.ReadString()
	if not metadmin.IsValidSID(sid) then return end
	local action = net.ReadInt(5)
	local str = net.ReadString()
	if action == 0 and HasPermission(ply,"ulx setrankid") then
		metadmin.setrank(ply,sid,str,net.ReadString())
	elseif action == 1 and HasPermission(ply,"ma.promote") then
		metadmin.promotion(ply,sid,str)
	elseif action == 2 and HasPermission(ply,"ma.demote") then
		metadmin.demotion(ply,sid,str)
	elseif action == 3 and HasPermission(ply,"ma.starttest") then
		metadmin.sendquestions(ply,sid,tonumber(str))
	elseif action == 4 and HasPermission(ply,"ma.viewresults") then
		metadmin.view_answers(ply,sid,tonumber(str))
	elseif action == 5 and HasPermission(ply,"ma.setstattest") then
		local stat = net.ReadInt(3)
		local tab = metadmin.players[sid].exam_answers
		local answers_tab = {}
		for k,v in pairs(tab) do
			if v.id == tonumber(str) then
				answers_tab = v
			end
		end
		if (answers_tab.ssadmin ~= "" and answers_tab.ssadmin ~= ply:SteamID()) and not HasPermission(ply,"ma.forcesetstattest") then metadmin.Notify(ply,Color(129,207,224),{"metadmin.teststatuschangedeny"}) return end
		print(str,stat)
		metadmin.SetStatusTest(tonumber(str),stat,ply:SteamID())
		metadmin.GetTests(sid, function(data)
			metadmin.players[sid].exam_answers = data
		end)
		metadmin.Notify(ply,{"metadmin.status_changed"})
		local target = player.GetBySteamID(sid)
		if target then
			metadmin.Notify(target,Color(129,207,224),{"metadmin.set_status",ply:Nick(),{status[stat]},metadmin.questions[tonumber(answers_tab.questions)].name})
		end
	elseif action == 7 and HasPermission(ply,"ma.givetalon") then
		metadmin.settalon(ply,sid,1)
	elseif action == 8 and HasPermission(ply,"ma.taketalon") then
		metadmin.settalon(ply,sid,2,str)
	end
end)

net.Receive("metadmin.settings", function(len, ply)
	if not HasPermission(ply,"ma.settings") then metadmin.Notify(ply,Color(129,207,224),{"metadmin.insufficient_permissions"}) return end
	for k,v in pairs(net.ReadTable()) do
		if k == "provider" and metadmin.providers[v] and v == "mysql" then
			if not file.Exists("bin/gmsv_mysqloo_win32.dll","LUA") then metadmin.Notify(ply,Color(129,207,224),{"metadmin.mysql_404"}) return end
			for _,v in pairs(metadmin.mysql) do
				if v == "" then metadmin.Notify(ply,Color(129,207,224),{"metadmin.check_mysql"}) return end
			end
		end
		if metadmin[k] ~= v then
			metadmin[k] = v
			local json = 0
			if istable(v) then v = util.TableToJSON(v) json = 1 end
			metadmin.EditSetting(k,v,json)
		end
	end
	for k,v in pairs(player.GetAll()) do
		metadmin.SendSettings(v)
	end
end)

net.Receive("metadmin.settings.mysql", function(len, ply)
	if not HasPermission(ply,"ma.settings") then metadmin.Notify(ply,Color(129,207,224),{"metadmin.insufficient_permissions"}) return end
	if net.ReadBool() == true then
		net.Start("metadmin.settings.mysql")
			net.WriteString(metadmin.mysql.host)
			net.WriteString(metadmin.mysql.database)
			net.WriteString(metadmin.mysql.user)
			net.WriteInt(metadmin.mysql.port,17)
		net.Send(ply)
	else
		local tab = net.ReadTable()
		for k,v in pairs(metadmin.mysql) do
			if not tab[k] then continue end
			metadmin.mysql[k] = tab[k]
		end
		metadmin.EditSetting("mysql",util.TableToJSON(metadmin.mysql),1)
	end
end)

net.Receive("metadmin.order", function(len, ply)
	local tar = net.ReadEntity()
	local plomb_detach = net.ReadBool()
	if plomb_detach then
		if not HasPermission(ply,"ma.order_plombs") then metadmin.Notify(ply,Color(129,207,224),{"metadmin.insufficient_permissions"}) return end
		local plomb = net.ReadString()
		if not metadmin.plombs[plomb] then return end
		tar.plombs[plomb] = true
		metadmin.Notify(false,Color(129,207,224),{"metadmin.plomb_detach_allowed",ply:Nick(),tar:Nick(),metadmin.plombs[plomb]})
		metadmin.Log(ply:Nick().." allowed "..tar:Nick().." break seal at "..metadmin.plombs[plomb])
	else
		if not HasPermission(ply,"ma.order_denial_signal") then metadmin.Notify(ply,Color(129,207,224),{"metadmin.insufficient_permissions"}) return end
		tar.pasred = true
		metadmin.Notify(false,Color(129,207,224),{"metadmin.deny_signal_pass_allowed",ply:Nick(),tar:Nick()})
		metadmin.Log(ply:Nick().." given order for "..tar:Nick().." to pass denial signal.")
	end
end)

net.Receive("metadmin.allplayers", function(len, ply)
	if not HasPermission(ply,"ma.offmenu") then metadmin.Notify(ply,Color(129,207,224),{"metadmin.insufficient_permissions"}) return end
	local group = net.ReadString()
	if group == "user" then return end
	if not metadmin.ranks[group] then return end
	metadmin.AllPlayers(group,function(data)
		if not IsValid(ply) then return end
		local tab = {}
		for k,v in pairs(data) do
			tab[k] = {}
			tab[k].nick = v.nick
			tab[k].SID = v.SID
		end
		net.Start("metadmin.allplayers")
			net.WriteTable(tab)
		net.Send(ply)
	end)
end)

net.Receive("metadmin.synch", function(len, ply)
	local ref = net.ReadBool()
	local sid = net.ReadString()
	if not metadmin.IsValidSID(sid) or not metadmin.players[sid] then return end
	if not ref then
		metadmin.OnOffSynch(sid,metadmin.players[sid].synch and 0 or 1)
		metadmin.GetDataSID(sid,function()
			metadmin.profile(ply,sid)
		end)
	elseif ref and HasPermission(ply,"ma.refsynch") then
		metadmin.GetDataSID(sid,function()
			metadmin.Notify(ply,Color(129,207,224),{"metadmin.data_updated"})
			metadmin.profile(ply,sid)
		end)
	end
end)


net.Receive("metadmin.getuncheckedtests", function(len,ply)
	if not HasPermission(ply,"ma.viewresults") then metadmin.Notify(ply,Color(129,207,224),{"metadmin.insufficient_permissions"}) return end
	metadmin.GetUncheckedTests(function(data)
		if not IsValid(ply) then return end
		net.Start("metadmin.getuncheckedtests")
			net.WriteTable(data)
		net.Send(ply)
	end)
end)

local talons = {[1]="зеленый",[2]="желтый",[0]="красный"}
local talonsen = {[1]="green",[2]="yellow",[0]="red"}
function metadmin.settalon(ply,sid,type,reason)
	if metadmin.players[sid] then
		if metadmin.players[sid].synch then metadmin.Notify(ply,Color(129,207,224),{"metadmin.player_sync_enabled"}) return end
		if type == 2 then
			local status = {}
			status.date = os.time()
			status.admin = ply:SteamID()
			if metadmin.players[sid].status.nom + 1 <= 3 then
				status.nom = metadmin.players[sid].status.nom + 1
			elseif metadmin.players[sid].status.nom + 1 > 3 then
				status.nom = 1
				if metadmin.players[sid].rank ~= "user" then
					local reason = (ply:Nick().." ("..ply:SteamID()..") отобрал красный талон.\nУВОЛЕН!\n"..ply:Nick().." ("..ply:SteamID()..") taken red token.\nFIRED!")
					local target = player.GetBySteamID(sid)
					if target then
						metadmin.SetUserGroup(target,"user",ply)
					end
					metadmin.AddExamInfo(sid,"user",ply:SteamID(),reason,2)
					metadmin.players[sid].rank = "user"
					metadmin.GetExamInfo(sid, function(data)
						metadmin.players[sid].exam = data
					end)
				end
			end
			metadmin.players[sid].status = status
			metadmin.SaveData(sid)
			metadmin.Notify(ply,Color(129,207,224),{"metadmin.token_taken_succ"})
			metadmin.Log(ply:Nick().." taken token from player "..sid)
			if reason then
				metadmin.violationgive(ply,sid,"Забрал "..talons[status.nom-1].." талон.\nTaken token "..talonsen[status.nom-1]..".\n"..reason)
			end
		else
			if metadmin.players[sid].status.nom - 1 > 0 then
				metadmin.players[sid].status.nom = metadmin.players[sid].status.nom - 1
				metadmin.players[sid].status.date = os.time()
				metadmin.players[sid].status.admin = ply:SteamID()
				metadmin.Notify(ply,Color(129,207,224),{"metadmin.token_returned_succ"})
				metadmin.Log(ply:Nick().." returned token to player "..sid)
				metadmin.SaveData(sid)
				metadmin.profile(ply,sid)
			end
		end
	else
		metadmin.GetDataSID(sid,function() metadmin.settalon(ply,sid,type,reason) end)
	end
end

net.Receive("metadmin.violations",function(len,ply)
	if not HasPermission(ply,"ma.viewviolations") then metadmin.Notify(ply,Color(129,207,224),{"metadmin.insufficient_permissions"}) return end
	local action = net.ReadBool()
	local sid = net.ReadString()
	local str = net.ReadString()
	if action and HasPermission(ply,"ma.violationgive") then
		metadmin.violationgive(ply,sid,str,net.ReadBool())
	elseif not action and HasPermission(ply,"ma.violationremove") then
		metadmin.violationremove(ply,sid,str)
	end
end)

function metadmin.violationgive(call,sid,str,global)
	if not global and not metadmin.players[sid].synch then
		metadmin.AddViolation(sid,call:SteamID(),str)
		metadmin.Notify(call,{"metadmin.violation_added"})
		metadmin.GetViolations(sid, function(data)
			metadmin.players[sid].localviolations = data
			if not IsValid(call) then return end
			metadmin.profile(call,sid)
		end)
	end
end

function metadmin.violationremove(call,sid,id)
	metadmin.Notify(call,Color(129,207,224),{"metadmin.violation_removed"})
	metadmin.RemoveViolation(tonumber(id))
	metadmin.GetViolations(sid, function(data)
		metadmin.players[sid].localviolations = data
		if not IsValid(call) then return end
		metadmin.profile(call,sid)
	end)
end


local ProfileData = {
	["violations"] = {
		"ma.viewviolations",
		20,
		function(sid)
			local tab = table.Copy(metadmin.players[sid].localviolations)
			table.Add(tab, metadmin.players[sid].violations)
			for k,v in pairs(tab) do
				v.SID = nil
			end
			return tab
		end
	},
	["exam"] = {
		"ma.examinfo",
		20,
		function(sid)
			local tab = {}
			for k,v in pairs(metadmin.players[sid].exam) do
				tab[k] = {
					date = v.date,
					nick = v.nick,
					examiner = v.examiner,
					note = v.note,
					rank = v.rank,
					type = v.type,
					server = v.server,
				}
			end
			return tab
		end
	},
	["exam_answers"] = {
		"ma.viewresults",
		30,
		function(sid)
			local tab = {}
			for k,v in pairs(metadmin.players[sid].exam_answers) do
				tab[k] = {
					id = v.id,
					questions = v.questions,
					date = v.date,
					status = v.status,
					admin = metadmin.GetNick(v.admin,v.admin),
					ssadmin = metadmin.GetNick(v.ssadmin,v.ssadmin)
				}
			end
			if metadmin.players[sid].tests_site then
				table.Add(tab,metadmin.players[sid].tests_site)
			end
			return tab
		end
	},
}

net.Receive("metadmin.profile2", function(len, ply)
	if ply.profile2time and ply.profile2time > os.time() then return end
	local sid = net.ReadString()
	local what = net.ReadString()
	local nom = net.ReadInt(32)
	if not metadmin.IsValidSID(sid) or not metadmin.players[sid] or metadmin.players[sid].nodata ~= nil or not what or not nom or nom <= 0 then return end
	ply.profile2time = os.time() + 0.5
	local tab = {}
	if ProfileData[what] then
		local info = ProfileData[what]
		if (sid == ply:SteamID() or HasPermission(ply,info[1])) then
			local s = 0
			local e = nom + info[2]
			for k,v in pairs(info[3](sid)) do
				if s >= nom then
					if s >= e then break end
					tab[k] = v
				end
				s = s + 1
			end
		end
	end
	net.Start("metadmin.profile2")
		net.WriteString(sid)
		net.WriteString(what)
		net.WriteTable(tab)
	net.Send(ply)
end)

function metadmin.profile(call,sid)
	if not call or not IsValid(call) then return end
	if type(sid) ~= "string" then sid = sid:SteamID() end
	if sid == "" then sid = call:SteamID() end
	if not metadmin.IsValidSID(sid) then
		for k, v in pairs(player.GetAll()) do
			if string.find(string.lower(v:Nick()),string.lower(sid)) then
				sid = v:SteamID()
			end
		end
	end
	if not metadmin.IsValidSID(sid) then return end
	if metadmin.players[sid] then
		if metadmin.players[sid].nodata ~= nil then metadmin.Notify(call,Color(129,207,224),{"metadmin.player_sync_error"}) end
		local tab = {}
		local sameply = (sid == call:SteamID())

		local tab2 = table.Copy(metadmin.players[sid].localviolations)
		table.Add(tab2, metadmin.players[sid].violations)
		tab.nvio = #tab2
		tab2 = nil

		tab.icons = metadmin.players[sid].icons

		tab.nodata = (metadmin.players[sid].nodata ~= nil)

		if metadmin.players[sid].nodata == nil then
			for k,v in pairs(ProfileData) do
				if (sameply or HasPermission(call,v[1])) then
					tab[k] = {}
					local n = 0
					for k2,v2 in pairs(v[3](sid)) do
						if n >= v[2] then break end
						tab[k][k2] = v2
						n = n + 1
					end
				end
			end
			if sameply or HasPermission(call,"ma.viewtalon") then
				tab.status = table.Copy(metadmin.players[sid].status)
				tab.status.admin = metadmin.GetNick(tab.status.admin,tab.status.admin)
			end
		end

		if sameply or HasPermission(call,"ma.viewtrains") then
			tab.trains = metadmin.players[sid].trains
		end
		net.Start("metadmin.profile")
			net.WriteTable(tab)
			net.WriteString(sid)
			net.WriteString(metadmin.players[sid].nick)
			net.WriteString(metadmin.players[sid].rank)
			net.WriteBool(metadmin.players[sid].synch)
		net.Send(call)
	else
		metadmin.GetDataSID(sid,function() metadmin.profile(call,sid) end,true)
	end
end

function metadmin.SetUserGroup(ply,group)
	if CAMI and ply:GetUserGroup() ~= group then
		CAMI.SignalUserGroupChanged(ply,ply:GetUserGroup(),group,"metadmin")
	end
	ply:SetUserGroup(group)
	metadmin.SendSettings(ply)
end

--[[
hook.Add("CAMI.PlayerUsergroupChanged","MetAdmin",function(ply,oldGroup,newGroup,source)
	if source == "metadmin" or oldGroup == newGroup then return end
	metadmin.setrank(nil,ply,newGroup,"Синхронизация через CAMI.")
end)]]

function metadmin.setrank(call,sid,rank,reason)
	if type(sid) ~= "string" then sid = sid:SteamID() end
	if not metadmin.IsValidSID(sid) then
		for k, v in pairs(player.GetAll()) do
			if string.find(string.lower(v:Nick()),string.lower(sid)) then
				sid = v:SteamID()
			end
		end
	end
	if not metadmin.IsValidSID(sid) then return end
	if metadmin.players[sid] then
		if metadmin.ranks[rank] and CheckUserGroup(rank) then
			if not IsValid(call) and metadmin.players[sid].synch then
				metadmin.OnOffSynch(sid,0)
				metadmin.GetDataSID(sid,function()
					metadmin.setrank(call,sid,rank,reason)
				end)
				return
			end
			if metadmin.players[sid].synch then metadmin.Notify(call,Color(129,207,224),{"metadmin.player_sync_enabled"}) return end
			if metadmin.players[sid].rank == rank then metadmin.Notify(call,Color(129,207,224),{"metadmin.rank_equal"}) return end
			if not reason or reason == "" then reason = "Установка ранга через команду.\nSet rank via cmd" end
			local nick = IsValid(call) and call:Nick() or "CONSOLE"
			local steamid = IsValid(call) and call:SteamID() or "CONSOLE"
			metadmin.players[sid].rank = rank
			metadmin.SaveData(sid)
			local target = player.GetBySteamID(sid)
			if target then
				metadmin.SetUserGroup(target,rank,call)
				SendQuestions(target)
			end
			metadmin.Notify(false,Color(129,207,224),{"metadmin.player_rank_set",nick,metadmin.players[sid].nick,metadmin.ranks[rank]})
			metadmin.Log(nick.." set rank for player "..metadmin.players[sid].nick.."|"..metadmin.ranks[rank])
			metadmin.AddExamInfo(sid,rank,steamid,reason,3)
			metadmin.GetExamInfo(sid, function(data)
				metadmin.players[sid].exam = data
			end)
		else
			metadmin.Notify(call,Color(129,207,224),{"metadmin.rank_404",rank})
		end
	else
		metadmin.GetDataSID(sid,function() metadmin.setrank(call,sid,rank,reason) end,true)
	end
end

function metadmin.promotion(call,sid,note)
	if not HasPermission(call,"ma.promote") then metadmin.Notify(ply,Color(129,207,224),{"metadmin.insufficient_permissions"}) return end
	if metadmin.players[sid] then
		if metadmin.players[sid].synch then metadmin.Notify(call,Color(129,207,224),{"metadmin.player_sync_enabled"}) return end
		local group = metadmin.players[sid].rank
		local newgroup = metadmin.prom[group]
		if not newgroup or not CheckUserGroup(newgroup) then return end
		if not HasPermission(call,"ma.prom"..newgroup) then return end
		local target = player.GetBySteamID(sid)
		if target then
			metadmin.SetUserGroup(target,newgroup,call)
		end
		local nick = metadmin.players[sid].nick
		metadmin.Notify(false,Color(129,207,224),{"metadmin.player_promoted",call:Nick(),nick,metadmin.ranks[newgroup]})
		metadmin.Log(call:Nick().." promoted player "..nick.." to "..metadmin.ranks[newgroup])
		metadmin.AddExamInfo(sid,newgroup,call:SteamID(),note,1)
		metadmin.players[sid].rank = newgroup
		metadmin.SaveData(sid)
		metadmin.GetExamInfo(sid, function(data)
			metadmin.players[sid].exam = data
			metadmin.profile(call,sid)
		end)
	else
		metadmin.GetDataSID(sid,function() metadmin.promotion(call,sid,note) end)
	end
end
function metadmin.demotion(call,sid,note)
	if not HasPermission(call,"ma.demote") then metadmin.Notify(ply,Color(129,207,224),{"metadmin.insufficient_permissions"}) return end
	if metadmin.players[sid] then
		if metadmin.players[sid].synch then metadmin.Notify(call,Color(129,207,224),{"metadmin.player_sync_enabled"}) return end
		local group = metadmin.players[sid].rank
		local newgroup = metadmin.dem[group]
		if not newgroup or not CheckUserGroup(newgroup) then return end
		local target = player.GetBySteamID(sid)
		if target then
			metadmin.SetUserGroup(target,newgroup,call)
		end
		local nick = metadmin.players[sid].nick
		metadmin.Notify(false,Color(129,207,224),{"metadmin.player_demoted",call:Nick(),nick,metadmin.ranks[newgroup]})
		metadmin.Log(call:Nick().." demoted player "..nick.." to "..metadmin.ranks[newgroup])
		metadmin.AddExamInfo(sid,newgroup,call:SteamID(),note,2)
		metadmin.players[sid].rank = newgroup
		metadmin.SaveData(sid)
		metadmin.GetExamInfo(sid, function(data)
			metadmin.players[sid].exam = data
			metadmin.profile(call,sid)
		end)
	else
		metadmin.GetDataSID(sid,function() metadmin.demotion(call,sid,note) end)
	end
end

net.Receive("metadmin.qaction",function(len,ply)
	if not HasPermission(ply,"ma.questionsmenu") then metadmin.Notify(ply,Color(129,207,224),{"metadmin.insufficient_permissions"}) return end
	local action = net.ReadInt(5)
	local id = net.ReadInt(32)
	if action == 1 and metadmin.questions[id] and HasPermission(ply,"ma.questionsimn") then
		if metadmin.questions[id].enabled == 1 then
			metadmin.Notify(ply,Color(129,207,224),{"metadmin.template_switch_disabled",metadmin.questions[id].name})
		else
			metadmin.Notify(ply,Color(129,207,224),{"metadmin.template_switch_enabled",metadmin.questions[id].name})
		end
		metadmin.SetEnabledQuestion(id,metadmin.questions[id].enabled == 1 and 0 or 1)
	elseif action == 2 and metadmin.questions[id] and HasPermission(ply,"ma.questionsremove") then
		metadmin.Notify(ply,Color(129,207,224),{"metadmin.template_removed",metadmin.questions[id].name})
		metadmin.RemoveQuestion(id)
	elseif action == 3 and metadmin.questions[id] and HasPermission(ply,"ma.questionsedit") then
		local tab = net.ReadTable()
		metadmin.SaveQuestion(id,util.TableToJSON(tab))
		metadmin.Notify(ply,Color(129,207,224),{"metadmin.template_redacted",metadmin.questions[id].name})
	elseif action == 4 and HasPermission(ply,"ma.questionscreate") then
		local name = net.ReadString()
		metadmin.AddQuestion(name)
		metadmin.Notify(ply,Color(129,207,224),{"metadmin.template_added",name})
	elseif action == 5 and metadmin.questions[id] and HasPermission(ply,"ma.questionsedit") then
		metadmin.SaveQuestionName(id,net.ReadString())
		metadmin.Notify(ply,Color(129,207,224),{"metadmin.template_redacted",metadmin.questions[id].name})
	elseif action == 6 and metadmin.questions[id] and HasPermission(ply,"ma.questionsedit") then
		local rectime = net.ReadInt(32)
		if rectime == metadmin.questions[id].timelimit then return end
		metadmin.SaveQuestionRecTime(id,rectime)
		metadmin.Notify(ply,Color(129,207,224),{"metadmin.template_redacted",metadmin.questions[id].name})
	else return end
	UpdateQuestions()
end)

function metadmin.sendquestions(call,sid,id)
	local target = player.GetBySteamID(sid)
	if target then
		--if target == call then metadmin.Notify(call,Color(129,207,224),{"metadmin.tests_selftest"}) return end
		if target.anstoques then metadmin.Notify(call,Color(129,207,224),{"metadmin.tests_still_in_progress",target.anstoques.nick}) return end
		if not metadmin.questions[id] then return metadmin.Notify(call,Color(129,207,224),{"metadmin.template_404"}) end
		if metadmin.questions[id].enabled == 0 then return metadmin.Notify(call,Color(129,207,224),{"metadmin.template_disabled"}) end
		net.Start("metadmin.questions")
			net.WriteTable(metadmin.questions[id].questions)
			net.WriteInt(metadmin.questions[id].timelimit or 0,32)
		net.Send(target)
		target.anstoques = {
			nick = call:Nick(),
			adminsid = call:SteamID(),
			idquestions = id,
			time = os.time(),
			answers = {}
		}
		target:SetNWBool("anstoques",true)
		metadmin.Notify(false,Color(129,207,224),{"metadmin.tests_sent",call:Nick(),metadmin.questions[id].name,target:Nick()})
		metadmin.Log(call:Nick().. " sent test ("..metadmin.questions[id].name..") to player "..target:Nick())
	end
end
function metadmin.view_answers(call,sid,id)
	if metadmin.players[sid] then
		local tab = {}
		for k,v in pairs(metadmin.players[sid].exam_answers) do
			if v.id == id then
				tab.answerstab = v
				tab.answers = util.JSONToTable(v.answers)
			end
		end
		tab.nick = metadmin.players[sid].nick
		tab.sid = sid
		tab.questions = metadmin.questions[tab.answerstab.questions].questions
		tab.timelimit = metadmin.questions[tab.answerstab.questions].timelimit
		net.Start("metadmin.viewanswers")
			net.WriteTable(tab)
		net.Send(call)
	else
		metadmin.GetDataSID(sid,function() metadmin.view_answers(call,sid,id) end)
	end
end

net.Receive("metadmin.viewblank", function(len, ply)
	if not HasPermission(ply,"ma.viewresults") then metadmin.Notify(ply,Color(129,207,224),{"metadmin.insufficient_permissions"}) return end
	local open = net.ReadBool()
	local target = net.ReadEntity()
	if open then
		if ply.viewblank then return end
		if not target.anstoques then return end
		ply.viewblank = target
		local tab = {}
		tab.questions = metadmin.questions[target.anstoques.idquestions].questions
		tab.nick = target:Nick()
		tab.sid = target:SteamID()
		tab.starttime = target.anstoques.time
		tab.timelimit = metadmin.questions[target.anstoques.idquestions].timelimit
		tab.answers = target.anstoques.answers
		net.Start("metadmin.viewblank")
			net.WriteBool(false)
			net.WriteTable(tab)
			net.WriteEntity(target)
		net.Send(ply)
	else
		ply.viewblank = nil
	end
end)

hook.Add("PlayerDisconnected","MetAdmin",function(ply)
	for k,v in pairs(player.GetAll()) do
		if v.viewblank == ply then
			v.viewblank = nil
		end
	end
end)

net.Receive("metadmin.answers", function(len, ply)
	if not ply.anstoques then return end
	local bool = net.ReadBool()
	local ans = net.ReadTable()
	if bool then
		ply.anstoques.answers[ans[1]] = ans[2]
		for k,v in pairs(player.GetAll()) do
			if v.viewblank == ply then
				net.Start("metadmin.viewblank")
					net.WriteBool(false)
					net.WriteTable({answers = ply.anstoques.answers})
				net.Send(v)
			end
		end
	else
		if metadmin.questions[ply.anstoques.idquestions].enabled == 0 then return end
		local time = (os.time()-ply.anstoques.time)
		metadmin.Notify(false,Color(129,207,224),{"metadmin.tests_completed",ply:Nick(),string.ToMinutesSeconds(time)})
		metadmin.Log(ply:Nick().." completed test in "..string.ToMinutesSeconds(time).." minutes.")
		metadmin.AddTest(ply:SteamID(),ply.anstoques.idquestions,util.TableToJSON(ans),time,ply.anstoques.adminsid)
		metadmin.GetTests(ply:SteamID(), function(data)
			metadmin.players[ply:SteamID()].exam_answers = data
		end)
		for k,v in pairs(player.GetAll()) do
			if v.viewblank == ply then
				net.Start("metadmin.viewblank")
					net.WriteBool(true)
				net.Send(v)
				v.viewblank = nil
			end
		end
		ply.anstoques = false
		ply:SetNWBool("anstoques",false)
	end
end)

function metadmin.GetDataSID(sid,cb,nocreate,online)
	if not metadmin.IsValidSID(sid) then return end
	metadmin.GetData(sid, function(data)
		if data and data[1] then
			if tonumber(data[1].synch) == 1 then
				metadmin.players[sid] = {exam = {},exam_answers = {},violations = {},localviolations = {},status = {date=0,admin="",nom=1},rank = data[1].synchgroup,nick = "",synch = true,rights = {},icons = {},nodata = false}
				local tab = {SID=sid,online=(online and "1" or "0"),unique_id=metadmin.unique_id}
				local ply = player.GetBySteamID(sid)
				if GetGlobalBool("metadmin.partner") and ply then tab.IP = ply:IPAddress() end
				http.Post("https://api.metrostroi.net/user",tab,function(body,len,headers,code)
					if code ~= 200 then
						metadmin.Log(sid.." web-sync failed! | Code = "..code)
						if metadmin.GetDataSID2 and GetGlobalBool("metadmin.partner") then metadmin.GetDataSID2(data,sid,cb,nocreate,online) return end
						metadmin.players[sid].nodata = true
					end
					if body == "" then
						metadmin.Log(sid.." web-sync failed! | Player doesn't exists on web database!")
						metadmin.OnOffSynch(sid,0)
						metadmin.GetDataSID(sid,cb)
						return
					end
					if not metadmin.players[sid].nodata then metadmin.players[sid] = util.JSONToTable(body) end
					if not metadmin.ranks[metadmin.players[sid].rank] or not CheckUserGroup(metadmin.players[sid].rank) then
						metadmin.Log(sid.." web-sync failed! | Rank "..metadmin.players[sid].rank.." doesn't exists!")
						metadmin.OnOffSynch(sid,0)
						metadmin.GetDataSID(sid,cb)
						return
					end
					if metadmin.players[sid].nick == "" then
						metadmin.players[sid].nick = data[1].nick
					end
					if not metadmin.players[sid].nodata and data[1].synchgroup ~= metadmin.players[sid].rank then
						metadmin.SetSynchGroup(sid,metadmin.players[sid].rank)
					end
					metadmin.players[sid].synch = true
					metadmin.GetViolations(sid, function(data)
						metadmin.players[sid].localviolations = data
					end)
					metadmin.GetTests(sid, function(data)
						metadmin.players[sid].exam_answers = data
					end)
					local target = player.GetBySteamID(sid)
					if target then
						metadmin.SendRights(target)
						if target:Nick() ~= metadmin.players[sid].nick then
							metadmin.UpdateNick(target)
							metadmin.players[sid].nick = target:Nick()
						end
						if target:GetUserGroup() ~= metadmin.players[sid].rank then
							metadmin.SetUserGroup(target,metadmin.players[sid].rank)
							SendQuestions(target)
						end
					end
					if cb then
						timer.Simple(0.25,cb)
					end
				end,
				function(err)
					metadmin.Log(sid.." web-sync failed! | err="..err)
					if metadmin.GetDataSID2 and GetGlobalBool("metadmin.partner") then metadmin.GetDataSID2(data,sid,cb,nocreate,online) return end
					if metadmin.players[sid].synch then metadmin.players[sid].nodata = true end
				end)
			else
				metadmin.players[sid] = {
					violations = {},
					icons = {},
					rights = {}
				}

				if metadmin.ranks[data[1].group] and CheckUserGroup(data[1].group) then
					metadmin.players[sid].rank = data[1].group
				else
					metadmin.players[sid].rank = "user"
					metadmin.Log("Unable to set player ("..sid..") rank | Rank "..data[1].group.." doesn't exists!")
				end
				metadmin.players[sid].nick = data[1].nick
				metadmin.players[sid].status = util.JSONToTable(data[1].status)
				metadmin.GetViolations(sid, function(data)
					metadmin.players[sid].localviolations = data
				end)
				metadmin.GetExamInfo(sid, function(data)
					metadmin.players[sid].exam = data
				end)
				metadmin.GetTests(sid, function(data)
					metadmin.players[sid].exam_answers = data
				end)
				local target = player.GetBySteamID(sid)
				if target then
					if target:Nick() ~= metadmin.players[sid].nick then
						metadmin.UpdateNick(target)
						metadmin.players[sid].nick = target:Nick()
					end
					if target:GetUserGroup() ~= metadmin.players[sid].rank then
						metadmin.SetUserGroup(target,metadmin.players[sid].rank)
					end
				end
				local tab = {SID=sid,online=(online and "1" or "0"),unique_id=metadmin.unique_id}
				local ply = player.GetBySteamID(sid)
				if GetGlobalBool("metadmin.partner") and ply then tab.IP = ply:IPAddress() end
				http.Post("https://api.metrostroi.net/user",tab,function(body,len,headers,code)
					if code ~= 200 then return end
					if body == "" then return end
					local tab = util.JSONToTable(body)
					metadmin.players[sid].icons = tab.icons
					metadmin.players[sid].rights = tab.rights
					if target then
						metadmin.SendRights(target)
					end
				end)
				if cb then
					timer.Simple(0.25,cb)
				end
			end
		elseif not nocreate then
			metadmin.CreateData(sid)
		end
	end)
end

hook.Add("PlayerCanHearPlayersVoice", "metadmin", function(listener,talker)
	if metadmin.voice and metadmin.disps then
		if listener:IsAdmin() then return true end
		if metadmin.players[talker:SteamID()] and metadmin.disps[metadmin.players[talker:SteamID()].rank] then
			return true
		end
		if metadmin.players[listener:SteamID()] and metadmin.disps[metadmin.players[listener:SteamID()].rank] then
			return true
		end
		return false
	end
end)


concommand.Add("metadmin.profile", function(ply,_,args)
	if not IsValid(ply) then return end
	if not HasPermission(ply,"ulx prid") then metadmin.Notify(ply,Color(129,207,224),{"metadmin.insufficient_permissions"}) return end
	local SID = table.concat(args)
	metadmin.profile(ply,SID)
end)

concommand.Add("metadmin.checkpermissions", function(ply)
	if not IsValid(ply) then return end
	local tab = {}
	for k,v in pairs(metadmin.Permissions) do
		table.insert(tab,{k,v,HasPermission(ply,k)})
	end
	net.Start("metadmin.checkpermissions")
		net.WriteTable(tab)
	net.Send(ply)
end)

concommand.Add("metadmin.partner_mode", function(ply)
	if IsValid(ply) then return end
	if not file.Exists("bin/gmsv_metadmin_win32.dll","LUA") or not file.Exists("data.ma","DATA") then return end
	if not metadmin.dll then require("metadmin") end
end)