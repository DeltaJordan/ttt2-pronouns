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

	local ply = player.GetBySteamID64(steamId)
	if not IsValid(ply) then
		return
	end

	hook.Run("TTT2PronounUpdateScoreboard");
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

	print("Received " .. newDataCount .. " entries of pronoun data from server.")
end)

hook.Add("PostInitPostEntity", "TTT2PronounInit", function()
	net.Start("TTT2PronounGetAll")
	net.SendToServer()
end)