# Curated List of Untranslated Strings in Besprited

This list contains string literals that are likely user-facing and should be internationalized using the `i18n()` function.

## Summary

- **Total user-facing strings found:** 195
- **Excluded internal strings:** 63 (serialization identifiers, enum values, debug messages, etc.)

---

## Strings That Need Internationalization

### Filter Names (5 strings)
These are displayed in the UI when filters are applied:
- `filters/convolution_matrix_filter.cpp`: "Convolution Matrix"
- `filters/median_filter.cpp`: "Median Blur"
- `filters/invert_color_filter.cpp`: "Invert Color"
- `filters/replace_color_filter.cpp`: "Replace Color"
- `filters/color_curve_filter.cpp`: "Color Curve"

### View/Tab Names (3 strings)
These appear as tab titles in the UI:
- `app/ui/data_recovery_view.cpp`: "Data Recovery"
- `app/ui/home_view.cpp`: "Home"
- `app/ui/devconsole_view.cpp`: "Console"

### Window Titles (4 strings)
Popup window and dialog titles:
- `app/ui/palette_popup.cpp`: "Palettes"
- `app/ui/font_popup.cpp`: "Fonts"
- `app/ui/configure_timeline_popup.cpp`: "Timeline Settings"

### UI Labels (15+ strings)
Text labels in various dialogs and UI elements:
- `app/commands/cmd_mask_by_color.cpp`: "Color:", "Tolerance:"
- `app/ui/status_bar.cpp`: "Frame:"
- `app/ui/context_bar.cpp`: "Pick:", "Sample:", "Tolerance:", "Opacity:", "Spray:", "Freehand:"
- `app/commands/cmd_about.cpp`: "Animated sprite editor & pixel art tool", "Authors:", "- Lead developer, graphics & maintainer", "- Default skin & graphics introduced in v0.8"
- `app/commands/cmd_sprite_properties.cpp`: "(only for indexed images)"

### Buttons (10+ strings)
Button labels throughout the UI:
- `app/commands/cmd_mask_by_color.cpp`: "&OK", "&Cancel"
- `app/commands/cmd_about.cpp`: "&Close"
- `app/console.cpp`: "&Close", "C&lear"
- `app/ui/status_bar.cpp`: "+"
- `app/commands/filters/filter_window.cpp`: "&OK", "&Cancel"
- `app/ui/color_bar.cpp`: "Remap"

### Checkboxes (5 strings)
Checkbox labels:
- `app/commands/cmd_mask_by_color.cpp`: "&Preview"
- `app/ui/context_bar.cpp`: "Contiguous", "Pixel-perfect", "Auto Select Layer"
- `app/commands/filters/filter_window.cpp`: "&Tiled"

### Menu Items (10+ strings)
Menu and context menu items:
- `app/ui/editor/editor.cpp`: "Play Once", "Rewind on Stop"
- `app/app_menus.cpp`: "WARNING!", "You should update your customized gui.xml file to the new version to get", "the latest commands available.", etc.

### Combo Box Items (90+ strings)
Dropdown menu options across many dialogs:
- Color types: "RGB", "HSB", "Index", "Gray", "Mask"
- Blend modes: "Normal", "Multiply", "Screen", "Overlay", "Darken", "Lighten", "Color Dodge", "Color Burn", "Hard Light", "Soft Light", "Difference", "Exclusion", "Hue", "Saturation", "Color", "Luminosity"
- Channel options: "Color+Alpha", "Color", "Alpha", "RGB+Alpha", "RGB", "HSB+Alpha", "HSB", "Gray+Alpha", "Gray", "Best fit Index"
- Layer sampling: "All Layers", "Current Layer"
- Sheet types: "Horizontal Strip", "Vertical Strip", "By Rows", "By Columns"
- Frame/layer options: "All frames", "Selected frames", "Visible layers", "Selected layers"
- Scaling methods: "Nearest-neighbor", "Bilinear", "RotSprite"
- Right-click behaviors: "Paint with background color", "Pick foreground color", "Erase", "Scroll"
- Grid scopes: "Global", "Current Document"
- Background sizes: "16x16", "8x8", "4x4", "2x2"
- Animation directions: "Forward", "Reverse", "Ping-pong"
- Change modes: "Abs", "Rel"
- Pattern alignment: "Pattern aligned to source", "Pattern aligned to destination", "Paint brush"
- Filter target buttons: "R", "G", "B", "A", "K", "Index"

### Tooltips (30+ strings)
Tooltip text for various UI elements in context bar, color bar, status bar, etc.:
- `app/ui/context_bar.cpp`: "Brush Type", "Brush Size (in pixels)", "Brush Angle (in degrees)", "Ink", "Opacity (paint intensity)", "Shades", "Spray Width", "Spray Speed", "Rotation Pivot", "Transparent Color", "Rotation Algorithm", "Freehand trace algorithm", "Extra paint bucket options", "Horizontal Symmetry", "Vertical Symmetry", "Replace selection", "Add to selection\n(Shift)", "Subtract from selection\n(Shift+Alt)", "Drop pixels here", "Cancel drag and drop"
- `app/ui/color_bar.cpp`: "Foreground color", "Background color", "Add foreground color to the palette", "Add background color to the palette", "Edit Color", "Sort & Gradients", "Presets", "Options", "Matches old indexes with new indexes"
- `app/ui/status_bar.cpp`: "Current Frame", "Zoom Level", "New Frame"
- `app/ui/select_accelerator.cpp`: "Also known as Windows key, logo key,\ncommand key, or system key."

### Separators (3 strings)
Menu separator labels:
- `app/ui/brush_popup.cpp`: "Saved Parameters", "Parameters to Save"
- `app/commands/cmd_about.cpp`: "Authors:"

### Status Bar Messages (15+ strings)
Messages displayed in the status bar:
- `app/commands/cmd_goto_layer.cpp`: "Layer `%s' selected"
- `app/commands/cmd_save_file.cpp`: "File %s, saved."
- `app/ui/document_view.cpp`: "Sprite '%s' closed."
- `app/ui/timeline.cpp`: "%s cels", "%s before frame %d", "%s after frame %d", "Onionskin is %s", "Layer '%s' [%s%s]", "Layer '%s' is %s", "Layer '%s' is %s (%s)"
- `app/app.cpp`: "%s | %s" (showing PACKAGE_AND_VERSION and COPYRIGHT)

### Widget Text Updates (10+ strings)
Dynamic text set on widgets:
- `app/commands/cmd_palette_editor.cpp`: " No Entry", " Multiple Entries"
- `app/commands/cmd_color_quantization.cpp`: "256"
- `app/commands/cmd_layer_properties.cpp`: "No Layer"
- `app/commands/cmd_modify_selection.cpp`: "Width:"
- `app/commands/cmd_export_sprite_sheet.cpp`: "Select File: " + filename
- `app/commands/cmd_keyboard_shortcuts.cpp`: "Add"
- `app/ui/context_bar.cpp`: "Select colors in the palette"
- `app/ui/brush_popup.cpp`: "Save Brush"
- `app/ui/file_selector.cpp`: "-------- Recent Paths --------"

### Ink Types (6 strings)
Display names for ink types shown in UI:
- `app/tools/ink_type.cpp`: "Simple Ink", "Alpha Compositing", "Copy Color+Alpha", "Lock Alpha", "Shading", "Unknown"

### Context Bar Help Text (3 strings)
Help text shown in the context bar:
- `app/commands/cmd_new_brush.cpp`: "Select brush bounds | Right-click to cut"
- `app/commands/cmd_canvas_size.cpp`: "Select new canvas size"
- `app/commands/cmd_import_sprite_sheet.cpp`: "Select bounds to identify sprite frames"

### Action Names (4 strings)
Names for undo/redo actions:
- `app/commands/cmd_modify_selection.cpp`: "Border", "Expand", "Contract", "Modify"

### Notification Text (1 string)
Text shown in notifications:
- `app/send_crash.cpp`: "Report last crash"

### Error Messages (2 strings)
User-facing error messages:
- `base/errno_string.cpp`: "Unknown error"
- `app/ui/keyboard_shortcuts.cpp`: "Unknown"

---

## Excluded Internal Strings (Not User-Facing)

These strings were identified as internal and do NOT need internationalization:

### Serialization/API Identifiers (37 strings)
- Blend mode identifiers: "normal", "multiply", "screen", etc. (lowercase, for file format)
- Animation direction: "forward", "reverse", "pingpong"
- Brush types: "circle", "square", "line", "image", "unknown"
- Ink type identifiers: "simple", "alpha_compositing", "copy_color", "lock_alpha", "shading", "unknown"
- Default palette identifier: "default"
- Platform identifiers: "emscripten", "windows", "macos", "android", "linux"

### Debug/Internal Messages (26 strings)
- Message type enum names: "Open", "Close", "Paint", "Timer", "KeyDown", etc.
- JavaScript object representation: "[Object object]"
- File system paths: "/tmp", "/"

---

## Notes

1. All strings listed in the "Strings That Need Internationalization" section should be wrapped with `i18n()`.
2. The excluded strings are used for serialization, APIs, or internal purposes and should remain as plain strings.
3. Some combo box items contain technical color channel names (R, G, B, A, K) which may or may not need translation depending on localization policy.
4. Status bar format strings include printf-style placeholders (%s, %d) which should be preserved in translations.

