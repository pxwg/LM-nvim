local map = vim.keymap.set
local cn = require("util.autocorrect")
local fit = require("util.fit")
local nt_file = require("util.note_file_index")

require("util.fast_keymap")

-- windows with hammerspoon function
local function save_and_delete_last_line()
  local ft = vim.bo.filetype
  local cursor_pos = vim.fn.getpos(".") -- 记录光标位置

  if ft == "tex" or ft == "markdown" then
    vim.cmd("w")
    local view = vim.fn.winsaveview()
    vim.api.nvim_buf_set_lines(0, -2, -1, false, {})
    vim.fn.winrestview(view)
    cn.autocorrect()
    vim.cmd("w")
  else
    vim.cmd("w")
  end
  vim.fn.setpos(".", cursor_pos) -- 恢复光标位置
end

local function is_rightmost_window()
  local current_win = vim.api.nvim_get_current_win()
  local current_pos = vim.api.nvim_win_get_position(current_win)[2]
  local max_col = current_pos

  for _, win in ipairs(vim.api.nvim_list_wins()) do
    local pos = vim.api.nvim_win_get_position(win)[2]
    if pos > max_col then
      max_col = pos
    end
  end

  return current_pos == max_col
end

local function is_leftmost_window()
  local current_win = vim.api.nvim_get_current_win()
  local current_pos = vim.api.nvim_win_get_position(current_win)[2]
  local min_col = current_pos

  for _, win in ipairs(vim.api.nvim_list_wins()) do
    local pos = vim.api.nvim_win_get_position(win)[2]
    if pos < min_col then
      min_col = pos
    end
  end

  return current_pos == min_col
end

-- switch to right window
map("n", "<C-l>", function()
  if is_rightmost_window() then
    vim.fn.system("hs -c 'focusNextWindow()'")
  else
    vim.cmd("wincmd l")
  end
end, { noremap = true, silent = true, desc = "Move to right window" })

-- same for left
map("n", "<C-h>", function()
  if is_leftmost_window() then
    vim.fn.system("hs -c 'focusPreviousWindow()'")
  else
    vim.cmd("wincmd h")
  end
end, { noremap = true, silent = true, desc = "Move to left window" })

local function DeleteLastCommandHistory()
  -- Get the current command history
  local history = vim.fn.histget("cmd", -1)

  -- Check if there is a command to delete
  if history ~= "" then
    -- Delete the last command from the history
    vim.fn.histdel("cmd", -1)
  else
  end
end

function ChNeovim()
  if is_leftmost_window() then
    vim.fn.system("hs -c 'focusPreviousWindow()'")
    DeleteLastCommandHistory()
  else
    vim.cmd("wincmd h")
    DeleteLastCommandHistory()
  end
end

function ClNeovim()
  if is_rightmost_window() then
    vim.fn.system("hs -c 'focusPreviousWindow()'")
    DeleteLastCommandHistory()
  else
    vim.cmd("wincmd l")
    DeleteLastCommandHistory()
  end
end

-- move between windows
map("n", "<C-j>", "<C-w>j", { silent = true })
map("n", "<C-k>", "<C-w>k", { silent = true })

--split
map("n", "<C-w>v", "", {
  noremap = true,
  silent = true,
  callback = function()
    vim.cmd("vsplit")
    vim.cmd("wincmd l")
  end,
})

-- move lines
map({ "n", "v" }, "L", "$", { silent = true })
map({ "n", "v" }, "H", "^", { silent = true })
map({ "n", "v" }, "j", "gj", { silent = true })
map({ "n", "v" }, "k", "gk", { silent = true })

--save
map({ "n", "v", "i" }, "<C-s>", function()
  -- save_and_delete_last_line()
  -- vim.cmd("stopinsert")
  if vim.bo.filetype ~= "tex" or vim.bo.filetype ~= "markdown" then
    require("conform").format()
  end
  vim.cmd("w")
  vim.cmd("stopinsert")
end, { noremap = true, silent = true })

--better j but can't be used with esc
-- map("i", "j", 'j<ESC>:lua require("util.fast_keymap").listen_for_key(200, "j")<CR>', { noremap = true, silent = true })

--undo and redo
map({ "n", "i" }, "<C-z>", "<C-o>:undo<CR>", { silent = true })
map({ "n", "i" }, "<C-r>", "<C-o>:redo<CR>", { silent = true })

-- signature_help
map(
  { "n" },
  "<leader>sh",
  "<cmd>lua vim.lsp.buf.signature_help()<CR>",
  { noremap = true, silent = true, desc = "[S]ignature [H]elp" }
)
map(
  { "i" },
  "<C-d>",
  "<cmd>lua vim.lsp.buf.signature_help()<CR>",
  { noremap = true, silent = true, desc = "Show Signature [H]elp" }
)
--- LSP dictionary
map("i", "<C-a>", "<cmd>:lua vim.lsp.buf.hover()<CR>", { noremap = true, silent = true, desc = "Show [D]ictionary" })
-- Lsp-telescope
if vim.g.picker == "telescope" then
  map("n", "gd", "<cmd>Telescope lsp_definitions theme=cursor<cr>", { desc = "Goto [D]efinition" })
  map("n", "gr", "<cmd>Telescope lsp_references theme=cursor<cr>", { desc = "[R]eferences", nowait = true })
  map("n", "gi", "<cmd>Telescope lsp_implementations theme=cursor<cr>", { desc = "Goto [I]mplementation" })
  map("n", "gy", "<cmd>Telescope lsp_type_definitions theme=cursor<cr>", { desc = "Goto T[y]pe Definition" })
end

-- dim
map("n", "<leader>ud", "<cmd>Twilight<cr>", { silent = true, desc = "[D]im" })

--which key
map("n", "<leader>?", ":WhichKey<cr>", { desc = "Buffer Local Keymaps (which-key)" })

-- enter github repo for plugins
require("util.plug_url")
local function set_keymap_if_in_plugins_dir()
  local current_dir = vim.fn.fnamemodify(vim.fn.expand("%:p"), ":h")
  -- local plugins_dir = vim.fn.expand("~/.config/nvim/lua/plugins")
  if current_dir:match("plugins") then
    vim.api.nvim_buf_set_keymap(
      0,
      "n",
      "gB",
      ":lua get_plugin_name()<CR>",
      { noremap = true, silent = true, desc = "[G]o to Plugin Url" }
    )
  end
end

vim.api.nvim_create_autocmd("BufEnter", {
  pattern = "*",
  callback = set_keymap_if_in_plugins_dir,
})

-- Exit insert mode and clear search highlight
map("n", "<ESC>", function()
  vim.cmd("nohlsearch")
end, { noremap = true, silent = true, desc = "Exit insert mode and clear search highlight" })

-- Terminal keymaps
local terminal_keymaps = {
  { "<C-/>", "", "+Open [T]erminal" },
  { "<C-/>t", "<cmd>lua require('util.terminal').open_terminal('t')<CR>", "Open [T] Terminal Float" },
  { "<C-/>j", "<cmd>lua require('util.terminal').open_terminal('j')<CR>", "Open [J] Terminal Float" },
  { "<C-/>l", "<cmd>lua require('util.terminal').open_terminal('l')<CR>", "Open [L] Terminal Float" },
  { "<C-/>k", "<cmd>lua require('util.terminal').open_terminal('k')<CR>", "Open [K] Terminal Float" },
  { "<C-/>h", "<cmd>lua require('util.terminal').open_terminal('h')<CR>", "Open [H] Terminal Float" },
  { "<C-/>J", "<cmd>lua require('util.terminal').open_terminal_split('j')<CR>", "Open [J] Terminal Split" },
  { "<C-/>L", "<cmd>lua require('util.terminal').open_terminal_split('l')<CR>", "Open [L] Terminal Split" },
  { "<C-/>K", "<cmd>lua require('util.terminal').open_terminal_split('k')<CR>", "Open [K] Terminal Split" },
  { "<C-/>H", "<cmd>lua require('util.terminal').open_terminal_split('h')<CR>", "Open [H] Terminal Split" },
}

local terminal_keymaps_space = {
  { "<leader>t", "", "+Open [T]erminal" },
  { "<leader>tt", "<cmd>lua require('util.terminal').open_terminal('t')<CR>", "Open [T] Terminal Float" },
  { "<leader>tj", "<cmd>lua require('util.terminal').open_terminal('j')<CR>", "Open [J] Terminal Float" },
  { "<leader>tl", "<cmd>lua require('util.terminal').open_terminal('l')<CR>", "Open [L] Terminal Float" },
  { "<leader>tk", "<cmd>lua require('util.terminal').open_terminal('k')<CR>", "Open [K] Terminal Float" },
  { "<leader>th", "<cmd>lua require('util.terminal').open_terminal('h')<CR>", "Open [H] Terminal Float" },
  { "<leader>tJ", "<cmd>lua require('util.terminal').open_terminal_split('j')<CR>", "Open [J] Terminal Split" },
  { "<leader>tL", "<cmd>lua require('util.terminal').open_terminal_split('l')<CR>", "Open [L] Terminal Split" },
  { "<leader>tK", "<cmd>lua require('util.terminal').open_terminal_split('k')<CR>", "Open [K] Terminal Split" },
  { "<leader>tH", "<cmd>lua require('util.terminal').open_terminal_split('h')<CR>", "Open [H] Terminal Split" },
}

for _, keymap in ipairs(terminal_keymaps) do
  map("n", keymap[1], keymap[2], { desc = keymap[3], noremap = true, silent = true })
end

for _, keymap in ipairs(terminal_keymaps_space) do
  map("n", keymap[1], keymap[2], { desc = keymap[3], noremap = true, silent = true })
end

require("util.cn_char")

-- debug
map("n", "/", function()
  local success = pcall(function()
    vim.cmd("nunmap n")
  end)
  if not success then
    vim.api.nvim_feedkeys("/", "n", true)
  else
    vim.api.nvim_feedkeys("/", "n", true)
  end
end, { noremap = true, silent = true })

-- jieba_nvim
map({ "x", "n" }, "B", function()
  local success = pcall(function()
    require("jieba_nvim").wordmotion_B()
  end)
  if not success then
    vim.api.nvim_feedkeys("B", "n", true)
  end
end, { noremap = false, silent = true })

map({ "x", "n" }, "b", function()
  local success = pcall(function()
    require("jieba_nvim").wordmotion_b()
  end)
  if not success then
    vim.api.nvim_feedkeys("b", "n", true)
  end
end, { noremap = false, silent = true })

map({ "x", "n" }, "w", function()
  local success = pcall(function()
    require("jieba_nvim").wordmotion_w()
  end)
  if not success then
    vim.api.nvim_feedkeys("w", "n", true)
  end
end, { noremap = false, silent = true })

map({ "x", "n" }, "W", function()
  local success = pcall(function()
    require("jieba_nvim").wordmotion_W()
  end)
  if not success then
    vim.api.nvim_feedkeys("W", "n", true)
  end
end, { noremap = false, silent = true })

map({ "x", "n" }, "E", function()
  local success = pcall(function()
    require("jieba_nvim").wordmotion_E()
  end)
  if not success then
    vim.api.nvim_feedkeys("E", "n", true)
  end
end, { noremap = false, silent = true })

map({ "x", "n" }, "e", function()
  local success = pcall(function()
    require("jieba_nvim").wordmotion_e()
  end)
  if not success then
    vim.api.nvim_feedkeys("e", "n", true)
  end
end, { noremap = false, silent = true })

map({ "x", "n" }, "ge", function()
  local success = pcall(function()
    require("jieba_nvim").wordmotion_ge()
  end)
  if not success then
    vim.api.nvim_feedkeys("ge", "n", true)
  end
end, { noremap = false, silent = true })

map({ "x", "n" }, "gE", function()
  local success = pcall(function()
    require("jieba_nvim").wordmotion_gE()
  end)
  if not success then
    vim.api.nvim_feedkeys("gE", "n", true)
  end
end, { noremap = false, silent = true })

local function jump_forward()
  local current_position = vim.fn.line(".")
  local jump_list = vim.fn.getjumplist()[1]
  local jump_index = vim.fn.getjumplist()[2]

  if jump_index < #jump_list then
    local next_jump = jump_list[jump_index + 1]
    if next_jump.lnum ~= current_position then
      vim.api.nvim_win_set_cursor(0, { next_jump.lnum, next_jump.col })
      vim.fn.setjumplist(jump_index + 1)
    end
  end
end

map("n", "<C-I>", function()
  jump_forward()
end, { noremap = true, silent = true })

map("n", "<leader>nf", function()
  require("util.note_fig").process_markdown_image_link()
end, { noremap = true, silent = true, desc = "[N]ote [F]igure (single)" })

map("n", "<leader>nF", function()
  require("util.note_fig").process_all_markdown_image_links()
end, { noremap = true, silent = true, desc = "[N]ote [F]igures (all)" })

-- workout fit
map("n", "<leader>nv", function()
  local line = vim.api.nvim_get_current_line()

  if line ~= "" then
    local tables = fit.generate_working_tables(line)
    local total_volume = fit.calculate_total_volume(tables)
    print("Total volume: " .. total_volume)
  end
end, { noremap = true, silent = true, desc = "[N]ote [V]olume (single)" })

map("v", "<leader>nV", function()
  local start_line = vim.fn.line("v")
  local end_line = vim.fn.line(".")
  if start_line > end_line then
    start_line, end_line = end_line, start_line
  end

  local lines = vim.api.nvim_buf_get_lines(0, start_line - 1, end_line, false)
  local total_weight = 0

  for _, line in ipairs(lines) do
    if line ~= "" then
      local tables = fit.generate_working_tables(line)
      local line_weight = fit.calculate_total_volume(tables)
      total_weight = total_weight + line_weight
    end
  end
  vim.api.nvim_buf_set_lines(0, end_line + 1, end_line + 1, false, { "Total weight: " .. total_weight })
end, { noremap = true, silent = true, desc = "[N]ote [F]it (selection)" })

map("n", "<leader>nn", function()
  if vim.bo.filetype == "markdown" then
    vim.cmd("wa")
    local spinner_frames = { "⠋", "⠙", "⠹", "⠸", "⠼", "⠴", "⠦", "⠧", "⠇", "⠏" }
    local spinner_index = 1
    local timer = vim.uv.new_timer()
    timer:start(
      0,
      50,
      vim.schedule_wrap(function()
        vim.api.nvim_echo({ { "Building tree... " .. spinner_frames[spinner_index] } }, false, {})
        spinner_index = (spinner_index % #spinner_frames) + 1
      end)
    )
    local path = vim.fn.expand("%:p")
    local name = vim.fn.fnamemodify(path, ":t:r")

    vim.cmd("nohlsearch")
    local start_time = vim.uv.hrtime()

    local chain = require("util.note_node_get_graph").double_chain
    chain.filepath = path
    chain.filename = name

    require("util.note_node_get_graph").show_buffer_inlines_menu({}, math.huge)

    local end_time = vim.loop.hrtime()
    timer:stop()
    timer:close()
    vim.schedule(function()
      vim.api.nvim_echo({ { "Build tree in: " .. ((end_time - start_time) / 1e6) .. " ms" } }, false, {})
    end)
  end
end, { noremap = true, silent = true, desc = "[N]ote [N]ode" })

map("n", "<leader>ni", function()
  if vim.bo.filetype == "markdown" then
    vim.cmd("wa")
    local input = vim.fn.input("Search Level: ")
    local path = vim.fn.expand("%:p")
    local name = vim.fn.fnamemodify(path, ":t:r")

    vim.cmd("nohlsearch")

    local chain = require("util.note_node_get_graph").double_chain
    chain.filepath = path
    chain.filename = name

    local start_time = vim.loop.hrtime() -- Start time in nanoseconds
    require("util.note_telescope").double_chain_insert({}, tonumber(input))

    local end_time = vim.loop.hrtime()
    vim.notify("Build tree in: " .. ((end_time - start_time) / 1e6) .. " ms", vim.log.levels.INFO)
  end
end, { noremap = true, silent = true, desc = "[N]ote [N]ode" })

map("v", "<CR>", function()
  if vim.bo.filetype == "markdown" then
    vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<Esc>", true, false, true), "nx", false)

    local selection_start = vim.fn.getpos("'<")
    local selection_end = vim.fn.getpos("'>")
    local start_line, start_col = selection_start[2], selection_start[3]
    local end_line, end_col = selection_end[2], selection_end[3]
    local lines = vim.api.nvim_buf_get_lines(0, start_line - 1, end_line, false)
    if #lines == 0 then
      return
    elseif #lines == 1 then
      lines[1] = string.sub(lines[1], start_col, end_col)
    else
      lines[1] = string.sub(lines[1], start_col)
      lines[#lines] = string.sub(lines[#lines], 1, end_col)
    end
    local selected_text = table.concat(lines, "\n")
    local filename = selected_text:gsub(" ", "_"):gsub("\\", "") .. ".md"
    local file_path = vim.fn.expand("%:p:h")
    local new_mkdn = "[" .. selected_text .. "]"
    new_mkdn = new_mkdn .. "(./" .. filename .. ")"
    local newline = vim.fn.getline("."):sub(1, start_col - 1) .. new_mkdn .. vim.fn.getline("."):sub(end_col + 1)
    vim.api.nvim_set_current_line(newline)
    local buffer_number = vim.fn.bufnr(vim.fs.joinpath(file_path, filename), true)
    vim.api.nvim_win_set_buf(0, buffer_number)
  end
end)

map("n", "<Tab>", function()
  if vim.bo.filetype == "markdown" then
    local success = require("util.markdown_link").goto_next_link()
    if not success then
      vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<Tab>", true, false, true), "n", true)
    end
  else
    vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<Tab>", true, false, true), "n", true)
  end
end, { noremap = true, silent = true })

map("n", "<S-Tab>", function()
  if vim.bo.filetype == "markdown" then
    local success = require("util.markdown_link").goto_prev_link()
    if not success then
      vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<S-Tab>", true, false, true), "n", true)
    end
  else
    vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<S-Tab>", true, false, true), "n", true)
  end
end, { noremap = true, silent = true })

map("n", "<CR>", function()
  local line = vim.fn.getline(".")
  local col = vim.fn.col(".")
  local link_pattern = "%[.-%]%((.-)%)"

  -- Find markdown link in current line
  local start_idx = 1
  while true do
    local link_start, link_end, link_target = string.find(line, link_pattern, start_idx)
    if not link_start then
      break
    end

    -- Check if cursor is positioned on this link
    if link_start <= col and col <= link_end then
      -- Open URL
      if link_target:match("^https?://") then
        vim.fn.jobstart("open " .. vim.fn.shellescape(link_target))
      else
        local file_path = link_target
        -- Related Path
        if not file_path:match("^[/~]") then
          local current_dir = vim.fn.expand("%:p:h")
          file_path = current_dir .. "/" .. file_path
        end
        vim.cmd("edit " .. vim.fn.fnameescape(file_path))
      end
      break
    end
    start_idx = link_end + 1
  end
end, { desc = "Open markdown links (file or URL)" })

map("n", "<C-x>", function()
  require("util.note_todo").toggle()
end)

-- smart tab for copilot, insertion and completion via luasnip
map("i", "<Tab>", function()
  if vim.fn.pumvisible() == 1 then
    return vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<C-n>", true, false, true), "n", true)
  end
  local success = require("copilot.suggestion").is_visible()
  local jumpable = require("luasnip").jumpable(1)
  -- local regex_match = vim.fn.searchpair("[([{<|“‘《]", "", "[)\\]}>|”’》]", "W") > 0
  if jumpable then
    require("luasnip").jump(1)
  elseif success then
    require("copilot.suggestion").accept_line()
  elseif not success then
    vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<Tab>", true, false, true), "n", true)
  else
    require("copilot.suggestion").accept_line()
  end
end, { noremap = true, silent = true, desc = "Accept Copilot suggestion or insert Tab" })

map("i", "<CR>", function()
  -- if vim.bo.filetype == "markdown" then
  -- return nt_file.new_line_below()
  if vim.bo.filetype == "tex" then
    return require("util.tex_item").insert_item()
  else
    return vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<CR>", true, false, true), "n", true)
  end
end, { noremap = true, silent = true, expr = true })

map("n", "o", function()
  if vim.bo.filetype == "markdown" then
    return nt_file.new_line_below()
  elseif vim.bo.filetype == "tex" then
    require("util.tex_item").insert_item_on_newline(false)
  else
    return vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("o", true, false, true), "n", true)
  end
end)

map("n", "O", function()
  if vim.bo.filetype == "markdown" then
    return nt_file.new_line_above()
  elseif vim.bo.filetype == "tex" then
    require("util.tex_item").insert_item_on_newline(true)
  else
    vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("O", true, false, true), "n", true)
  end
end)

-- keymapping for phonograph.nvim
map("n", "<leader>pp", function()
  vim.cmd("PhonographInsertPdf")
end, { noremap = true, silent = true, desc = "[P]hono [P]df" })
map("n", "<leader>pu", function()
  vim.cmd("PhonographInsertUrl")
end, { noremap = true, silent = true, desc = "[P]hono [U]rl" })
map("n", "<leader>po", function()
  vim.cmd("PhonographOpen")
end, { noremap = true, silent = true, desc = "[P]hono [O]pen" })
map("n", "<C-LeftMouse>", function()
  vim.cmd("PhonographMouseOpen")
end, { noremap = true, silent = true, desc = "[P]hono [O]pen" })
map("n", "<leader>pe", function()
  vim.cmd("PhonographEdit")
end, { noremap = true, silent = true, desc = "[P]hono [U]pdate" })
map("n", "<leader>pr", function()
  vim.cmd("PhonographReview")
end, { noremap = true, silent = true, desc = "[P]hono [R]estore" })
