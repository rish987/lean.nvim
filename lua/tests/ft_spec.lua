describe('filetype detection', function()
  require('tests.helpers').setup {}

  it('recognizes a lean 3 file',
    function(_)
      vim.api.nvim_command("edit test/lean3/test.lean")
      assert.is.same(vim.bo.ft, "lean3")
    end)

  it('recognizes a lean 4 file',
    function(_)
      vim.api.nvim_command("edit test/lean/Test.lean")
      assert.is.same(vim.bo.ft, "lean")
    end)
end)
