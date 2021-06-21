local infoview = require('lean.infoview')
local get_num_wins = function() return #vim.api.nvim_list_wins() end

require('tests.helpers').setup {
  infoview = { enable = true },
  lsp = { enable = true },
  lsp3 = { enable = true },
}
describe('infoview', function()
  local win = vim.api.nvim_get_current_win()

  vim.api.nvim_command("edit lua/tests/fixtures/example-lean3-project/test.lean")

  local infoview_info = infoview.open()

  describe('initial', function()
    it('closes',
    function(_)
      local num_wins = get_num_wins()
      infoview.close()
      assert.is_false(vim.api.nvim_win_is_valid(infoview_info.window))
      assert.is.equal(num_wins - 1, get_num_wins())
    end)

    it('remains closed on BufWinEnter',
    function(_)
      local num_wins = get_num_wins()
      vim.api.nvim_command("edit lua/tests/fixtures/example-lean3-project/test/test1.lean")
      assert.is.equal(num_wins, get_num_wins())
    end)

    it('opens',
    function(_)
      local num_wins = get_num_wins()
      infoview_info = infoview.open()
      assert.is_true(vim.api.nvim_win_is_valid(infoview_info.window))
      assert.is.equal(num_wins + 1, get_num_wins())
    end)

    it('remains open on BufWinEnter',
    function(_)
      local num_wins = get_num_wins()
      vim.api.nvim_command("edit lua/tests/fixtures/example-lean3-project/test/test1.lean")
      assert.is_true(vim.api.nvim_win_is_valid(infoview_info.window))
      assert.is.equal(num_wins, get_num_wins())
    end)

    it('can be manually quit',
    function(_)
      local num_wins = get_num_wins()
      vim.api.nvim_set_current_win(infoview_info.window)
      vim.api.nvim_command("quit")
      assert.is_false(vim.api.nvim_win_is_valid(infoview_info.window))
      assert.is.equal(num_wins - 1, get_num_wins())
      assert.is.equal(win, vim.api.nvim_get_current_win())
    end)

    it('can be manually closed',
    function(_)
      infoview_info = infoview.open()
      local num_wins = get_num_wins()
      vim.api.nvim_set_current_win(infoview_info.window)
      vim.api.nvim_command("close")
      assert.is_false(vim.api.nvim_win_is_valid(infoview_info.window))
      assert.is.equal(num_wins - 1, get_num_wins())
      assert.is.equal(win, vim.api.nvim_get_current_win())
    end)
  end)

  infoview_info = infoview.open()

  vim.api.nvim_command("tabedit lua/tests/fixtures/example-lean4-project/Test.lean")

  local new_win = vim.api.nvim_get_current_win()
  local new_infoview_info = infoview.open()

  describe('new tab', function()
    it('closes independently',
    function(_)
      local num_wins = get_num_wins()
      infoview.close()
      assert.is_true(vim.api.nvim_win_is_valid(infoview_info.window))
      assert.is_false(vim.api.nvim_win_is_valid(new_infoview_info.window))
      assert.is.equal(num_wins - 1, get_num_wins())
    end)

    it('remains closed on BufWinEnter',
    function(_)
      local num_wins = get_num_wins()
      vim.api.nvim_command("edit lua/tests/fixtures/example-lean4-project/Test/Test1.lean")
      assert.is.equal(num_wins, get_num_wins())
    end)

    it('opens independently',
    function(_)
      vim.api.nvim_set_current_win(win)
      infoview.close()
      vim.api.nvim_set_current_win(new_win)
      local num_wins = get_num_wins()
      new_infoview_info = infoview.open()
      assert.is_false(vim.api.nvim_win_is_valid(infoview_info.window))
      assert.is_true(vim.api.nvim_win_is_valid(new_infoview_info.window))
      assert.is.equal(num_wins + 1, get_num_wins())
    end)

    it('remains open on BufWinEnter',
    function(_)
      local num_wins = get_num_wins()
      vim.api.nvim_command("edit lua/tests/fixtures/example-lean4-project/Test/Test1.lean")
      assert.is_true(vim.api.nvim_win_is_valid(new_infoview_info.window))
      assert.is.equal(num_wins, get_num_wins())
    end)
  end)
end)
