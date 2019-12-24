local PLUGIN = {}
PLUGIN.Title = "MetAdmin"
PLUGIN.Description = ""
PLUGIN.Author = "HellReach"
PLUGIN.Privileges = {}
for k,v in pairs(metadmin.Permissions) do
	table.insert(PLUGIN.Privileges,k)
end
evolve:RegisterPlugin(PLUGIN)

-- Я не проверял работу с evolve и не знаю никого, кто бы его использовал.