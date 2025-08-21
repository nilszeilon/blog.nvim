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
{
  "nilszeilon/blog.nvim",
  config = function()
    require("blog").setup({
      blog_dir = vim.fn.expand("~/blog"), -- Where to store your blog
      posts_dir = "posts",                    -- Subdirectory for posts
      date_format = "%Y-%m-%d",               -- Date format for filenames
      frontmatter = true,                     -- Use frontmatter in posts
    })
  end
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
