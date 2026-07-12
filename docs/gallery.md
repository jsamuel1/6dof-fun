# Gallery

Photos of the build as it progresses — bench tests, calibration, first poses,
and the printed mounts. The gallery starts empty and fills in as milestones
land (first choreographed pose sequence, PLA fit checks, PETG finals).

## Build photos

<figure markdown>
  ![The assembled arm, side view](img/arm-full-view.jpg){ width="600" }
  <figcaption>The fully assembled arm on the bench — all six MG996R servos mounted, wiring loomed back to the base.</figcaption>
</figure>

<figure markdown>
  ![Elegoo controller, PCA9685 driver, and USB cables](img/electronics-components.jpg){ width="600" }
  <figcaption>The electronics before wiring: Elegoo Mega controller, PCA9685 16-channel PWM/servo driver, and USB cables.</figcaption>
</figure>

<figure markdown>
  ![Elegoo ESP32 boards in their case](img/esp32-boards.jpg){ width="600" }
  <figcaption>The Elegoo ESP32 boards (WiFi + Bluetooth, Arduino-IDE compatible) that run the micro-ROS firmware.</figcaption>
</figure>

## Adding photos

Images live in `docs/img/` in the repository.

1. Copy the photo into `docs/img/`. Use short, dated, descriptive names:

   ```
   docs/img/2026-07-15-single-servo-sweep.jpg
   docs/img/2026-07-20-first-pose.jpg
   ```

2. Resize before committing — around 1600px on the long edge keeps the repo
   and page loads reasonable:

   ```bash
   # macOS, in-place resize
   sips -Z 1600 docs/img/2026-07-20-first-pose.jpg
   ```

3. Add an entry to this page with a caption:

   ```markdown
   <figure markdown>
     ![First choreographed pose](img/2026-07-20-first-pose.jpg){ width="600" }
     <figcaption>First choreographed pose sequence — all six joints under Foxglove control.</figcaption>
   </figure>
   ```

4. Commit the image and this page together. The docs workflow republishes the
   site on push to `main`.

The [home page](index.md) currently shows a placeholder hero image
(`docs/img/hero-placeholder.svg`). When you have a good photo of the
assembled arm, add it as `docs/img/hero.jpg` and update the image reference
at the top of `docs/index.md`.
