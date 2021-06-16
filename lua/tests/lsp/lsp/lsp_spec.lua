local helpers = require('tests.helpers')

local function lsp_no_error()
  local diagnostics = vim.lsp.diagnostic.get()

  assert.is_equal(0, #diagnostics)
end

local function lsp_test(pos, method, conversion_func, expected)
  vim.api.nvim_win_set_cursor(0, pos)
  local params = vim.lsp.util.make_position_params()

  local buf_result = false

  vim.lsp.buf_request(0, method, params, function(_, _, result)
    --print(vim.inspect(result))
    assert.is_true(type(result) == "table")
    local out = conversion_func(result)
    for _, string in pairs(expected) do
      assert.message( "\nexpected to contain: \n" .. string ..  "\nactual: \n" .. out
      ).is_truthy(out:find(string, nil, true))
    end
    buf_result = true
  end)

  local success, _ = vim.wait(10000, function() return buf_result end)

  assert.is_true(success)
end

describe('lsp', function()
  helpers.setup {
    lsp = { enable = true },
    lsp3 = { enable = true },
  }
  it('lean 3', function()
    vim.api.nvim_command("edit lua/tests/fixtures/example-lean3-project/test.lean")
    helpers.wait_for_ready_lsp()
    vim.wait(5000)

    lsp_no_error()

    it('hover', function()
      lsp_test({3, 20}, "textDocument/hover",
      function(result)
        assert.is_truthy(result.contents)
        local lines = {}
        for _, contents in ipairs(result.contents) do
          if contents.language == 'lean' then
            vim.list_extend(lines, {contents.value})
          end
        end
        return table.concat(lines, "\n")
      end,
      {"test : ℕ"})
    end)
    it('definition', function()
      lsp_test({3, 20}, "textDocument/definition",
      function(result)
        assert.is_truthy(result[1])
        return result[1].uri
      end,
      {"tests/fixtures/example-lean3-project/test/test1.lean"})
    end)
  end)

  it('lean 4', function()
    vim.api.nvim_command("edit lua/tests/fixtures/example-lean4-project/Test.lean")
    helpers.wait_for_ready_lsp()
    vim.wait(5000)

    lsp_no_error()

    it('hover', function()
      lsp_test({3, 20}, "textDocument/hover",
      function(result)
        assert.is_truthy(result.contents)
        return result.contents.value
      end,
      {"test : Nat"})
    end)

    it('definition', function()
      lsp_test({3, 20}, "textDocument/definition",
      function(result)
        assert.is_truthy(result[1])
        return result[1].targetUri:lower()
      end,
      -- case-insensitive because MacOS FS is case-insensitive
      {("tests/fixtures/example-lean4-project/Test/Test1.lean"):lower()})
    end)
  end)

end)
