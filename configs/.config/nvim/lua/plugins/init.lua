vim.cmd("packadd vim-jetpack")

require("jetpack.paq")({
  { "tani/vim-jetpack" },
  -- color scheme
  {
    "haishanh/night-owl.vim",
    event = { "VimEnter", "ColorSchemePre" },
    config = function()
      require("plugins.night-owl")
    end,
  },
})
