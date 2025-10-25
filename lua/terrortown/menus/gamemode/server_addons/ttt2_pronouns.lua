CLGAMEMODESUBMENU.base = "base_gamemodesubmenu"
CLGAMEMODESUBMENU.title = "pronouns_addon_info"

local function MakeElement(form, name, typ, data, no_help)
	local real_data = table.Merge({
		label = "label_ttt2_pronouns_" .. name,
		help = "help_ttt2_pronouns_" .. name,
		serverConvar = "ttt2_pronouns_" .. name,
		min = 0,
		max = 100,
		decimal = 0,
	}, data or {})

	if not no_help then
		form:MakeHelp({
			label = real_data.help,
			params = real_data.help_params or {},
		})
	end

	return form[typ](form, real_data)
end

function CLGAMEMODESUBMENU:Populate(parent)
	local antighost_options = vgui.CreateTTT2Form(parent, "pronouns_settings_antighost")
	MakeElement(antighost_options, "antighost", "MakeCheckBox")

	local display_options = vgui.CreateTTT2Form(parent, "pronouns_settings_display")
	MakeElement(display_options, "voice", "MakeCheckBox")
	MakeElement(display_options, "bodies", "MakeCheckBox")
	MakeElement(display_options, "players", "MakeCheckBox")
	MakeElement(display_options, "scoreboard_append", "MakeCheckBox")
	MakeElement(display_options, "scoreboard_column", "MakeCheckBox")
end