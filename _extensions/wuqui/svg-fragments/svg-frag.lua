-- svg-frag shortcode (root-level file)
Shortcodes = Shortcodes or {}

local function read_file(path)
  local f, err = io.open(path, "rb")
  if not f then error("svg-frag: cannot open file: " .. tostring(err)) end
  local data = f:read("*a")
  f:close()
  return data
end

local function has_class(attrs, name)
  local cls = attrs:match('class%s*=%s*"([^"]*)"')
  if not cls then return false end
  for token in cls:gmatch("%S+") do if token == name then return true end end
  return false
end

local function add_or_append_class(attrs, name)
  if not name or name == "" then return attrs end
  if attrs:find('class%s*=') then
    if has_class(attrs, name) then return attrs end
    return (attrs:gsub('class%s*=%s*"([^"]*)"', function(val)
      if val == "" then return 'class="' .. name .. '"' end
      return 'class="' .. val .. ' ' .. name .. '"'
    end, 1))
  else
    return attrs .. ' class="' .. name .. '"'
  end
end

local function set_data_index(attrs, n)
  if n == nil then return attrs end
  if attrs:find('data%-fragment%-index%s*=') then
    return (attrs:gsub('data%-fragment%-index%s*=%s*"[^"]*"', 'data-fragment-index="' .. tostring(n) .. '"', 1))
  else
    return attrs .. ' data-fragment-index="' .. tostring(n) .. '"'
  end
end

local function compute_layer_order(svg)
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

  local seq_to_rank = {}
  for i, it in ipairs(ordered) do seq_to_rank[it.seq] = i - 1 end
  return seq_to_rank, layer_seq
end

local function annotate_layers(svg, start_index, fragment_class)
  local seq_to_rank, total_layers = compute_layer_order(svg)
  if total_layers == 0 then return svg end
  local seen_layers = 0
  local out = svg:gsub("<g%s(.-)>", function(attrs)
    if attrs:find('inkscape:groupmode%s*=%s*"layer"') then
      seen_layers = seen_layers + 1
      local rank = seq_to_rank[seen_layers]
      local frag_index = start_index + (rank or (seen_layers - 1))
      local new_attrs = add_or_append_class(attrs, fragment_class)
      new_attrs = set_data_index(new_attrs, frag_index)
      return "<g " .. new_attrs .. ">"
    else
      return "<g " .. attrs .. ">"
    end
  end)
  return out
end

Shortcodes["svg-frag"] = function(args, kwargs, meta)
  local file = kwargs["file"] or args[1]
  if not file or file == "" then
    return pandoc.Para({ pandoc.Str("svg-frag: missing 'file' parameter") })
  end
  local start = tonumber(kwargs["start"]) or 0
  local class_name = kwargs["class"] or "fragment"
  local effect = kwargs["effect"]
  local reduced = kwargs["reduced_motion"]
  local svg = read_file(file)
  if reduced == "show-all" then return pandoc.RawBlock('html', svg) end
  local combined_class = class_name
  if effect and effect ~= "" then combined_class = combined_class .. " " .. effect end
  local out = annotate_layers(svg, start, combined_class)
  return pandoc.RawBlock('html', out)
end

return {}


