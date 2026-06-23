# DDP Viewer — Google Play Store Listing

Copy-paste ready content for the Play Console **Main store listing**. Character
limits noted next to each field; all values below are within limit.

---

## App name (max 30)

```
DDP Viewer
```

Alternative if you want keywords in the name (29 chars):

```
DDP Viewer — Pixel Monitor
```

---

## Short description (max 80)

```
Watch live DDP pixel data on your screen — virtual LEDs for xLights, FPP & more.
```

(79 chars)

---

## Full description (max 4000)

```
DDP Viewer turns your phone, tablet, or Android device into a live virtual LED
display. It listens for DDP (Distributed Display Protocol) pixel data on your
local network and renders it on screen in real time — no physical controllers,
no wiring, and no LEDs required.

Point any DDP sender — xLights, FPP (Falcon Player), pixel mapper tools, or your
own software — at the device running DDP Viewer and watch your layout light up
instantly.

WHY USE IT
• Preview your sequences and effects without setting up real hardware.
• Test a model or universe on the couch before deploying it to the yard.
• Debug your DDP output: confirm color order, channel mapping, and frame rate.
• Use a spare phone or tablet as a dedicated effects monitor.

LIVE DDP RECEIVER
Listens on UDP port 4048 and reassembles incoming packets into complete frames.
Rendering is decoupled from packet arrival, so the picture stays smooth and
flicker-free no matter how a sender chunks frames or uses the PUSH flag.

TWO LAYOUT MODES
• Matrix — define a simple width × height pixel grid right in the app.
• xModel — import an xLights .xmodel Custom model file to render its exact pixel
  grid, including sparse and irregular layouts.

GET THE COLORS RIGHT
Configurable color order — RGB, GRB, BGR, RBG, GBR, or BRG — so WS2812 strips
(usually GRB) and every other device display with accurate colors.

FLEXIBLE CHANNEL MAPPING
Set a channel offset to start reading at any channel, perfect for viewing a
single model inside a larger universe.

LIVE STATS OVERLAY
See FPS, packets per second, the last sequence number, displayed pixel count,
and the source IP of the most recent datagram — everything you need to verify
your stream at a glance.

BUILT-IN TEST PATTERN
No sender on the network? Toggle the animated rainbow test pattern to drive the
canvas locally and confirm your layout renders correctly.

GETTING STARTED
1. Open DDP Viewer and configure your layout (Matrix or import an .xmodel).
2. Find the device's IP address (shown in the app / your network settings).
3. From your DDP sender, send pixel data to that IP on port 4048.
4. Watch it light up.

DDP Viewer is built for the holiday-lights, pixel-art, and LED hobbyist
community. It's a viewer and diagnostic tool — it does not control physical
hardware, so it's completely safe to experiment with.

Open source. No ads. No accounts. No tracking.
```

---

## Listing details

| Field | Suggested value |
| --- | --- |
| **App category** | Tools (alt: House & Home, or Entertainment) |
| **Tags** | LED, pixels, DDP, xLights, lighting |
| **Contact email** | scott@scottnation.com |
| **Website** | (your GitHub repo URL) |
| **Privacy policy** | Required — see `store/privacy-policy.md` |

---

## Data safety form (Play Console)

DDP Viewer collects and transmits **no** personal or usage data. Answer the
Data safety section as:

- **Does your app collect or share user data?** No
- **Is all user data encrypted in transit?** N/A (no data collected)
- **Do you provide a way to request data deletion?** N/A

Network usage: the app only **receives** UDP datagrams on the local network and
renders them. It does not send personal data anywhere.

---

## Content rating

Expected rating: **Everyone**. When completing the IARC questionnaire, answer
"No" to all violence, sexuality, gambling, controlled-substance, and
user-interaction/data-sharing questions. The app has no social features, no
in-app purchases, and no ads.

---

## Graphic asset checklist

Play requires these before you can publish. See `store/ASSETS.md` for specs and
suggested capture shots.

- [ ] **App icon** — 512 × 512 PNG (32-bit, with alpha). Source: `assets/icon/icon.png`.
- [ ] **Feature graphic** — 1024 × 500 PNG/JPG (no transparency). Shown at top of listing.
- [ ] **Phone screenshots** — 2–8 images, 16:9 or 9:16, min 320 px, max 3840 px.
- [ ] **7-inch tablet screenshots** — optional but recommended.
- [ ] **10-inch tablet screenshots** — optional but recommended.

Suggested screenshots:
1. Live rainbow test pattern filling the canvas.
2. A matrix layout receiving a real xLights sequence.
3. An imported xModel rendering a sparse/custom shape.
4. The stats overlay (FPS / packets / source IP) visible.
5. The configuration screen (color order, channel offset, layout mode).

---

## Pre-launch technical notes (not part of the listing)

These are blockers for a production release — not store-listing copy, but you'll
hit them when you upload.

DONE:
- [x] **Application ID** set to `com.sandbdesigns.ddpviewer` (`build.gradle.kts`,
      `namespace` + `applicationId`; `MainActivity.kt` moved to match).
- [x] **Release signing config** scaffolded. Provide `android/key.properties`
      (see `android/key.properties.example`) and your upload keystore; until then
      release builds fall back to the debug key automatically.
- [x] **Launcher label** changed to `DDP Viewer`
      (`android/app/src/main/AndroidManifest.xml`).
- [x] **INTERNET permission** added to the main manifest so release builds can
      receive UDP (`android/app/src/main/AndroidManifest.xml`).

STILL TODO:
1. Create your upload keystore and `android/key.properties`, then build the
   artifact with `flutter build appbundle --release`.
```

