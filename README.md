# CeTTyAssist

CeTTyAssist is a lightweight WoW Retail recommendation display addon. (inspired by Hekili visually)

It reads Blizzard Single Button Assist recommendations and mirrors them as a multi-icon queue to help you learn a simple rotation flow.

It is not automation, not a one-button macro, and not an optimized rotation engine.

## Install
1. Copy the `CeTTyAssist` folder into your WoW addons directory:
   - `_retail_/Interface/AddOns/CeTTyAssist`
2. Restart WoW or run `/reload`.
3. Enable **CeTTyAssist** on the character select addon list.

## Slash Commands
- `/cetty` open/close settings
- `/cettyassist` alias for `/cetty`
- `/cetty on` enable addon
- `/cetty off` disable addon
- `/cetty debug` toggle debug chat output
- `/cetty direction left|right` set queue direction
- `/cetty status` print runtime status
- `/cetty test` print current assisted recommendation

## Edit Mode Anchor
- In WoW Edit Mode, CeTTyAssist shows a draggable anchor frame.
- Drag the anchor to reposition the recommendation frame.
- Right-click the anchor in Edit Mode to open settings.
- Movement is managed by Edit Mode (no lock/unlock setting required).

## Settings Highlights
- Enable/disable addon and show/hide out-of-combat behavior
- Number of icons shown (1 to 5)
- Main icon size, queue icon size, spacing, and queue X/Y offsets
- Hotkey text:
  - font size
  - anchor position (Center, Top Left, Top Right)
  - X/Y offsets
- Icon shape (Square, Circle, Hexagon)
- Theme preset:
  - `Modern (Default)`
  - `Blizzard (scaling issue - WIP)`
- Empty/background icon texture selection

## Recommendation Source
- Assisted-only source: Blizzard Single Button Assist.
- Custom profile logic is not used.
- `Profiles.lua` remains in the repository as legacy/reference content and is not loaded by the TOC.

## Notes
- SavedVariables key: `CeTTyAssistDB`
- Legacy settings in `CettyRotationsDB` are migrated automatically on login.
- Default update interval is 0.10s.
