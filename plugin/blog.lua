if vim.fn.has("nvim-0.7.0") == 0 then
  vim.api.nvim_err_writeln("blog.nvim requires at least nvim-0.7.0")
  return
end

if vim.g.loaded_blog then
  return
end
vim.g.loaded_blog = true

vim.api.nvim_create_user_command("BlogNew", function(opts)
  require("blog").new_post(opts.args)
end, { nargs = "?" })

vim.api.nvim_create_user_command("BlogList", function()
  require("blog").list_posts()
end, {})

vim.api.nvim_create_user_command("BlogBuild", function()
  require("blog").build()
end, {})