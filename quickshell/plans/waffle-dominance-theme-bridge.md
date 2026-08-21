# Plan: Phase 1 — Bridge Yemi/Dominance theme into Waffle (the "Auto" slot)

## Goal
Make iNiR's verbatim waffle `Looks.qml` resolve against the Yemi-shell (Dominance) theme
stack so waffle renders the Dominance palette — **without breaking Pill**. This is the
"pack yemishell theme for waffle" step. Waffle's own iNiR theme
machinery (ThemePresets / real MaterialThemeLoader / scheduled+night themes / ii·aurora·angel
styles / wallpaper quantizer) is **Phase 2**, after waffle is functionally complete. Porting
remaining modules is **Phase 3**.

## Why this approach (Option A)
Waffle widgets read only `modules/waffle/looks` (`Looks.qml`), which reads `Appearance.*`.
The seam is entirely at `Appearance`. `Dyn.active` (the Dominance M3 scheme) is the SAME source
Pill already uses (`Theme`/`yemi*` are derived from `Dyn`), so bridging to `Dyn` converges —
Pill keys are preserved, only additive tokens are added. The waffle `Looks.qml` is brought in
via **rename** (current stubbed copy kept as `Looks.stub.qml`), not line-edited.

## Current state / gap
- `config/Appearance.qml` (singleton, registered in `config/qmldir`) is Dominance-shaped:
  exposes `colors.*` (from `Theme.onGlow/verm/cream/cardBot`) and `m3: Dyn.active`,
  `yemi*`/`flame*`. It is **missing** every iNiR-shaped prop waffle's `Looks` references:
  `m3colors`, `aurora`, `angel`, `inirEverywhere`, `auroraEverywhere`, `angelEverywhere`,
  `globalStyle`, `backgroundTransparency`, `contentTransparency`, `autoBackgroundTransparency`,
  `autoContentTransparency`, `wallpaperVibrancy`, `wallpaperDominantColor`, and many `colors.*`
  tokens (colLayer3/4, colOnLayer0/2, colOnLayer1Inactive, hover/active variants, *Container,
  colTertiary*, colError*, colSurface, colPopupSurface, colOverlay, colTooltip, colOnTooltip,
  colShadow, colText*, colBorder*, colInput*, colScrollbar*, colSelection*, colAccent, colInfo,
  colWarning, colSuccess*).
- **Waffle `Looks.qml` is currently STUBBED** (not iNiR-verbatim): every theme-dependent line is
  commented as `// ORIGINAL (iNiR, restore when theme bridge is built):` and replaced with hardcoded
  values (`dark: true`, `bg0Opaque: "#1e1e1e"`, `accentActive: "#3a88f2"`, `fg: "#e6e6e6"`, etc.),
  plus an added `import qs.config`. Phase 1 therefore **replaces** it via rename (see Implementation
  step 0) rather than editing those stubs.
- `Config.options.appearance.globalStyle` defaults to `"material"` (Config.qml:346).
  `Config.options.waffles.theming.useMaterialColors` defaults to `true` (Config.qml:2091).
  → once `colors`/`m3colors` are Dyn-backed, waffle (useMaterial=true, material style ⇒
  `glassActive=false`) renders Dominance solid surfaces. Matches "pack yemishell theme for waffle".
- `Dyn.active` = raw mood M3 scheme, snake_case keys:
  `surface, surface_container, surface_container_low, surface_container_high,
  surface_container_highest, primary, primary_container, on_primary, on_primary_container,
  secondary, secondary_container, on_secondary, tertiary, tertiary_container, on_tertiary,
  on_tertiary_container, outline, outline_variant, on_surface, on_surface_variant, error,
  error_container, on_error, on_error_container, inverse_surface, inverse_on_surface`.
  `Flags.systemMood` selects dark/light; `Dyn.schemeValid` gates.

## Implementation (edit `config/Appearance.qml`; replace `Looks.qml` via rename)

0. **Replace waffle `Looks.qml` via rename** (do NOT line-edit the stubs):
   - Rename current stubbed `modules/waffle/looks/Looks.qml` → `Looks.stub.qml` (kept for reference;
     `qmldir` still maps `Looks → Looks.qml`, so the stub becomes inert).
   - Copy iNiR `modules/waffle/looks/Looks.qml` → `modules/waffle/looks/Looks.qml`.
   - Add `import qs.config` to its header (quickshell's `Appearance` lives at `qs.config`, not
     auto-imported as in iNiR). Keep `import qs.modules.common` + `qs.modules.common.functions`.
   - Result: waffle uses the true iNiR `Looks`, which reads the `Appearance` bridge built below.
1. **Add `m3colors` QtObject** derived from `Dyn.active` (with `?? fallback` + `Dyn.schemeValid`):
   darkmode = `Flags.systemMood !== "light"`; map each iNiR `m3*` token ← `Dyn.active.<snake_key>`
   (m3background←surface, m3onBackground←on_surface, m3surface←surface,
   m3surfaceContainerLow←surface_container_low, m3surfaceContainer←surface_container,
   m3surfaceContainerHigh←surface_container_high, m3surfaceContainerHighest←surface_container_highest,
   m3primary←primary, m3onPrimary←on_primary, m3primaryContainer←primary_container,
   m3onPrimaryContainer←on_primary_container, m3secondary←secondary, m3onSecondary←on_secondary,
   m3secondaryContainer←secondary_container, m3onSecondaryContainer←on_secondary_container,
   m3tertiary←tertiary, m3onTertiary←on_tertiary, m3tertiaryContainer←tertiary_container,
   m3onTertiaryContainer←on_tertiary_container, m3onSurface←on_surface,
   m3onSurfaceVariant←on_surface_variant, m3outline←outline, m3outlineVariant←outline_variant,
   m3error←error, m3onError←on_error, m3errorContainer←error_container,
   m3onErrorContainer←on_error_container, m3inverseSurface←inverse_surface,
   m3inverseOnSurface←inverse_on_surface, transparent:false).
   Use iNiR's literal hex defaults as fallbacks so waffle never sees `undefined`.
2. **Add style + transparency + dominant props**:
   - `globalStyle`: `Config.options?.appearance?.globalStyle ?? "material"`
   - `inirEverywhere: globalStyle === "inir"`
   - `auroraEverywhere: globalStyle === "aurora" || globalStyle === "angel"`
   - `angelEverywhere: globalStyle === "angel"`
   - `backgroundTransparency` / `contentTransparency`: from `Config.options?.appearance?.transparency`
     (toggle+values); default `0` when disabled (mirror iNiR, simplified — transparency OFF by default).
   - `autoBackgroundTransparency` / `autoContentTransparency`: constant defaults (no vibrancy calc in P1).
   - `wallpaperVibrancy`: `0` (no quantizer yet).
   - `wallpaperDominantColor: Dyn.schemeValid ? Dyn.primary : m3colors.m3primary`.
    - `aurora` QtObject (MUST expose — `Looks` references these even in material style):
      `overlayTransparentize, subSurfaceTransparentize, popupTransparentize, tooltipTransparentize,
      layerTransparentize, colOverlay, colOverlayHover, colSubSurface, colSubSurfaceHover,
      colSubSurfaceActive, colElevatedSurface, colElevatedSurfaceHover, colPopupSurface,
      colPopupSurfaceHover, colPopupSurfaceActive, colTooltipSurface, colTooltipBorder,
      colDialogSurface, colPopupBorder, colTextSecondary`.
      Source transparency from `Config.options?.appearance?.aurora?.transparency` (add keys if
      missing, iNiR defaults: overlay 0.30, subSurface 0.42, popup 0.32, tooltip 0.28, layer 0.32);
      colors derived from `m3colors`/`colors` via `ColorUtils.transparentize`.
    - `angel` QtObject (used when globalStyle = angel): at minimum expose
      `blurIntensity, blurSaturation, overlayOpacity, noiseOpacity, vignetteStrength,
      panelTransparentize, cardTransparentize, popupTransparentize, tooltipTransparentize,
      colGlassPanel, colGlassCard, colGlassCardHover, colGlassCardActive, colGlassElevated,
      colGlassElevatedHover, colGlassElevatedActive, colGlassPopup, colGlassPopupHover,
      colGlassPopupActive, colGlassTooltip, colGlassTooltipHover, colGlassTooltipActive,
      colBorderSubtle, colPanelBorder`. Source from `Config.options?.appearance?.angel?.transparency`
      (add keys if missing). Only used in angel style (not P1 default) but must be defined.
3. **Expand `colors` (keep Pill keys, add M3 tokens)**:
   - PRESERVE existing `var colors` keys Pill uses (colPrimary=Theme.onGlow, colLayer0/1/2=cardBot-based,
     colSubtext, colOnLayer1, colOutlineVariant, colLayer0Border, colLayer1Border, colScrim,
     colLayer2Hover, colLayer1Hover, colPrimaryHover).
   - ADD tokens `Looks` reads, derived from `m3colors` + `ColorUtils` (mirror iNiR's `Appearance.colors`
     derivation — it already references `m3colors`, `backgroundTransparency`, `contentTransparency`,
     `aurora.layerTransparentize`, `ColorUtils`):
     colLayer0..4 (+Hover/Active), colOnLayer0..4, colOnLayer1Inactive,
     colPrimaryContainer, colPrimaryContainerHover/Active, colOnPrimaryContainer, colOnPrimary,
     colSecondary(keep)/Hover/Active, colSecondaryContainer, colOnSecondary, colOnSecondaryContainer,
     colTertiary(keep)/Hover/Active, colTertiaryContainer, colOnTertiary, colOnTertiaryContainer,
     colError(keep)/Hover, colErrorContainer, colOnError, colOnErrorContainer,
     colSurface, colSurfaceHover, colPopupSurface, colOverlay, colTooltip, colOnTooltip, colShadow,
     colText, colTextSecondary, colTextMuted, colBorder*, colInput*, colScrollbar*, colSelection*,
     colAccent, colInfo, colWarning, colSuccess*.
   - Since `m3colors` is the same `Dyn` source Pill already uses, converging shared keys is safe.
4. **Guard `MaterialThemeLoader` (no clobber)**: quickshell's ported `MaterialThemeLoader`
   watches an iNiR colors.json path that `after-wall.sh` does NOT write (it writes
   `yemi-shell/colors.json` for `Dyn`). Confirm its watcher stays inert; if it could fire,
   gate `applyColors` or make `m3colors` non-mutable so it can't overwrite Dyn-derived values.
   Phase 2 wires the real iNiR theme apply.

## Defaults (Phase 1)
- `globalStyle="material"` ⇒ `glassActive=false` ⇒ waffle = solid Dominance surfaces.
- `useMaterialColors=true` (already) ⇒ waffle renders Dominance M3 via `colors`.
- Transparency OFF by default (toggle later).
Result: waffle shows the Yemi/Dominance theme. (To instead keep Win11 greys by default, set
`waffles.theming.useMaterialColors=false` — one-line; confirm desired default at implement time.)

## Validation
1. Parse: switch `panelFamily` to `"waffle"`; confirm NO QML errors for
   `Appearance.m3colors` / `aurora` / `angel` / `inirEverywhere` / `backgroundTransparency` / `wallpaperDominantColor`.
2. Live: waffle family → bar/panels render with Dominance accent + surfaces (not Win11 grey, since useMaterial=true).
3. Change wallpaper via `after-wall.sh` → `Dyn` updates → waffle recolors (Auto behavior).
4. Pill family still renders correctly — shared common widgets now read the same Dyn-backed
   `Appearance.colors` (verify no visual regression).
5. Toggle `appearance.globalStyle` to `aurora`/`angel` → glass paths resolve (no crash); revert to `material`.
6. Toggle `waffles.theming.useMaterialColors=false` → waffle falls back to Win11 greys (proves non-material path resolves).

## Risks
- `Looks.qml` may reference a token not enumerated above → add during validation.
- Expanding `Appearance.colors` also feeds the **shared common widget library** (used by Pill via
  `modules/common/widgets/**`). Values converge on `Dyn` (Dominance) so Pill stays theme-correct,
  but validate Pill's shared widgets for visual regression after the change.
- `MaterialThemeLoader` mutation of `m3colors` must be inert in Phase 1 (its watcher path is
  `${stateUserPath}/generated/colors.json`; confirm it never points at a valid iNiR-schema file,
  or gate `applyColors`).

## Out of scope (future)
- **Phase 2**: connect waffle's own iNiR theme machinery — ThemePresets, real MaterialThemeLoader
  apply (matugen/switchwall), scheduled/night themes, ii·aurora·angel styles, wallpaper quantizer
  for `wallpaperDominantColor`/`wallpaperVibrancy`, "Auto" regen signature. Done once waffle complete.
- **Phase 3**: port remaining waffle modules/services (the "more mods").
