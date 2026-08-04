# NexusMind UI Style Guide

## Purpose

NexusMind uses functional, AI-readable interfaces. Every color, container and
spacing choice must communicate hierarchy, state or an available action. Do not
add decorative gradients, floating ornaments or imagery that does not support a
task.

## Design Tokens

| Token | Value | Use |
| --- | --- | --- |
| Electric Blue | `#4DA3FF` | Primary actions, selected states and active controls |
| Mint Accent | `#3DD6A0` | Healthy system state and confirmed completion |
| Fact Text | `#1A1A1A` | Primary text in light mode |
| Dark Background | `#1C1C1E` | Default app background |
| Dark Content Surface | `#2C2C2E` | Cards, sheets and form fields in dark mode |
| Dark Primary Text | `#FFFFFF` | Titles and key values |
| Dark Body Text | `#A1A1AA` | Descriptions and controls |
| Dark Metadata | `#71717A` | Timestamps and secondary information |
| Page padding | `20px` horizontal, `24px` vertical | Default scrollable page inset |
| Surface radius | `20px` | Independent information or status surfaces |
| Control radius | `16px` | Buttons, chips and inputs |
| Major section gap | `24px` | Between page anchor, control groups and information sections |
| Related control gap | `12px` | Between controls and repeated information surfaces |
| Bottom content inset | `100px` | Scrollable tab content above the floating navigation |
| Surface shadow | black 12%, blur `18px`, y `8px` | Subtle dark-mode elevation |

The Flutter source of truth is `lib/core/ui/nexus_theme.dart`. Screens consume
`Theme.of(context)` and `NexusLayout`; they must not duplicate token values.

## Typography

Use four levels only: 28 for the page anchor, 18 for section titles, 15 for
body and controls, and 13 for metadata. Use regular tracking. Headings use
weight 700, section labels 600, and body text 400-500. Workspace pages use
`NexusPageHeader` for the 28px page anchor and contextual description; detail
pages retain the shared Material app bar only for back navigation.

## Layout and Hierarchy

- Use the F-pattern: context first, then status, then the primary action.
- Keep a 24px gap between major sections and 12px between related controls.
- A home page begins with a context anchor, then one 56px primary AI action.
- Status summaries use an evenly divided row or grid. Each item exposes a
  short label and a single prominent value.
- A page has one primary action. AI actions use AI Accent; confirmed status
  uses Brand Green. Do not use semantic colors as decoration.
- Prefer outlined Material icons with clear tooltips for icon-only controls.

## Components and States

- `NexusSurface` is the default framed information block. Do not put surfaces
  inside other surfaces unless the inner element is an independently actionable
  repeated item.
- Each workspace starts with its page anchor, then one focused control surface
  when filtering or creation is needed, then repeated `NexusSurface` items.
  AI expert cards use a primary-container icon tile; todo cards use a checkbox,
  title and compact metadata row. Do not introduce a second card radius,
  padding scale or standalone grey background for these flows.
- Use electric-blue `FilledButton` controls for decisive commands and soft
  dark outlined secondary controls for quick actions. Primary commands are at
  least 52px high; active controls may use a restrained blue glow.
- Smart-home room cards prioritise a rounded room image with a bottom black
  gradient so white labels remain readable. Always supply a visual fallback
  when a remote image cannot load.
- Every async surface shows loading, empty and error states. Repository calls
  start in `initState` or a user action, never in `build`.
- Maintain light and dark themes through the shared theme. Do not hard-code
  white, black or arbitrary greys in feature pages.

## Responsive Rules

Support 320px through 430px widths without fixed content widths. Use
`Expanded`, `Wrap`, scrolling quick-action rows and `SafeArea`. Labels may wrap
but must not overlap, truncate essential state, or resize their parent controls.
