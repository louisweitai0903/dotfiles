# Frontend Standards

## Layout & styling

- Position and align elements with layout primitives (flexbox, grid,
  margin-inline: auto). Never use padding, margins, or absolute offsets
  to visually nudge something into a centered or aligned position.
- Use padding/margin/gap only for spacing, and only with values from the
  project's spacing scale/design tokens. No arbitrary pixel values.
  If the project has no scale, use the CSS/UI framework's default scale
  (e.g. Tailwind's spacing utilities). With no framework either, define
  a small scale once as CSS custom properties (e.g. `--space-1` …
  `--space-6` in rem) and use only those.
- Prefer relative/fluid sizing (rem, %, fr, min/max/clamp) over fixed px
  so layouts adapt to container size.

## Component reuse

- When a component is needed on another page, reuse it: move or extract
  it to a shared location and import it. Never duplicate or rewrite it.
- Replace page-specific dependencies (context, route params, fetched
  data) with props so the component works in both places.
- Handle small variations with props; if variations grow large, prefer
  composition over adding many conditional flags.
- After moving, update all imports and delete the old copy.

## Design & interaction

- Make every screen that has a primary task action-led: one obvious,
  high-contrast call-to-action with a clear verb label, placed where the
  eye lands. Don't invent a CTA on read-only screens; on error screens
  the CTA is the recovery action (Retry / Go back).
  Users should be able to click without having to think.
- Web applications must work on mobile, tablet and desktop. Check the
  layout at each breakpoint.
- On mobile, prefer icons over text for actions and navigation. Every
  icon-only control still needs an accessible label (`aria-label` or
  equivalent), and keep a text label where an icon alone is ambiguous.
- Any button that waits on the backend shows a loading state and is
  disabled until the response arrives, so repeated clicks can't fire
  duplicate requests. On error or timeout, re-enable it and show the
  error.
- Use one font family across the app, and one design language (colors,
  radii, shadows, component styles) on every page, unless the user
  explicitly says otherwise.
