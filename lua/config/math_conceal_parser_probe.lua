-- Temporary opt-out flight recorder for intermittent nightly parser invalidity.
-- No profiler, no source text capture, no automatic parser repair.
local probe_path = vim.fn.expand("~/math-conceal.nvim/scripts/probes/nightly-parser/probe.lua")

local function start()
  local ok, result = pcall(dofile, probe_path)
  if not ok then
    vim.schedule(function()
      vim.notify("Parser probe could not start: " .. tostring(result), vim.log.levels.WARN)
    end)
    return
  end
  return result
end

local function enabled()
  return vim.g.mc_parser_probe_enabled ~= false and vim.env.MC_PARSER_PROBE ~= "0"
end

vim.api.nvim_create_user_command("MCParserProbeStart", function()
  start()
end, { desc = "Start the nightly parser flight recorder" })

vim.api.nvim_create_user_command("MCParserProbeStatus", function()
  if not _G.MCParserProbe then
    print("Parser probe is not installed")
    return
  end
  print(vim.inspect(MCParserProbe.status()))
end, { desc = "Show parser recorder state and output directory" })

vim.api.nvim_create_user_command("MCParserProbeDump", function()
  if not _G.MCParserProbe then
    print("Parser probe is not installed")
    return
  end
  print(MCParserProbe.dump("manual-lag"))
end, { desc = "Save parser evidence without repairing or restarting" })

vim.api.nvim_create_user_command("MCParserProbeStop", function()
  if _G.MCParserProbe then
    print(vim.inspect(MCParserProbe.stop()))
  end
end, { desc = "Save evidence and remove parser recorder hooks" })

if vim.v.vim_did_enter == 1 then
  if enabled() then
    start()
  end
else
  vim.api.nvim_create_autocmd("VimEnter", {
    group = vim.api.nvim_create_augroup("MCParserProbeAutoStart", { clear = true }),
    once = true,
    callback = function()
      if enabled() then
        start()
      end
    end,
  })
end
