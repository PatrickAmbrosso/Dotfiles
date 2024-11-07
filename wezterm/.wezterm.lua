-- Pull in the wezterm API
local wezterm = require 'wezterm'
local io = require 'io'
local os = require 'os'

-- This will hold the configuration.
local config = wezterm.config_builder()

-- This is where you actually apply your config choice

-- For example, changing the color scheme:
config.color_scheme = 'Catppuccin Macchiato (Gogh)'
config.window_close_confirmation = "NeverPrompt"
config.front_end = "OpenGL"
config.max_fps = 144
config.default_cursor_style = "BlinkingBar"
config.animation_fps = 1
config.cursor_blink_rate = 500
config.term = "xterm-256color"
config.window_background_opacity = 0.92
config.prefer_egl = true
config.font = wezterm.font("JetBrainsMono Nerd Font")
config.font_size = 10.5
config.line_height = 1.1
config.window_padding = {
	left = 15,
	right = 15,
	top = 15,
	bottom = 15,
}



config.default_prog = { "pwsh", "-NoLogo" }
config.initial_cols = 80


-- Window & Tab Bar Configurations
config.hide_tab_bar_if_only_one_tab = true
config.use_fancy_tab_bar = false
config.window_decorations = "RESIZE"
config.tab_bar_at_bottom = true
config.tab_max_width = 30
config.colors = {
	-- background = '#3b224c',
	-- background = "#181616", -- vague.nvim bg
	-- background = "#080808", -- almost black
	-- background = "#0c0b0f", -- dark purple
	-- background = "#020202", -- dark purple
	-- background = "#17151c", -- brighter purple
	-- background = "#16141a",
	-- background = "#0e0e12", -- bright washed lavendar
	-- background = 'rgba(59, 34, 76, 100%)',
	cursor_border = "#f9e2af",
	-- cursor_fg = "#281733",
	cursor_bg = "#f9e2af",
	-- selection_fg = '#281733',

	tab_bar = {
		background = "#1e1e2e",
		-- background = "rgba(0, 0, 0, 0%)",
		active_tab = {
			bg_color = "#181825",
			fg_color = "#cba6f7",
			intensity = "Normal",
			underline = "None",
			italic = false,
			strikethrough = false,
		},
		inactive_tab = {
			bg_color = "#1e1e2e",
			fg_color = "#f8f2f5",
			intensity = "Normal",
			underline = "None",
			italic = false,
			strikethrough = false,
		},

		new_tab = {
			-- bg_color = "rgba(59, 34, 76, 50%)",
			bg_color = "#1e1e2e",
			fg_color = "#f9e2af",
		},
	},
}

-- keymaps
config.keys = {
	{
		key = "h",
		mods = "CTRL|SHIFT|ALT",
		action = wezterm.action.SplitPane({
			direction = "Right",
			size = { Percent = 50 },
		}),
	},
	{
		key = "v",
		mods = "CTRL|SHIFT|ALT",
		action = wezterm.action.SplitPane({
			direction = "Down",
			size = { Percent = 50 },
		}),
	},
	{ key = 'l', mods = 'ALT', action = wezterm.action.ShowLauncher },
}

config.launch_menu = {
	{
		label = "Launch a PowerShell Session",
		args = { "pwsh.exe", "-NoLogo" }
	},
	{
		label = "Launch a Nushell Session",
		args = { "nu.exe" }
	},
	{
		label = "Monitor System Resources with btop",
		args = { "btop.exe" }
	}
}

-- -- The filled in variant of the < symbol
-- local SOLID_LEFT_ARROW = wezterm.nerdfonts.ple_left_half_circle_thick

-- -- The filled in variant of the > symbol
-- local SOLID_RIGHT_ARROW = wezterm.nerdfonts.ple_right_half_circle_thick

-- -- This function returns the suggested title for a tab.
-- -- It prefers the title that was set via `tab:set_title()`
-- -- or `wezterm cli set-tab-title`, but falls back to the
-- -- title of the active pane in that tab.
-- function tab_title(tab_info)
--   local title = tab_info.tab_title
--   -- if the tab title is explicitly set, take that
--   if title and #title > 0 then
--     return title
--   end
--   -- Otherwise, use the title from the active pane
--   -- in that tab
--   return tab_info.active_pane.title
-- end

-- wezterm.on(
--   'format-tab-title',
--   function(tab, tabs, panes, config, hover, max_width)
--     local edge_background = 'rgba(0, 0, 0, 0%)'
--     local background = '#1b1032'
--     local foreground = '#808080'

--     if tab.is_active then
--       background = '#2b2042'
--       foreground = '#c0c0c0'
--     elseif hover then
--       background = '#3b3052'
--       foreground = '#909090'
--     end

--     local edge_foreground = background

--     local title = tab_title(tab)

--     -- ensure that the titles fit in the available space,
--     -- and that we have room for the edges.
--     title = wezterm.truncate_right(title, max_width - 2)

--     return {
--       { Background = { Color = edge_background } },
--       { Foreground = { Color = edge_foreground } },
--       { Text = SOLID_LEFT_ARROW },
--       { Background = { Color = background } },
--       { Foreground = { Color = foreground } },
--       { Text = title },
--       { Background = { Color = edge_background } },
--       { Foreground = { Color = edge_foreground } },
--       { Text = SOLID_RIGHT_ARROW },
--     }
--   end
-- )


-- config.colors = {
-- 	tab_bar = {
-- 		-- background = "#0c0b0f",
-- 		background = "rgba(0, 0, 0, 0%)",
-- 		active_tab = {
-- 			bg_color = "rgba(0, 0, 0, 0%)",
-- 			fg_color = "#bea3c7",
-- 			intensity = "Normal",
-- 			underline = "None",
-- 			italic = false,
-- 			strikethrough = false,
-- 		},
-- 		inactive_tab = {
-- 			bg_color = "rgba(0, 0, 0, 0%)",
-- 			fg_color = "#f8f2f5",
-- 			intensity = "Normal",
-- 			underline = "None",
-- 			italic = false,
-- 			strikethrough = false,
-- 		},

-- 		new_tab = {
-- 			-- bg_color = "rgba(59, 34, 76, 50%)",
-- 			bg_color = "#0c0b0f",
-- 			fg_color = "#feca57",
-- 		},
-- 	},

-- }

-- and finally, return the configuration to wezterm
return config