---
name: CV Ready
description: A phone-first CV workshop where the CV is a lump of clay pressed into shape until it is ready.
colors:
  scarlet-rush: "#DA2C38"
  turf-green: "#226F54"
  willow-green: "#87C38F"
  lemon-chiffon: "#F4F0BB"
  dark-coffee: "#43291F"
  willow-ground: "#E9F1E4"
  ground-surface: "#F5F9F3"
  lemon-raised: "#FCFAEB"
  lemon-paper: "#F8F5D3"
  well-base: "#DFECDC"
  coffee-muted: "#8A7A74"
  coffee-line: "#E1DDDB"
  turf-soft: "#E0EBE7"
  scarlet-soft: "#FAE1E3"
  turf-deep: "#2E5641"
  scarlet-deep: "#AD2B30"
  night-ground: "#251711"
  night-surface: "#372219"
  night-paper: "#553D2F"
  night-line: "#634D3B"
  night-ink: "#F8F6D6"
  night-muted: "#AA9C79"
  night-slab: "#1A533F"
  night-accent: "#DE4550"
  night-danger: "#E1525C"
  night-success-soft: "#524B38"
  night-danger-soft: "#6D2A26"
typography:
  display-large:
    fontFamily: "Bricolage Grotesque"
    fontSize: "52px"
    fontWeight: 800
    lineHeight: 1.1
    letterSpacing: "-1.6px"
  display-medium:
    fontFamily: "Bricolage Grotesque"
    fontSize: "42px"
    fontWeight: 800
    lineHeight: 1.1
    letterSpacing: "-1.2px"
  display-small:
    fontFamily: "Bricolage Grotesque"
    fontSize: "34px"
    fontWeight: 800
    lineHeight: 1.1
    letterSpacing: "-1px"
  headline-large:
    fontFamily: "Bricolage Grotesque"
    fontSize: "30px"
    fontWeight: 700
    lineHeight: 1.1
    letterSpacing: "-0.8px"
  headline-medium:
    fontFamily: "Bricolage Grotesque"
    fontSize: "26px"
    fontWeight: 700
    lineHeight: 1.1
    letterSpacing: "-0.6px"
  headline-small:
    fontFamily: "Bricolage Grotesque"
    fontSize: "22px"
    fontWeight: 700
    lineHeight: 1.2
    letterSpacing: "-0.4px"
  title-large:
    fontFamily: "Figtree"
    fontSize: "19px"
    fontWeight: 700
    lineHeight: 1.3
    letterSpacing: "-0.2px"
  title-medium:
    fontFamily: "Figtree"
    fontSize: "16px"
    fontWeight: 700
    lineHeight: 1.3
  title-small:
    fontFamily: "Figtree"
    fontSize: "14px"
    fontWeight: 600
    lineHeight: 1.3
  body-large:
    fontFamily: "Figtree"
    fontSize: "16px"
    fontWeight: 400
    lineHeight: 1.45
  body-medium:
    fontFamily: "Figtree"
    fontSize: "14.5px"
    fontWeight: 400
    lineHeight: 1.45
  body-small:
    fontFamily: "Figtree"
    fontSize: "13px"
    fontWeight: 400
    lineHeight: 1.45
  label-large:
    fontFamily: "Figtree"
    fontSize: "15px"
    fontWeight: 700
    lineHeight: 1.2
    letterSpacing: "0.1px"
  label-medium:
    fontFamily: "Figtree"
    fontSize: "13px"
    fontWeight: 600
    lineHeight: 1.2
  label-small:
    fontFamily: "Figtree"
    fontSize: "11.5px"
    fontWeight: 600
    lineHeight: 1.2
    letterSpacing: "0.2px"
rounded:
  pill-handle: "3px"
  s: "16px"
  shad: "18px"
  m: "22px"
  toast: "24px"
  l: "28px"
  xl: "36px"
spacing:
  gutter: "16px"
  card-pad: "18px"
  sheet-pad: "22px"
  dialog-pad: "24px"
  section-top: "28px"
  section-bottom: "12px"
  list-tail: "120px"
components:
  button-primary:
    backgroundColor: "{colors.turf-green}"
    textColor: "{colors.lemon-chiffon}"
    typography: "{typography.label-large}"
    rounded: "{rounded.m}"
    padding: "16px 22px"
    height: "52px"
  button-primary-compact:
    backgroundColor: "{colors.turf-green}"
    textColor: "{colors.lemon-chiffon}"
    rounded: "{rounded.m}"
    padding: "12px 16px"
  button-accent:
    backgroundColor: "{colors.scarlet-rush}"
    textColor: "#FFFFFF"
    typography: "{typography.label-large}"
    rounded: "{rounded.m}"
    padding: "16px 22px"
    height: "52px"
  button-soft:
    backgroundColor: "{colors.lemon-chiffon}"
    textColor: "{colors.dark-coffee}"
    typography: "{typography.label-large}"
    rounded: "{rounded.m}"
    padding: "16px 22px"
    height: "52px"
  button-ghost:
    textColor: "{colors.turf-green}"
    typography: "{typography.label-large}"
    rounded: "{rounded.m}"
    padding: "16px 22px"
    height: "48px"
  icon-button:
    backgroundColor: "{colors.lemon-raised}"
    textColor: "{colors.dark-coffee}"
    rounded: "{rounded.s}"
    size: "48px"
  field:
    backgroundColor: "{colors.well-base}"
    textColor: "{colors.dark-coffee}"
    typography: "{typography.body-large}"
    rounded: "{rounded.m}"
    padding: "10px 16px"
  cv-sheet:
    backgroundColor: "{colors.lemon-paper}"
    textColor: "{colors.dark-coffee}"
    rounded: "{rounded.l}"
    padding: "16px 8px 16px 16px"
  home-slab:
    backgroundColor: "{colors.turf-green}"
    textColor: "{colors.lemon-chiffon}"
    rounded: "0 0 40px 40px"
    padding: "14px 20px 26px"
  nav-bar:
    backgroundColor: "{colors.lemon-raised}"
    textColor: "{colors.coffee-muted}"
    typography: "{typography.label-medium}"
    rounded: "36px 36px 0 0"
    height: "72px"
  nav-indicator:
    backgroundColor: "{colors.lemon-chiffon}"
    textColor: "{colors.dark-coffee}"
  dialog:
    backgroundColor: "{colors.lemon-raised}"
    textColor: "{colors.dark-coffee}"
    rounded: "{rounded.xl}"
    padding: "24px 24px 20px"
    width: "420px"
  sheet:
    backgroundColor: "{colors.lemon-raised}"
    rounded: "{rounded.xl}"
    padding: "10px 22px 22px"
  toast-success:
    backgroundColor: "{colors.turf-green}"
    textColor: "{colors.lemon-chiffon}"
    typography: "{typography.title-small}"
    rounded: "{rounded.toast}"
    padding: "14px 10px 14px 16px"
  toast-error:
    backgroundColor: "{colors.scarlet-rush}"
    textColor: "#FFFFFF"
    rounded: "{rounded.toast}"
    padding: "14px 10px 14px 16px"
  toast-warning:
    backgroundColor: "{colors.lemon-chiffon}"
    textColor: "{colors.dark-coffee}"
    rounded: "{rounded.toast}"
  toast-info:
    backgroundColor: "{colors.dark-coffee}"
    textColor: "{colors.lemon-chiffon}"
    rounded: "{rounded.toast}"
  readiness-stamp:
    backgroundColor: "{colors.lemon-chiffon}"
    textColor: "{colors.dark-coffee}"
    rounded: "50%"
    size: "132px"
---

# Design System: CV Ready

## Overview

**Creative North Star: "The Clay Workshop"**

The CV is a lump of clay the user presses into shape until it is "ready". Every surface in the app is a soft extruded clay body lit from the top-left: a diagonal light-to-base-to-shade gradient for volume, a coffee-tinted drop shadow with a real downward offset plus a tight contact shadow for weight, and a pale highlight bloom on the top-left rim. Pressing a body sinks it: the gradient inverts, the shadow shrinks to 35%, and the body scales to 0.975. Inputs are the inverse, recessed wells darker along their top edge.

The world is warm and handmade rather than corporate. A willow-tinted ground carries Turf Green slabs (the shell, primary actions, the home header), Lemon Chiffon paper (where the CV lives), Dark Coffee ink, and a single Scarlet "full stop" that marks what still needs attention. The dark theme is not grey: it moves the whole world into the Dark Coffee family, with Willow taking over the primary role. Density is phone-first: a 16dp gutter, short cards, one primary action per view, a bottom navigation slab. The playfulness ends at the export: the generated CV PDF stays plain, single-column real text, because ATS readability beats decoration.

It explicitly rejects the category default of a grey form wizard with a blue progress bar.

**Key Characteristics:**
- Five binding brand colours; every UI colour is one of them or a mix of them.
- Claymorphism everywhere: `Clay.box` for raised bodies, `Clay.well` for recessed inputs and unselected options.
- Generous, soft radii (16 to 36dp); nothing is square except edge-docked slabs on their docked side.
- Bricolage Grotesque (800/700, tight negative tracking) for display; Figtree for everything readable.
- GSAP-named motion: expo.out arrivals, back.out pops, squash-on-landing; all of it honours "Remove animations".
- Signature: the Readiness Stamp, a lemon clay disc whose ink rises to the ATS score and squashes like the logo's full stop.

## Colors

Five binding brand colours (Scarlet Rush, Turf Green, Willow Green, Lemon Chiffon, Dark Coffee) and tones mixed only from them, white and black. Semantic roles live in the `ClayColors` theme extension and flip between light and dark.

### Primary
- **Turf Green**: the shell colour. Primary buttons, focus borders, cursor, success, the home header slab, the splash, the score and match slabs, the logo's lines. In dark mode the slab deepens to Night Slab and the primary role passes to Willow Green.
- **Turf Deep / Turf Soft**: pressed and tinted Turf; Turf Soft is the light-mode success and secondary-container fill.

### Secondary
- **Willow Green**: the middle readiness band (score 50 to 79), text selection (at 45% alpha), the tint mixed into the light ground and wells, and the dark-mode primary (with Dark Coffee on top).

### Tertiary
- **Lemon Chiffon**: the paper. The text colour on every Turf surface, the nav indicator, soft buttons, the selected template card, the warning tone, and the Readiness Stamp's clay body. Lemon Paper is the CV-sheet card fill; Lemon Raised is the light surfaceRaised (cards, sheets, dialogs, nav bar, icon buttons).
- **Scarlet Rush**: the full stop. The logo dot and the wordmark's period, low scores (under 50), missing keywords, destructive actions, error toasts and field errors. Lightened in dark mode (Night Accent, Night Danger) to hold contrast on coffee.

### Neutral
- **Dark Coffee**: all ink in light mode, the shadow tint for every clay body, the scrim for dialogs (42%), sheets (38%) and the busy overlay (40%), and the info-toast fill.
- **Coffee Muted**: secondary text, labels, inactive nav labels.
- **Coffee Line**: dividers, field borders at rest, the sheet grab handle.
- **Willow Ground / Ground Surface / Well Base**: the light app ground, the Material surface and the recessed-well fill.
- **Night Ground / Night Surface / Night Paper / Night Line / Night Ink / Night Muted**: the dark theme's Dark Coffee family; ink is lemon-white, not pure white.

### Named Rules
**The Five-Colour Rule.** Every colour on screen resolves to one of the five brand colours or a `Color.lerp` of them with white, black or each other. No new hues, no Material defaults showing through.

**The Full Stop Rule.** Scarlet means "this still needs you": low score, missing keyword, error, delete. It is never used for decoration or for a neutral primary action.

**The Lemon-On-Turf Rule.** Text on Turf (light or dark slab) is Lemon Chiffon, never white; text on Lemon is Dark Coffee.

## Typography

**Display Font:** Bricolage Grotesque (bundled as `Bricolage`, weights 500/700/800)
**Body Font:** Figtree (bundled, weights 400/500/600/700, 400 italic)

**Character:** A chunky, slightly quirky grotesque with tight tracking does the shouting, set like stamped clay; Figtree is calm, round and highly legible for the forms that are most of the app.

### Hierarchy
- **Display** (800, 52 / 42 / 34px, 1.1, tracking -1.6 / -1.2 / -1.0px): splash and hero moments only.
- **Headline** (700, 30 / 26 / 22px, 1.1 to 1.2, tracking -0.8 / -0.6 / -0.4px): Headline Large greets on the home slab; Headline Small is every section title, dialog title and sheet title.
- **Title** (Figtree 700/700/600, 19 / 16 / 14px, 1.3): app bar titles (Large), card titles (Medium), field labels, toast and banner text (Small).
- **Body** (Figtree 400, 16 / 14.5 / 13px, 1.45): field input text is Body Large; Body Small is muted by default.
- **Label** (Figtree 700/600/600, 15 / 13 / 11.5px, 1.2): button labels (Large); Medium and Small are muted metadata and nav labels.
- **Numerals**: scores use Bricolage 800 with tabular figures.

### Named Rules
**The No Eyebrow Rule.** Section headings are a single Headline Small line with an optional trailing action. No kicker or eyebrow labels above them.

**The Display-Is-Bricolage Rule.** Bricolage appears only at headline size and above, in the wordmark, and in score numerals. Everything readable at length is Figtree.

## Layout

Single-column, phone-first. Screens sit on the ground with a 16dp side gutter; scrolling lists end with a 120dp tail so the floating action and nav never cover the last card. Section titles carry 28dp above and 12dp below. Cards pad 16 to 18dp; sheets 22dp; dialogs 24dp and cap at 420dp wide. Edge-docked slabs (home header, bottom nav) run full-bleed and round only their free edge. Touch targets are at least 48dp; filled buttons are at least 52dp tall. Tabs switch with a 2% upward slide and fade; pages use Android's predictive-back transition.

## Elevation & Depth

Depth is the material itself. Every raised body uses `Clay.box`: a top-left to bottom-right gradient (base lightened toward the highlight by 30%, or only 8% on dark mode and on dark fills so labels keep 4.5:1, then base, then shaded toward the shadow by 10% or 22% in dark) with three shadows scaled by a `depth` factor. Recessed surfaces use `Clay.well`: a top-down gradient darkened along its first 22% and a 1px line border.

### Shadow Vocabulary
- **Rim highlight** (`offset -4d,-4d; blur 12d; spread -2; highlight at 75% light / 6% dark`): the top-left light bloom. Dropped when pressed.
- **Drop shadow** (`offset 0,12d; blur 28d; spread -6; coffee at 16% light / black at 45% dark`): the body's weight.
- **Contact shadow** (`offset 0,3d; blur 6d; spread -1; coffee at 10% light / black at 35% dark`): grounds the body.
- **Depth steps in use**: 0.55 icon buttons, 0.6 selected options, 0.7 banners, 0.8 buttons, 0.9 nav slab, 1.0 cards, 1.1 home slab, 1.2 sheets, 1.3 busy card, 1.4 dialogs.

### Named Rules
**The Pressed-In Rule.** Press inverts the gradient, multiplies depth by 0.35 and scales to 0.975 over 160ms power3.out, with a selection-click haptic. Nothing lifts on press.

**The Coffee Shadow Rule.** Light-mode shadows are tinted Dark Coffee, never neutral black or grey.

## Shapes

Soft, pillowy rounding throughout: 16dp (icon buttons), 18dp (shadcn inputs and selects), 22dp (buttons, fields, option cards), 24dp (toasts), 28dp (cards, banners), 36dp (dialogs, sheets, slab free edges; the home slab's bottom uses 40dp). The Readiness Stamp and the logo dot are perfect circles; the logo's lines are fully rounded capsules. Borders appear only on wells (1px line, 1.6 to 1.8px when focused or in error).

## Components

### Buttons
Tactile clay pills that sink when pressed.
- **Shape:** gently rounded (22dp), minimum 52dp tall.
- **Primary:** Turf body with Lemon label (Willow with Coffee in dark), 16 x 22dp padding; compact 12 x 16dp.
- **Accent:** Scarlet with white label, reserved for destructive confirmation.
- **Soft:** Lemon body with Coffee label (Night Surface in dark); used on Turf slabs.
- **Ghost:** a flat Material text button in Turf, 48dp target; the "Batal" partner in dialogs.
- **Loading:** the label swaps for the pebble loader tinted to the label colour. Disabled is 50% opacity.

### Icon buttons
Round-cornered 48dp clay squares (16dp radius, depth 0.55) on surfaceRaised, with a tooltip. Icons are Hugeicons stroke-rounded at 1.8 stroke, 20 to 22dp.

### Cards / Containers
- **Corner Style:** 28dp.
- **Background:** Lemon Paper for CV sheets, Lemon Raised for general cards; Turf slab for hero summaries.
- **Shadow Strategy:** `Clay.box` at depth 1 (see Elevation).
- **Internal Padding:** 16 to 18dp.
- **CV Sheet:** mini page thumbnail, title, headline, template and relative time, and the score in its readiness colour (Willow drops to Turf on light ground for contrast). Tap opens, long-press opens actions.

### Inputs / Fields
- **Style:** a shadcn `ShadInput` dressed as a recessed well: Well Base gradient, 1px Coffee Line border, 22dp radius, 10 x 16dp padding, Body Large text, placeholder at 75% muted.
- **Focus:** border shifts to Turf (Willow in dark) at 1.8px.
- **Error:** border and helper text in Scarlet. Labels sit above in Title Small; hints below in Body Small.

### Selectable options
Unselected options are wells; the selected one is raised as a Lemon clay body (Night Slab in dark) at depth 0.6, animating over 160ms.

### Navigation
A clay slab docked at the bottom: Lemon Raised, 36dp top corners, depth 0.9, 72dp tall. Three destinations (CV Saya, Cocokkan, Akun); the indicator is Lemon (Night Slab in dark), selected label Coffee 700, inactive labels muted 600; the selected icon grows to 24dp. App bars are flat on the ground with Title Large.

### Feedback
- **Toast:** a clay pill (24dp) that drops in from the top over expo.out, squashes on landing (scale x +4%, y -6%), and leaves upward; swipe up dismisses. Tones: success Turf/Lemon, error Scarlet/white (heavy haptic, 4.2s), warning Lemon/Coffee, info Coffee/Lemon. Announced to screen readers.
- **Banner:** inline clay body (28dp, depth 0.7) in the tone colours with title, message at 86% and an optional action; fades and slides 15% up on entry.
- **Dialog:** Lemon Raised clay at 36dp and depth 1.4 over a 42% coffee scrim; pops from 0.86 scale with back.out over 420ms. Destructive confirmation uses the Accent button.
- **Sheet:** the same clay, inset 8dp from the screen edges and the gesture bar, with a 44 x 5dp grab handle; follows the keyboard.
- **Busy overlay:** a 240dp clay card with the 150dp pebble loader and a label, for AI and PDF work.

### Readiness Stamp (signature)
A lemon clay disc (default 132dp; 116dp on the home slab) with a radial top-left sheen and a soft drop shadow. A wave-topped ink rises to the score over 1100ms expo.out, coloured by band: Turf at 80+, Willow at 50 to 79, Scarlet below 50. On every score change it squashes from the bottom (up to 10%) like the logo's full stop landing. Numerals are Bricolage 800 at 34% of the size, Lemon on Turf ink and Coffee otherwise.

### Brand mark
Logo concept A: three rounded Turf lines of a CV ending in a Scarlet full stop. The animated version grows the lines left-to-right (520ms expo.out, 120ms stagger) then drops the dot and squashes it (back.out). The wordmark is "CV Ready" in Bricolage 800 with a Scarlet period; on Turf it is Lemon.

### Illustrations and Lottie
Flat clay SVG illustrations (empty CVs, job match, AI helper) float 6dp on a 2.4s power2.inOut loop. Lottie covers hero, success and the three-pebble loader, which is the only loading indicator.

## Do's and Don'ts

### Do:
- **Do** build every raised surface with `Clay.box` and every input or unselected option with `Clay.well`; pick a depth from the established steps (0.55 to 1.4).
- **Do** read colours from `context.clay` so light and dark both work; use raw `Palette` only for brand-fixed elements (logo, stamp, toast tones).
- **Do** put Lemon text on Turf and Coffee text on Lemon.
- **Do** use the `Motion` curves and durations (fast 160ms, medium 320ms, slow 560ms, stagger 55ms) and wrap durations in `Motion.of` so "Remove animations" yields zero.
- **Do** keep touch targets at 48dp or larger and give every pressable a semantic label.
- **Do** use Hugeicons stroke-rounded at 1.8 stroke via `Hi`, and prefer illustrations over clusters of icons.
- **Do** keep the exported CV plain: single column, real text, standard fonts.

### Don't:
- **Don't** introduce a colour that is not one of the five brand colours or a mix of them.
- **Don't** use Scarlet for anything other than attention, low score or destruction.
- **Don't** use flat Material cards, neutral grey shadows, or a grey-and-blue form-wizard look.
- **Don't** add kicker or eyebrow labels above section titles.
- **Don't** use a spinner or progress ring for loading; use the pebble `ClayLoader`.
- **Don't** carry clay styling, colour or illustrations into the exported PDF.
