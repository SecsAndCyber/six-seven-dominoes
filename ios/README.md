# iOS export notes

Requirements:

- macOS with Xcode installed
- Godot iOS export templates installed

Typical steps:

1. In Godot Editor, install/export the iOS template and choose the `iOS (Xcode)` preset.
2. Export an Xcode project from Godot (not a .ipa). Open the generated Xcode workspace/project.
3. In Xcode, set your Team and provisioning profile, update bundle identifier to match your provisioning, and set code signing settings.
4. Build and run on a device or archive to produce an .ipa.

Notes:

- You must use a Mac to complete the iOS export and signing steps.
- If using Godot's custom iOS templates, follow Godot docs for template installation.
