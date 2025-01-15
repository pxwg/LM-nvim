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
  local handle = io.popen("pmset -g batt")
  if handle then
    local result = handle:read("*a")
    handle:close()
    if result then
      local percentage = result:match("(%d?%d?%d)%%")
      if result:match("discharging") then
        return { percentage, "discharging" }
      elseif result:match("charging") then
        return { percentage, "charging" }
      elseif result:match("charged") then
        return { percentage, "charged" }
      elseif result:match("finishing charge") then
        return { percentage, "charged" }
      end
    end
  end
  -- print("Battery status: N/A") -- Debug print
  return "N/A"
end

M.get_battery_icon = function()
  local battery_level = tonumber(M.get_battery_status()[1])
  local battery_status = M.get_battery_status()[2]
  if not battery_level then
    return "󰁺󱐋"
  elseif battery_level == 100 then
    return "󰁹" .. (battery_status ~= "discharging" and "󱐋" or "")
  elseif battery_level >= 80 then
    return "󰂁" .. (battery_status ~= "discharging" and "󱐋" or "")
  elseif battery_level >= 60 then
    return "󰁿" .. (battery_status ~= "discharging" and "󱐋" or "")
  elseif battery_level >= 40 then
    return "󰁽" .. (battery_status ~= "discharging" and "󱐋" or "")
  elseif battery_level >= 20 then
    return "󰁻" .. (battery_status ~= "discharging" and "󱐋" or "")
  elseif battery_level <= 10 then
    return "󰁺󱐋"
  else
    return "󰁺󱐋"
  end
end

return M
