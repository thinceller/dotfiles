-- vim.fn["ddc#custom#patch_global"]({
--   ui = "pum",
--   sources = {
--     "around",
--     "file",
--   },
--   sourceOptions = {
--     ["_"] = {
--       matchers = { "matcher_fuzzy" },
--       sorters = { "sorter_fuzzy" },
--       converters = { "converter_fuzzy" },
--     },
--     around = {
--       mark = "A",
--     },
--     file = {
--       mark = "F",
--       isVolatile = true,
--     },
--   },
--   sourceParams = {
--     around = {
--       maxSize = 100,
--     },
--   },
-- })

vim.cmd([[
  inoremap <silent><expr> <TAB>
   \ pum#visible() ? '<Cmd>call pum#map#insert_relative(+1)<CR>' :
   \ (col('.') <= 1 <Bar><Bar> getline('.')[col('.') - 2] =~# '\s') ?
   \ '<TAB>' : ddc#map#manual_complete()
]])
vim.keymap.set(
  "i",
  "<S-TAB>",
  'pum#visible() ? "<Cmd>call pum#map#insert_relative(-1)<CR>" : "<C-h>"',
  { noremap = true, silent = true, expr = true, replace_keycodes = false }
)
vim.keymap.set("i", "<C-n>", "<Cmd>call pum#map#insert_relative(+1)<CR>", { noremap = true })
vim.keymap.set("i", "<C-p>", "<Cmd>call pum#map#insert_relative(-1)<CR>", { noremap = true })
vim.keymap.set("i", "<C-y>", "<Cmd>call pum#map#confirm()<CR>", { noremap = true })
vim.keymap.set("i", "<C-e>", "<Cmd>call pum#map#cancel()<CR>", { noremap = true })

vim.fn["ddc#enable"]()
