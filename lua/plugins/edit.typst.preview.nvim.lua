local function get_open_cmd()
  if vim.fn.has("mac") == 1 then
    return "kitten"
  elseif vim.fn.has("linux") then
    return "mac kitten"
  end
end

return {
  "chomosuke/typst-preview.nvim",
  ft = "typst",
  priority = 1000,
  version = "1.*",
  opts = {
    -- port = 56000,
    -- debug = true,
    open_cmd = get_open_cmd()
      .. " @ --to unix:/tmp/mykitty launch --type window --title TypstPreview --dont-take-focus awrit %s",
    extra_args = {
      "--input=preview=true",
    },
    dependencies_bin = {
      ["tinymist"] = "tinymist",
      ["websocat"] = "websocat",
    },
    get_root = function(_)
      return vim.fn.getcwd()
    end,
    -- [新增 1] 强制所有预览都编译 index.typ
    get_main_file = function(path)
      return vim.fn.getcwd() .. "/index.typ"
    end,
  },
  -- [新增 2] 使用 config 函数添加自动命令
  config = function(_, opts)
    -- 手动调用 setup
    require("typst-preview").setup(opts)

    -- 添加 Autocmd：切换 Buffer 时更新 focus.json
    vim.api.nvim_create_autocmd("BufEnter", {
      -- 仅监听 note 目录下的 typ 文件 (根据你的 ZK 结构调整)
      pattern = "*/note/*.typ",
      callback = function(ev)
        local root = vim.fn.expand("~/wiki/")
        -- 获取文件名作为 ID (例如 2602181239.typ -> 2602181239)
        local filename = vim.fn.fnamemodify(ev.file, ":t")
        local id = filename:gsub("%.typ$", "")

        -- 写入 focus.json
        local focus_file = root .. "/focus.json"
        local f = io.open(focus_file, "w")
        if f then
          f:write('{"focus": "' .. id .. '"}')
          f:close()
        end
      end,
    })
  end,
}
