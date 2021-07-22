local infoview = require('lean.infoview')
local fixtures = require('tests.fixtures')

require('tests.helpers').setup { infoview = { enable = true, autoopen = false, autoclose = true } }
describe('infoview', function()
  describe("autocloses", function()
    describe("when switching to non-lean window", function()
      it('from lean',
        function(_)
          vim.api.nvim_command('edit ' .. fixtures.lean_project.some_existing_file)
          infoview.get_current_infoview():open()
          assert.open_infoview()
          vim.api.nvim_command('edit temp')
          assert.is_not.open_infoview()
      end)

      it('from lean3 ',
        function(_)
          vim.api.nvim_command('edit ' .. fixtures.lean3_project.some_existing_file)
          assert.is_not.open_infoview()
          infoview.get_current_infoview():open()
          assert.open_infoview()
          vim.api.nvim_command('edit temp')
          assert.is_not.open_infoview()
      end)

      it('from multiple splits',
        function(_)
          vim.api.nvim_command('edit ' .. fixtures.lean_project.some_existing_file)
          vim.api.nvim_command('vsplit ' .. fixtures.lean3_project.some_existing_file)
          infoview.get_current_infoview():open()
          assert.open_infoview()
          vim.api.nvim_command('edit temp')
          assert.open_infoview()
          vim.api.nvim_command('wincmd l')
          vim.api.nvim_command('edit temp')
          assert.is_not.open_infoview()
      end)

      it('from multiple splits, same buffer',
        function(_)
          vim.api.nvim_command('edit ' .. fixtures.lean3_project.some_existing_file)
          vim.api.nvim_command('vsplit ' .. fixtures.lean3_project.some_existing_file)
          infoview.get_current_infoview():open()
          assert.open_infoview()
          vim.api.nvim_command('edit temp')
          assert.open_infoview()
          vim.api.nvim_command('wincmd l')
          vim.api.nvim_command('edit temp')
          assert.is_not.open_infoview()
      end)
    end)
    describe("when closing", function()
      vim.api.nvim_command('tabnew')
      vim.api.nvim_command('edit temp')
      vim.api.nvim_command('vsplit')
      it('single window',
        function(_)
          vim.api.nvim_command('edit ' .. fixtures.lean_project.some_existing_file)
          infoview.get_current_infoview():open()
          assert.equals(1, infoview.get_current_infoview().lean_windows.get_count())
          assert.open_infoview()
          vim.api.nvim_command('close')
          assert.equals(0, infoview.get_current_infoview().lean_windows.get_count())
          assert.is_not.open_infoview()
      end)

      vim.api.nvim_command('vsplit')
      it('multiple windows',
        function(_)
          vim.api.nvim_command('edit ' .. fixtures.lean_project.some_existing_file)
          infoview.get_current_infoview():open()
          assert.open_infoview()
          vim.api.nvim_command('vsplit')
          vim.api.nvim_command('edit ' .. fixtures.lean3_project.some_existing_file)
          assert.equals(2, infoview.get_current_infoview().lean_windows.get_count())
          assert.open_infoview()
          vim.api.nvim_command('close')
          assert.equals(1, infoview.get_current_infoview().lean_windows.get_count())
          assert.open_infoview()
          vim.api.nvim_command('close')
          assert.equals(0, infoview.get_current_infoview().lean_windows.get_count())
          assert.is_not.open_infoview()
      end)

      vim.api.nvim_command('vsplit')
      it('multiple windows, non-last externally',
        function(_)
          vim.api.nvim_command('edit ' .. fixtures.lean_project.some_existing_file)
          infoview.get_current_infoview():open()
          assert.open_infoview()
          vim.api.nvim_command('vsplit')
          vim.api.nvim_command('edit ' .. fixtures.lean3_project.some_existing_file)
          assert.equals(2, infoview.get_current_infoview().lean_windows.get_count())
          assert.open_infoview()
          vim.api.nvim_command('2close')
          assert.equals(1, infoview.get_current_infoview().lean_windows.get_count())
          assert.open_infoview()
          vim.api.nvim_command('close')
          assert.equals(0, infoview.get_current_infoview().lean_windows.get_count())
          assert.is_not.open_infoview()
      end)

      vim.api.nvim_command('vsplit')
      it('multiple windows, same buffer',
        function(_)
          vim.api.nvim_command('edit ' .. fixtures.lean_project.some_existing_file)
          infoview.get_current_infoview():open()
          assert.open_infoview()
          vim.api.nvim_command('vsplit')
          vim.api.nvim_command('edit ' .. fixtures.lean_project.some_existing_file)
          assert.open_infoview()
          assert.equals(2, infoview.get_current_infoview().lean_windows.get_count())
          vim.api.nvim_command('close')
          assert.equals(1, infoview.get_current_infoview().lean_windows.get_count())
          assert.open_infoview()
          vim.api.nvim_command('close')
          assert.equals(0, infoview.get_current_infoview().lean_windows.get_count())
          assert.is_not.open_infoview()
      end)
      it('tab\'s last window',
        function(_)
          vim.api.nvim_command('edit ' .. fixtures.lean_project.some_existing_file)
          infoview.get_current_infoview():open()
          assert.open_infoview()
          assert.is.equal(2, #vim.api.nvim_list_tabpages())
          vim.api.nvim_command('close')
          assert.is.equal(1, #vim.api.nvim_list_tabpages())
      end)
    end)
    vim.api.nvim_command('tabnew')
    vim.api.nvim_command('edit temp')
    vim.api.nvim_command('vsplit')
    it("when both closing and switching", function()
      vim.api.nvim_command('edit ' .. fixtures.lean_project.some_existing_file)
      infoview.get_current_infoview():open()
      assert.open_infoview()
      vim.api.nvim_command('vsplit')
      vim.api.nvim_command('edit ' .. fixtures.lean3_project.some_existing_file)
      assert.equals(2, infoview.get_current_infoview().lean_windows.get_count())
      assert.open_infoview()
      vim.api.nvim_command('close')
      assert.equals(1, infoview.get_current_infoview().lean_windows.get_count())
      assert.open_infoview()
      vim.api.nvim_command('edit temp')
      assert.equals(0, infoview.get_current_infoview().lean_windows.get_count())
      assert.is_not.open_infoview()
    end)
    vim.api.nvim_command('tabclose')
  end)
  describe("does not autoclose", function()
    vim.api.nvim_command('tabnew')
    vim.api.nvim_command('edit temp')
    vim.api.nvim_command('vsplit')
    it('when closing single window externally',
      function(_)
        vim.api.nvim_command('edit ' .. fixtures.lean_project.some_existing_file)
        infoview.get_current_infoview():open()
        vim.api.nvim_command('wincmd l')
        assert.equals(1, infoview.get_current_infoview().lean_windows.get_count())
        vim.api.nvim_command('1close')
        assert.open_infoview()
        assert.equals(0, infoview.get_current_infoview().lean_windows.get_count())
    end)
    vim.api.nvim_command('edit temp')

    vim.api.nvim_command('vsplit')
    it('when closing multiple windows externally',
      function(_)
        vim.api.nvim_command('edit ' .. fixtures.lean_project.some_existing_file)
        infoview.get_current_infoview():open()
        vim.api.nvim_command('vsplit')
        vim.api.nvim_command('edit ' .. fixtures.lean3_project.some_existing_file)
        assert.equals(2, infoview.get_current_infoview().lean_windows.get_count())
        vim.api.nvim_command('wincmd l')
        vim.api.nvim_command('wincmd l')
        vim.api.nvim_command('1close')
        assert.equals(1, infoview.get_current_infoview().lean_windows.get_count())
        vim.api.nvim_command('1close')
        assert.open_infoview()
        assert.equals(0, infoview.get_current_infoview().lean_windows.get_count())
    end)

    vim.api.nvim_command('vsplit')
    it('when closing irrelevant window',
      function(_)
        vim.api.nvim_command('edit ' .. fixtures.lean_project.some_existing_file)
        infoview.get_current_infoview():open()
        assert.equals(1, infoview.get_current_infoview().lean_windows.get_count())
        vim.api.nvim_command('2close')
        assert.open_infoview()
        assert.equals(1, infoview.get_current_infoview().lean_windows.get_count())
        vim.api.nvim_command('edit temp')
    end)

    vim.api.nvim_command('vsplit')
    it('when autoclose disabled',
      function(_)
        vim.api.nvim_command('edit ' .. fixtures.lean_project.some_existing_file)
        infoview.get_current_infoview():open()
        infoview.set_autoclose(false)
        assert.equals(1, infoview.get_current_infoview().lean_windows.get_count())
        vim.api.nvim_command('close')
        assert.open_infoview()
        assert.equals(0, infoview.get_current_infoview().lean_windows.get_count())
        vim.api.nvim_command('edit temp')
    end)
  end)

  it('continues to autoclose when autoclose re-enabled',
    function(_)
      vim.api.nvim_command('edit ' .. fixtures.lean_project.some_existing_file)
      infoview.get_current_infoview():open()
      infoview.set_autoclose(true)
      assert.equals(1, infoview.get_current_infoview().lean_windows.get_count())
      vim.api.nvim_command('close')
      assert.is_not.open_infoview()
      assert.equals(0, infoview.get_current_infoview().lean_windows.get_count())
  end)
end)
