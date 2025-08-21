-- Example configuration for blog.nvim
-- Add this to your Neovim configuration

-- For lazy.nvim users:
return {
  "yourusername/blog.nvim",
  lazy = true,
  cmd = { "BlogNew", "BlogList", "BlogBuild" },
  config = function()
    require("blog").setup({
      -- Where your blog files will be stored
      blog_dir = vim.fn.expand("~/my-blog"),
      
      -- Subdirectory for markdown posts
      posts_dir = "posts",
      
      -- Date format for post filenames
      date_format = "%Y-%m-%d",
      
      -- Whether to use frontmatter (recommended)
      frontmatter = true,
    })
  end,
  keys = {
    { "<leader>bn", "<cmd>BlogNew<cr>", desc = "New blog post" },
    { "<leader>bl", "<cmd>BlogList<cr>", desc = "List blog posts" },
    { "<leader>bb", "<cmd>BlogBuild<cr>", desc = "Build blog" },
  },
}