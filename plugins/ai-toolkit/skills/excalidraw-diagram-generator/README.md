# Excalidraw Diagram Generator

A Claude Code skill that generates Excalidraw diagram JSON files with automatic PNG rendering via Playwright.

## First-Time Setup

```pwsh
cd .github/skills/excalidraw-diagram-generator/references;
dotnet run render_excalidraw.cs -- install-browsers;
```

## Usage

```pwsh
cd .github/skills/excalidraw-diagram-generator/references;
dotnet run render_excalidraw.cs -- <path-to-file.excalidraw> [--output path.png] [--scale 2] [--width 1920];
```

```prompt
Create an Excalidraw diagram showing how the Distributed Lock works.
```

## Acknowledgments

This skill is based on the work of [Cole Medin](https://www.youtube.com/watch?v=m3fqyXZ4k4I). Thank you for the original concept and design methodology.
