-- inkscape_layers_to_fragments.lua
-- Usage:
--   lua inkscape_layers_to_fragments.lua input.svg > output.svg
--   lua inkscape_layers_to_fragments.lua input.svg 0 > output.svg         -- start index (default 0)
--   lua inkscape_layers_to_fragments.lua input.svg 0 fragment > output.svg -- class name (default "fragment")

local input_path = arg[1]
if not input_path then
  io.stderr:write("Usage: lua inkscape_layers_to_fragments.lua input.svg [start_index] [class]\n")
  os.exit(1)
end

local start_index = tonumber(arg[2] or "0") or 0
local fragment_class = arg[3] or "fragment"

local f, err = io.open(input_path, "rb")
if not f then
  io.stderr:write("Error opening file: " .. tostring(err) .. "\n")
  os.exit(1)
end
local svg = f:read("*a")
f:close()

local function has_class(attrs, name)
  local cls = attrs:match('class%s*=%s*"([^"]*)"')
  if not cls then return false end
  for token in cls:gmatch("%S+") do
    if token == name then return true end
  end
  return false
end

local function add_or_append_class(attrs, name)
  if attrs:find('class%s*=') then
    if has_class(attrs, name) then
      return attrs
    end
    return (attrs:gsub('class%s*=%s*"([^"]*)"', function(val)
      if val == "" then
        return 'class="' .. name .. '"'
      else
        return 'class="' .. val .. ' ' .. name .. '"'
      end
    end, 1))
  else
    return attrs .. ' class="' .. name .. '"'
  end
end

local function set_data_index(attrs, n)
  if attrs:find('data%-fragment%-index%s*=') then
    return (attrs:gsub('data%-fragment%-index%s*=%s*"[^"]*"', 'data-fragment-index="' .. tostring(n) .. '"', 1))
  else
    return attrs .. ' data-fragment-index="' .. tostring(n) .. '"'
  end
end

-- First pass: collect all layer <g ...> with their labels and order
local layers = {}
local layer_seq = 0
svg:gsub("<g%s(.-)>", function(attrs)
  if attrs:find('inkscape:groupmode%s*=%s*"layer"') then
    layer_seq = layer_seq + 1
    local label = attrs:match('inkscape:label%s*=%s*"([^"]*)"') or ""
    local num = label:match("(%d+)%s*$") or label:match("(%d+)")
    table.insert(layers, { seq = layer_seq, label = label, num = tonumber(num) })
  end
  return attrs
end)

-- Build mapping from encountered sequence -> assigned fragment index (by label number)
local numbered, unnumbered = {}, {}
for _, it in ipairs(layers) do
  if it.num then table.insert(numbered, it) else table.insert(unnumbered, it) end
end
table.sort(numbered, function(a, b)
  if a.num == b.num then return a.seq < b.seq end
  return a.num < b.num
end)
table.sort(unnumbered, function(a, b) return a.seq < b.seq end)

local ordered = {}
for _, it in ipairs(numbered) do table.insert(ordered, it) end
for _, it in ipairs(unnumbered) do table.insert(ordered, it) end

local seq_to_frag_index = {}
for i, it in ipairs(ordered) do
  seq_to_frag_index[it.seq] = start_index + (i - 1)
end

-- Second pass: rewrite tags assigning indices by label-order mapping
local seen_layers = 0
svg = svg:gsub("<g%s(.-)>", function(attrs)
  if attrs:find('inkscape:groupmode%s*=%s*"layer"') then
    seen_layers = seen_layers + 1
    local frag_index = seq_to_frag_index[seen_layers] or (start_index + seen_layers - 1)
    local new_attrs = add_or_append_class(attrs, fragment_class)
    new_attrs = set_data_index(new_attrs, frag_index)
    return "<g " .. new_attrs .. ">"
  else
    return "<g " .. attrs .. ">"
  end
end)

io.write(svg)


