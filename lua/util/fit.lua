local M = {}

---@class WorkoutTable
---@field weight number
---@field reps number
---@field sets number

-- Helper function to split a string by a delimiter
--- @param input string
--- @param delimiter string
--- @return table
local function split(input, delimiter)
  local result = {}
  for match in (input .. delimiter):gmatch("(.-)" .. delimiter) do
    table.insert(result, match)
  end
  return result
end

-- Function to extract numbers from a string
--- @param s string
local function extract_numbers(s)
  local numbers = {}
  for num in s:gmatch("%d+") do
    table.insert(numbers, tonumber(num))
  end
  return numbers
end

-- Function to parse the input line and generate table collections
--- @param input_line string
--- @return table WorkoutTable[]
function M.generate_working_tables(input_line)
  -- Split the input line into parts
  input_line = input_line:gsub("，", ",")
  local parts = split(input_line, "|")
  if #parts < 3 then
    error("Invalid input format: not enough parts")
  end

  for i, part in ipairs(parts) do
    parts[i] = part:match("^%s*(.-)%s*$")
  end

  -- Check for empty values in weights and reps_sets
  if not parts[3] or parts[3] == "" then
    error("Invalid input format: weights are missing")
  end
  if not parts[4] or parts[4] == "" then
    error("Invalid input format: reps and sets are missing")
  end

  -- Extract weights and repetitions
  local weights = split(parts[3], ",")
  local reps_sets = split(parts[4], "，")

  local tables = {}
  local numbers = extract_numbers(reps_sets[1])
  for i = 1, #weights do
    local weight = weights[i]:match("^%s*(.-)%s*$"):gsub("kg", "")
    local reps = numbers[2 * i - 1]
    local sets = numbers[2 * i]

    -- Check for empty or invalid values
    if not weight or weight == "" then
      error("Invalid input format: weight is missing for one of the entries")
    end
    if not reps or not sets then
      error("Invalid input format: reps or sets are missing for one of the entries")
    end

    table.insert(tables, { weight = tonumber(weight), reps = reps, sets = sets })
  end

  return tables
end

--- Function calculate the total volume of the workout
--- @param tables WorkoutTable[]
--- @return number
function M.calculate_total_volume(tables)
  local total_volume = 0
  for _, table in ipairs(tables) do
    total_volume = total_volume + table.weight * table.reps * table.sets
  end
  return total_volume
end

return M
