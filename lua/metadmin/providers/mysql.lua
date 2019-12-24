require("mysqloo") -- https://github.com/FredyH/MySQLOO
local db = mysqloo.connect(metadmin.mysql.host, metadmin.mysql.user, metadmin.mysql.pass, metadmin.mysql.database, metadmin.mysql.port)

local start = [[CREATE TABLE IF NOT EXISTS `ma_answers` (
  `id` int(11) NOT NULL AUTO_INCREMENT PRIMARY KEY,
  `SID` varchar(20) NOT NULL,
  `date` int(11) NOT NULL,
  `questions` INT(11) NOT NULL,
  `status` int(11) NOT NULL DEFAULT '0',
  `answers` text NOT NULL,
  `time` int(11) NOT NULL,
  `admin` text NOT NULL,
  `ssadmin` text NOT NULL
) ENGINE=MyISAM DEFAULT CHARSET=utf8;
CREATE TABLE IF NOT EXISTS `ma_examinfo` (
  `id` int(11) NOT NULL AUTO_INCREMENT PRIMARY KEY,
  `SID` varchar(20) NOT NULL,
  `date` int(11) NOT NULL,
  `rank` text NOT NULL,
  `examiner` text NOT NULL,
  `note` text NOT NULL,
  `type` int(11) NOT NULL,
  `server` text NOT NULL
) ENGINE=MyISAM DEFAULT CHARSET=utf8;
CREATE TABLE IF NOT EXISTS `ma_players` (
  `SID` varchar(20) NOT NULL,
  `group` text NOT NULL,
  `status` text NOT NULL,
  `nick` text NOT NULL,
  `synch` tinyint(1) NOT NULL,
  `synchgroup` text NOT NULL,
  UNIQUE KEY `SID` (`SID`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;
CREATE TABLE IF NOT EXISTS `ma_questions` (
  `id` int(11) NOT NULL AUTO_INCREMENT PRIMARY KEY,
  `name` text NOT NULL,
  `questions` text NOT NULL,
  `timelimit` int(11) NOT NULL DEFAULT '0',
  `enabled` int(1) NOT NULL DEFAULT '0'
) ENGINE=MyISAM DEFAULT CHARSET=utf8;
CREATE TABLE IF NOT EXISTS `ma_violations` (
  `id` int(11) NOT NULL AUTO_INCREMENT PRIMARY KEY,
  `SID` varchar(20) NOT NULL,
  `date` int(11) NOT NULL,
  `admin` text NOT NULL,
  `server` text NOT NULL,
  `violation` text NOT NULL
) ENGINE=MyISAM DEFAULT CHARSET=utf8;
]]

local function OnError(_, err, sql)
	if db:status() ~= mysqloo.DATABASE_CONNECTED then
		db:connect()
		db:wait()
		if db:status() ~= mysqloo.DATABASE_CONNECTED then
			ErrorNoHalt("Переподключение не удалось.")
			return
		end
	end
	MsgN("MetAdmin MySQL: Error: "..err.."\n("..sql..")")
end

function db:onConnected()
	local utf8 = db:query("SET names 'utf8'")
	utf8:start()
	MsgN("MetAdmin MySQL: Connected!")
	local q = db:query(start)
	q.onError = OnError
	q:start()
end

function db:onConnectionFailed(err)
	MsgN("MetAdmin MySQL: Error: "..err)
end

db:connect()
metadmin.players = metadmin.players or {}

function metadmin.GetData(sid,cb)
	local q = db:prepare("SELECT * FROM `ma_players` WHERE SID = ?")
	q.onSuccess = function(_, data)
		cb(data)
	end
	q.onError = OnError
	q:setString(1,sid)
	q:start()
end

function metadmin.SaveData(sid)
	if not metadmin.players[sid] then return end
	local rank = metadmin.players[sid].rank or "user"
	local status = util.TableToJSON(metadmin.players[sid].status)
	local q = db:prepare("UPDATE `ma_players` SET `group` = ?, `status` = ? WHERE `SID` = ?")
	q.onError = OnError
	q:setString(1,rank)
	q:setString(2,status)
	q:setString(3,sid)
	q:start()
end

function metadmin.UpdateNick(ply)
	local sid = ply:SteamID()
	if not metadmin.players[sid] then return end
	local q = db:prepare("UPDATE `ma_players` SET `nick` = ? WHERE `SID` = ?")
	q.onError = OnError
	q:setString(1,ply:Nick())
	q:setString(2,sid)
	q:start()
end

function metadmin.OnOffSynch(sid,on)
	if not isnumber(on) then return end
	local q = db:prepare("UPDATE `ma_players` SET `synch` = ? WHERE `SID` = ?")
	q.onError = OnError
	q:setNumber(1,on)
	q:setString(2,sid)
	q:start()
end

function metadmin.SetSynchGroup(sid,rank)
	local q = db:prepare("UPDATE `ma_players` SET `synchgroup` = ? WHERE `SID` = ?")
	q.onError = OnError
	q:setString(1,rank)
	q:setString(2,sid)
	q:start()
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

	local q = db:prepare("INSERT INTO `ma_players` (`SID`,`group`,`status`,`nick`) VALUES (?,?,?,?)")
	q.onSuccess = function()
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

	q.onError = OnError
	q:setString(1,sid)
	q:setString(2,group)
	q:setString(3,status)
	q:setString(4,nick)
	q:start()
end

function metadmin.GetQuestions(cb)
	local q = db:query("SELECT * FROM ma_questions")
	q.onSuccess = function(self, data)
		cb(data)
	end
	q.onError = OnError
	q:start()
end

function metadmin.SaveQuestion(id,questions)
	local q = db:prepare("UPDATE `ma_questions` SET `questions` = ? WHERE `id` = ?")
	q.onError = OnError
	q:setString(1,questions)
	q:setNumber(2,id)
	q:start()
end

function metadmin.SetEnabledQuestion(id,enabled)
	local q = db:prepare("UPDATE `ma_questions` SET `enabled` = ? WHERE `id` = ?")
	q.onError = OnError
	q:setNumber(1,enabled)
	q:setNumber(2,id)
	q:start()
end

function metadmin.SaveQuestionName(id,name)
	local q = db:prepare("UPDATE `ma_questions` SET `name` = ? WHERE `id` = ?")
	q.onError = OnError
	q:setString(1,name)
	q:setNumber(2,id)
	q:start()
end

function metadmin.SaveQuestionRecTime(id,time)
	local q = db:prepare("UPDATE `ma_questions` SET `timelimit` = ? WHERE `id` = ?")
	q.onError = OnError
	q:setNumber(1,time)
	q:setNumber(2,id)
	q:start()
end

function metadmin.RemoveQuestion(id)
	local q = db:prepare("DELETE FROM `ma_questions` WHERE `id` = ?")
	q.onError = OnError
	q:setNumber(1,id)
	q:start()
end

function metadmin.AddQuestion(name)
	local q = db:prepare("INSERT INTO `ma_questions` (`name`,`questions`,`enabled`) VALUES (?,'{}','0')")
	q.onError = OnError
	q:setString(1,name)
	q:start()
end

function metadmin.GetTests(sid,cb)
	local q = db:prepare("SELECT * FROM ma_answers WHERE SID = ? ORDER BY id DESC")
	q.onSuccess = function(self, data)
		for k,v in pairs(data) do
			data[k].questions = tonumber(v.questions)
			data[k].date = tonumber(v.date)
		end
		cb(data)
	end
	q.onError = OnError
	q:setString(1,sid)
	q:start()
end

function metadmin.GetUncheckedTests(cb)
	local q = db:query("SELECT `ma_answers`.`id`,`ma_answers`.`date`,`ma_answers`.`SID`,`ma_answers`.`questions`,`ma_players`.`nick` FROM `ma_answers` LEFT JOIN `ma_players` ON (`ma_answers`.`SID` = `ma_players`.`SID`) WHERE `ma_answers`.`status` = 0 ORDER BY id DESC LIMIT 30")
	q.onSuccess = function(self, data)
		cb(data)
	end
	q.onError = OnError
	q:start()
end


function metadmin.AddTest(sid,ques,ans,time,adminsid)
	local q = db:prepare("INSERT INTO `ma_answers` (`SID`,`date`,`questions`,`answers`,`admin`,`time`,`ssadmin`) VALUES (?,?,?,?,?,?,'')")
	q.onError = OnError
	q:setString(1,sid)
	q:setNumber(2,os.time())
	q:setNumber(3,tonumber(ques))
	q:setString(4,ans)
	q:setString(5,adminsid)
	q:setNumber(6,time)
	q:start()
end

function metadmin.SetStatusTest(id,status,ssadmin)
	local q = db:prepare("UPDATE `ma_answers` SET `status` = ?,`ssadmin` = ? WHERE `id`= ?")
	q.onError = OnError
	q:setNumber(1,status)
	q:setString(2,ssadmin)
	q:setNumber(3,id)
	q:start()
end

function metadmin.GetViolations(sid,cb)
	local q = db:prepare("SELECT `ma_violations`.*,`ma_players`.`nick` FROM `ma_violations` LEFT JOIN `ma_players` ON (`ma_violations`.`admin` = `ma_players`.`SID`) WHERE `ma_violations`.`SID` = ? ORDER BY id DESC")
	q.onSuccess = function(self, data)
		cb(data)
	end
	q.onError = OnError
	q:setString(1,sid)
	q:start()
end

function metadmin.AddViolation(sid,adminsid,violation)
	if not adminsid then adminsid = "CONSOLE" end
	local q = db:prepare("INSERT INTO `ma_violations` (`SID`,`date`,`admin`,`server`,`violation`) VALUES (?,?,?,?,?)")
	q.onError = OnError
	q:setString(1,sid)
	q:setNumber(2,os.time())
	q:setString(3,adminsid)
	q:setString(4,metadmin.server)
	q:setString(5,violation)
	q:start()
end

function metadmin.RemoveViolation(id)
	local q = db:prepare("DELETE FROM `ma_violations` WHERE `id` = ?")
	q.onError = OnError
	q:setNumber(1,id)
	q:start()
end

function metadmin.GetExamInfo(sid,cb)
	local q = db:prepare("SELECT `ma_examinfo`.*,`ma_players`.`nick` FROM `ma_examinfo` LEFT JOIN `ma_players` ON (`ma_examinfo`.`examiner` = `ma_players`.`SID`) WHERE `ma_examinfo`.`SID` = ? ORDER BY id DESC")
	q.onSuccess = function(self, data)
		cb(data)
	end
	q.onError = OnError
	q:setString(1,sid)
	q:start()
end
function metadmin.AddExamInfo(sid,rank,adminsid,note,type)
	local q = db:prepare("INSERT INTO `ma_examinfo` (`SID`,`date`,`rank`,`examiner`,`note`,`type`,`server`) VALUES (?,?,?,?,?,?,?)")
	q.onError = OnError
	q:setString(1,sid)
	q:setNumber(2,os.time())
	q:setString(3,rank)
	q:setString(4,adminsid)
	q:setString(5,note)
	q:setNumber(6,type)
	q:setString(7,metadmin.server)
	q:start()
end

function metadmin.AllPlayers(group,cb)
	local q = db:prepare("SELECT SID, nick FROM `ma_players` WHERE `synchgroup` = ? OR (`group` = ? AND `synchgroup` = '')")
	q.onSuccess = function(self, data)
		cb(data)
	end
	q.onError = OnError
	q:setString(1,group)
	q:setString(2,group)
	q:start()
end