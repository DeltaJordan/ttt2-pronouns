local function GetPronounORM()
	local sqlTableName = "ttt2_pronouns_table"
	local savingKeys = {
		-- steamId is primary key column 'name'
		pronouns = {
			typ = "string",
			default = nil
		}
	}

	if not sql.CreateSqlTable(sqlTableName, savingKeys) then return end
	return orm.Make(sqlTableName)
end

local function UpdatePlayerRowPronounsPosition(panel)
	-- copy pasted from ttt2 code in cl_sb_row.lua
	local x = panel.nick:GetPos()
	local w = panel.nick:GetSize()
	local count = 0
	local mgn = 10
	local iconSizes = 16
	local tx = x + w + mgn
	local iconTbl = {"dev", "vip", "addondev", "admin", "streamer", "heroes",}
	for i = 1, #iconTbl do
		local entry = iconTbl[i]
		local iconData = panel[entry]
		if iconData:IsVisible() then count = count + 1 end
	end
	panel.pronoun:SetPos(tx + (iconSizes + mgn) * count, (SB_ROW_HEIGHT - panel.nick:GetTall()) * 0.5)
	panel.pronoun:SizeToContents()
end

local function UpdatePlayerRowPronounsText(ply, panel)
	local prons = ""
	local pronounORM = GetPronounORM()
	if not pronounORM then return end
	local userTable = pronounORM:Find(ply:SteamID64())
	if userTable then prons = userTable.pronouns end
	if prons == "" then return end
	-- set character limit and amount to truncate to
	local appendMaxChar = GetConVar("ttt2_pronouns_scoreboard_append_maxchar"):GetInt()
	if string.len(prons) > appendMaxChar then prons = string.sub(prons, 1, appendMaxChar - 2) .. "..." end
	prons = "(" .. prons .. ")"
	panel.pronoun:SetText(prons)
	panel.pronoun:SizeToContents()
end

local function UpdateAllPlayersScoreboard()
	if not GetConVar("ttt2_pronouns_scoreboard_append"):GetBool() then return end
	local scoreboardPanel = GAMEMODE:GetScoreboardPanel()
	if not IsValid(scoreboardPanel) then return end
	if not scoreboardPanel:IsVisible() then return end
	-- get all the group panels from the scoreboard
	for _, group in pairs(scoreboardPanel.ply_groups) do
		if not IsValid(group) then continue end
		-- iterate over the player row panels in the group and then set each pronoun
		for _, panel in pairs(group.rows) do
			UpdatePlayerRowPronounsPosition(panel)
		end
	end
end

local function GetPlayerRowPanel(ply)
	if not IsValid(ply) then return end
	local scoreboardPanel = GAMEMODE:GetScoreboardPanel()
	if not IsValid(scoreboardPanel) then return end
	local group = ScoreGroup(ply)
	local groupPanel = scoreboardPanel.ply_groups[group]
	if not IsValid(groupPanel) then return end
	-- player row panel
	return groupPanel.rows[ply]
end

hook.Add("TTTScoreboardColumns", "PronounsScoreboard", function(panel)
	-- simple way of checking if its a player row panel or not
	-- can probably be done more elegantly
	if panel.open ~= nil then
		panel.pronoun = vgui.Create("DLabel", panel)
		panel.pronoun:SetMouseInputEnabled(false)
		panel.pronoun:SetFont("treb_small")
		panel.pronoun:SetText("")
		panel.pronoun:SetTextColor(COLOR_WHITE)
		-- wait a think to update
		-- 2 times cause I notice it possibly being bugged after 1 think somehow
		timer.Create("UpdatePronounsNextThink" .. SysTime(), 1 / 150, 1, function()
			UpdatePlayerRowPronounsText(panel.Player, panel)
			UpdatePlayerRowPronounsPosition(panel)
			-- absolutely make sure it actually looks good now
			timer.Create("UpdatePronounsPosition" .. SysTime(), 0.05, 2, function() UpdatePlayerRowPronounsPosition(panel) end)
		end)
	end

	if GetConVar("ttt2_pronouns_scoreboard_column"):GetBool() then
		panel:AddColumn("Pronouns", function(ply)
			local prons = ""
			local pronounORM = GetPronounORM()
			if not pronounORM then return "" end
			local userTable = pronounORM:Find(ply:SteamID64())
			if userTable then prons = userTable.pronouns end
			local columnMaxChar = GetConVar("ttt2_pronouns_scoreboard_column_maxchar"):GetInt()
			if string.len(prons) > columnMaxChar then prons = string.sub(prons, 1, columnMaxChar - 2) .. "..." end
			return prons
			-- the number down here is the width of the column
		end, 70)
	end
end)

-- keep updating the position, like when the username changes possibly
timer.Create("PronounsScoreboardPositionUpdate", 0.3, 0, function()
	UpdateAllPlayersScoreboard()
end)

hook.Add("TTT2PronounUpdateScoreboard", "PronounsUpdateScoreboard", function()
	local playerRowPanel = GetPlayerRowPanel(ply)
	UpdatePlayerRowPronounsText(ply, playerRowPanel)
end)