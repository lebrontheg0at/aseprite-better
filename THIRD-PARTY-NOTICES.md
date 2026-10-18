# Third-party notices

## This extension

`aseprite-better` — CC0 1.0 Universal (public domain). See [LICENSE](LICENSE).

## Perfect Pixel — grid restore algorithm

The **Perfect Pixel (Grid Restore)** command in this extension implements the
algorithm of the following project, which is licensed under the MIT License:

- **Perfect Pixel** — https://github.com/theamusing/perfectPixel
- Author: theAmusing
- Distributed on PyPI as [`perfect-pixel`](https://pypi.org/project/perfect-pixel/) (License: MIT)

The upstream project is the authoritative source for its own license text and
copyright line. Related projects:

- `perfectPixel-ComfyUI` by TobyKSKGD — a ComfyUI node that wraps the package
  above; it contains no algorithm code of its own.

**No upstream source code was copied into this extension.** The Lua code was
written from scratch against the Aseprite API, following the algorithm
(gradient-profile grid size estimation, per-grid-line snapping, per-cell
sampling) together with the deviations documented in [README](README.md):

- only the gradient estimator is ported; the FFT estimator is not,
- the peak threshold uses a high percentile of the profile instead of its
  maximum, so transparent margins do not hide the grid,
- sampling is alpha-aware and skips fully transparent pixels,
- an optional post-pass merges the near-duplicate colours produced by sampling
  each cell independently.

Because the implementation follows a MIT-licensed work, the MIT License text is
reproduced below in full for attribution.

### MIT License

```
MIT License

Copyright (c) theAmusing

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```
