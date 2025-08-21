local M = {}

M.config = {
  blog_dir = vim.fn.expand("~/blog"),
  posts_dir = "posts",
  date_format = "%Y-%m-%d",
  frontmatter = true,
}

local function ensure_dir(path)
  if vim.fn.isdirectory(path) == 0 then
    vim.fn.mkdir(path, "p")
  end
end

function M.setup(opts)
  M.config = vim.tbl_deep_extend("force", M.config, opts or {})
  ensure_dir(M.config.blog_dir)
  ensure_dir(M.config.blog_dir .. "/" .. M.config.posts_dir)
end

function M.new_post(title)
  if not title or title == "" then
    title = vim.fn.input("Post title: ")
    if title == "" then
      vim.notify("Post title required", vim.log.levels.ERROR)
      return
    end
  end

  local date = os.date(M.config.date_format)
  local filename = date .. "-" .. title:lower():gsub("%s+", "-"):gsub("[^%w%-]", "") .. ".md"
  local filepath = M.config.blog_dir .. "/" .. M.config.posts_dir .. "/" .. filename

  if vim.fn.filereadable(filepath) == 1 then
    vim.notify("Post already exists: " .. filename, vim.log.levels.WARN)
    vim.cmd("edit " .. filepath)
    return
  end

  local content = {}
  if M.config.frontmatter then
    table.insert(content, "---")
    table.insert(content, "title: " .. title)
    table.insert(content, "date: " .. os.date("%Y-%m-%d %H:%M:%S"))
    table.insert(content, "draft: false")
    table.insert(content, "---")
    table.insert(content, "")
  end
  table.insert(content, "# " .. title)
  table.insert(content, "")

  vim.fn.writefile(content, filepath)
  vim.cmd("edit " .. filepath)
  vim.notify("Created new post: " .. filename, vim.log.levels.INFO)
end

function M.list_posts()
  local posts_path = M.config.blog_dir .. "/" .. M.config.posts_dir
  local files = vim.fn.glob(posts_path .. "/*.md", false, true)
  
  if #files == 0 then
    vim.notify("No posts found", vim.log.levels.INFO)
    return
  end

  local posts = {}
  for _, file in ipairs(files) do
    local filename = vim.fn.fnamemodify(file, ":t")
    local modified = vim.fn.getftime(file)
    table.insert(posts, {
      path = file,
      name = filename,
      modified = modified
    })
  end

  table.sort(posts, function(a, b) return a.modified > b.modified end)

  vim.ui.select(
    posts,
    {
      prompt = "Select post to edit:",
      format_item = function(item)
        local date = os.date("%Y-%m-%d %H:%M", item.modified)
        return string.format("%s (modified: %s)", item.name, date)
      end
    },
    function(choice)
      if choice then
        vim.cmd("edit " .. choice.path)
      end
    end
  )
end

function M.build()
  local blog_dir = M.config.blog_dir
  local posts_dir = blog_dir .. "/" .. M.config.posts_dir
  local files = vim.fn.glob(posts_dir .. "/*.md", false, true)

  if #files == 0 then
    vim.notify("No posts to build", vim.log.levels.WARN)
    return
  end

  local posts = {}
  for _, file in ipairs(files) do
    local content = vim.fn.readfile(file)
    local title = vim.fn.fnamemodify(file, ":t:r")
    local date = ""
    local is_draft = false

    if M.config.frontmatter and content[1] == "---" then
      for i = 2, #content do
        if content[i] == "---" then
          break
        end
        local key, value = content[i]:match("^(%w+):%s*(.+)$")
        if key == "title" then
          title = value
        elseif key == "date" then
          date = value
        elseif key == "draft" and value == "true" then
          is_draft = true
        end
      end
    end

    if not is_draft then
      local filename = vim.fn.fnamemodify(file, ":t")
      local html_name = filename:gsub("%.md$", ".html")
      table.insert(posts, {
        title = title,
        date = date,
        filename = html_name,
        md_file = file
      })
    end
  end

  table.sort(posts, function(a, b) return a.date > b.date end)

  M.generate_html(posts)
  vim.notify("Blog built successfully! " .. #posts .. " posts generated", vim.log.levels.INFO)
end

function M.generate_html(posts)
  local blog_dir = M.config.blog_dir

  local index_html = [[<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>My Blog</title>
    <style>
        body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Oxygen, Ubuntu, Cantarell, sans-serif;
            line-height: 1.6;
            color: #333;
            max-width: 700px;
            margin: 0 auto;
            padding: 20px;
        }
        h1 {
            border-bottom: 2px solid #333;
            padding-bottom: 10px;
        }
        .post-list {
            list-style: none;
            padding: 0;
        }
        .post-item {
            margin-bottom: 20px;
            padding-bottom: 20px;
            border-bottom: 1px solid #eee;
        }
        .post-item:last-child {
            border-bottom: none;
        }
        .post-title {
            font-size: 1.3em;
            margin-bottom: 5px;
        }
        .post-title a {
            color: #333;
            text-decoration: none;
        }
        .post-title a:hover {
            color: #0066cc;
        }
        .post-date {
            color: #666;
            font-size: 0.9em;
        }
    </style>
</head>
<body>
    <h1>My Blog</h1>
    <ul class="post-list">
]]

  for _, post in ipairs(posts) do
    index_html = index_html .. string.format([[
        <li class="post-item">
            <div class="post-title">
                <a href="%s">%s</a>
            </div>
            <div class="post-date">%s</div>
        </li>
]], post.filename, post.title, post.date)
  end

  index_html = index_html .. [[
    </ul>
</body>
</html>]]

  vim.fn.writefile(vim.split(index_html, "\n"), blog_dir .. "/index.html")

  local post_template = [[<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>%s</title>
    <style>
        body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Oxygen, Ubuntu, Cantarell, sans-serif;
            line-height: 1.6;
            color: #333;
            max-width: 700px;
            margin: 0 auto;
            padding: 20px;
        }
        .back-link {
            margin-bottom: 20px;
        }
        .back-link a {
            color: #0066cc;
            text-decoration: none;
        }
        .back-link a:hover {
            text-decoration: underline;
        }
        .post-date {
            color: #666;
            font-size: 0.9em;
            margin-bottom: 20px;
        }
        h1 {
            margin-bottom: 10px;
        }
        pre {
            background: #f4f4f4;
            padding: 15px;
            overflow-x: auto;
            border-radius: 5px;
        }
        code {
            background: #f4f4f4;
            padding: 2px 5px;
            border-radius: 3px;
        }
        blockquote {
            border-left: 4px solid #ddd;
            margin-left: 0;
            padding-left: 20px;
            color: #666;
        }
    </style>
</head>
<body>
    <div class="back-link">
        <a href="index.html">← Back to posts</a>
    </div>
    <article>
        <h1>%s</h1>
        <div class="post-date">%s</div>
        %s
    </article>
</body>
</html>]]

  for _, post in ipairs(posts) do
    local content = vim.fn.readfile(post.md_file)
    local body_start = 1
    
    if M.config.frontmatter and content[1] == "---" then
      for i = 2, #content do
        if content[i] == "---" then
          body_start = i + 1
          break
        end
      end
    end

    local body_lines = {}
    for i = body_start, #content do
      table.insert(body_lines, content[i])
    end
    
    local body_md = table.concat(body_lines, "\n")
    local body_html = M.simple_md_to_html(body_md)
    
    local html = string.format(post_template, post.title, post.title, post.date, body_html)
    local html_path = blog_dir .. "/" .. post.filename
    vim.fn.writefile(vim.split(html, "\n"), html_path)
  end
end

function M.simple_md_to_html(md)
  local html = md
  
  html = html:gsub("&", "&amp;")
  html = html:gsub("<", "&lt;")
  html = html:gsub(">", "&gt;")
  
  html = html:gsub("\n### (.-)\n", "\n<h3>%1</h3>\n")
  html = html:gsub("\n## (.-)\n", "\n<h2>%1</h2>\n")
  html = html:gsub("\n# (.-)\n", "\n<h1>%1</h1>\n")
  
  html = html:gsub("%*%*(.-)%*%*", "<strong>%1</strong>")
  html = html:gsub("%*(.-)%*", "<em>%1</em>")
  
  html = html:gsub("%[([^%]]+)%]%(([^%)]+)%)", '<a href="%2">%1</a>')
  
  html = html:gsub("`([^`]+)`", "<code>%1</code>")
  
  html = html:gsub("\n%* (.-)\n", "\n<li>%1</li>\n")
  html = html:gsub("(<li>.-</li>)", "<ul>%1</ul>")
  
  html = html:gsub("\n\n", "</p>\n<p>")
  html = "<p>" .. html .. "</p>"
  
  html = html:gsub("<p></p>", "")
  html = html:gsub("<p>(<h%d>)", "%1")
  html = html:gsub("(</h%d>)</p>", "%1")
  html = html:gsub("<p>(<ul>)", "%1")
  html = html:gsub("(</ul>)</p>", "%1")
  
  return html
end

return M