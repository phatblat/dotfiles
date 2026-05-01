-- wezTerm Configuration
-- https://wezterm.org/config/files.html
-- https://wezterm.org/config/lua/config/index.html

-- behaviors
-- automatically_reload_config = true,

local wezterm = require('wezterm')
local mux = wezterm.mux
local config = wezterm.config_builder()

config.automatically_reload_config = true

-- scrollbar
config.scrollback_lines = 5000

-- paste behaviours
config.canonicalize_pasted_newlines = 'CarriageReturn'
-- config.paste_from_clipboard_on_selection = true

-- For example, changing the initial geometry for new windows:
config.initial_cols = 120
config.initial_rows = 28

-- or, changing the font size and color scheme.
config.font_size = 15
config.font = wezterm.font 'JetBrains Mono'
config.color_scheme = 'AdventureTime'

config.default_prog = { '/opt/homebrew/bin/zsh' }

-- Quake-style dropdown: no title bar, no padding
config.window_decorations = 'RESIZE'
config.window_padding = { left = 0, right = 0, top = 0, bottom = 0 }

-- Position window at top of screen, full width, half height
wezterm.on('gui-startup', function(cmd)
  local screen = wezterm.gui.screens().active
  local tab, pane, window = mux.spawn_window(cmd or {})
  local gui = window:gui_window()
  gui:set_position(screen.x, screen.y)
  gui:set_inner_size(screen.width, screen.height / 2)
end)

-- Finally, return the configuration to wezterm:
return config
