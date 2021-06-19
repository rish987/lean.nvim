local helpers = require('tests.helpers')

local function try_lsp_req(pos, method)
  vim.api.nvim_win_set_cursor(0, pos)
  local params = vim.lsp.util.make_position_params()

  local req_result
  local success, _ = vim.wait(10000, function()
    local results = vim.lsp.buf_request_sync(0, method, params)
    if results[1] and results[1] == nil then return false end

    for _, result in pairs(results) do
      req_result = result.result
    end
    if req_result then return true end

    return false
  end, 1000)

  return success and req_result
end

describe('basic lsp', function()
  helpers.setup {
    lsp = { enable = true },
    lsp3 = { enable = true },
  }
  it('lean 3', function()
    vim.api.nvim_command("edit lua/tests/fixtures/example-lean3-project/test.lean")
    helpers.wait_for_ready_lsp()
    vim.wait(6000)

    it('hover', function()
      local result = try_lsp_req({3, 20}, "textDocument/hover")
      assert.message("hover request failed").is_truthy(result)
      assert.is_not_nil(result.contents)
      assert.are_equal(type(result.contents), "table")
      local lines = {}
      for _, contents in ipairs(result.contents) do
        if contents.language == 'lean' then
          vim.list_extend(lines, {contents.value})
        end
      end
      local text = table.concat(lines, "\n")
      assert.has_all(text, {"test : ℕ"})
    end)
    it('definition', function()
      local result = try_lsp_req({3, 20}, "textDocument/definition")
      assert.message("definition request failed").is_truthy(result)
      assert.is_not_nil(result[1])
      assert.is_not_nil(result[1].uri)
      local text = result[1].uri
      assert.has_all(text, {"tests/fixtures/example-lean3-project/test/test1.lean"})
    end)
  end)

  it('lean 4', function()
    vim.api.nvim_command("edit lua/tests/fixtures/example-lean4-project/Test.lean")
    helpers.wait_for_ready_lsp()
    vim.wait(6000)

    it('hover', function()
      local result = try_lsp_req({3, 20}, "textDocument/hover")
      assert.message("hover request failed").is_truthy(result)
      assert.is_not_nil(result.contents)
      assert.is_not_nil(result.contents.value)
      local text = result.contents.value
      assert.has_all(text, {"test : Nat"})
    end)

    it('definition', function()
      local result = try_lsp_req({3, 20}, "textDocument/definition")
      assert.message("definition request failed").is_truthy(result)
      assert.is_not_nil(result[1])
      assert.is_not_nil(result[1].targetUri)
      local text = result[1].targetUri:lower()
      -- case-insensitive because MacOS FS is case-insensitive
      assert.has_all(text, {("tests/fixtures/example-lean4-project/Test/Test1.lean"):lower()})
    end)
  end)
end)
