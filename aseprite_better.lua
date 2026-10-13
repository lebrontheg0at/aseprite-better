-- Aseprite Better
-- Quality-of-life commands for Aseprite:
--   1. Toggle the visibility of the bottom-most layer (Layer 1)
--   2. Drop shadow generator (hard/soft, new layer or merged, palette-aware)
--
-- Both commands follow the Aseprite UI language (Chinese or English).

local pc = app.pixelColor

-- ---------------------------------------------------------------------------
-- Shared helpers
-- ---------------------------------------------------------------------------

local function is_chinese()
  local lang = app.preferences.general.language or ""
  return lang:lower():find("^zh") ~= nil
end

local function ui_labels()
  if is_chinese() then
    return {
      -- bottom layer command
      toggle_title = "切换最底层可见性",
      no_sprite = "没有打开的精灵。",
      no_layer = "请先选择一个图层。",
      -- drop shadow command
      shadow_title = "投影",
      about = "从当前图层的图形生成投影。",
      offset_x = "水平偏移",
      offset_y = "垂直偏移",
      softness = "柔化半径",
      color_mode = "颜色",
      mode_darken = "自动压暗",
      mode_custom = "自定义颜色",
      mode_palette = "吸附到调色板",
      custom_color = "阴影颜色",
      darken = "保留亮度 %",
      opacity = "不透明度 %",
      output = "输出到",
      out_layer = "新建图层（当前层下方）",
      out_merge = "合并到当前图层",
      scope = "作用范围",
      scope_cel = "当前帧",
      scope_frames = "当前图层所有帧",
      shadow_layer_name = "阴影",
    }
  end
  return {
    toggle_title = "Toggle Visibility of Bottom Layer",
    no_sprite = "No sprite is open.",
    no_layer = "Select a layer first.",
    shadow_title = "Drop Shadow",
    about = "Generate a drop shadow from the active layer's artwork.",
    offset_x = "Offset X",
    offset_y = "Offset Y",
    softness = "Softness (px)",
    color_mode = "Color",
    mode_darken = "Darken artwork",
    mode_custom = "Custom color",
    mode_palette = "Snap to palette",
    custom_color = "Shadow color",
    darken = "Keep brightness %",
    opacity = "Opacity %",
    output = "Output",
    out_layer = "New layer (below current)",
    out_merge = "Merge into current layer",
    scope = "Scope",
    scope_cel = "Current frame",
    scope_frames = "All frames of current layer",
    shadow_layer_name = "Shadow",
  }
end

-- ---------------------------------------------------------------------------
-- 1. Toggle the visibility of the bottom-most layer
-- ---------------------------------------------------------------------------

-- sprite.layers is ordered bottom-to-top, so layers[1] is the bottom layer.
function toggle_bottom_layer(spr)
  spr = spr or app.activeSprite
  if not spr then return false end
  local layers = spr.layers
  if not layers or #layers == 0 then return false end
  local bottom = layers[1]
  bottom.isVisible = not bottom.isVisible
  return bottom.isVisible
end

-- ---------------------------------------------------------------------------
-- 2. Drop shadow
-- ---------------------------------------------------------------------------

-- Nearest palette entry to col (RGB distance), so palette-aware shadows keep
-- the sprite's indexed palette intact.
local function nearest_palette_color(spr, col)
  local pal = spr.palettes[1]
  local best, best_d = col, math.huge
  for i = 0, 255 do
    local ok, c = pcall(function() return pal:getColor(i) end)
    if not ok then break end
    local d = (c.red - col.red) ^ 2 + (c.green - col.green) ^ 2 + (c.blue - col.blue) ^ 2
    if d < best_d then
      best_d = d
      best = Color{ r = c.red, g = c.green, b = c.blue, a = 255 }
    end
  end
  return best
end

-- Separable box blur over a flat alpha array (clamped edges), radius r.
local function box_blur(alpha, w, h, r)
  if r < 1 then return alpha end
  local tmp = {}
  for y = 0, h - 1 do
    local row = y * w
    for x = 0, w - 1 do
      local sum, cnt = 0, 0
      for k = -r, r do
        local xx = x + k
        if xx < 0 then xx = 0 elseif xx > w - 1 then xx = w - 1 end
        sum = sum + alpha[row + xx + 1]
        cnt = cnt + 1
      end
      tmp[row + x + 1] = sum / cnt
    end
  end
  local out = {}
  for y = 0, h - 1 do
    for x = 0, w - 1 do
      local sum, cnt = 0, 0
      for k = -r, r do
        local yy = y + k
        if yy < 0 then yy = 0 elseif yy > h - 1 then yy = h - 1 end
        sum = sum + tmp[yy * w + x + 1]
        cnt = cnt + 1
      end
      out[y * w + x + 1] = sum / cnt
    end
  end
  return out
end

local function build_shadow_image(src, opts)
  local w, h = src.width, src.height
  local colors, alpha = {}, {}
  local factor = opts.darken / 100

  for y = 0, h - 1 do
    for x = 0, w - 1 do
      local v = src:getPixel(x, y)
      local idx = y * w + x + 1
      alpha[idx] = pc.rgbaA(v)
      if opts.flat_color then
        colors[idx] = { opts.flat_color.red, opts.flat_color.green, opts.flat_color.blue }
      else
        colors[idx] = {
          math.floor(pc.rgbaR(v) * factor),
          math.floor(pc.rgbaG(v) * factor),
          math.floor(pc.rgbaB(v) * factor),
        }
      end
    end
  end

  if opts.softness >= 1 then
    alpha = box_blur(alpha, w, h, opts.softness)
  end

  local out = Image(w, h)
  local op = opts.opacity / 100
  for y = 0, h - 1 do
    for x = 0, w - 1 do
      local idx = y * w + x + 1
      local a = math.floor(alpha[idx] * op + 0.5)
      if a > 0 then
        local c = colors[idx]
        out:putPixel(x, y, pc.rgba(c[1], c[2], c[3], a))
      end
    end
  end
  return out
end

local function frames_to_process(spr, opts)
  if opts.all_frames then
    local list = {}
    for i = 1, #spr.frames do list[#list + 1] = i end
    return list
  end
  return { app.frame }
end

-- opts fields:
--   dx, dy      number, offset in pixels
--   softness    number, 0 = hard
--   mode        "darken" | "custom" | "palette"
--   color       Color, used by custom/palette
--   darken      number 0..100 (keep-brightness percentage)
--   opacity     number 0..100
--   output      "layer" | "merge"
--   all_frames  boolean
--   layer       Layer (defaults to the active layer)
-- Returns a short result string.
function apply_drop_shadow(opts)
  local spr = app.activeSprite
  if not spr then return "no sprite" end
  local layer = opts.layer or app.activeLayer
  if not layer then return "no layer" end

  local flat = nil
  if opts.mode == "custom" then
    flat = opts.color
  elseif opts.mode == "palette" then
    flat = nearest_palette_color(spr, opts.color)
  end

  local params = {
    dx = opts.dx or 1,
    dy = opts.dy or 1,
    softness = math.max(0, math.floor(opts.softness or 0)),
    flat_color = flat,
    darken = opts.darken or 60,
    opacity = opts.opacity or 100,
    all_frames = opts.all_frames or false,
  }

  local labels = ui_labels()
  local done = 0

  app.transaction(function()
    local shadow_layer = nil
    if opts.output == "layer" then
      shadow_layer = spr:newLayer()
      shadow_layer.name = labels.shadow_layer_name
      -- stackIndex is 1-based from the bottom; writing it reorders the stack
      -- and pushes the layers above it up by one.
      shadow_layer.stackIndex = layer.stackIndex
    end

    for _, frame in ipairs(frames_to_process(spr, params)) do
      local cel = layer:cel(frame)
      if cel then
        local simg = build_shadow_image(cel.image, params)
        local sx = cel.position.x + params.dx
        local sy = cel.position.y + params.dy

        if shadow_layer then
          local existing = shadow_layer:cel(frame)
          if existing then
            existing.image = simg
            existing.position = Point(sx, sy)
          else
            spr:newCel(shadow_layer, frame, simg, Point(sx, sy))
          end
        else
          -- Merge: grow the cel to cover artwork + shadow, then write shadow
          -- pixels only where the artwork is transparent.
          local ox, oy = cel.position.x, cel.position.y
          local ow, oh = cel.image.width, cel.image.height
          local minx = math.min(ox, sx)
          local miny = math.min(oy, sy)
          local maxx = math.max(ox + ow, sx + simg.width)
          local maxy = math.max(oy + oh, sy + simg.height)
          local nw, nh = maxx - minx, maxy - miny

          local merged = Image(nw, nh)
          merged:drawImage(cel.image, Point(ox - minx, oy - miny))
          for y = 0, simg.height - 1 do
            for x = 0, simg.width - 1 do
              local v = simg:getPixel(x, y)
              if pc.rgbaA(v) > 0 then
                local dx2 = (sx - minx) + x
                local dy2 = (sy - miny) + y
                if dx2 >= 0 and dx2 < nw and dy2 >= 0 and dy2 < nh then
                  if pc.rgbaA(merged:getPixel(dx2, dy2)) == 0 then
                    merged:putPixel(dx2, dy2, v)
                  end
                end
              end
            end
          end
          cel.image = merged
          cel.position = Point(minx, miny)
        end
        done = done + 1
      end
    end
  end)

  app.refresh()
  return string.format("shadow applied to %d cel(s)", done)
end

-- ---------------------------------------------------------------------------
-- Registration
-- ---------------------------------------------------------------------------

function init(plugin)
  local labels = ui_labels()

  plugin:newCommand{
    id = "HideBottomLayer",
    title = labels.toggle_title,
    group = "layer_properties",
    onclick = function()
      if not app.activeSprite then
        app.alert(labels.no_sprite)
        return
      end
      toggle_bottom_layer()
      app.refresh()
    end,
  }

  plugin:newCommand{
    id = "DropShadow",
    title = labels.shadow_title,
    group = "edit_fx",
    onclick = function()
      local spr = app.activeSprite
      if not spr then
        app.alert(labels.no_sprite)
        return
      end
      if not app.activeLayer then
        app.alert(labels.no_layer)
        return
      end

      local dlg = Dialog{ title = labels.shadow_title }
      if not dlg then return end

      dlg:label{ label = labels.about }
      dlg:separator{}
      dlg:number{ id = "dx", label = labels.offset_x, text = "1", decimals = 0 }
      dlg:number{ id = "dy", label = labels.offset_y, text = "1", decimals = 0 }
      dlg:number{ id = "softness", label = labels.softness, text = "0", decimals = 0 }
      dlg:separator{}
      dlg:combobox{
        id = "mode", label = labels.color_mode,
        option = labels.mode_custom,
        options = { labels.mode_darken, labels.mode_custom, labels.mode_palette },
      }
      dlg:color{ id = "color", label = labels.custom_color, color = Color{ r = 0, g = 0, b = 0, a = 255 } }
      dlg:number{ id = "darken", label = labels.darken, text = "60", decimals = 0 }
      dlg:number{ id = "opacity", label = labels.opacity, text = "60", decimals = 0 }
      dlg:separator{}
      dlg:combobox{
        id = "output", label = labels.output,
        option = labels.out_layer,
        options = { labels.out_layer, labels.out_merge },
      }
      dlg:combobox{
        id = "scope", label = labels.scope,
        option = labels.scope_cel,
        options = { labels.scope_cel, labels.scope_frames },
      }
      dlg:separator{}
      dlg:button{ id = "ok", text = "OK", focus = true }
      dlg:button{ id = "cancel", text = "Cancel" }
      dlg:show()

      local data = dlg.data
      if not data.ok then return end

      local mode = "darken"
      if data.mode == labels.mode_custom then mode = "custom"
      elseif data.mode == labels.mode_palette then mode = "palette" end

      apply_drop_shadow{
        layer = app.activeLayer,
        dx = data.dx,
        dy = data.dy,
        softness = data.softness,
        mode = mode,
        color = data.color,
        darken = math.max(0, math.min(100, data.darken)),
        opacity = math.max(0, math.min(100, data.opacity)),
        output = (data.output == labels.out_merge) and "merge" or "layer",
        all_frames = (data.scope == labels.scope_frames),
      }
    end,
  }
end
