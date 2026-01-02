-- wezTerm Configuration
-- https://wezterm.org/config/files.html
-- https://wezterm.org/config/lua/config/index.html

local wezterm = require 'wezterm'
local config = wezterm.config_builder()

-- For example, changing the initial geometry for new windows:
config.initial_cols = 120
config.initial_rows = 28

-- or, changing the font size and color scheme.
config.font_size = 15
config.font = wezterm.font 'JetBrains Mono'
config.color_scheme = 'AdventureTime'

-- Finally, return the configuration to wezterm:
return config
