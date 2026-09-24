return {
  { "neovim/nvim-lspconfig", opts = { servers = {
    clangd = { mason = false, cmd = { "clangd", "--background-index", "--clang-tidy", "--header-insertion=never" } },
  } } },
}
