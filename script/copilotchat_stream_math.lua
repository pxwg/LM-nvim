local lazy_ok, lazy = pcall(require, "lazy")
if lazy_ok then
  lazy.load({ plugins = { "CopilotChat.nvim" } })
end

local ok, copilot_chat = pcall(require, "CopilotChat")
if not ok then
  vim.notify("CopilotChat.nvim is not available: " .. tostring(copilot_chat), vim.log.levels.ERROR)
  return
end

local constants = require("CopilotChat.constants")

local delay_ms = tonumber(vim.g.copilotchat_stream_math_delay_ms) or 35
local chunk_chars = tonumber(vim.g.copilotchat_stream_math_chunk_chars) or 3

local text = [=[你好。下面给几个路径积分相关公式，顺便测试行内与展示公式。

行内公式：量子振幅常写作 $\langle q_f,t_f|q_i,t_i\rangle = \int_{q(t_i)=q_i}^{q(t_f)=q_f}\mathcal{D}q\,e^{\frac{i}{\hbar}S[q]}$，其中作用量为 $S[q]=\int_{t_i}^{t_f}L(q,\dot q,t)\,dt$。

展示公式：

$$
Z[J]=\int \mathcal{D}\phi\,\exp\left\{\frac{i}{\hbar}\left(S[\phi]+\int d^dx\,J(x)\phi(x)\right)\right\}
$$

$$
\langle \mathcal{O}[\phi]\rangle=\frac{1}{Z[0]}\int \mathcal{D}\phi\,\mathcal{O}[\phi]\,e^{\frac{i}{\hbar}S[\phi]}
$$

$$
K(x_f,t_f;x_i,t_i)=\int_{x(t_i)=x_i}^{x(t_f)=x_f}\mathcal{D}x(t)\,\exp\left(\frac{i}{\hbar}\int_{t_i}^{t_f}dt\,\left[\frac{m}{2}\dot{x}^2-V(x)\right]\right)
$$

$$
Z_E=\int \mathcal{D}\phi\,e^{-S_E[\phi]/\hbar}
$$

$$
\frac{\delta Z[J]}{\delta J(x)}=\frac{i}{\hbar}\int \mathcal{D}\phi\,\phi(x)\,\exp\left\{\frac{i}{\hbar}\left(S[\phi]+\int d^dy\,J(y)\phi(y)\right)\right\}
$$

这些已经足够测试：行内公式、带边界条件的路径积分、生成泛函、欧氏路径积分和泛函导数。
]=]

local function split_utf8(input, size)
  local chunks = {}
  local current = {}
  local count = 0

  for char in input:gmatch("[%z\1-\127\194-\244][\128-\191]*") do
    table.insert(current, char)
    count = count + 1

    if count >= size then
      table.insert(chunks, table.concat(current))
      current = {}
      count = 0
    end
  end

  if #current > 0 then
    table.insert(chunks, table.concat(current))
  end

  return chunks
end

local chunks = split_utf8(text, chunk_chars)
local state = {
  index = 1,
  streamed = "",
}

copilot_chat.open()
copilot_chat.chat:clear()
copilot_chat.chat:start()

copilot_chat.chat:add_message({
  role = constants.ROLE.ASSISTANT,
  content = "",
})

local function finish()
  copilot_chat.chat:add_message({
    role = constants.ROLE.ASSISTANT,
    content = "\n" .. vim.trim(state.streamed) .. "\n",
  }, true)
  copilot_chat.chat:finish()
  vim.notify("Finished CopilotChat stream math render test", vim.log.levels.INFO)
end

local function tick()
  local chunk = chunks[state.index]
  if not chunk then
    finish()
    return
  end

  state.streamed = state.streamed .. chunk
  copilot_chat.chat:add_message({
    role = constants.ROLE.ASSISTANT,
    content = chunk,
  })

  state.index = state.index + 1
  vim.defer_fn(tick, delay_ms)
end

vim.defer_fn(tick, delay_ms)
