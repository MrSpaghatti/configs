-- mod-version:3
local core = require "core"
local keymap = require "core.keymap"
local style = require "core.style"
local CommandView = require "core.commandview"
local RootView = require "core.rootview"
local config = require "core.config"
local common = require "core.common"


local keyhud = {}

config.plugins.keyhud = common.merge({
  stroke_map = {
    ["escape"] = "<ESC>",
    ["space"] = "<SPACE>",  --"␣""
    ["left gui"] = "<CMD>", --"⌘"
    ["right gui"] = "<CMD>",
    ["left ctrl"] = "<CTRL>",
    ["right ctrl"] = "<CTRL>",
    ["left alt"] = "<ALT>",
    ["right alt"] = "<ALT>",
    ["left"] = "←",
    ["right"] = "→",
    ["up"] = "↑",
    ["down"] = "↓",
    ["left shift"] = "⇧",
    ["right shift"] = "⇧",
    ["capslock"] = "⇪",
    ["return"] = "<RETURN>", --"↵",
    ["backspace"] = "⌫",
    ["delete"] = "⌦",
    ["pageup"] = "<UP>",     --"⇞",
    ["pagedown"] = "<DOWN>", --"⇟",
    ["home"] = "<HOME>",     --"↖",
    ["end"] = "<END>",       --"↘",
    ["tab"] = "<TAB>",       --"⇥",
  },
  max_time = 0.5,
  only_mapped = false,
  filters = {
    ["commandview"] = true,
    ["mouse"] = true
  },
  position = "right",
}, config.plugins.keyhud)

style.keyhud = common.merge(
  {
    background = { common.color "#00000066" },
    text = { common.color "#ffffffdd" },
    font = style.big_font,  -- style.code_font:copy(46 * SCALE)
  },
  style.keyhud
)

keyhud.last_strokes = {}
keyhud.last_strokes_time_stamp = {}


keyhud.on_key_pressed__orig = keymap.on_key_pressed
keyhud.on_key_released__orig = keymap.on_key_released


local function dv()
  return core.active_view
end

function keymap.on_key_pressed(k, ...)
  if dv():is(CommandView) and config.plugins.keyhud.filters.commandview then
    return keyhud.on_key_pressed__orig(k, ...)
  end
  if config.plugins.keyhud.filters.mouse and (string.find(k, "click", 1, true) or string.find(k, "wheel", 1, true)) then
    return keyhud.on_key_pressed__orig(k, ...)
  end
  local x = config.plugins.keyhud.stroke_map[k]
  if x == nil and not config.plugins.keyhud.only_mapped then
    if #k > 1 then
      x = '<' .. k .. '>'
    else
      x = k
    end
  end
  if x ~= nil then
    for i, key in ipairs(keyhud.last_strokes) do
      if x == key then
        keyhud.last_strokes_time_stamp[i] = -1
        x = nil
        break
      end
    end
  end
  if x ~= nil then
    table.insert(keyhud.last_strokes, x)
    table.insert(keyhud.last_strokes_time_stamp, -1)
  end
  return keyhud.on_key_pressed__orig(k, ...)
end

function keymap.on_key_released(k)
  if #keyhud.last_strokes then
    local x = config.plugins.keyhud.stroke_map[k]
    if x == nil then
      x = k
    end
    for i, key in ipairs(keyhud.last_strokes) do
      if x == key then
        keyhud.last_strokes_time_stamp[i] = system.get_time()
        break
      end
    end
  end
  return keyhud.on_key_released__orig(k)
end

local rvDraw = RootView.draw
function RootView:draw(...)
  rvDraw(self, ...)
  local position = config.plugins.keyhud.position
  if position ~= 'right' and position ~= 'left' then
    core.error("`config.plugins.keyhud.position` can be only `left` or `right`")
    return nil
  end
  local font = style.keyhud.font
  local h = font:get_height() + 20
  local w = h
  local y = self.size.y - 10
  local next_strokes = {}
  local next_timestamps = {}
  local start_i, end_i, step = 0, 0, 1
  if position == "left" then
    local x = 10
    for i = 1, #keyhud.last_strokes do
      local t0 = keyhud.last_strokes_time_stamp[i]
      if t0 < 0 or system.get_time() - t0 < config.plugins.keyhud.max_time then
        local key = keyhud.last_strokes[i]
        core.redraw = true
        -- y = self.size.y - core.status_view.size.y
        local tw = font:get_width(key)
        local th = font:get_height()
        w = h
        if tw + 20 > w then
          w = tw + 20
        end
        renderer.draw_rect(x, y - h, w, h, style.keyhud.background)
        renderer.draw_text(font, key, x + w / 2 - tw / 2, y - h / 2 - th / 2,
          style.keyhud.text)
        x = x + w + 10
        table.insert(next_strokes, key)
        table.insert(next_timestamps, t0)
      end
    end
    start_i = 1
    end_i = #next_strokes
    step = 1
  else
    local x = self.size.x - 10
    for i = #keyhud.last_strokes, 1, -1 do
      local t0 = keyhud.last_strokes_time_stamp[i]
      if t0 < 0 or system.get_time() - t0 < config.plugins.keyhud.max_time then
        local key = keyhud.last_strokes[i]
        core.redraw = true
        -- y = self.size.y - core.status_view.size.y
        local tw = font:get_width(key)
        local th = font:get_height()
        if tw + 20 > w then
          w = tw + 20
        end
        renderer.draw_rect(x - w, y - h, w, h, style.keyhud.background)
        renderer.draw_text(font, key, x - w / 2 - tw / 2, y - h / 2 - th / 2,
          style.keyhud.text)
        x = x - w - 10
        table.insert(next_strokes, key)
        table.insert(next_timestamps, t0)
      end
    end
    start_i = #next_strokes
    end_i = 1
    step = -1
  end
  keyhud.last_strokes = {}
  keyhud.last_strokes_time_stamp = {}
  for i = start_i, end_i, step do
    table.insert(keyhud.last_strokes, next_strokes[i])
    table.insert(keyhud.last_strokes_time_stamp, next_timestamps[i])
  end
end

return keyhud
