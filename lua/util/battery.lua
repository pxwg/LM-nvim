local M = {}

M.get_battery_time = function()
  local handle = io.popen("pmset -g batt")
  if handle then
    local result = handle:read("*a")
    handle:close()
    if result then
      if result:match("discharging") then
        local time_remaining = result:match("(%d+:%d+)")
        return time_remaining or "N/A"
      elseif result:match("charging") or result:match("charged") then
        return " "
      elseif result:match("finished charging") then
        return " "
      end
    end
  end
  return " "
end

M.get_battery_status = function()
  local handle = io.popen("pmset -g batt | grep -Eo '[0-9]+%'")
  if handle then
    local result = handle:read("*a")
    handle:close()
    if result then
      return result:match("%d+")
    end
  end
  return "N/A"
end

M.get_battery_icon = function()
  local battery_level = tonumber(M.get_battery_status())
  if not battery_level then
    return "󰁺"
  elseif battery_level == 100 then
    return "󰁹"
  elseif battery_level >= 80 then
    return "󰂁"
  elseif battery_level >= 60 then
    return "󰁿"
  elseif battery_level >= 40 then
    return "󰁽"
  elseif battery_level >= 20 then
    return "󰁻"
  elseif battery_level >= 10 then
    return "󰁺"
  else
    return "󰁺"
  end
end

return M
