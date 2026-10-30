-- Tmux-style controls for Rex. Appearance remains in Rex's Settings.
local prefix = "ctrl+a>"
local terminal = "com.superlogical.terminal"

local function bind(key, action, args)
  rex.bind(prefix .. key, action, args)
end

bind("ctrl+a", "pane.send_key", { key = "ctrl+a" })
bind("c", "client.tab.new")
bind("n", "client.tab.next")
bind("p", "client.tab.previous")
bind(",", "client.tab.rename")
bind("s", "session.switch")
bind("shift+4", "session.rename")
bind("shift+5", "pane.split.right") -- %
bind("shift+'", "pane.split.down") -- "
bind("z", "pane.zoom")
-- pane.close is unavailable when the tab has only one pane. General Close
-- closes a split pane or, for the last pane, the tab (like tmux kill-pane).
bind("x", "client.close")
bind("shift+7", "client.tab.close") -- &
bind("shift+1", "pane.move_to_new_tab") -- !
bind("o", "pane.focus_next")
bind("=", "pane.balance")
bind("r", "client.config.reload")
bind("shift+/", "client.palette.toggle") -- ?
bind("/", "client.find.open")

for index = 1, 9 do
  bind(tostring(index), "client.tab.goto", { index = index })
end

local directions = {
  { key = "h", direction = "left" },
  { key = "j", direction = "down" },
  { key = "k", direction = "up" },
  { key = "l", direction = "right" },
}

-- Keep navigation inside Vim and nested tmux. The Neovim companion in these
-- dotfiles hands focus back to Rex when a Vim split has no further neighbor.
local function application_handles_navigation(process)
  if not process then
    return true
  end
  local name = (process.name or ""):match("([^/]+)$") or ""
  return name:match("^g?vim") ~= nil
    or name:match("^g?nvim") ~= nil
    or name:match("^g?view") ~= nil
    or name:match("^tmux") ~= nil
end

for _, entry in ipairs(directions) do
  local key, direction = entry.key, entry.direction
  bind(key, "pane.focus", { direction = direction })
  bind(direction, "pane.focus", { direction = direction })
  bind("ctrl+" .. direction, "pane.resize", { direction = direction, amount = 5 })

  rex.bind("ctrl+" .. key, function()
    local process, err = rex.block.call(terminal, "process", {})
    if err or application_handles_navigation(process and process.foreground) then
      return false -- Preserve the original key in the terminal.
    end
    local result, focus_err = rex.session.focus_direction { direction = direction, wrap = true }
    if not result then
      error(focus_err, 0)
    end
    return true
  end)
end

-- A persistent resize mode: Ctrl+A, v; h/j/k/l or arrows; Esc/q/Enter to leave.
rex.mode("resize", { exclusive = true })
bind("v", "client.mode.enter", { name = "resize" })
for _, entry in ipairs(directions) do
  for _, key in ipairs { entry.key, entry.direction } do
    rex.bind("resize/" .. key, "pane.resize", { direction = entry.direction, amount = 5 })
    rex.bind("resize/shift+" .. key, "pane.resize", { direction = entry.direction, amount = 15 })
  end
end
rex.bind("resize/=", "pane.balance")
for _, key in ipairs { "escape", "q", "enter" } do
  rex.bind("resize/" .. key, "client.mode.exit")
end

-- Rex floating layers replace the notes and activity display-popup bindings.
-- The process runs in the focused terminal's directory; exiting closes it.
local function popup(script, bounds)
  local process, process_err = rex.block.call(terminal, "process", {})
  if not process then
    error(process_err, 0)
  end
  local foreground = process.foreground or process.child or {}
  local cwd = foreground.cwd or process.home
  local layer, err = rex.session.new_layer {
    bounds = bounds,
    focus = true,
    layout = rex.layout.block {
      flavor = "com.superlogical.terminal.shell",
      options = {
        shell = "none",
        command = { "/bin/zsh", "-lc", script },
        cwd = cwd,
        exit = { on_completion = true },
      },
    },
  }
  if not layer then
    error(err, 0)
  end
  return layer
end

rex.action {
  name = "project_notes",
  title = "Project Notes",
  description = "Open .local/notes.md in Neovim beside the current terminal.",
  run = function()
    -- Keep this short-lived editor independent of other editors' ShaDa files.
    return popup("mkdir -p .local && exec nvim -i NONE .local/notes.md", { 0.55, 0, 0.45, 1 })
  end,
}
bind("shift+n", "project_notes")

rex.action {
  name = "activity_monitor",
  title = "Activity Monitor",
  description = "Open btop in a floating terminal; q closes it.",
  run = function()
    return popup("exec btop", { 0.04, 0.075, 0.92, 0.85 })
  end,
}
bind("shift+a", "activity_monitor")

-- Tmux copy-mode, tmux-pins, and TPM plugins do not load in Rex.
-- Ctrl+A / opens Rex's native search; regular Cmd+C copies a native selection.
