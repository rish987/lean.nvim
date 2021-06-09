local M = {_infoviews_wins = {}, _infoviews_tabs = {}, _opts = {}}

local _INFOVIEW_BUF_NAME = 'lean://infoview'
local _DEFAULT_BUF_OPTIONS = {
  bufhidden = 'wipe',
  filetype = 'leaninfo',
  modifiable = false,
}
local _DEFAULT_WIN_OPTIONS = {
  cursorline = false,
  number = false,
  relativenumber = false,
  spell = false,
  wrap = true,
}

local _SEVERITY = {
  [0] = "other",
  [1] = "error",
  [2] = "warning",
  [3] = "information",
  [4] = "hint",
}

-- create autocmds under the specified group and local to
-- the given buffer; clears any existing autocmds
-- from the buffer beforehand
local function set_autocmds_guard(group, autocmds, bufnum)
  local buffer_string = bufnum == 0 and "<buffer>"
    or string.format("<buffer=%d>", bufnum)

  vim.api.nvim_exec(string.format([[
    augroup %s
      autocmd! %s * %s
      %s
    augroup END
  ]], group, group, buffer_string, autocmds), false)
end

local function _infoviews()
  if M._opts.one_per_tab then return M._infoviews_tabs end
  return M._infoviews_wins
end

local function infoviews(src_idx) return _infoviews()[src_idx] end

-- get infoview index (either window number or tabpage depending on per-win/per-tab mode)
local function get_idx()
  return M._opts.one_per_tab and vim.api.nvim_get_current_tabpage() or vim.api.nvim_get_current_win()
end

local function open_win(infoview)
  if not infoview.data then
    infoview.data = {}
    local infoview_bufnr = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_set_name(infoview_bufnr, _INFOVIEW_BUF_NAME .. infoview_bufnr)
    for name, value in pairs(_DEFAULT_BUF_OPTIONS) do
      vim.api.nvim_buf_set_option(infoview_bufnr, name, value)
    end

    local current_window = vim.api.nvim_get_current_win()
    local current_tab = vim.api.nvim_get_current_tabpage()

    if M._opts.one_per_tab then
      vim.cmd "botright vsplit"
    else
      vim.cmd "rightbelow vsplit"
    end
    vim.cmd(string.format("buffer %d", infoview_bufnr))

    local window = vim.api.nvim_get_current_win()

    for name, value in pairs(_DEFAULT_WIN_OPTIONS) do
      vim.api.nvim_win_set_option(window, name, value)
    end
    -- This makes the infoview robust to manually being closed by the user
    -- (though they technically shouldn't do this).
    -- It makes sure that the infoview is erased from the table when this happens.
    set_autocmds_guard("LeanInfoViewWindow", string.format([[
      autocmd WinClosed <buffer> lua require'lean.infoview'.close_win_wrapper(%s, %s, false, true)
    ]], current_window, current_tab), 0)
    vim.api.nvim_set_current_win(current_window)

    infoview.data.buf = infoview_bufnr
    infoview.data.win = window
  end
end

-- check is the given index still points to a valid tab/window
local function idx_is_valid(idx)
  return M._opts.one_per_tab and vim.api.nvim_tabpage_is_valid(idx) or vim.api.nvim_win_is_valid(idx)
end

local function refresh_infos()
  for key, infoview in pairs(_infoviews()) do
    -- clear any windows/tabs that have been closed
    if not idx_is_valid(key) then
      _infoviews()[key] = nil
    else
      open_win(infoview)
    end
  end
  for _, infoview in pairs(_infoviews()) do
    if not infoview.data then goto continue end
    local window = infoview.data.win
    local max_width = M._opts.max_width or 79
    if vim.api.nvim_win_get_width(window) > max_width then
      vim.api.nvim_win_set_width(window, max_width)
    end
    ::continue::
  end
end

-- clear window/buffer data, optionally indicating closure
-- i.e. if close = true, then
-- the window will be marked as closed and its display data deleted
-- but if close = false, then
-- the window will have its display data deleted
local function close_win_raw(src_idx, close)
  if not infoviews(src_idx) then return end
  if close then infoviews(src_idx).open = false end

  -- always clear the window/buffer data
  infoviews(src_idx).data = nil
end

-- physically close infoview, optionally indicating closure
local function close_win(src_idx, close)
  if infoviews(src_idx).data then
    vim.api.nvim_win_close(infoviews(src_idx).data.win, true)
  end

  -- NOTE: it seems this isn't necessary since unlisted buffers are deleted automatically?
  --if M._infoviews[src_win].buf then
  --  vim.api.nvim_buf_delete(M._infoviews[src_win].buf, { force = true })
  --end

  close_win_raw(src_idx, close)
end

function M.update()
  local src_idx = get_idx()

  -- TODO: make the default value for 'open' user-configurable
  if not infoviews(src_idx) then
    _infoviews()[src_idx] = { data = nil, open = true }
  end

  refresh_infos()

  local infoview = infoviews(src_idx)

  if infoview.open == false then return end
  local infoview_bufnr = infoview.data.buf

  local _update = vim.bo.ft == "lean3" and require('lean.lean3').update_infoview or function(set_lines)
    local current_buffer = vim.api.nvim_get_current_buf()
    local cursor = vim.api.nvim_win_get_cursor(0)
    local params = vim.lsp.util.make_position_params()
    -- Shift forward by 1, since in vim it's easier to reach word
    -- boundaries in normal mode.
    params.position.character = params.position.character + 1
    return vim.lsp.buf_request(0, "$/lean/plainGoal", params, function(_, _, result)
      local lines = {}

      if type(result) == "table" and result.goals then
        vim.list_extend(lines,
          {#result.goals == 0 and '▶ goals accomplished 🎉' or
            #result.goals == 1 and '▶ 1 goal' or
            string.format('▶ %d goals', #result.goals)})
        for _, each in pairs(result.goals) do
          vim.list_extend(lines, {''})
          vim.list_extend(lines, vim.split(each, '\n', true))
        end
      end

      for _, diag in pairs(vim.lsp.diagnostic.get_line_diagnostics(current_buffer, cursor[0])) do
        local start = diag.range["start"]
        local end_ = diag.range["end"]
        vim.list_extend(lines, {'', string.format('▶ %d:%d-%d:%d: %s:',
          start.line+1, start.character+1, end_.line+1, end_.character+1, _SEVERITY[diag.severity])})
        vim.list_extend(lines, vim.split(diag.message, '\n', true))
      end

      set_lines(lines)
    end)
  end

  return _update(function(lines)
    vim.api.nvim_buf_set_option(infoview_bufnr, 'modifiable', true)
    vim.api.nvim_buf_set_lines(infoview_bufnr, 0, -1, true, lines)
    -- HACK: This shouldn't really do anything, but I think there's a neovim
    --       display bug. See #27 and neovim/neovim#14663. Specifically,
    --       as of NVIM v0.5.0-dev+e0a01bdf7, without this, updating a long
    --       infoview with shorter contents doesn't properly redraw.
    vim.api.nvim_buf_call(infoview_bufnr, vim.fn.winline)
    vim.api.nvim_buf_set_option(infoview_bufnr, 'modifiable', false)
  end)
end

function M.enable(opts)
  M._opts = opts
  if M._opts.one_per_tab == nil then M._opts.one_per_tab = true end
  M.set_autocmds()
end

-- TODO: once neovim implements autocmds in its lua api, we can make
-- the publicly exposed functions used below into local ones

function M.set_autocmds()
  vim.api.nvim_exec(string.format([[
    augroup LeanInfoView
      autocmd!
      autocmd FileType lean3 lua require'lean.infoview'.set_update_autocmds()
      autocmd FileType lean lua require'lean.infoview'.set_update_autocmds()
      autocmd FileType lean3 lua require'lean.infoview'.set_closed_autocmds()
      autocmd FileType lean lua require'lean.infoview'.set_closed_autocmds()
    augroup END
  ]]), false)
end

function M.set_update_autocmds()
  -- guarding is necessary here because I noticed the FileType event being
  -- triggered multiple times for a single file (not sure why)
  set_autocmds_guard("LeanInfoViewUpdate", [[
    autocmd CursorHold <buffer> lua require'lean.infoview'.update()
    autocmd CursorHoldI <buffer> lua require'lean.infoview'.update()
  ]], 0)
end

function M.set_closed_autocmds()
  set_autocmds_guard("LeanInfoViewClose", [[
    autocmd QuitPre <buffer> lua require'lean.infoview'.close_win_wrapper(-1, -1, true, false)
    autocmd WinClosed <buffer> ]] ..
    [[lua require'lean.infoview'.close_win_wrapper(tonumber(vim.fn.expand('<afile>')), -1, false, false)
  ]], 0)
end

function M.close_win_wrapper(src_winnr, src_tabnr, close_info, already_closed)
  if src_winnr == -1 then
    src_winnr = vim.api.nvim_get_current_win()
  end
  if src_tabnr == -1 then
    src_tabnr = vim.api.nvim_win_get_tabpage(src_winnr)
  end
  local src_idx = src_winnr
  if M._opts.one_per_tab then
    src_idx = src_tabnr

    if not already_closed then
      -- do not close infoview if there are remaining lean files
      -- in the tab
      for _, win in pairs(vim.api.nvim_tabpage_list_wins(src_idx)) do
        if win == src_winnr then goto continue end
        local buf = vim.api.nvim_win_get_buf(win)
        local ft =  vim.api.nvim_buf_get_option(buf, "filetype")
        if ft == "lean3" or ft == "lean" then return end
        ::continue::
      end
    end
  end

  if not close_info and not already_closed then
    -- this check is needed since apparently WinClosed can be triggered
    -- multiple times for a single window close?
    if infoviews(src_idx) and infoviews(src_idx).data ~= nil then
      -- remove these autocmds so the infoview can now be closed manually without issue
      set_autocmds_guard("LeanInfoViewWindow", "", infoviews(src_idx).data.buf)
    end
  end

  if close_info then
    -- if closing with :q, close the infoview as well
    close_win(src_idx, false)
  else
    -- if closing with ctrl-W + c, just detach the infoview and leave it there
    close_win_raw(src_idx, false)
  end
end

function M.is_open()
  return infoviews(get_idx()).open ~= false
end

function M.open()
  local src_idx = get_idx()
  infoviews(src_idx).open = true
  return infoviews(src_idx).data
end

function M.set_pertab()
  if M._opts.one_per_tab then return end

  M.close_all(false)

  M._opts.one_per_tab = true

  refresh_infos()
end

function M.set_perwindow()
  if not M._opts.one_per_tab then return end

  M.close_all(false)

  M._opts.one_per_tab = false

  refresh_infos()
end

function M.close_all(close)
  -- close all current infoviews
  for key, _ in pairs(_infoviews()) do
    close_win(key, close)
  end
end

function M.close()
  if not M.is_open() then return end

  close_win(get_idx(), true)

  -- necessary because closing a window can cause others to resize
  refresh_infos()
end

function M.toggle()
  if M.is_open() then M.close() else M.open() end
end

return M
