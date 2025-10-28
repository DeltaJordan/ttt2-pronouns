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

local SBPANELROW = vgui.GetControlTable("TTTScorePlayerRow")
SBPANELROW.pronoun_UpdatePlayerData = SBPANELROW.pronoun_UpdatePlayerData or SBPANELROW.UpdatePlayerData

function SBPANELROW:UpdatePlayerData()
	SBPANELROW:pronoun_UpdatePlayerData()

	if not GetConVar("ttt2_pronouns_scoreboard_append"):GetBool() then return end

	local prons = ""
	local pronounORM = GetPronounORM()
	if not pronounORM then return end
	local userTable = pronounORM:Find(self.Player:SteamID64())
	if userTable then prons = userTable.pronouns end
	if prons == "" then return end
	-- set character limit and amount to truncate to
	local appendMaxChar = GetConVar("ttt2_pronouns_scoreboard_append_maxchar"):GetInt()
	if string.len(prons) > appendMaxChar then prons = string.sub(prons, 1, appendMaxChar - 2) .. "..." end
	prons = "(" .. prons .. ")"
	self.nick:SetText(self.Player:Nick() .. " " .. prons)
	self.nick:SizeToContents()
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

hook.Add("TTT2PronounUpdateScoreboard", "PronounsUpdateScoreboard", function()
	local playerRowPanel = GetPlayerRowPanel(ply)
	playerRowPanel:UpdatePlayerData()
end)