metadmin.players = metadmin.players or {}

do
	sql.Query([[CREATE TABLE IF NOT EXISTS `ma_answers` (
	`id` INTEGER PRIMARY KEY AUTOINCREMENT,
	`SID` TEXT NOT NULL,
	`date` INT(11) NOT NULL,
	`questions` INT(11) NOT NULL,
	`status` INT(11) NOT NULL DEFAULT (0),
	`answers` TEXT NOT NULL,
	`time` INT(11) NOT NULL,
	`admin` TEXT NOT NULL,
	`ssadmin` TEXT NOT NULL DEFAULT ''
	)]])
	sql.Query([[CREATE TABLE IF NOT EXISTS `ma_examinfo` (
	`id` INTEGER PRIMARY KEY AUTOINCREMENT,
	`SID` TEXT NOT NULL,
	`date` INT(11) NOT NULL,
	`rank` TEXT NOT NULL,
	`examiner` TEXT NOT NULL,
	`note` TEXT NOT NULL,
	`type` INT(11) NOT NULL,
	`server` TEXT NOT NULL
	)]])
	sql.Query([[CREATE TABLE IF NOT EXISTS `ma_players` (
	`SID` SID TEXT NOT NULL UNIQUE,
	`group` TEXT NOT NULL,
	`status` TEXT NOT NULL,
	`nick` TEXT NOT NULL DEFAULT '',
	`synch` INT(1) NOT NULL DEFAULT (0),
	`synchgroup` TEXT NOT NULL DEFAULT ''
	)]])
	sql.Query([[CREATE TABLE IF NOT EXISTS `ma_questions` (
	`id` INTEGER PRIMARY KEY AUTOINCREMENT,
	`name` TEXT NOT NULL,
	`questions` TEXT NOT NULL,
	`timelimit` INT(11) NOT NULL DEFAULT (0),
	`enabled` INT(1) NOT NULL DEFAULT (0)
	)]])
	sql.Query([[CREATE TABLE IF NOT EXISTS `ma_violations` (
	`id` INTEGER PRIMARY KEY AUTOINCREMENT,
	`SID` TEXT NOT NULL,
	`date` TEXT(11) NOT NULL,
	`admin` TEXT NOT NULL,
	`server` TEXT NOT NULL,
	`violation` TEXT NOT NULL
	)]])
end

function metadmin.GetData(sid,cb)
	local result = sql.Query("SELECT * FROM `ma_players` WHERE SID='"..sid.."'")
	cb(result)
end

function metadmin.SaveData(sid)
	if not metadmin.players[sid] then return end
	local rank = metadmin.players[sid].rank or "user"
	local status = util.TableToJSON(metadmin.players[sid].status)
	sql.Query("UPDATE `ma_players` SET `group` = "..sql.SQLStr(rank)..",`status` = "..sql.SQLStr(status).." WHERE `SID`="..sql.SQLStr(sid))
end

function metadmin.UpdateNick(ply)
	local sid = ply:SteamID()
	if not metadmin.players[sid] then return end
	sql.Query("UPDATE `ma_players` SET `nick` = "..sql.SQLStr(ply:Nick()).." WHERE `SID`='"..sid.."'")
end

function metadmin.OnOffSynch(sid,on)
	if not metadmin.players[sid] or not isnumber(on) then return end
	sql.Query("UPDATE `ma_players` SET `synch` = "..on..",`synchgroup` = '' WHERE `SID`='"..sid.."'")
end

function metadmin.SetSynchGroup(sid,rank)
	sql.Query("UPDATE `ma_players` SET `synchgroup` = "..sql.SQLStr(rank).." WHERE `SID`='"..sid.."'")
end

function metadmin.CreateData(sid)
	local status = "{\"date\":"..os.time()..",\"nom\":1,\"admin\":\"\"}"
	local group = "user"
	local nick = ""
	local ply = player.GetBySteamID(sid)
	if ply then
		nick = ply:Nick()
		if metadmin.groupwrite then
			group = ply:GetUserGroup()
		else
			metadmin.SetUserGroup(ply,group)
		end
	end
	sql.Query("INSERT INTO `ma_players` (`SID`,`group`,`status`,`nick`) VALUES ('"..sid.."',"..sql.SQLStr(group)..","..sql.SQLStr(status)..","..sql.SQLStr(nick)..")")
	metadmin.players[sid] = {}
	metadmin.players[sid].rank = group
	metadmin.players[sid].nick = nick
	metadmin.players[sid].status = {}
	metadmin.players[sid].status.nom = 1
	metadmin.players[sid].status.admin = ""
	metadmin.players[sid].status.date = os.time()
	metadmin.players[sid].violations = {}
	metadmin.players[sid].localviolations = {}
	metadmin.players[sid].exam = {}
	metadmin.players[sid].exam_answers = {}
	metadmin.players[sid].icons = {}
	metadmin.players[sid].rights = {}
	if metadmin.synch then
		metadmin.OnOffSynch(sid,1)
		metadmin.GetDataSID(sid)
	else
		http.Post("https://api.metrostroi.net/user",{SID=sid,online=(online and "1" or "0"),unique_id=metadmin.unique_id},function(body,len,headers,code)
			if code ~= 200 then return end
			if body == "" then return end
			local tab = util.JSONToTable(body)
			metadmin.players[sid].icons = tab.icons
			metadmin.players[sid].rights = tab.rights
			if ply then
				metadmin.SendRights(ply)
			end
		end)
	end
end

function metadmin.GetQuestions(cb)
	local result = sql.Query("SELECT * FROM ma_questions")
	if not result then result = {} end
	cb(result)
end

function metadmin.SaveQuestion(id,questions)
	sql.Query("UPDATE `ma_questions` SET `questions` = "..sql.SQLStr(questions).." WHERE `id`="..id)
end

function metadmin.SetEnabledQuestion(id,enabled)
	sql.Query("UPDATE `ma_questions` SET `enabled` = '"..enabled.."' WHERE `id`="..id)
end

function metadmin.SaveQuestionName(id,name)
	sql.Query("UPDATE `ma_questions` SET `name` = "..sql.SQLStr(name).." WHERE `id`="..tonumber(id))
end

function metadmin.SaveQuestionRecTime(id,time)
	sql.Query("UPDATE `ma_questions` SET `timelimit` = '"..tonumber(time).."' WHERE `id`="..tonumber(id))
end

function metadmin.RemoveQuestion(id)
	sql.Query("DELETE FROM `ma_questions` WHERE `id`='"..id.."'")
end

function metadmin.AddQuestion(name)
	sql.Query("INSERT INTO `ma_questions` (`id`,`name`,`questions`,`enabled`) VALUES (NULL,"..sql.SQLStr(name)..",'{}','0')")
end

function metadmin.GetTests(sid,cb)
	local result = sql.Query("SELECT * FROM ma_answers WHERE SID="..sql.SQLStr(sid).." ORDER BY id DESC")
	if not result then result = {} else
		for k,v in pairs(result) do
			result[k].id = tonumber(v.id)
			result[k].questions = tonumber(v.questions)
			result[k].date = tonumber(v.date)
			result[k].time = tonumber(v.time)
			result[k].status = tonumber(v.status)
		end
	end
	cb(result)
end

function metadmin.GetUncheckedTests(cb)
	local result = sql.Query("SELECT `ma_answers`.`id`,`ma_answers`.`date`,`ma_answers`.`SID`,`ma_answers`.`questions`,`ma_players`.`nick` FROM `ma_answers` LEFT JOIN `ma_players` ON (`ma_answers`.`SID` = `ma_players`.`SID`) WHERE `ma_answers`.`status` = 0 ORDER BY id DESC LIMIT 30")
	if not result then result = {} end
	cb(result)
end

function metadmin.AddTest(sid,ques,ans,time,adminsid)
	sql.Query("INSERT INTO `ma_answers` (`id`,`SID`,`date`,`questions`,`answers`,`admin`,`time`,`ssadmin`) VALUES (NULL,'"..sid.."','"..os.time().."','"..tonumber(ques).."',"..sql.SQLStr(ans)..",'"..adminsid.."','"..tonumber(time).."','')")
end

function metadmin.SetStatusTest(id,status,ssadmin)
	sql.Query("UPDATE `ma_answers` SET `status` = '"..status.."',`ssadmin` = "..sql.SQLStr(ssadmin).." WHERE `id`='"..tonumber(id).."'")
end

function metadmin.GetViolations(sid,cb)
	local result = sql.Query("SELECT `ma_violations`.*,`ma_players`.`nick` FROM `ma_violations` LEFT JOIN `ma_players` ON (`ma_violations`.`admin` = `ma_players`.`SID`) WHERE `ma_violations`.`SID` = "..sql.SQLStr(sid).." ORDER BY id DESC")
	if not result then result = {} else
		for k,v in pairs(result) do
			result[k].date = tonumber(result[k].date)
		end
	end
	cb(result)
end

function metadmin.AddViolation(sid,adminsid,violation)
	if not adminsid then adminsid = "CONSOLE" end
	sql.Query("INSERT INTO `ma_violations` (`id`,`SID`,`date`,`admin`,`server`,`violation`) VALUES (NULL,'"..sid.."','"..os.time().."','"..adminsid.."',"..sql.SQLStr(metadmin.server)..","..sql.SQLStr(violation)..")")
end

function metadmin.RemoveViolation(id)
	sql.Query("DELETE FROM `ma_violations` WHERE `id`="..id)
end

function metadmin.GetExamInfo(sid,cb)
	local result = sql.Query("SELECT `ma_examinfo`.*,`ma_players`.`nick` FROM `ma_examinfo` LEFT JOIN `ma_players` ON (`ma_examinfo`.`examiner` = `ma_players`.`SID`) WHERE `ma_examinfo`.`SID` = "..sql.SQLStr(sid).." ORDER BY id DESC")
	if not result then result = {} end
	cb(result)
end
function metadmin.AddExamInfo(sid,rank,adminsid,note,type)
	sql.Query("INSERT INTO `ma_examinfo` (`SID`,`date`,`rank`,`examiner`,`note`,`type`,`server`) VALUES ('"..sid.."','"..os.time().."',"..sql.SQLStr(rank)..",'"..adminsid.."',"..sql.SQLStr(note)..",'"..type.."',"..sql.SQLStr(metadmin.server)..")")
end

function metadmin.AllPlayers(group,cb)
	local result = sql.Query("SELECT SID, nick FROM `ma_players` WHERE `synchgroup`="..sql.SQLStr(group).." OR (`group`="..sql.SQLStr(group).." AND `synchgroup`='')")
	if not result then result = {} end
	cb(result)
end