-- crop_svg_to_drawing.lua
-- Usage:
--   lua src/crop_svg_to_drawing.lua input.svg output.svg
-- Crops the SVG page to the drawing bounds using Inkscape CLI.

local input_path = arg[1]
local output_path = arg[2]
if not input_path or not output_path then
  io.stderr:write("Usage: lua src/crop_svg_to_drawing.lua input.svg output.svg\n")
  os.exit(1)
end

-- Quote a path for shell
local function q(p)
  if p:find("'") then
    -- fallback to double quotes if single quotes present
    return '"' .. p:gsub('"', '\\"') .. '"'
  else
    return "'" .. p .. "'"
  end
end

local cmd = "inkscape --export-type=svg --export-area-drawing " .. q(input_path) .. " -o " .. q(output_path)
local ok = os.execute(cmd)
if ok ~= true and ok ~= 0 then
  io.stderr:write("Inkscape export failed with code: " .. tostring(ok) .. "\n")
  os.exit(1)
end


