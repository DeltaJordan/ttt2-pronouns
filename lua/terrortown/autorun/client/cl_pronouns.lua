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

local function PlayerAppendPronouns(ply, panel)
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
	-- trigger PerformLayout which should set everything in the
	-- right position for this to also be set in the right position.
	panel:InvalidateLayout(true)
	panel.nick:SizeToContents()
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

	panel.pronoun:SetText(prons)
	panel.pronoun:SizeToContents()
	panel.pronoun:SetPos(tx + (iconSizes + mgn) * count, (SB_ROW_HEIGHT - panel.nick:GetTall()) * 0.5)
	-- text color could be set as the same one as the name but didnt feel like it I think its fine
	panel.pronoun:SetTextColor(COLOR_WHITE)
end

local function UpdateAllPlayersScoreboard()
	if not GetConVar("ttt2_pronouns_scoreboard_append"):GetBool() then return end
	local scoreboardPanel = GAMEMODE:GetScoreboardPanel()
	if not IsValid(scoreboardPanel) then return end
	-- get all the group panels from the scoreboard
	for _, group in pairs(scoreboardPanel.ply_groups) do
		if not IsValid(group) then continue end
		-- iterate over the player row panels in the group and then set each pronoun
		for _, panel in pairs(group.rows) do
			local ply = panel:GetPlayer()
			if not IsValid(ply) then continue end
			PlayerAppendPronouns(ply, panel)
		end
	end
end

local function UpdatePlayerScoreboard(ply)
	if not IsValid(ply) then return end
	local scoreboardPanel = GAMEMODE:GetScoreboardPanel()
	if not IsValid(scoreboardPanel) then return end
	local group = ScoreGroup(ply)
	local groupPanel = scoreboardPanel.ply_groups[group]
	if not IsValid(groupPanel) then return end
	-- player row panel
	local panel = groupPanel.rows[ply]
	if not IsValid(panel) then return end
	PlayerAppendPronouns(ply, panel)
end

hook.Add("TTTRenderEntityInfo", "TTTPronounsTargetID", function(tData)
	local displayOnBodies = GetConVar("ttt2_pronouns_bodies"):GetBool()
	local displayOnPlayers = GetConVar("ttt2_pronouns_players"):GetBool()
	local ent = tData:GetEntity()
	if displayOnBodies and ent:IsPlayerRagdoll() and CORPSE.GetFound(ent, false) then
		local ply = CORPSE.GetPlayer(ent)
		if IsValid(ply) then
			local pronounORM = GetPronounORM()
			if not pronounORM then return end
			local userTable = pronounORM:Find(ply:SteamID64())
			if not userTable then return end
			tData:AddDescriptionLine("(" .. userTable.pronouns .. ")", Color(255, 255, 255))
		end
	elseif displayOnPlayers and ent:IsPlayer() then
		local pronounORM = GetPronounORM()
		if not pronounORM then return end
		local userTable = pronounORM:Find(ent:SteamID64())
		if not userTable then return end
		tData:AddDescriptionLine("(" .. userTable.pronouns .. ")", Color(255, 255, 255))
	end
end)

net.Receive("TTT2PronounBroadcast", function()
	local steamId = net.ReadUInt64()
	local pronouns = net.ReadString()
	local pronounORM = GetPronounORM()
	local pronounData = pronounORM:Find(steamId)
	if pronouns ~= "nil" then
		if not pronounData then
			pronounData = pronounORM:New({
				name = steamId,
				pronouns = pronouns
			})
		else
			pronounData.pronouns = pronouns
		end

		if pronounData:Save() then
			print("Saved the following pronoun data:" .. "\n   SteamID64: " .. steamId .. "\n   Pronouns: " .. pronouns)
		else
			print("Failed to save the received data to the database.")
		end
	elseif pronounData and pronounData:Delete() then
		print("Deleted pronoun data for " .. steamId .. ".")
	end

	UpdatePlayerScoreboard(player.GetBySteamID64(steamId))
end)

net.Receive("TTT2PronounGetAll", function(_, ply)
	sql.Query("DROP TABLE ttt2_pronouns_table")
	local pronounORM = GetPronounORM()
	local newDataCount = net.ReadUInt(16)
	for i = 1, newDataCount do
		local newDataEntry = pronounORM:New({
			name = net.ReadUInt64(),
			pronouns = net.ReadString()
		})

		newDataEntry:Save()
	end

	print("Recieved " .. newDataCount .. " entries of pronoun data from server.")
end)

hook.Add("PostInitPostEntity", "TTT2PronounInit", function()
	net.Start("TTT2PronounGetAll")
	net.SendToServer()
end)

hook.Add("TTTScoreboardColumns", "PronounsScoreboard", function(panel)
	-- simple way of checking if its a player row panel or not
	-- can probably be done more elegantly
	if panel.open ~= nil then
		panel.pronoun = vgui.Create("DLabel", panel)
		panel.pronoun:SetMouseInputEnabled(false)
		panel.pronoun:SetFont("treb_small")
		panel.pronoun:SetText("")
		-- wait a think to update
		-- 2 times cause I notice it possibly being bugged after 1 think somehow
		timer.Create("UpdatePronounsNextThink", 1 / 150, 2, function() UpdateAllPlayersScoreboard() end)
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

-- The marker addon recreates the scoreboard in a way that breaks with my code.
-- Here we replace the function that gives it identical functionality except in a way that shouldnt break things.
hook.Add("InitPostEntity", "MarkerWorkaroundFix", function()
	if MARKER_DATA == nil then return end
	MARKER_DATA.UpdateScoreboard = function(self)
		if sboard_panel == nil then return end
		sboard_panel:Remove()
		sboard_panel = nil
	end
end)