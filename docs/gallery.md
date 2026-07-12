# Gallery

Photos of the build as it progresses — bench tests, calibration, first poses,
and the printed mounts. The gallery starts empty and fills in as milestones
land (first choreographed pose sequence, PLA fit checks, PETG finals).

!!! note "No photos yet"
    The build is in progress. Photos land here as each bring-up milestone
    completes.

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
