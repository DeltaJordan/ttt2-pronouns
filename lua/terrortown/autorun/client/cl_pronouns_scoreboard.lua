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

-- Stolen from TTT2/gamemodes/terrortown/gamemode/client/vgui/cl_sb_row.lua @ https://github.com/TTT-2/TTT2
local function ColorForPlayer(ply)
	if IsValid(ply) then
		---
		-- @realm client
		local c = hook.Run("TTTScoreboardColorForPlayer", ply)

		-- verify that we got a proper color
		if c and istable(c) and c.r and c.b and c.g and c.a then
			return c
		else
			ErrorNoHaltWithStack(
				"TTTScoreboardColorForPlayer hook returned something that isn't a color!\n"
			)
		end
	end

	return namecolor.default
end

local SBPANELROW = vgui.GetControlTable("TTTScorePlayerRow")
SBPANELROW.pronoun_UpdatePlayerData = SBPANELROW.pronoun_UpdatePlayerData or SBPANELROW.UpdatePlayerData
function SBPANELROW:UpdatePlayerData()
	if not GetConVar("ttt2_pronouns_scoreboard_append"):GetBool() then
		self:pronoun_UpdatePlayerData()
		return
	end

	-- Extremely hacky workaround to prevent update flickering.
	-- Note that a generic object with a few empty functions would technically work,
	-- but this is way more future-proof.
	local protectNick = self.nick
	self.nick = vgui.Create("DLabel", self)
	self:pronoun_UpdatePlayerData()
	self.nick:Remove()
	self.nick = protectNick

	local ply = self.Player
	if not IsValid(ply) then return end
	local prons = ""
	local pronounORM = GetPronounORM()
	if pronounORM then
		local userTable = pronounORM:Find(ply:SteamID64())
		if userTable then prons = userTable.pronouns end
	end

	if prons and prons ~= "" then
		-- set character limit and amount to truncate to
		local appendMaxChar = GetConVar("ttt2_pronouns_scoreboard_append_maxchar"):GetInt()
		if string.len(prons) > appendMaxChar then prons = string.sub(prons, 1, appendMaxChar - 2) .. "..." end
		prons = "(" .. prons .. ")"
		self.nick:SetText(ply:Nick() .. "  " .. prons)
	else
		self.nick:SetText(ply:Nick())
	end
	self.nick:SizeToContents()
	self.nick:SetTextColor(ColorForPlayer(ply))
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

hook.Add("TTT2PronounUpdateScoreboard", "PronounsUpdateScoreboard", function(ply)
	if not IsValid(ply) then return end
	local playerRowPanel = GetPlayerRowPanel(ply)
	playerRowPanel:UpdatePlayerData()
end)