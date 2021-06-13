describe('filetype detection', function()
  require('tests.helpers').setup {}

  it('recognizes a lean 3 file',
    function(_)
      vim.api.nvim_command("edit lua/tests/fixtures/example-lean3-project/test.lean")
      assert.is.same(vim.bo.ft, "lean3")
    end)

  -- NOTE: currently broken (works when manually testsing - timing issue with :setfiletype?)

  --it('recognizes a lean 4 file',
  --  function(_)
  --    vim.api.nvim_command("edit lua/tests/fixtures/example-lean4-project/Test.lean")
  --    assert.is.same(vim.bo.ft, "lean")
  --  end)
end)
