-- Color-preserving copy viewer. Rendering/wrap handling adapted from rexkit.
-- Copyright (c) 2026 snipeship; MIT license in licenses/rexkit.txt.
-- Runs independently of the user's Neovim configuration.
local cfg = vim.json.decode(vim.env.REX_COPY_SETTINGS or "{}")
local MAX_LINES = 100000
local LARGE = 1024 * 1024
local o = vim.o
o.loadplugins = false
o.termguicolors = true
o.swapfile = false
o.undofile = false
o.shadafile = "NONE"
o.modeline = false
o.clipboard = ""
o.mouse = "a"
o.number = false
o.relativenumber = false
o.signcolumn = "no"
o.foldenable = false
o.cursorline = false
o.scrolloff = 0
o.ignorecase = true
o.smartcase = true
o.incsearch = true
o.hlsearch = true
o.showmode = false
o.showcmd = false
o.ruler = false
o.cmdheight = 0
o.laststatus = 2
o.timeoutlen = 300
o.shortmess = "aoOstTWIcCF"
o.report = 1000000
o.fillchars = "eob: "
o.scrollback = MAX_LINES
-- Keep Rex's background and ANSI palette; reverse video works on light/dark themes.
vim.api.nvim_set_hl(0, "Normal", {})
vim.api.nvim_set_hl(0, "NormalNC", {})
vim.api.nvim_set_hl(0, "StatusLine", { reverse = true })
vim.api.nvim_set_hl(0, "StatusLineNC", { reverse = true })
vim.api.nvim_set_hl(0, "Visual", { reverse = true })
vim.api.nvim_set_hl(0, "Search", { reverse = true })
vim.api.nvim_set_hl(0, "IncSearch", { reverse = true, bold = true })
vim.api.nvim_set_hl(0, "CurSearch", { link = "IncSearch" })

local total, failure, flash = 0, nil, nil
function _G.RexCopyStatus()
  local mode = vim.fn.mode()
  local selecting = mode == "v" or mode == "V" or mode == "\22"
  local title = selecting and " SELECT " or " COPY "
  local hint = selecting and "y/enter copy · esc cancel" or "? search · v select · q close"
  if vim.api.nvim_win_get_width(0) < 55 then hint = selecting and "y copy · esc cancel" or "v select · q close" end
  return title .. (failure or flash or hint):gsub("%%", "%%%%") .. " %=%l/" .. math.max(total, 1) .. " "
end
o.statusline = "%!v:lua.RexCopyStatus()"
local function close() vim.cmd("qa!") end
local function map(lhs, rhs) vim.keymap.set("n", lhs, rhs, { silent = true }) end
map("q", close)
map("<Esc>", close)
map("<C-c>", close)
vim.keymap.set("x", "<CR>", "y")
vim.keymap.set("x", "q", "<Esc>")
map("<CR>", "yy")
map("<Space>", "v")
vim.keymap.set({ "n", "x" }, "G", function()
  return vim.v.count == 0 and (math.max(1, vim.fn.prevnonblank(vim.fn.line("$"))) .. "G") or "G"
end, { expr = true })
-- Never let this read-only terminal picture become an input terminal.
for _, key in ipairs({ "i", "I", "a", "A", "<Insert>" }) do map(key, "<Nop>") end
vim.api.nvim_create_autocmd("TermEnter", {
  callback = function() vim.schedule(function() vim.cmd.stopinsert() end) end,
})

-- Soft wraps ---------------------------------------------------------------
-- A terminal buffer breaks long lines into rows. Copies should not: yanks
-- rejoin rows that continue the row above, found by matching the rows
-- against the capture's own lines (from the bottom, as the terminal may have
-- dropped rows at the top).

local page = "" -- the capture as loaded (after fit)
local logical = nil -- its lines without colours, built on the first copy
local wraps = { tick = -1, rows = {} }

local function strip(line) return (line:gsub("\27%[[%d;:]*m", "")) end

local function lines_of(text)
  local out = {}
  for line in (text .. "\n"):gmatch("(.-)\n") do
    out[#out + 1] = strip(line)
  end
  return out
end

-- continued returns the set of rows that continue the row above.
local function continued()
  local buf = vim.api.nvim_get_current_buf()
  local tick = vim.api.nvim_buf_get_changedtick(buf)
  if wraps.tick == tick then return wraps.rows end
  logical = logical or lines_of(page)
  local rows = vim.api.nvim_buf_get_lines(buf, 0, total, false)
  local cont, r = {}, #rows
  for i = #logical, 1, -1 do
    if r < 1 then break end
    local want, first, text = logical[i], r, rows[r]
    while #text < #want and first > 1 do
      first = first - 1
      text = rows[first] .. text
    end
    if text ~= want then break end -- out of step: trust only what matched
    for k = first + 1, r do cont[k] = true end
    r = first - 1
  end
  wraps = { tick = tick, rows = cont }
  return cont
end

-- rejoin merges the yanked pieces of wrapped lines; first is the row of
-- pieces[1].
local function rejoin(pieces, first)
  local cont, out = continued(), { pieces[1] }
  for i = 2, #pieces do
    if cont[first + i - 1] then
      out[#out] = out[#out] .. pieces[i]
    else
      out[#out + 1] = pieces[i]
    end
  end
  return out
end

vim.api.nvim_create_autocmd("TextYankPost", {
  callback = function()
    local ev = vim.v.event
    if ev.operator ~= "y" then return end
    local lines = vim.deepcopy(ev.regcontents)
    if ev.regtype:sub(1, 1) ~= "\22" then
      lines = rejoin(lines, vim.fn.line("'["))
    end
    if ev.regtype == "V" then lines[#lines + 1] = "" end
    -- OSC 52 reaches the viewing Rex client, including remote sessions.
    require("vim.ui.clipboard.osc52").copy("+")(lines)
    vim.schedule(close)
  end,
})

-- Y copies the whole line under the cursor, however many rows it wraps to.
map("Y", function()
  local cont, first, last = continued(), vim.fn.line("."), vim.fn.line(".")
  while cont[first] do first = first - 1 end
  while cont[last + 1] do last = last + 1 end
  vim.cmd(first .. "," .. last .. "yank")
end)

-- Loading ----------------------------------------------------------------

local function read(path)
  local f, err = io.open(path or "", "rb")
  if not f then return nil, err end
  local data = f:read("a")
  f:close()
  return data
end

-- Row budget ---------------------------------------------------------------
-- 'scrollback' counts terminal rows, not lines: a line wider than the window
-- takes several rows, and the terminal silently drops the oldest rows past
-- the limit. Keep the newest complete lines that fit, and report omitted output.

local function omitted(n, which)
  return "\27[2;3m… " .. n .. (n == 1 and " line" or " lines") .. " of " .. which .. " output not shown\27[m"
end

-- rows_of is how many rows line takes at cols columns, or an upper bound.
local function rows_of(line, cols)
  local text = strip(line)
  if #text <= cols then return 1 end -- never wider than its bytes
  if not text:find("[\128-\255]") then return math.ceil(#text / cols) end
  -- A wide character that does not fit at the end of a row moves to the next
  -- one, so a row may hold one cell less.
  return math.ceil(vim.fn.strdisplaywidth(text) / math.max(1, cols - 1))
end

-- Keep the newest complete logical lines that fit Neovim's row budget.
local function fit(data)
  local cols = math.max(1, vim.api.nvim_win_get_width(0))
  local budget = MAX_LINES - o.lines - 4
  local lines = vim.split(data, "\n", { plain = true })
  local first, used = #lines + 1, 0
  for i = #lines, 1, -1 do
    local rows = rows_of(lines[i], cols)
    if used + rows > budget then break end
    first, used = i, used + rows
  end
  local text = table.concat(lines, "\n", first)
  if first > 1 then text = omitted(first - 1, "older") .. "\n" .. text end
  return text
end

local function keys(seq)
  vim.cmd.normal({ vim.api.nvim_replace_termcodes(seq, true, false, true), bang = true })
end

local function place(start)
  local last = math.max(1, vim.fn.prevnonblank(vim.fn.line("$")))
  total = last
  if start == "top" then
    keys("gg")
    return
  end
  vim.api.nvim_win_set_cursor(0, { last, 0 })
  keys("zb")
  if start == "page-up" then
    keys("<C-b>")
  elseif start == "half-up" then
    keys("<C-u>")
  end
end

local function load()
  local data, err = read(cfg.file)
  if not data then
    failure = "cannot read the capture: " .. tostring(err)
    return
  end
  data = fit((data:gsub("\n$", ""))) -- keep the cursor on the last line, not below it
  page = data
  local buf = vim.api.nvim_get_current_buf()
  local chan = vim.api.nvim_open_term(buf, {})
  vim.bo[buf].scrollback = MAX_LINES
  if data ~= "" then
    if #data > LARGE then
      flash = "loading…" -- the terminal needs ~1 s for 8 MB
      vim.cmd.redraw()
    end
    -- No pty translates line ends here, so send what a terminal expects.
    local crlf, breaks = data:gsub("\n", "\r\n")
    local tick = vim.api.nvim_buf_get_changedtick(buf)
    vim.api.nvim_chan_send(chan, crlf)
    -- The terminal parses the data at once but fills the buffer on its next
    -- refresh; wait for that before placing the cursor.
    local want = math.min(breaks + 1, MAX_LINES)
    vim.wait(5000, function()
      return vim.api.nvim_buf_get_changedtick(buf) ~= tick and vim.api.nvim_buf_line_count(buf) >= want
    end, 5)
    flash = nil
  end
  place(cfg.start)
  vim.api.nvim_exec_autocmds("User", { pattern = "RexCopyLoaded" })
end

vim.api.nvim_create_autocmd("VimEnter", { once = true, callback = load })
