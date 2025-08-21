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
    <script src="https://cdn.tailwindcss.com"></script>
</head>
<body class="bg-gray-50 text-gray-900 font-sans leading-relaxed">
    <div class="max-w-3xl mx-auto px-6 py-8">
        <h1 class="text-4xl font-bold mb-8 pb-4 border-b-2 border-gray-900">My Blog</h1>
        <ul class="space-y-6">
]]

  for _, post in ipairs(posts) do
    index_html = index_html .. string.format([[
        <li class="bg-white rounded-lg p-6 shadow-sm border border-gray-200 hover:shadow-md transition-shadow">
            <div class="text-xl font-semibold mb-2">
                <a href="%s" class="text-gray-900 hover:text-blue-600 transition-colors">%s</a>
            </div>
            <div class="text-gray-600 text-sm">%s</div>
        </li>
]], post.filename, post.title, post.date)
  end

  index_html = index_html .. [[
        </ul>
    </div>
</body>
</html>]]

  vim.fn.writefile(vim.split(index_html, "\n"), blog_dir .. "/index.html")

  local post_template = [[<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>%s</title>
    <script src="https://cdn.tailwindcss.com"></script>
</head>
<body class="bg-gray-50 text-gray-900 font-sans leading-relaxed">
    <div class="max-w-3xl mx-auto px-6 py-8">
        <div class="mb-6">
            <a href="index.html" class="text-blue-600 hover:text-blue-700 transition-colors">← Back to posts</a>
        </div>
        <article class="bg-white rounded-lg p-8 shadow-sm border border-gray-200">
            <h1 class="text-4xl font-bold mb-4">%s</h1>
            <div class="text-gray-600 text-sm mb-8 pb-4 border-b border-gray-200">%s</div>
            <div class="prose prose-gray max-w-none">
                %s
            </div>
        </article>
    </div>
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