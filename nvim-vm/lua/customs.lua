-- Conifg diagnostic
vim.diagnostic.config {
  signs = true,
  underline = true,
  virtual_text = true,
  virtual_lines = false,
  update_in_insert = true,
  float = {
    header = false,
    border = 'rounded',
    focusable = true,
  } }

vim.keymap.set('n', '<leader>dp', function()
  vim.diagnostic.open_float({ border = 'rounded' })
end, { noremap = true, silent = true })
