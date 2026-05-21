local lazy_ok, lazy = pcall(require, "lazy")
if lazy_ok then
  lazy.load({ plugins = { "CopilotChat.nvim" } })
end

local constants = require("CopilotChat.constants")
local copilot_chat = require("CopilotChat")

local delay_ms = tonumber(vim.g.copilotchat_stream_math_delay_ms) or 35
local chunk_chars = tonumber(vim.g.copilotchat_stream_math_chunk_chars) or 3

local text = [=[Hello. Below are several path-integral formulas for testing both inline and display math rendering.

Inline formula: a quantum transition amplitude is often written as $\langle q_f,t_f|q_i,t_i\rangle = \int_{q(t_i)=q_i}^{q(t_f)=q_f}\mathcal{D}q\,e^{\frac{i}{\hbar}S[q]}$, where the action is $S[q]=\int_{t_i}^{t_f}L(q,\dot q,t)\,dt$.

Display formulas:

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

Additional examples:

- Free-particle propagator:

$$
K_0(x_f,t_f;x_i,t_i)=\sqrt{\frac{m}{2\pi i\hbar (t_f-t_i)}}\,\exp\left[\frac{i m (x_f-x_i)^2}{2\hbar (t_f-t_i)}\right]
$$

- Wick rotation from real time to imaginary time: $t=-i\tau$, so $e^{\frac{i}{\hbar}S}\to e^{-\frac{1}{\hbar}S_E}$.

- Correlation functions from the generating functional:

$$
\langle \phi(x_1)\phi(x_2)\rangle=\left.\frac{\hbar^2}{i^2 Z[J]}\frac{\delta^2 Z[J]}{\delta J(x_1)\delta J(x_2)}\right|_{J=0}
$$

These examples should be enough to test inline math, display math, boundary-conditioned path integrals, generating functionals, Euclidean path integrals, functional derivatives, propagators, and correlation functions.
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

copilot_chat.open({
  window = {
    layout = "replace",
  },
})
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
