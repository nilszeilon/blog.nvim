# blog.nvim

A minimal Neovim plugin for writing and publishing blogs directly to GitHub Pages.

## Features

- Write blog posts in Markdown without leaving Neovim
- Automatic HTML generation with minimal, clean styling
- GitHub Pages ready output
- Simple post management

## Installation

Using [lazy.nvim](https://github.com/folke/lazy.nvim):

```lua

-- For lazy.nvim users:
return {
	"nilszeilon/blog.nvim",
	lazy = true,
	cmd = { "BlogNew", "BlogList", "BlogBuild" },
	config = function()
		require("blog").setup({
			-- Where your blog files will be stored
			blog_dir = vim.fn.expand("~/nvim-blog"),

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

```

## Usage

### Commands

- `:BlogNew [title]` - Create a new blog post
- `:BlogList` - List and select posts to edit
- `:BlogBuild` - Generate HTML files for GitHub Pages

### Workflow

1. Create a new post:
   ```vim
   :BlogNew My First Post
   ```

2. Write your content in Markdown

3. Build your blog:
   ```vim
   :BlogBuild
   ```

4. Push the blog directory to GitHub and enable Pages

### Blog Structure

```
~/nvim-blog/
├── index.html          # Generated home page
├── posts/              # Your markdown posts
│   ├── 2024-01-15-my-first-post.md
│   └── 2024-01-16-another-post.md
└── *.html              # Generated post pages
```

## GitHub Pages Setup

1. Create a new repository for your blog
2. Run `:BlogBuild` to generate HTML files
3. Push your blog directory to the repository
4. Go to Settings → Pages → Source → Deploy from branch (main, root)
5. Your blog will be live at `https://yourusername.github.io/repository-name/`

## License

MIT
