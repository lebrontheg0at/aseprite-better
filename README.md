# Aseprite Better

A small collection of quality-of-life commands for [Aseprite](https://www.aseprite.org/),
bundled in one extension.

![preview](docs/preview.png)

## Commands

### 1. Toggle Visibility of Bottom Layer

Toggles the bottom-most layer (Layer 1) — the layer at the bottom of the Layers
panel — regardless of which layer is currently selected. Useful for flipping
backgrounds or reference layers on and off while drawing.

Aseprite's built-in `LayerVisibility` command only affects the *active* layer;
this one always targets the bottom of the stack.

### 2. Drop Shadow

Generates a drop shadow from the active layer's artwork. Pixel edges stay crisp —
no anti-aliasing is introduced.

| Mode | What it produces |
|---|---|
| **Darken artwork** | Shadow color = each pixel's own color scaled by "Keep brightness %". Organic, palette-consistent shadows. |
| **Custom color** | One flat color for the whole shadow. Default: **black at 60% opacity** — the classic look. |
| **Snap to palette** | Like custom color, but snapped to the nearest entry of the sprite palette. |

Options: offset X/Y (negatives allowed), softness (alpha box-blur radius; 0 = hard
pixel-art edges), opacity, output (new layer below / merged into current layer),
scope (current frame / all frames of the layer).

### 3. Flatten Colors

`Edit → FX → Flatten Colors` (`编辑 → FX → 扁平化`).

Removes the two things that make pixel art look "muddy":

- **Semi-transparent pixels** (0 < alpha < 100%) become **fully transparent**.
- **Similar colors** are merged into one, so the artwork ends up with few flat
  colors and no visible gradients. The tolerance controls how far apart two
  colors may be and still count as "the same".

The color histogram is collected across all processed frames before clustering, so
the same input color always maps to the same output color in every frame — the
flattening stays consistent over an animation.

A summary is shown afterwards, e.g. `Flattened: 118 colors → 24, cleared 312
semi-transparent pixel(s)`.

Not supported in Indexed color mode (convert with `Sprite → Color Mode → RGB`
first).

## Install

Copy `package.json` and `aseprite_better.lua` into:

```
%APPDATA%\Aseprite\extensions\aseprite-better\
```

Then restart Aseprite. Or double-click the packaged `.aseprite-extension` file.

## Usage

- Toggle bottom layer: bind a shortcut in `Edit → Keyboard Shortcuts` (search
  "Toggle Visibility of Bottom Layer" / "切换最底层可见性"). It also appears in the
  Layer menu.
- Drop shadow: `Edit → FX → Drop Shadow` (`编辑 → FX → 投影`).

Both command titles follow the Aseprite UI language (Chinese or English).

## Implementation notes

- `sprite.layers` is ordered bottom-to-top: `layers[1]` is the bottom layer.
- Aseprite's Lua API has no layer-reorder function, but `Layer.stackIndex` is
  writable — the shadow layer uses it to insert itself directly below the source layer.
- The current frame is `app.frame` (there is no `sprite.frame`).
- Aseprite ships no blur filter, so the soft-shadow mode uses a hand-written
  separable box blur over the alpha channel.
- Merge mode grows the cel to cover artwork + shadow, then writes shadow pixels
  only where the artwork is transparent, so original pixels are never overwritten.

## License

CC0 — Public Domain.
