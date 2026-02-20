-- Pull in the wezterm API
local wezterm = require "wezterm"
local nix_paths = require "nix_paths"
local mux = wezterm.mux

-- This will hold the configuration.
local config = wezterm.config_builder()

-- This is where you actually apply your config choices.
-- -----------------------------------------------------
-- https://wezterm.org/config/lua/config/

-- Font
config.font_size = 13
config.font = wezterm.font("CaskaydiaCove Nerd Font")
config.font_rules = {
  -- This overrides the CaskaydiaCove Nerd Font ExtraLight, which is selected by default
  -- and it looks awful
  {
    intensity = 'Half',
    italic = false,
    font = wezterm.font {
      family = 'CaskaydiaCove Nerd Font',
      weight = 'DemiBold',
      style = 'Italic',
    },
  },
}

-- Colours / Theme
config.color_scheme = "AlacrittyPort"
config.color_schemes = {
  -- base16_default_dark
  -- https://github.com/alacritty/alacritty-theme/blob/f82c742634b5e840731dd7c609e95231917681a5/themes/base16_default_dark.toml
  ["AlacrittyPort"] = {
    foreground = "#d8d8d8",
    background = "#181818",

    ansi = {
      "#181818", -- black
      "#ab4642", -- red
      "#a1b56c", -- green
      "#f7ca88", -- yellow
      "#7cafc2", -- blue
      "#ba8baf", -- magenta
      "#86c1b9", -- cyan
      "#d8d8d8", -- white
    },

    brights = {
      "#585858", -- black
      "#ab4642", -- red
      "#a1b56c", -- green
      "#f7ca88", -- yellow
      "#7cafc2", -- blue
      "#ba8baf", -- magenta
      "#86c1b9", -- cyan
      "#f8f8f8", -- white
    },

    cursor_bg = "#f8f8f8",
    cursor_fg = "#f8f8f8",
    selection_bg = "#45475a",
    selection_fg = "#cdd6f4",
  },
}

-- Appearance
config.window_decorations = "NONE"
config.enable_tab_bar = false
config.window_background_opacity = 0.85
config.window_padding = {
  left = 0,
  right = 0,
  top = 0,
  bottom = 0,
}
-- This makes the window maximized when launched
wezterm.on('gui-startup', function(cmd)
  local _, _, window = mux.spawn_window(cmd or {})
  window:gui_window():maximize()
end)

-- Mouse
-- Configuration for raw Wezterm, does not apply
-- when zellij is running.
config.mouse_bindings = {
  -- Faster scroll up
  {
    event = { Down = { streak = 1, button = { WheelUp = 1 } } },
    mods = 'NONE',
    action = wezterm.action.ScrollByLine(-6),
    alt_screen = false,
  },
  -- Faster scroll down
  {
    event = { Down = { streak = 1, button = { WheelDown = 1 } } },
    mods = 'NONE',
    action = wezterm.action.ScrollByLine(6),
    alt_screen = false,
  },
}


-- Keybinds
config.keys = {
  -- These are for macOS, not needed on Linux
  -- {
  --   key = 'LeftArrow',
  --   mods = 'SUPER',
  --   action = wezterm.action.SendString('\x1bB'),
  -- },
  -- {
  --   key = 'RightArrow',
  --   mods = 'SUPER',
  --   action = wezterm.action.SendString('\x1bF'),
  -- },

  -- Scroll configuration for raw Wezterm, does not apply
  -- when zellij is running.
  --
  -- Also, it interferes with Zellij intercepting the PgUp/PgDown
  -- keys, so it should not be left uncommented.
  --
  -- But in case I ever move away from Zellij, this is a useful
  -- snippet to remember.
  --
  -- -- Scroll one full screen per press
  -- {
  --   key = 'PageUp',
  --   mods = 'NONE',
  --   action = wezterm.action.ScrollByPage(-1),
  --   alt_screen = false
  -- },
  -- {
  --   key = 'PageDown',
  --   mods = 'NONE',
  --   action = wezterm.action.ScrollByPage(1),
  --   alt_screen = false
  -- },
  --
  -- Turn off some default keybindings which are not needed
  {
    key = 't',
    mods = 'SHIFT|CTRL',
    action = wezterm.action.DisableDefaultAssignment,
  },
  {
    key = 't',
    mods = 'SUPER',
    action = wezterm.action.DisableDefaultAssignment,
  },
  {
    key = 'n',
    mods = 'SUPER',
    action = wezterm.action.DisableDefaultAssignment,
  },
  {
    key = 'w',
    mods = 'SUPER',
    action = wezterm.action.DisableDefaultAssignment,
  },
  {
    key = 'n',
    mods = 'SHIFT|CTRL',
    action = wezterm.action.DisableDefaultAssignment,
  },
}

-- Misc
config.max_fps = 120
config.window_close_confirmation = 'NeverPrompt'
config.enable_wayland = true -- force native Wayland
config.default_prog = {
  nix_paths.zellij,
  "attach",
  "--create",
  "wezterm",
}

-- -----------------------------------------------------

-- Finally, return the configuration to wezterm:
return config
