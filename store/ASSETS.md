# Store Graphic Assets

Specs and a capture plan for the images Google Play requires.

## Generated assets (ready to upload)

| Asset | File | Size |
| --- | --- | --- |
| App icon | `graphics/icon-512.png` | 512 × 512 |
| Feature graphic | `graphics/feature-graphic.png` | 1024 × 500 |
| Phone screenshot 1 | `graphics/screenshots/01-live-matrix.png` | 1080 × 2400 |
| Phone screenshot 2 | `graphics/screenshots/02-color-order.png` | 1080 × 2400 |
| Phone screenshot 3 | `graphics/screenshots/03-matrix-48x32.png` | 1080 × 2400 |

The app icon is downscaled from `assets/icon/icon.png` (1024²) with:
`python -c "from PIL import Image; Image.open('assets/icon/icon.png').convert('RGBA').resize((512,512), Image.LANCZOS).save('store/graphics/icon-512.png')"`

Regenerate any time (Windows, needs Python + Pillow):

```bash
python graphics/make_feature_graphic.py   # -> graphics/feature-graphic.png
python graphics/make_screenshots.py       # frames graphics/raw/*.png -> graphics/screenshots/
```

Raw, unframed device captures are kept in `graphics/raw/` (captured from the
release build on an Android emulator with the bundled `tool/test_sender.dart`
feeding a live DDP rainbow).

## Required by Play

| Asset | Spec | Notes |
| --- | --- | --- |
| App icon | 512 × 512 PNG, 32-bit w/ alpha, ≤ 1 MB | Already have a source at `assets/icon/icon.png` — export/resize to 512². |
| Feature graphic | 1024 × 500 PNG or JPG, no alpha | Banner at top of the listing. Put the icon + "DDP Viewer" + tagline on the `#18181D` brand background. |
| Phone screenshots | 2–8 images; JPG or 24-bit PNG (no alpha); 320–3840 px per side; aspect 16:9 or 9:16 | Required to publish. |
| 7" tablet screenshots | Same format | Optional, recommended. |
| 10" tablet screenshots | Same format | Optional, recommended. |

Brand background color: `#18181D` (matches the adaptive-icon background in
`pubspec.yaml`).

## Capturing screenshots

Run a release build on a device/emulator, then for each shot:

```bash
flutter run --release
# capture with:  adb exec-out screencap -p > shot1.png
```

Suggested set (matches the listing copy):

1. **Test pattern** — toggle the in-app animated rainbow so the canvas is full
   and colorful. Best "hero" shot.
2. **Live matrix** — a real xLights/FPP sequence playing on a matrix layout.
3. **xModel** — an imported `.xmodel` rendering a sparse/custom shape.
4. **Stats overlay** — FPS / packets-per-second / source IP visible.
5. **Config screen** — color order, channel offset, and layout-mode controls.

If you have no sender handy for shots 2–3, use the bundled tools:

```bash
dart run tool/test_sender.dart   # emit a synthetic DDP stream
```

## Optional polish

Frame the raw screenshots on the `#18181D` background with a one-line caption
each (e.g. "Live, flicker-free DDP rendering", "Import xLights .xmodel files",
"Per-stream stats at a glance"). Many tools (or a quick Figma/Canva template)
can batch this.
