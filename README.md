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

## Configuration

### Basic Setup

```lua
require("blog").setup({
  blog_dir = "~/my-blog",      -- Where to generate the blog
  posts_dir = "posts",          -- Directory for markdown posts
  date_format = "%Y-%m-%d",     -- Date format in frontmatter
  frontmatter = true,           -- Use YAML frontmatter
})
```

### Custom HTML Templates

You can override the default HTML generation by providing custom functions in your config:

```lua
require("blog").setup({
	blog_dir = vim.fn.expand("~/my-blog"),
  
  -- Custom index page generator
  generate_index_html = function(posts)
    local html = [[<!DOCTYPE html>
<html>
<head>
    <title>My Personal Blog</title>
    <style>
        body { font-family: Georgia, serif; max-width: 800px; margin: 0 auto; padding: 20px; }
        h1 { color: #333; border-bottom: 2px solid #333; }
        .post { margin: 20px 0; padding: 15px; background: #f5f5f5; }
        .post a { color: #0066cc; text-decoration: none; }
        .date { color: #666; font-size: 0.9em; }
    </style>
</head>
<body>
    <h1>Welcome to My Blog</h1>
    <div class="posts">
]]
    
    for _, post in ipairs(posts) do
      html = html .. string.format([[
        <div class="post">
            <h2><a href="%s">%s</a></h2>
            <div class="date">%s</div>
        </div>
]], post.filename, post.title, post.date)
    end
    
    html = html .. [[
    </div>
</body>
</html>]]
    return html
  end,
  
  -- Custom post page generator
  generate_post_html = function(post, body_html)
    return string.format([[<!DOCTYPE html>
<html>
<head>
    <title>%s - My Blog</title>
    <style>
        body { font-family: Georgia, serif; max-width: 800px; margin: 0 auto; padding: 20px; }
        h1 { color: #333; }
        .meta { color: #666; font-style: italic; margin-bottom: 30px; }
        .content { line-height: 1.6; }
        .back { margin-bottom: 20px; }
        .back a { color: #0066cc; text-decoration: none; }
    </style>
</head>
<body>
    <div class="back"><a href="index.html">← Back to all posts</a></div>
    <article>
        <h1>%s</h1>
        <div class="meta">Published on %s</div>
        <div class="content">%s</div>
    </article>
</body>
</html>]], post.title, post.title, post.date, body_html)
  end,
})
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
~/my-blog/
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
