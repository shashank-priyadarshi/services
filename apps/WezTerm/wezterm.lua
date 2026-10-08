local wezterm = require 'wezterm'
local act = wezterm.action
local mux = wezterm.mux
local config = wezterm.config_builder()

-- Open the first window in full screen. Spawning the window here, rather
-- than looking it up later, guarantees its GUI window already exists.
wezterm.on('gui-startup', function(cmd)
  local _, _, window = mux.spawn_window(cmd or {})
  window:gui_window():toggle_fullscreen()
end)

-- Use native executables for the platform running WezTerm.
local is_windows = wezterm.target_triple:find('windows') ~= nil
local git_bash = 'C:\\Program Files\\Git\\bin\\bash.exe'
local git_exe
local tmux_exe

local function file_exists(path)
  local file = io.open(path, 'r')

  if file then
    file:close()
    return true
  end

  return false
end

if is_windows then
  git_exe = 'C:\\Program Files\\Git\\cmd\\git.exe'
else
  git_exe = '/usr/bin/git'

  -- WezTerm's GUI does not inherit the login shell's PATH.
  for _, candidate in ipairs({
    '/opt/homebrew/bin/tmux',
    '/usr/local/bin/tmux',
    '/usr/bin/tmux',
  }) do
    if file_exists(candidate) then
      tmux_exe = candidate
      break
    end
  end
end

-- Status-bar colors.
local directory_color = '#7dcfff'
local branch_color = '#bb9af7'
local pomodoro_color = '#ff9e64'
local clock_color = '#c0caf5'

-- Remove the Windows title bar but retain resize borders. On macOS keep
-- the title bar so native full screen can reveal it (with the traffic
-- light buttons) when the pointer reaches the top of the screen.
if is_windows then
  config.window_decorations = 'RESIZE'
else
  config.window_decorations = 'TITLE | RESIZE'
end

-- On macOS, use native full screen so content starts below the notch and
-- menu bar instead of being drawn underneath them. Ignored elsewhere.
config.native_macos_fullscreen_mode = true

-- Bottom status bar.
config.enable_tab_bar = true
config.tab_bar_at_bottom = true
config.use_fancy_tab_bar = false
config.hide_tab_bar_if_only_one_tab = false

-- Hide tab titles such as "1: bash.exe" but retain status areas.
config.show_tabs_in_tab_bar = false
config.show_new_tab_button_in_tab_bar = false

-- Update once per second for the Pomodoro timer.
config.status_update_interval = 1000

-- Start Git Bash on Windows; use the platform's normal shell elsewhere.
if is_windows then
  config.default_prog = {
    git_bash,
    '--login',
    '-i',
  }
end

config.default_cwd = wezterm.home_dir

-- Normalize Windows, URI, and Git Bash paths.
local function normalize_path(path)
  path = path or ''
  path = path:gsub('\\', '/')

  -- /C:/Users/... -> C:/Users/...
  path = path:gsub('^/([A-Za-z]:/)', '%1')

  -- /c/Users/... -> C:/Users/...
  path = path:gsub(
    '^/([A-Za-z])/(.*)$',
    function(drive, rest)
      return drive:upper() .. ':/' .. rest
    end
  )

  -- Remove trailing slashes except from drive roots such as C:/.
  if not path:match('^[A-Za-z]:/$') and path ~= '/' then
    path = path:gsub('/+$', '')
  end

  return path
end

-- When the pane runs a tmux client, WezTerm only sees the client's own
-- directory. Ask tmux for the active pane's directory of the client
-- attached to this pane's tty instead.
local function tmux_cwd(pane)
  if not tmux_exe then
    return nil
  end

  local process = pane:get_foreground_process_name() or ''

  if not process:match('tmux$') then
    return nil
  end

  local tty = pane:get_tty_name()

  if not tty then
    return nil
  end

  local call_ok, tmux_ok, output = pcall(
    wezterm.run_child_process,
    {
      tmux_exe,
      'display-message',
      '-c',
      tty,
      '-p',
      '#{pane_current_path}',
    }
  )

  if not call_ok or not tmux_ok or not output then
    return nil
  end

  local path = output:match('^([^\r\n]+)')

  if not path or path == '' then
    return nil
  end

  return path
end

-- Convert WezTerm's working-directory URL to a filesystem path.
local function cwd_path(pane)
  local from_tmux = tmux_cwd(pane)

  if from_tmux then
    return normalize_path(from_tmux)
  end

  local cwd = pane:get_current_working_dir()

  if not cwd then
    return ''
  end

  local success, path = pcall(function()
    return cwd.file_path
  end)

  if not success or not path then
    path = tostring(cwd):gsub('^file://[^/]*', '')

    path = path:gsub(
      '%%(%x%x)',
      function(hex)
        return string.char(tonumber(hex, 16))
      end
    )
  end

  return normalize_path(path)
end

-- Return path relative to base, or nil when path is outside base.
local function relative_to(path, base)
  path = normalize_path(path)
  base = normalize_path(base)

  if path == '' or base == '' then
    return nil
  end

  local lower_path = path:lower()
  local lower_base = base:lower()

  if lower_path == lower_base then
    return ''
  end

  if lower_path:sub(1, #lower_base + 1)
    == lower_base .. '/'
  then
    return path:sub(#base + 2)
  end

  return nil
end

-- Obtain the repository/worktree/submodule root and current branch.
local function git_information(cwd)
  if cwd == '' then
    return nil, ''
  end

  local call_ok, git_ok, output = pcall(
    wezterm.run_child_process,
    {
      git_exe,
      '-C',
      cwd,
      'rev-parse',
      '--show-toplevel',
      '--abbrev-ref',
      'HEAD',
    }
  )

  if not call_ok or not git_ok or not output then
    return nil, ''
  end

  local repository, branch =
    output:match('([^\r\n]+)[\r\n]+([^\r\n]+)')

  if not repository then
    return nil, ''
  end

  return normalize_path(repository), branch or ''
end

local home = normalize_path(wezterm.home_dir)

-- Use GOPATH from WezTerm's environment when available.
-- Otherwise use Go's standard default: $HOME/go.
local gopath = os.getenv('GOPATH')

if not gopath or gopath == '' then
  gopath = home .. '/go'
else
  -- On Windows, GOPATH may contain multiple paths separated by semicolons.
  gopath = gopath:match('^[^;]+') or gopath
end

gopath = normalize_path(gopath)
local go_src = normalize_path(gopath .. '/src')

local function format_bottom_path(cwd, repository)
  -- Inside Git, stop at the repository, worktree, or submodule root.
  local path = normalize_path(repository or cwd)

  if path == '' then
    return '[unknown directory]'
  end

  -- Inside GOPATH/src, omit the complete GOPATH/src prefix.
  local go_relative = relative_to(path, go_src)

  if go_relative ~= nil then
    if go_relative == '' then
      return '.'
    end

    return go_relative
  end

  -- Outside GOPATH but within HOME, replace HOME with "~".
  local home_relative = relative_to(path, home)

  if home_relative ~= nil then
    if home_relative == '' then
      return '~'
    end

    return '~/' .. home_relative
  end

  -- Outside HOME, retain the absolute path.
  return path
end

-----------------------------------------------------------------------
-- Pomodoro timer
-----------------------------------------------------------------------

local pomodoro = {
  duration = 25 * 60,
  remaining = 25 * 60,
  running = false,
  ends_at = nil,
  notification_sent = false,
}

local function pomodoro_remaining()
  if not pomodoro.running then
    return pomodoro.remaining
  end

  local remaining = math.max(
    0,
    pomodoro.ends_at - os.time()
  )

  if remaining == 0 then
    pomodoro.running = false
    pomodoro.remaining = 0
    pomodoro.ends_at = nil
  end

  return remaining
end

local function pomodoro_text()
  local remaining = pomodoro_remaining()
  local minutes = math.floor(remaining / 60)
  local seconds = remaining % 60

  local state

  if pomodoro.running then
    state = '>'
  else
    state = '||'
  end

  return string.format(
    'POMO %s %02d:%02d',
    state,
    minutes,
    seconds
  )
end

local function toggle_pomodoro(window)
  if pomodoro.running then
    pomodoro.remaining = pomodoro_remaining()
    pomodoro.running = false
    pomodoro.ends_at = nil

    window:toast_notification(
      'Pomodoro',
      'Timer paused',
      nil,
      3000
    )

    return
  end

  -- Restart at 25 minutes if the previous timer completed.
  if pomodoro.remaining <= 0 then
    pomodoro.remaining = pomodoro.duration
  end

  pomodoro.running = true
  pomodoro.notification_sent = false
  pomodoro.ends_at = os.time() + pomodoro.remaining

  window:toast_notification(
    'Pomodoro',
    'Timer started',
    nil,
    3000
  )
end

local function reset_pomodoro(window)
  pomodoro.running = false
  pomodoro.remaining = pomodoro.duration
  pomodoro.ends_at = nil
  pomodoro.notification_sent = false

  window:toast_notification(
    'Pomodoro',
    'Timer reset to 25 minutes',
    nil,
    3000
  )
end

-----------------------------------------------------------------------
-- Bottom status bar
-----------------------------------------------------------------------

wezterm.on('update-status', function(window, pane)
  local cwd = cwd_path(pane)
  local repository, branch = git_information(cwd)
  local shown_path = format_bottom_path(cwd, repository)
  local remaining = pomodoro_remaining()

  if remaining == 0
    and not pomodoro.notification_sent
  then
    pomodoro.notification_sent = true

    window:toast_notification(
      'Pomodoro complete',
      'The 25-minute work session is complete.',
      nil,
      5000
    )
  end

  -- Directory on the left.
  window:set_left_status(
    wezterm.format {
      'ResetAttributes',
      {
        Foreground = {
          Color = directory_color,
        },
      },
      {
        Attribute = {
          Intensity = 'Bold',
        },
      },
      {
        Text = ' ' .. shown_path .. ' ',
      },
    }
  )

  local right_status = {
    'ResetAttributes',
  }

  -- Git branch.
  if branch ~= '' then
    table.insert(
      right_status,
      {
        Foreground = {
          Color = branch_color,
        },
      }
    )

    table.insert(
      right_status,
      {
        Attribute = {
          Intensity = 'Bold',
        },
      }
    )

    table.insert(
      right_status,
      {
        Text = ' git:' .. branch .. ' ',
      }
    )
  end

  -- Pomodoro timer.
  table.insert(
    right_status,
    {
      Foreground = {
        Color = pomodoro_color,
      },
    }
  )

  table.insert(
    right_status,
    {
      Attribute = {
        Intensity = 'Bold',
      },
    }
  )

  table.insert(
    right_status,
    {
      Text = ' | ' .. pomodoro_text() .. ' ',
    }
  )

  -- Clock.
  table.insert(
    right_status,
    {
      Foreground = {
        Color = clock_color,
      },
    }
  )

  table.insert(
    right_status,
    {
      Attribute = {
        Intensity = 'Normal',
      },
    }
  )

  table.insert(
    right_status,
    {
      Text = ' | ' .. wezterm.strftime('%H:%M') .. ' ',
    }
  )

  window:set_right_status(
    wezterm.format(right_status)
  )
end)

-----------------------------------------------------------------------
-- Theme selector
-----------------------------------------------------------------------

local function select_theme(window, pane)
  local choices = {}

  for name, _ in pairs(
    wezterm.get_builtin_color_schemes()
  ) do
    choices[#choices + 1] = {
      id = name,
      label = name,
    }
  end

  table.sort(
    choices,
    function(a, b)
      return a.label < b.label
    end
  )

  window:perform_action(
    act.InputSelector {
      title = 'Select WezTerm theme',
      choices = choices,
      fuzzy = true,

      action = wezterm.action_callback(
        function(selected_window, _, id)
          if not id then
            return
          end

          local overrides =
            selected_window:get_config_overrides() or {}

          overrides.color_scheme = id

          selected_window:set_config_overrides(
            overrides
          )
        end
      ),
    },
    pane
  )
end

-----------------------------------------------------------------------
-- Key bindings
-----------------------------------------------------------------------

config.keys = {
  -- Search and switch themes.
  {
    key = 't',
    mods = 'CTRL|ALT',
    action = wezterm.action_callback(select_theme),
  },

  -- Windows-style clipboard paste.
  {
    key = 'v',
    mods = 'CTRL',
    action = act.PasteFrom 'Clipboard',
  },

  -- Start or pause the Pomodoro timer.
  {
    key = 'p',
    mods = 'CTRL|ALT',
    action = wezterm.action_callback(
      function(window, _)
        toggle_pomodoro(window)
      end
    ),
  },

  -- Reset the Pomodoro timer.
  {
    key = 'r',
    mods = 'CTRL|ALT',
    action = wezterm.action_callback(
      function(window, _)
        reset_pomodoro(window)
      end
    ),
  },
}

return config
