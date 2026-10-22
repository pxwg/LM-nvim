local M = {}
local methods = {
  ['textDocument/definition'] = true,
  ['textDocument/references'] = true,
}

local function is_preferred(client, method)
  return client.name == 'wiki-ocaml'
    or (client.name == 'zettyp-lsp' and method == 'textDocument/definition')
end

local function has_locations(result)
  return type(result) == 'table' and next(result) ~= nil
end

function M.filter(results, method)
  method = method or 'textDocument/definition'
  local preferred = {}
  for id, response in pairs(results) do
    local client = vim.lsp.get_client_by_id(id)
    if client and is_preferred(client, method) and not response.err and has_locations(response.result) then
      preferred[id] = response
    end
  end
  return next(preferred) and preferred or results
end

function M.setup()
  if M._setup then return end
  M._setup = true
  local request_all = vim.lsp.buf_request_all
  vim.lsp.buf_request_all = function(bufnr, request_method, params, handler)
    if not methods[request_method] then
      return request_all(bufnr, request_method, params, handler)
    end
    return request_all(bufnr, request_method, params, function(results, ...)
      return handler(M.filter(results, request_method), ...)
    end)
  end
end

-- Snacks requests clients directly and streams results. Buffer navigation
-- responses until all clients finish so response order cannot affect priority.
function M.setup_snacks()
  local source = require('snacks.picker.source.lsp')
  if M._snacks_setup then return end
  M._snacks_setup = true
  local request = source.request
  source.request = function(buf, request_method, params, cb)
    if not methods[request_method] then
      return request(buf, request_method, params, cb)
    end
    local responses = {}
    local preferred = false
    request(buf, request_method, params, function(client, result, response_params)
      responses[#responses + 1] = { client = client, result = result, params = response_params }
      if is_preferred(client, request_method) and has_locations(result) then
        preferred = true
      end
    end)
    local function replay()
      for _, response in ipairs(responses) do
        if not preferred or is_preferred(response.client, request_method) then
          cb(response.client, response.result, response.params)
        end
      end
    end
    if vim.in_fast_event() then
      local async = assert(require('snacks.picker.util.async').running())
      async:schedule(function()
        if not async:aborted() then replay() end
      end)
    else
      replay()
    end
  end
end

return M
