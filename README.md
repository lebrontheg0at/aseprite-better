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

**Black threshold** is a separate tolerance measured from pure black: any color
whose **every channel** is at or below the value is snapped to `#000000` before
the normal merge runs. That is how dark noise, off-black outlines and near-black
shadows collapse into one true black instead of a cluster of slightly different
dark greys. `0` disables it. It is per channel, so `16` catches everything up to
`(16,16,16)` — easier to reason about than a Euclidean radius for this case. The
regular merge tolerance still uses Euclidean RGB distance.

Not supported in Indexed color mode (convert with `Sprite → Color Mode → RGB`
first).

### 4. Perfect Pixel (Grid Restore)

`Edit → FX → Perfect Pixel` (`编辑 → FX → 完美像素`).

For artwork that came out of an upscaler or an image generator: it detects the
underlying pixel grid and resamples exactly one colour per cell, turning soft or
noisy "fake pixel art" edges back into crisp pixel blocks.

| Option | Meaning |
|---|---|
| Sampling | **Majority cluster** (two-means per cell — most robust), **Center sample**, or **Median** |
| Grid size | **Auto detect**, or type the column/row count yourself |
| Merge similar colors | Tolerance for merging near-duplicate colours *after* sampling; `0` disables it |
| Output | **New sprite** at the true pixel size, or **new layer** that keeps the canvas size |

Algorithm reference: [Perfect Pixel](https://github.com/theamusing/perfectPixel)
by theAmusing (MIT) — see [THIRD-PARTY-NOTICES.md](THIRD-PARTY-NOTICES.md) for the
full attribution and license text. Grid size is estimated from gradient profiles,
each grid line is then snapped to the strongest nearby edge, and one sample is
taken per cell. This is an
independent Lua implementation for Aseprite, with three deliberate differences:

- Only the gradient estimator is ported; the upstream FFT estimator is not.
- The peak threshold uses a high percentile of the profile instead of its maximum,
  so a transparent margin (whose hard "empty → artwork" edge can dwarf every real
  grid line) does not hide the grid. Upstream would fail on such sprites.
- Sampling is alpha-aware and skips fully transparent pixels, so sprites with
  transparent backgrounds restore cleanly instead of picking up muddy edges.
  A cell with no opaque pixel is written out as fully transparent.

Each cell is sampled independently, so cells sharing one true colour still differ
by a few units — that is why the merge step exists (upstream expects a separate
quantisation pass; here `Flatten Colors` can do it too).

### 5. Redraw Outline

`Edit → FX → Redraw Outline` (`编辑 → FX → 重绘描边`).

Takes artwork whose outline is uneven — mixed colours, 1 px here and 2 px there —
and redraws it as one flat colour at exactly one width.

| Option | Meaning |
|---|---|
| Outline width | The new outline's thickness in px (1–8) |
| Outline color | One flat colour for the whole outline |
| Strip old outline | How many outer layers of the existing silhouette to peel off first. Set it to the **maximum** width of the old outline; `0` just adds a clean outline around the artwork as-is |
| Output | Replace the current layer, or put the redrawn copy on a new layer above |

The outline is the ring of pixels touching the peeled shape, including diagonal
touches — the same shape a hand-drawn pixel-art outline has, corners included.

Two things worth knowing:

- Stripping peels **layers of the silhouette**, it cannot tell outline from
  artwork. Wherever the old outline was thinner than the strip amount, one layer
  of the artwork itself is peeled too. Prefer redrawing over iterating small
  changes, or use the new-layer output to compare.
- Peeling too far empties thin parts of the shape; the command refuses with a
  message instead of erasing them silently.

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
