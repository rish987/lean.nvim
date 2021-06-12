local M = {}

local find_project_root = require('lspconfig.util').root_pattern('leanpkg.toml')

-- Ideally this obviously would use a TOML parser but yeah choosing to
-- do nasty things and not add the dependency for now.
local _MARKER = '.*lean_version.*\".*:3.*'

function M.init3()
  pcall(vim.cmd, 'TSBufDisable highlight')  -- tree-sitter-lean is lean4-only
  vim.b.lean3 = true
end

function M.detect()
  vim.bo.ft = "lean"
  local project_root = find_project_root(vim.api.nvim_buf_get_name(0))
  if project_root then
    local result = vim.fn.readfile(project_root .. '/leanpkg.toml')
    for _, line in ipairs(result) do
      if line:match(_MARKER) then vim.bo.ft = "lean3" end
    end
  end
  if vim.bo.ft == "lean3" then M.init3() end
end

return M
