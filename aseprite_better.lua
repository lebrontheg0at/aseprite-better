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
      -- flatten colors command
      flatten_title = "扁平化",
      flatten_about = "把相近的颜色归并成同一个颜色，并清除半透明像素。",
      ft_tolerance = "相似色合并阈值",
      ft_black = "黑色阈值（0 = 关闭）",
      ft_black_hit = "吸附到纯黑 %d 个像素。",
      ft_clear = "清除半透明像素（0<不透明度<100%）",
      ft_indexed = "索引色模式暂不支持，请先转为 RGB 模式（精灵 → 色彩模式 → RGB）。",
      ft_summary = "扁平化完成：颜色 %d → %d，清除半透明像素 %d 个。",
      -- perfect pixel command
      pp_title = "完美像素（网格还原）",
      pp_about = "检测像素画的网格并逐格重新采样，把杂乱的边缘还原成干净的像素块。",
      pp_sampling = "采样方式",
      pp_s_majority = "多数聚类",
      pp_s_center = "中心采样",
      pp_s_median = "中位数",
      pp_grid = "网格大小",
      pp_g_auto = "自动检测",
      pp_g_manual = "手动指定",
      pp_grid_w = "横向格数",
      pp_grid_h = "纵向格数",
      pp_output = "输出到",
      pp_o_layer = "新建图层（放大回原尺寸）",
      pp_o_sprite = "新建精灵（真实像素尺寸）",
      pp_scope = "处理范围",
      pp_scope_layer = "当前图层",
      pp_layer_name = "完美像素",
      pp_fail = "网格检测失败：画面里找不到足够明显的像素边界。请改用「手动指定」格数。",
      pp_bad_size = "检测到的像素格 %.2f × %.2f px 超出合理范围（4～20 px），结果可能不对；可用手动指定。",
      pp_result_layer = "检测到像素格 %.2f × %.2f px，已在原尺寸上还原为 %d × %d 格。",
      pp_result_sprite = "检测到像素格 %.2f × %.2f px，已新建精灵 %d × %d。",
      pp_merge = "合并相近颜色（0 = 关闭）",
      pp_colors = "颜色 %d → %d。",
      -- redraw contour command
      ro_title = "重绘轮廓",
      ro_about = "检测所有细的深色轮廓线（灰黑/蓝黑等都算），统一为指定颜色和宽度；较宽的深色块保持不动。",
      ro_dark = "深色判定阈值（亮度 ≤）",
      ro_max_line = "轮廓最大宽度（更宽的深色块不处理）",
      ro_width = "轮廓宽度（px）",
      ro_color = "轮廓颜色",
      ro_output = "输出到",
      ro_o_replace = "替换当前图层",
      ro_o_layer = "新建图层（当前层上方）",
      ro_layer_name = "轮廓",
      ro_fail = "没有检测到符合条件的深色轮廓。可尝试调大深色判定阈值或轮廓最大宽度。",
      ro_summary = "已重绘 %d 条轮廓：宽度 %d px，轮廓 %d 像素，修整 %d 像素。",
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
    flatten_title = "Flatten Colors",
    flatten_about = "Merge similar colors into one and clear semi-transparent pixels.",
    ft_tolerance = "Color merge tolerance",
    ft_black = "Black threshold (0 = off)",
    ft_black_hit = "Snapped %d pixel(s) to pure black.",
    ft_clear = "Clear semi-transparent pixels (0 < alpha < 100%)",
    ft_indexed = "Indexed color mode is not supported. Convert to RGB first (Sprite → Color Mode → RGB).",
    ft_summary = "Flattened: %d colors → %d, cleared %d semi-transparent pixel(s).",
    pp_title = "Perfect Pixel (Grid Restore)",
    pp_about = "Detect the pixel grid and resample each cell, turning messy edges into clean pixel blocks.",
    pp_sampling = "Sampling",
    pp_s_majority = "Majority cluster",
    pp_s_center = "Center sample",
    pp_s_median = "Median",
    pp_grid = "Grid size",
    pp_g_auto = "Auto detect",
    pp_g_manual = "Manual",
    pp_grid_w = "Grid columns",
    pp_grid_h = "Grid rows",
    pp_output = "Output",
    pp_o_layer = "New layer (scaled back to canvas size)",
    pp_o_sprite = "New sprite (true pixel size)",
    pp_scope = "Source",
    pp_scope_layer = "Active layer",
    pp_layer_name = "Perfect Pixel",
    pp_fail = "Grid detection failed: no clear pixel boundaries were found. Use the manual grid size instead.",
    pp_bad_size = "Detected pixel size %.2f × %.2f px is outside the plausible range (4-20 px); the result may be wrong - consider the manual grid size.",
    pp_result_layer = "Detected %.2f × %.2f px per cell; restored to %d × %d cells at canvas size.",
    pp_result_sprite = "Detected %.2f × %.2f px per cell; created a new %d × %d sprite.",
    pp_merge = "Merge similar colors (0 = off)",
    pp_colors = "Colors %d → %d.",
    ro_title = "Redraw Contour",
    ro_about = "Detect thin dark contour lines (grey-black, blue-black, ...) and redraw them at one color and width; thicker dark blocks are left alone.",
    ro_dark = "Dark threshold (luminance ≤)",
    ro_max_line = "Max contour width (thicker dark blocks are skipped)",
    ro_width = "Contour width (px)",
    ro_color = "Contour color",
    ro_output = "Output",
    ro_o_replace = "Replace current layer",
    ro_o_layer = "New layer (above current)",
    ro_layer_name = "Contour",
    ro_fail = "No dark contour matched. Try raising the dark threshold or the max contour width.",
    ro_summary = "%d contour(s) redrawn at %d px: %d contour pixels, %d pixels adjusted.",
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
-- 3. Flatten colors
-- ---------------------------------------------------------------------------

-- Turns semi-transparent pixels fully transparent and merges similar colors
-- into a single color, so the artwork ends up with few flat colors and no
-- visible gradients.
--
-- The color histogram is collected across every processed frame first and
-- clustered once, so the same input color always maps to the same output color
-- in all frames (important for animation).
--
-- opts fields:
--   layer        Layer (defaults to the active layer)
--   tolerance    number, max RGB distance for two colors to be merged (0..255)
--   black_tol    number, every channel of a near-black color must be <= this
--                to snap it to pure black (0 = off)
--   clear_semi   boolean, clear pixels with 0 < alpha < 255 (default true)
--   all_frames   boolean
-- Returns a table { before = n, after = n, cleared = n, black = n }.
function flatten_colors(opts)
  local spr = app.activeSprite
  if not spr then return nil end
  local layer = opts.layer or app.activeLayer
  if not layer then return nil end
  if spr.colorMode == ColorMode.INDEXED then return nil end

  local tol = math.max(0, math.min(255, math.floor(opts.tolerance or 24)))
  local black_tol = math.max(0, math.min(255, math.floor(opts.black_tol or 0)))
  local tol2 = tol * tol
  local clear_semi = opts.clear_semi
  if clear_semi == nil then clear_semi = true end

  local frames = frames_to_process(spr, { all_frames = opts.all_frames })
  local counts, keys = {}, {}
  local centers, map = {}, {}
  local cleared = 0
  local black_snapped = 0

  local function color_key(r, g, b)
    return r * 65536 + g * 256 + b
  end

  app.transaction(function()
    -- pass 1: clear semi-transparent pixels, collect the color histogram
    for _, frame in ipairs(frames) do
      local cel = layer:cel(frame)
      if cel then
        local img = cel.image
        for y = 0, img.height - 1 do
          for x = 0, img.width - 1 do
            local v = img:getPixel(x, y)
            local a = pc.rgbaA(v)
            if a > 0 then
              if a < 255 then
                if clear_semi then
                  img:putPixel(x, y, pc.rgba(0, 0, 0, 0))
                  cleared = cleared + 1
                end
              else
                local key = color_key(pc.rgbaR(v), pc.rgbaG(v), pc.rgbaB(v))
                if counts[key] then
                  counts[key] = counts[key] + 1
                else
                  counts[key] = 1
                  keys[#keys + 1] = key
                end
              end
            end
          end
        end
      end
    end

    -- cluster: walk colors from most to least frequent, keep a color as a new
    -- cluster center only when it is not already close to an existing one
    table.sort(keys, function(a, b) return counts[a] > counts[b] end)

    -- Black gets its own threshold: any color with every channel at or below
    -- black_tol is snapped to pure black before the normal merge runs. The
    -- threshold is per channel (not Euclidean) because "near black" means all
    -- three channels are low, and that is how the number is easiest to reason
    -- about. Pure black then joins the cluster centers, so later colors may
    -- still merge into it under the normal tolerance.
    if black_tol > 0 then
      local black = { 0, 0, 0 }
      centers[#centers + 1] = black
      for _, key in ipairs(keys) do
        local r = math.floor(key / 65536) % 256
        local g = math.floor(key / 256) % 256
        local b = key % 256
        if r <= black_tol and g <= black_tol and b <= black_tol then
          map[key] = black
          black_snapped = black_snapped + counts[key]
        end
      end
    end

    for _, key in ipairs(keys) do
      if not map[key] then
        local r = math.floor(key / 65536) % 256
        local g = math.floor(key / 256) % 256
        local b = key % 256
        local best, best_d = nil, math.huge
        for _, c in ipairs(centers) do
          local dr, dg, db = r - c[1], g - c[2], b - c[3]
          local d = dr * dr + dg * dg + db * db
          if d < best_d then
            best_d = d
            best = c
          end
        end
        if best and best_d <= tol2 then
          map[key] = best
        else
          local c = { r, g, b }
          centers[#centers + 1] = c
          map[key] = c
        end
      end
    end

    -- pass 2: remap every opaque pixel to its cluster center
    for _, frame in ipairs(frames) do
      local cel = layer:cel(frame)
      if cel then
        local img = cel.image
        for y = 0, img.height - 1 do
          for x = 0, img.width - 1 do
            local v = img:getPixel(x, y)
            if pc.rgbaA(v) == 255 then
              local r, g, b = pc.rgbaR(v), pc.rgbaG(v), pc.rgbaB(v)
              local c = map[color_key(r, g, b)]
              if c and (c[1] ~= r or c[2] ~= g or c[3] ~= b) then
                img:putPixel(x, y, pc.rgba(c[1], c[2], c[3], 255))
              end
            end
          end
        end
      end
    end
  end)

  app.refresh()
  return { before = #keys, after = #centers, cleared = cleared, black = black_snapped }
end

-- ---------------------------------------------------------------------------
-- 4. Perfect Pixel (grid restore)
-- ---------------------------------------------------------------------------
--
-- Implements the algorithm of "Perfect Pixel" by theAmusing (MIT License),
-- https://github.com/theamusing/perfectPixel — grid size estimation from
-- gradient profiles, per-grid-line snapping, then one sample per cell.
-- This Lua code is an independent implementation for the Aseprite API, not a
-- copy of the upstream Python source. See THIRD-PARTY-NOTICES.md for the full
-- attribution and license text, and README.md for the deliberate deviations
-- (gradient estimator only, percentile threshold, alpha-aware sampling).

local function to_gray(img)
  local w, h = img.width, img.height
  local gray = {}
  for y = 0, h - 1 do
    for x = 0, w - 1 do
      local v = img:getPixel(x, y)
      gray[y * w + x + 1] = 0.299 * pc.rgbaR(v) + 0.587 * pc.rgbaG(v) + 0.114 * pc.rgbaB(v)
    end
  end
  return gray
end

-- Sobel gradients with edge clamping; returns per-column |gx| sums and
-- per-row |gy| sums, which spike on the pixel-art grid lines.
local function gradient_profiles(gray, w, h)
  local col = {}
  local row = {}
  for i = 1, w do col[i] = 0 end
  for i = 1, h do row[i] = 0 end

  local function g(x, y)
    if x < 0 then x = 0 elseif x >= w then x = w - 1 end
    if y < 0 then y = 0 elseif y >= h then y = h - 1 end
    return gray[y * w + x + 1]
  end

  for y = 0, h - 1 do
    for x = 0, w - 1 do
      local tl, tc, tr = g(x - 1, y - 1), g(x, y - 1), g(x + 1, y - 1)
      local ml, mr = g(x - 1, y), g(x + 1, y)
      local bl, bc, br = g(x - 1, y + 1), g(x, y + 1), g(x + 1, y + 1)
      local sx = (tr + 2 * mr + br) - (tl + 2 * ml + bl)
      local sy = (bl + 2 * bc + br) - (tl + 2 * tc + tr)
      col[x + 1] = col[x + 1] + math.abs(sx)
      row[y + 1] = row[y + 1] + math.abs(sy)
    end
  end
  return col, row
end

local function median(t)
  if #t == 0 then return nil end
  local c = {}
  for i = 1, #t do c[i] = t[i] end
  table.sort(c)
  local n = #c
  if n % 2 == 1 then return c[(n + 1) / 2] end
  return (c[n / 2] + c[n / 2 + 1]) / 2
end

-- Robust reference level for the peak threshold. Upstream uses the profile
-- maximum; on a sprite with transparent margins that single hard edge
-- (empty -> artwork) can be an order of magnitude above every real grid line
-- and would hide all of them, so we use a high percentile instead.
local function profile_reference(profile, n)
  local c = {}
  for i = 1, n do c[i] = profile[i] end
  table.sort(c)
  local idx = math.max(1, math.floor(n * 0.9))
  return c[idx]
end

-- Grid size from the spacing between strong gradient peaks.
local function estimate_grid(n, profile, rel_thr, min_interval)
  local ref = profile_reference(profile, n)
  if ref <= 1e-6 then return nil end
  local thr = rel_thr * ref
  local peaks = {}
  for i = 2, n - 1 do
    if profile[i] > profile[i - 1] and profile[i] > profile[i + 1] and profile[i] >= thr then
      if #peaks == 0 or (i - peaks[#peaks]) >= min_interval then
        peaks[#peaks + 1] = i
      end
    end
  end
  if #peaks < 4 then return nil end
  local gaps = {}
  for i = 2, #peaks do gaps[#gaps + 1] = peaks[i] - peaks[i - 1] end
  local m = median(gaps)
  if not m or m <= 0 then return nil end
  return n / m
end

-- Snap one grid line: strongest local maximum within [origin-range, origin+range],
-- otherwise the rounded origin (upstream find_best_grid).
local function snap_line(origin, range, profile, n)
  local best = math.floor(origin + 0.5)
  local best_v = -1
  for i = -math.floor(range + 0.5), math.floor(range + 0.5) do
    local c = math.floor(origin + i + 0.5)
    if c >= 1 and c <= n - 2 then
      local v = profile[c + 1]
      if v > profile[c] and v > profile[c + 2] and v > best_v then
        best_v = v
        best = c
      end
    end
  end
  return best
end

-- Walk outward from the centre, snapping each successive grid line.
local function refine_lines(size, profile, n, cell, intensity)
  local coords = {}
  local x = snap_line(size / 2, cell, profile, n)
  while x < n + cell / 2 do
    x = snap_line(x, cell * intensity, profile, n)
    coords[#coords + 1] = x
    x = x + cell
  end
  x = snap_line(size / 2, cell, profile, n) - cell
  while x > -cell / 2 do
    x = snap_line(x, cell * intensity, profile, n)
    coords[#coords + 1] = x
    x = x - cell
  end
  table.sort(coords)
  return coords
end

-- Collect a cell's pixels (strided so huge cells stay cheap). Fully
-- transparent pixels are skipped: on a sprite they are "no artwork here", and
-- letting them take part would drag edge cells towards a muddy see-through
-- average instead of the artwork's own colour. A cell with no opaque pixel at
-- all comes back empty and is written out as fully transparent.
local function collect_cell(img, x0, y0, x1, y1, cap)
  local rs, gs, bs, as = {}, {}, {}, {}
  local n = 0
  local cw = math.max(1, x1 - x0)
  local ch = math.max(1, y1 - y0)
  local stride = 1
  if cw * ch > cap then
    stride = math.max(1, math.ceil(math.sqrt((cw * ch) / cap)))
  end
  local y = y0
  while y < y1 and n < cap do
    local x = x0
    while x < x1 and n < cap do
      local v = img:getPixel(x, y)
      local a = pc.rgbaA(v)
      if a > 0 then
        n = n + 1
        rs[n], gs[n], bs[n], as[n] = pc.rgbaR(v), pc.rgbaG(v), pc.rgbaB(v), a
      end
      x = x + stride
    end
    y = y + stride
  end
  return rs, gs, bs, as, n
end

local function mean_of(rs, gs, bs, as, n)
  local sr, sg, sb, sa = 0, 0, 0, 0
  for i = 1, n do
    sr, sg, sb, sa = sr + rs[i], sg + gs[i], sb + bs[i], sa + as[i]
  end
  return sr / n, sg / n, sb / n, sa / n
end

-- Two-means split of the cell; the bigger cluster wins (upstream majority).
local function sample_majority(rs, gs, bs, as, n)
  if n == 0 then return 0, 0, 0, 0 end
  local c0r, c0g, c0b, c0a = rs[1], gs[1], bs[1], as[1]
  local bi, bd = 1, -1
  for i = 1, n do
    local dr, dg, db, da = rs[i] - c0r, gs[i] - c0g, bs[i] - c0b, as[i] - c0a
    local d = dr * dr + dg * dg + db * db + da * da
    if d > bd then
      bd = d
      bi = i
    end
  end
  local c1r, c1g, c1b, c1a = rs[bi], gs[bi], bs[bi], as[bi]
  local n0, n1 = 0, 0
  for _ = 1, 6 do
    local i0, i1 = {}, {}
    n0, n1 = 0, 0
    for i = 1, n do
      local dr0, dg0, db0, da0 = rs[i] - c0r, gs[i] - c0g, bs[i] - c0b, as[i] - c0a
      local dr1, dg1, db1, da1 = rs[i] - c1r, gs[i] - c1g, bs[i] - c1b, as[i] - c1a
      local d0 = dr0 * dr0 + dg0 * dg0 + db0 * db0 + da0 * da0
      local d1 = dr1 * dr1 + dg1 * dg1 + db1 * db1 + da1 * da1
      if d1 < d0 then
        n1 = n1 + 1
        i1[n1] = i
      else
        n0 = n0 + 1
        i0[n0] = i
      end
    end
    if n0 > 0 then
      local sr, sg, sb, sa = 0, 0, 0, 0
      for _, i in ipairs(i0) do sr, sg, sb, sa = sr + rs[i], sg + gs[i], sb + bs[i], sa + as[i] end
      c0r, c0g, c0b, c0a = sr / n0, sg / n0, sb / n0, sa / n0
    end
    if n1 > 0 then
      local sr, sg, sb, sa = 0, 0, 0, 0
      for _, i in ipairs(i1) do sr, sg, sb, sa = sr + rs[i], sg + gs[i], sb + bs[i], sa + as[i] end
      c1r, c1g, c1b, c1a = sr / n1, sg / n1, sb / n1, sa / n1
    end
  end
  if n1 >= n0 then return c1r, c1g, c1b, c1a end
  return c0r, c0g, c0b, c0a
end

local function sample_cell(img, x0, y0, x1, y1, method, cap)
  local rs, gs, bs, as, n = collect_cell(img, x0, y0, x1, y1, cap)
  if n == 0 then return 0, 0, 0, 0 end
  if method == "center" then
    local cx = math.floor((x0 + x1 - 1) / 2)
    local cy = math.floor((y0 + y1 - 1) / 2)
    local v = img:getPixel(cx, cy)
    return pc.rgbaR(v), pc.rgbaG(v), pc.rgbaB(v), pc.rgbaA(v)
  elseif method == "median" then
    local tr, tg, tb, ta = {}, {}, {}, {}
    for i = 1, n do tr[i], tg[i], tb[i], ta[i] = rs[i], gs[i], bs[i], as[i] end
    return median(tr) or 0, median(tg) or 0, median(tb) or 0, median(ta) or 0
  end
  return sample_majority(rs, gs, bs, as, n)
end

local function rnd(v)
  v = math.floor(v + 0.5)
  if v < 0 then return 0 elseif v > 255 then return 255 end
  return v
end

-- Each cell is sampled on its own, so cells that share one true colour still
-- come out a few units apart (the upstream tool has the same property and
-- expects a quantisation pass afterwards). Merge those near-duplicates so the
-- restored grid really is flat. Returns colours before / after.
local function merge_grid_colors(cells, tol)
  local counts, order = {}, {}
  local function key_of(c)
    return c[1] * 16777216 + c[2] * 65536 + c[3] * 256 + c[4]
  end
  for j = 1, #cells do
    for i = 1, #cells[j] do
      local k = key_of(cells[j][i])
      if counts[k] then
        counts[k] = counts[k] + 1
      else
        counts[k] = 1
        order[#order + 1] = k
      end
    end
  end
  table.sort(order, function(a, b) return counts[a] > counts[b] end)

  local tol2 = tol * tol
  local centers, map = {}, {}
  for _, k in ipairs(order) do
    local r = math.floor(k / 16777216) % 256
    local g = math.floor(k / 65536) % 256
    local b = math.floor(k / 256) % 256
    local a = k % 256
    local best, best_d = nil, math.huge
    for _, c in ipairs(centers) do
      local dr, dg, db, da = r - c[1], g - c[2], b - c[3], a - c[4]
      local d = dr * dr + dg * dg + db * db + da * da
      if d < best_d then
        best_d = d
        best = c
      end
    end
    if best and best_d <= tol2 then
      map[k] = best
    else
      local c = { r, g, b, a }
      centers[#centers + 1] = c
      map[k] = c
    end
  end

  for j = 1, #cells do
    for i = 1, #cells[j] do
      local m = map[key_of(cells[j][i])]
      cells[j][i] = { m[1], m[2], m[3], m[4] }
    end
  end
  return #order, #centers
end

-- opts fields:
--   method      "majority" | "center" | "median"
--   grid_w      number  (0/nil = auto detect)
--   grid_h      number
--   output      "layer" | "sprite"
--   frame       number (for "layer" output)
-- Returns a table, or nil plus a message key on failure.
function perfect_pixel_restore(opts)
  local spr = app.activeSprite
  if not spr then return nil, "no_sprite" end
  local layer = app.activeLayer
  if not layer then return nil, "no_layer" end
  local frame = opts.frame or app.frame

  local w, h = spr.width, spr.height
  local src = nil
  do
    -- the active cel's own image bounds, so unrelated empty margins are ignored
    local cel = layer:cel(frame)
    if not cel then return nil, "no_cel" end
    src = { img = cel.image, x = cel.position.x, y = cel.position.y }
    w, h = cel.image.width, cel.image.height
  end

  local gray = to_gray(src.img)
  local col_sum, row_sum = gradient_profiles(gray, w, h)

  local gw, gh = opts.grid_w or 0, opts.grid_h or 0
  local auto = (gw <= 0 or gh <= 0)
  if auto then
    local e_col = estimate_grid(w, col_sum, 0.2, 4)
    local e_row = estimate_grid(h, row_sum, 0.2, 4)
    if not e_col or not e_row then return nil, "pp_fail" end
    gw = math.max(1, math.floor(e_col + 0.5))
    gh = math.max(1, math.floor(e_row + 0.5))
    -- implausible cell sizes mean the detection latched onto noise; a grid
    -- coarser than the artwork would also blow up the sampling loop below
    local cw, ch = w / gw, h / gh
    if cw < 2 or cw > 64 or ch < 2 or ch > 64 then return nil, "pp_fail" end
  else
    gw = math.max(1, math.min(w, gw))
    gh = math.max(1, math.min(h, gh))
  end

  local cell_w = w / gw
  local cell_h = h / gh
  local xs = refine_lines(w, col_sum, w, cell_w, 0.25)
  local ys = refine_lines(h, row_sum, h, cell_h, 0.25)
  if #xs < 2 or #ys < 2 then return nil, "pp_fail" end

  local nw, nh = #xs - 1, #ys - 1
  local method = opts.method or "majority"

  -- one sample per cell
  local cells = {}
  for j = 1, nh do
    local y0 = math.max(0, math.ceil(ys[j]))
    local y1 = math.min(h, math.ceil(ys[j + 1]))
    if y1 <= y0 then y1 = math.min(h, y0 + 1) end
    local row = {}
    for i = 1, nw do
      local x0 = math.max(0, math.ceil(xs[i]))
      local x1 = math.min(w, math.ceil(xs[i + 1]))
      if x1 <= x0 then x1 = math.min(w, x0 + 1) end
      local r, g, b, a = sample_cell(src.img, x0, y0, x1, y1, method, 128)
      row[i] = { rnd(r), rnd(g), rnd(b), rnd(a) }
    end
    cells[j] = row
  end

  local before, after = nil, nil
  if (opts.merge_tol or 0) > 0 then
    before, after = merge_grid_colors(cells, opts.merge_tol)
  end

  app.transaction(function()
    if opts.output == "sprite" then
      local ns = Sprite(nw, nh)
      local nlayer = ns.layers[1]
      nlayer.name = ui_labels().pp_layer_name
      local nimg = Image(nw, nh)
      for j = 1, nh do
        for i = 1, nw do
          local c = cells[j][i]
          nimg:putPixel(i - 1, j - 1, pc.rgba(c[1], c[2], c[3], c[4]))
        end
      end
      ns:newCel(nlayer, 1, nimg, Point(0, 0))
    else
      -- same canvas size, each cell filled as one flat block
      local out_img = Image(w, h)
      for j = 1, nh do
        local y0 = math.max(0, math.ceil(ys[j]))
        local y1 = math.min(h, math.ceil(ys[j + 1]))
        for i = 1, nw do
          local x0 = math.max(0, math.ceil(xs[i]))
          local x1 = math.min(w, math.ceil(xs[i + 1]))
          local c = cells[j][i]
          local col = pc.rgba(c[1], c[2], c[3], c[4])
          for y = y0, y1 - 1 do
            for x = x0, x1 - 1 do
              out_img:putPixel(x, y, col)
            end
          end
        end
      end
      local nl = spr:newLayer()
      nl.name = ui_labels().pp_layer_name
      spr:newCel(nl, frame, out_img, Point(src.x, src.y))
    end
  end)

  app.refresh()
  return {
    cell_w = cell_w,
    cell_h = cell_h,
    nw = nw,
    nh = nh,
    src_w = w,
    src_h = h,
    auto = auto,
    colors_before = before,
    colors_after = after,
  }
end

-- ---------------------------------------------------------------------------
-- 5. Redraw Contour
-- ---------------------------------------------------------------------------

-- ITU-R BT.601 luma.
local function lum_of(r, g, b)
  return 0.299 * r + 0.587 * g + 0.114 * b
end

-- Zhang-Suen thinning: reduces a stroke mask to a connected 1-px centreline.
local function thin_mask(mask, w, h)
  local function at(x, y)
    if x < 1 or x > w or y < 1 or y > h then return false end
    return mask[y * w + x]
  end
  local changed = true
  while changed do
    changed = false
    for step = 1, 2 do
      local del = {}
      for y = 1, h do
        for x = 1, w do
          if mask[y * w + x] then
            local p = {
              at(x, y - 1), at(x + 1, y - 1), at(x + 1, y), at(x + 1, y + 1),
              at(x, y + 1), at(x - 1, y + 1), at(x - 1, y), at(x - 1, y - 1),
            }
            local b = 0
            for i = 1, 8 do
              if p[i] then b = b + 1 end
            end
            if b >= 2 and b <= 6 then
              local a = 0
              for i = 1, 8 do
                if not p[i] and p[i % 8 + 1] then a = a + 1 end
              end
              if a == 1 then
                local ok
                if step == 1 then
                  ok = (not p[1] or not p[3] or not p[5])
                    and (not p[3] or not p[5] or not p[7])
                else
                  ok = (not p[1] or not p[3] or not p[7])
                    and (not p[1] or not p[5] or not p[7])
                end
                if ok then del[#del + 1] = y * w + x end
              end
            end
          end
        end
      end
      if #del > 0 then
        changed = true
        for _, i in ipairs(del) do mask[i] = false end
      end
    end
  end
  return mask
end

local function dilate4(mask, w, h)
  local out = {}
  for y = 1, h do
    for x = 1, w do
      local i = y * w + x
      local v = mask[i]
      if not v then
        if (x > 1 and mask[i - 1]) or (x < w and mask[i + 1])
          or (y > 1 and mask[i - w]) or (y < h and mask[i + w]) then
          v = true
        end
      end
      out[i] = v or false
    end
  end
  return out
end

local function dilate_es(mask, w, h)
  local out = {}
  for y = 1, h do
    for x = 1, w do
      local i = y * w + x
      local v = mask[i]
      if not v and ((x < w and mask[i + 1]) or (y < h and mask[i + w])) then
        v = true
      end
      out[i] = v or false
    end
  end
  return out
end

-- Distance (in px, 4-connected) from every masked cell to the nearest cell
-- outside the mask: 1 for a lone 1-px line, 2 for the centre of a 3-px line.
local function distance_inside(mask, w, h)
  local dist = {}
  local queue, qh = {}, 1
  for y = 1, h do
    for x = 1, w do
      local i = y * w + x
      if mask[i] then
        local edge = (x == 1) or (x == w) or (y == 1) or (y == h)
          or (not mask[i - 1]) or (not mask[i + 1])
          or (not mask[i - w]) or (not mask[i + w])
        if edge then
          dist[i] = 1
          queue[#queue + 1] = i
        end
      end
    end
  end
  while qh <= #queue do
    local i = queue[qh]
    qh = qh + 1
    local x = (i - 1) % w + 1
    local y = math.floor((i - 1) / w) + 1
    local d = dist[i] + 1
    if x > 1 and mask[i - 1] and dist[i - 1] == nil then dist[i - 1] = d; queue[#queue + 1] = i - 1 end
    if x < w and mask[i + 1] and dist[i + 1] == nil then dist[i + 1] = d; queue[#queue + 1] = i + 1 end
    if y > 1 and mask[i - w] and dist[i - w] == nil then dist[i - w] = d; queue[#queue + 1] = i - w end
    if y < h and mask[i + w] and dist[i + w] == nil then dist[i + w] = d; queue[#queue + 1] = i + w end
  end
  return dist
end

local function bfs_through(w, h, seeds, passable)
  local dist, pay = {}, {}
  local queue, qh = {}, 1
  for _, s in ipairs(seeds) do
    if dist[s.idx] == nil then
      dist[s.idx] = 0
      pay[s.idx] = s.val
      queue[#queue + 1] = s.idx
    end
  end
  while qh <= #queue do
    local i = queue[qh]
    qh = qh + 1
    local x = (i - 1) % w + 1
    local y = math.floor((i - 1) / w) + 1
    local d = dist[i] + 1
    if x > 1 and dist[i - 1] == nil and passable[i - 1] then
      dist[i - 1] = d; pay[i - 1] = pay[i]; queue[#queue + 1] = i - 1
    end
    if x < w and dist[i + 1] == nil and passable[i + 1] then
      dist[i + 1] = d; pay[i + 1] = pay[i]; queue[#queue + 1] = i + 1
    end
    if y > 1 and dist[i - w] == nil and passable[i - w] then
      dist[i - w] = d; pay[i - w] = pay[i]; queue[#queue + 1] = i - w
    end
    if y < h and dist[i + w] == nil and passable[i + w] then
      dist[i + w] = d; pay[i + w] = pay[i]; queue[#queue + 1] = i + w
    end
  end
  return dist, pay
end

-- Redraw every dark *contour* at one colour and one width.
--
-- "Contour" is decided per connected dark region by measuring its stroke
-- width (2 * deepest interior distance - 1): regions up to `max_line_width`
-- px thick are contours and get redrawn, anything thicker is a filled dark
-- shape and is left completely untouched. That is what keeps big black
-- blocks, dark clothing and heavy shadows intact.
--
-- opts fields:
--   layer          Layer (defaults to the active layer)
--   dark_threshold number 0..255, luma at or below this counts as dark
--   max_line_width number, dark regions thicker than this are fill (not contour)
--   width          number, target contour thickness in px (1..8)
--   color          Color, the contour colour
--   output         "replace" | "layer"
--   all_frames     boolean
-- Returns { width, contours, pixels, adjusted } or nil + "ro_fail".
function redraw_contour(opts)
  local spr = app.activeSprite
  if not spr then return nil end
  local layer = opts.layer or app.activeLayer
  if not layer then return nil end

  local thr = math.max(0, math.min(255, math.floor(opts.dark_threshold or 60)))
  local max_line = math.max(1, math.min(32, math.floor(opts.max_line_width or 5)))
  local width = math.max(1, math.min(8, math.floor(opts.width or 2)))
  local ocol = opts.color or Color{ r = 0, g = 0, b = 0, a = 255 }
  local packed = pc.rgba(ocol.red, ocol.green, ocol.blue, ocol.alpha or 255)

  local frames = frames_to_process(spr, { all_frames = opts.all_frames })
  local results = {}
  local total_contours, total_px, total_adj = 0, 0, 0

  for _, frame in ipairs(frames) do
    local cel = layer:cel(frame)
    if cel then
      local iw, ih = cel.image.width, cel.image.height
      local pad = width + 2
      local w, h = iw + 2 * pad, ih + 2 * pad
      local n = w * h

      local colors, dark = {}, {}
      for y = 0, ih - 1 do
        for x = 0, iw - 1 do
          local v = cel.image:getPixel(x, y)
          if pc.rgbaA(v) > 0 then
            local i = (y + pad + 1) * w + (x + pad + 1)
            colors[i] = v
            if lum_of(pc.rgbaR(v), pc.rgbaG(v), pc.rgbaB(v)) <= thr then
              dark[i] = true
            end
          end
        end
      end

      local ddist = distance_inside(dark, w, h)

      -- label dark components (8-connected) and measure each one's width
      local visited, contour = {}, {}
      local contours = 0
      for i = 1, n do
        if dark[i] and not visited[i] then
          local stack, comp = { i }, {}
          visited[i] = true
          local maxd = 0
          while #stack > 0 do
            local j = table.remove(stack)
            comp[#comp + 1] = j
            local dj = ddist[j] or 1
            if dj > maxd then maxd = dj end
            local x = (j - 1) % w + 1
            local y = math.floor((j - 1) / w) + 1
            for dy = -1, 1 do
              for dx = -1, 1 do
                if dx ~= 0 or dy ~= 0 then
                  local nx, ny = x + dx, y + dy
                  if nx >= 1 and nx <= w and ny >= 1 and ny <= h then
                    local k = ny * w + nx
                    if dark[k] and not visited[k] then
                      visited[k] = true
                      stack[#stack + 1] = k
                    end
                  end
                end
              end
            end
          end
          local comp_width = 2 * maxd - 1
          if comp_width <= max_line then
            contours = contours + 1
            for _, j in ipairs(comp) do contour[j] = true end
          end
        end
      end

      if contours > 0 then
        local skel = {}
        for i = 1, n do skel[i] = contour[i] end
        thin_mask(skel, w, h)

        local new = skel
        for _ = 1, math.floor((width - 1) / 2) do new = dilate4(new, w, h) end
        if width % 2 == 0 then new = dilate_es(new, w, h) end

        local removed = {}
        local any_removed = false
        for i = 1, n do
          if contour[i] and not new[i] then
            removed[i] = true
            any_removed = true
          end
        end

        local dA, pA, dB, pB = {}, {}, {}, {}
        if any_removed then
          local sa, st = {}, {}
          local function add_seed(j)
            if not removed[j] and not new[j] and not contour[j] then
              if colors[j] ~= nil then
                sa[#sa + 1] = { idx = j, val = colors[j] }
              else
                st[#st + 1] = { idx = j, val = "transparent" }
              end
            end
          end
          for i = 1, n do
            if removed[i] then
              local x = (i - 1) % w + 1
              local y = math.floor((i - 1) / w) + 1
              if x > 1 then add_seed(i - 1) end
              if x < w then add_seed(i + 1) end
              if y > 1 then add_seed(i - w) end
              if y < h then add_seed(i + w) end
            end
          end
          dA, pA = bfs_through(w, h, sa, removed)
          dB, pB = bfs_through(w, h, st, removed)
        end

        local img = Image(w, h)
        local cnt_new, cnt_adj = 0, 0
        local minx, miny, maxx, maxy = w, h, 1, 1
        for y = 1, h do
          for x = 1, w do
            local i = y * w + x
            local v
            if new[i] then
              v = packed
              cnt_new = cnt_new + 1
            elseif removed[i] then
              if dA[i] ~= nil and (dB[i] == nil or dA[i] <= dB[i]) then
                v = pA[i]
              end
              cnt_adj = cnt_adj + 1
            else
              v = colors[i]
            end
            if v ~= nil then
              img:putPixel(x - 1, y - 1, v)
              if x < minx then minx = x end
              if x > maxx then maxx = x end
              if y < miny then miny = y end
              if y > maxy then maxy = y end
            end
          end
        end

        local cw, ch = maxx - minx + 1, maxy - miny + 1
        local cropped = Image(cw, ch)
        cropped:drawImage(img, Point(1 - minx, 1 - miny))
        results[#results + 1] = {
          frame = frame,
          img = cropped,
          pos = Point(cel.position.x - pad + minx - 1, cel.position.y - pad + miny - 1),
        }
        total_contours = total_contours + contours
        total_px = total_px + cnt_new
        total_adj = total_adj + cnt_adj
      end
    end
  end

  if #results == 0 then return nil, "ro_fail" end

  local labels = ui_labels()
  app.transaction(function()
    local new_layer = nil
    if opts.output == "layer" then
      new_layer = spr:newLayer()
      new_layer.name = labels.ro_layer_name
      new_layer.stackIndex = layer.stackIndex + 1
    end
    for _, r in ipairs(results) do
      if new_layer then
        local existing = new_layer:cel(r.frame)
        if existing then
          existing.image = r.img
          existing.position = r.pos
        else
          spr:newCel(new_layer, r.frame, r.img, r.pos)
        end
      else
        local cel = layer:cel(r.frame)
        cel.image = r.img
        cel.position = r.pos
      end
    end
  end)

  app.refresh()
  return {
    width = width,
    contours = total_contours,
    pixels = total_px,
    adjusted = total_adj,
  }
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

  plugin:newCommand{
    id = "FlattenColors",
    title = labels.flatten_title,
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
      if spr.colorMode == ColorMode.INDEXED then
        app.alert(labels.ft_indexed)
        return
      end

      local dlg = Dialog{ title = labels.flatten_title }
      if not dlg then return end

      dlg:label{ label = labels.flatten_about }
      dlg:separator{}
      dlg:number{ id = "tolerance", label = labels.ft_tolerance, text = "24", decimals = 0 }
      dlg:number{ id = "black_tol", label = labels.ft_black, text = "0", decimals = 0 }
      dlg:check{ id = "clear_semi", text = labels.ft_clear, selected = true }
      dlg:separator{}
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

      local res = flatten_colors{
        layer = app.activeLayer,
        tolerance = data.tolerance,
        black_tol = data.black_tol,
        clear_semi = data.clear_semi,
        all_frames = (data.scope == labels.scope_frames),
      }
      if res then
        local msg = string.format(labels.ft_summary, res.before, res.after, res.cleared)
        if res.black and res.black > 0 then
          msg = msg .. " " .. string.format(labels.ft_black_hit, res.black)
        end
        app.alert(msg)
      end
    end,
  }

  plugin:newCommand{
    id = "PerfectPixel",
    title = labels.pp_title,
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

      local dlg = Dialog{ title = labels.pp_title }
      if not dlg then return end

      dlg:label{ label = labels.pp_about }
      dlg:separator{}
      dlg:combobox{
        id = "sampling", label = labels.pp_sampling,
        option = labels.pp_s_majority,
        options = { labels.pp_s_majority, labels.pp_s_center, labels.pp_s_median },
      }
      dlg:combobox{
        id = "grid", label = labels.pp_grid,
        option = labels.pp_g_auto,
        options = { labels.pp_g_auto, labels.pp_g_manual },
      }
      dlg:number{ id = "grid_w", label = labels.pp_grid_w, text = "32", decimals = 0 }
      dlg:number{ id = "grid_h", label = labels.pp_grid_h, text = "32", decimals = 0 }
      dlg:number{ id = "merge", label = labels.pp_merge, text = "10", decimals = 0 }
      dlg:separator{}
      dlg:combobox{
        id = "output", label = labels.pp_output,
        option = labels.pp_o_sprite,
        options = { labels.pp_o_sprite, labels.pp_o_layer },
      }
      dlg:separator{}
      dlg:button{ id = "ok", text = "OK", focus = true }
      dlg:button{ id = "cancel", text = "Cancel" }
      dlg:show()

      local data = dlg.data
      if not data.ok then return end

      local method = "majority"
      if data.sampling == labels.pp_s_center then method = "center"
      elseif data.sampling == labels.pp_s_median then method = "median" end

      local manual = (data.grid == labels.pp_g_manual)
      local out_sprite = (data.output == labels.pp_o_sprite)

      local res, err = perfect_pixel_restore{
        method = method,
        grid_w = manual and data.grid_w or 0,
        grid_h = manual and data.grid_h or 0,
        merge_tol = math.max(0, math.min(255, data.merge or 0)),
        output = out_sprite and "sprite" or "layer",
        frame = app.frame,
      }
      if not res then
        app.alert(err == "pp_fail" and labels.pp_fail or labels.no_layer)
        return
      end
      if res.auto and (res.cell_w < 4 or res.cell_w > 20 or res.cell_h < 4 or res.cell_h > 20) then
        app.alert(string.format(labels.pp_bad_size, res.cell_w, res.cell_h))
      end
      local msg
      if out_sprite then
        msg = string.format(labels.pp_result_sprite, res.cell_w, res.cell_h, res.nw, res.nh)
      else
        msg = string.format(labels.pp_result_layer, res.cell_w, res.cell_h, res.nw, res.nh)
      end
      if res.colors_before then
        msg = msg .. " " .. string.format(labels.pp_colors, res.colors_before, res.colors_after)
      end
      app.alert(msg)
    end,
  }

  plugin:newCommand{
    id = "RedrawOutline",
    title = labels.ro_title,
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

      local dlg = Dialog{ title = labels.ro_title }
      if not dlg then return end

      dlg:label{ label = labels.ro_about }
      dlg:separator{}
      dlg:number{ id = "dark", label = labels.ro_dark, text = "60", decimals = 0 }
      dlg:number{ id = "max_line", label = labels.ro_max_line, text = "5", decimals = 0 }
      dlg:number{ id = "width", label = labels.ro_width, text = "2", decimals = 0 }
      dlg:color{ id = "color", label = labels.ro_color, color = Color{ r = 0, g = 0, b = 0, a = 255 } }
      dlg:separator{}
      dlg:combobox{
        id = "output", label = labels.ro_output,
        option = labels.ro_o_replace,
        options = { labels.ro_o_replace, labels.ro_o_layer },
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

      local res, err = redraw_contour{
        layer = app.activeLayer,
        dark_threshold = data.dark,
        max_line_width = data.max_line,
        width = data.width,
        color = data.color,
        output = (data.output == labels.ro_o_layer) and "layer" or "replace",
        all_frames = (data.scope == labels.scope_frames),
      }
      if not res then
        app.alert(err == "ro_fail" and labels.ro_fail or labels.no_layer)
        return
      end
      app.alert(string.format(labels.ro_summary, res.contours, res.width, res.pixels, res.adjusted))
    end,
  }
end
