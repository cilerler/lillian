<#
.SYNOPSIS
    Syncs AI configuration from .github/ (source of truth) to platform-specific directories.

.DESCRIPTION
    Copies and transforms content from GitHub Copilot format to Claude Code and Gemini formats.
    No symlinks required — everything is copied with platform-appropriate frontmatter and paths.

    Source of truth (.github/):
      instructions/*.instructions.md  -> .claude/rules/*.md, .agent/rules/*.md
      prompts/*.prompt.md             -> .claude/commands/*.md, .agent/prompts/*.md
      agents/*.agent.md               -> .claude/agents/*.md
      skills/                         -> .claude/skills/, .agent/skills/
      CONTRIBUTING.md                 -> (stays at .github/)
      copilot-instructions.md         -> (stays at .github/)

    In consumer repos using this as a submodule (.ai/), also copies:
      .ai/.github/*                   -> .github/*

.PARAMETER BasePath
    Root of the repository. Defaults to the script's grandparent directory.

.PARAMETER SourcePath
    Path to the AI template source. Defaults to BasePath itself (for the base repo).
    For consumer repos, set this to ".ai" to copy from the submodule.

.EXAMPLE
    # Base repo (melis): sync from .github/ to .claude/ and .agent/
    .\tools\sync-ai-platforms.ps1

    # Consumer repo: sync from submodule
    .\.ai\tools\sync-ai-platforms.ps1 -BasePath "." -SourcePath ".ai"
#>
param(
    [string]$BasePath = (Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)),
    [string]$SourcePath = ""
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

# --- Helpers ---

function Parse-Frontmatter {
    param([string]$Content)

    if ($Content -match "(?s)^---\r?\n(.*?)\r?\n---\r?\n(.*)$") {
        $yaml = $Matches[1]
        $body = $Matches[2]
    } else {
        return @{ Frontmatter = @{}; Body = $Content }
    }

    # Simple YAML parser for our known structures
    $fm = [ordered]@{}
    $currentKey = $null
    $currentList = $null

    foreach ($line in ($yaml -split "`n")) {
        $line = $line.TrimEnd("`r")

        # List item under current key
        if ($line -match "^\s+-\s+(.+)$" -and $currentKey) {
            if ($null -eq $currentList) { $currentList = @() }
            $currentList += $Matches[1].Trim()
            continue
        }

        # Flush previous list
        if ($currentKey -and $currentList) {
            $fm[$currentKey] = $currentList
            $currentList = $null
        }

        # Key-value pair
        if ($line -match "^(\w[\w-]*):\s*(.*)$") {
            $currentKey = $Matches[1]
            $value = $Matches[2].Trim().Trim('"').Trim("'")
            if ($value -eq "") {
                # Next lines might be a list
                $currentList = @()
            } else {
                $fm[$currentKey] = $value
                $currentKey = $null
            }
        }

        # Nested object (handoffs, etc.) - skip complex structures
        if ($line -match "^\s+\w+:" -and $line -notmatch "^\s+-") {
            # Part of a nested object, skip
        }
    }

    # Flush final list
    if ($currentKey -and $currentList) {
        $fm[$currentKey] = $currentList
    }

    return @{ Frontmatter = $fm; Body = $body }
}

function Format-Frontmatter {
    param([System.Collections.Specialized.OrderedDictionary]$Fields)

    if ($Fields.Count -eq 0) { return "" }

    $lines = @("---")
    foreach ($key in $Fields.Keys) {
        $val = $Fields[$key]
        if ($val -is [array]) {
            $lines += "${key}:"
            foreach ($item in $val) {
                $lines += "  - `"$item`""
            }
        } else {
            # Quote strings that contain special chars
            if ($val -match "[:#\[\]{},>|&!%@]" -or $val -match "^\s" -or $val -match "\s$") {
                $lines += "${key}: `"$val`""
            } else {
                $lines += "${key}: $val"
            }
        }
    }
    $lines += "---"
    return ($lines -join "`n")
}

function Write-SyncedFile {
    param(
        [string]$Path,
        [string]$FrontmatterText,
        [string]$Body
    )

    $dir = Split-Path -Parent $Path
    if (-not (Test-Path $dir)) {
        New-Item -ItemType Directory -Force -Path $dir | Out-Null
    }

    $content = if ($FrontmatterText) {
        "$FrontmatterText`n$Body"
    } else {
        $Body
    }

    # Normalize line endings to LF
    $content = $content -replace "`r`n", "`n"

    [System.IO.File]::WriteAllText($Path, $content, [System.Text.UTF8Encoding]::new($false))
}

# --- Path Rewriting ---

# Rewrites .github/ references in body content to platform-native paths.
# Skills are symlinked, so .github/skills/ -> .claude/skills/ or .agent/skills/
# Agents/instructions/prompts are synced with renamed files.

function Rewrite-PathsForClaude {
    param([string]$Body)

    # Platform-specific directory mappings (specific filenames)
    $Body = $Body -replace '\.github/skills/', '.claude/skills/'
    $Body = $Body -replace '\.github/agents/(\w[\w-]*)\.agent\.md', '.claude/agents/$1.md'
    $Body = $Body -replace '\.github/instructions/(\w[\w-]*)\.instructions\.md', '.claude/rules/$1.md'
    $Body = $Body -replace '\.github/prompts/(\w[\w-]*)\.prompt\.md', '.claude/commands/$1.md'

    # Wildcard and dynamic patterns (e.g. *.agent.md, <role>.agent.md)
    $Body = $Body -replace '\.github/agents/([^`\s]*?)\.agent\.md', '.claude/agents/$1.md'
    $Body = $Body -replace '\.github/instructions/([^`\s]*?)\.instructions\.md', '.claude/rules/$1.md'
    $Body = $Body -replace '\.github/prompts/([^`\s]*?)\.prompt\.md', '.claude/commands/$1.md'

    # Bare directory references (e.g. ".github/agents/")
    $Body = $Body -replace '\.github/agents/', '.claude/agents/'
    $Body = $Body -replace '\.github/instructions/', '.claude/rules/'
    $Body = $Body -replace '\.github/prompts/', '.claude/commands/'

    # Shared files
    $Body = $Body -replace '\.github/copilot-instructions\.md', 'CLAUDE.md'
    $Body = $Body -replace '\.github/CONTRIBUTING\.md', '.github/CONTRIBUTING.md'
    return $Body
}

function Rewrite-PathsForGemini {
    param([string]$Body)

    # Platform-specific directory mappings (specific filenames)
    $Body = $Body -replace '\.github/skills/', '.agent/skills/'
    $Body = $Body -replace '\.github/instructions/(\w[\w-]*)\.instructions\.md', '.agent/rules/$1.md'
    $Body = $Body -replace '\.github/prompts/(\w[\w-]*)\.prompt\.md', '.agent/prompts/$1.md'

    # Wildcard and dynamic patterns
    $Body = $Body -replace '\.github/instructions/([^`\s]*?)\.instructions\.md', '.agent/rules/$1.md'
    $Body = $Body -replace '\.github/prompts/([^`\s]*?)\.prompt\.md', '.agent/prompts/$1.md'

    # Bare directory references
    $Body = $Body -replace '\.github/instructions/', '.agent/rules/'
    $Body = $Body -replace '\.github/prompts/', '.agent/prompts/'

    # Shared files
    $Body = $Body -replace '\.github/copilot-instructions\.md', 'GEMINI.md'
    $Body = $Body -replace '\.github/CONTRIBUTING\.md', '.github/CONTRIBUTING.md'
    return $Body
}

function Rewrite-PathsForPlugin {
    param([string]$Body)

    # Plugin content is mirrored from .claude/, but plugin files reference
    # paths inside the installed plugin via ${CLAUDE_PLUGIN_ROOT} (resolved at
    # runtime by Claude Code). Rewrite .claude/ prefixes to that variable so
    # the references resolve when the plugin is installed from a cache dir.
    $Body = $Body.Replace('.claude/skills/',   '${CLAUDE_PLUGIN_ROOT}/skills/')
    $Body = $Body.Replace('.claude/agents/',   '${CLAUDE_PLUGIN_ROOT}/agents/')
    $Body = $Body.Replace('.claude/commands/', '${CLAUDE_PLUGIN_ROOT}/commands/')
    return $Body
}

# --- Tool Mapping (Copilot -> Claude) ---

$ToolMap = @{
    "read"    = @("Read", "Glob", "Grep")
    "search"  = @("Grep", "Glob")
    "web"     = @("WebFetch", "WebSearch")
    "vscode"  = @("Read", "Glob", "Grep", "Edit", "Write")
    "execute" = @("Bash")
    "edit"    = @("Edit", "Write")
    "agent"   = @("Agent")
    "todo"    = @("TodoWrite")
}

function Map-ToolsToClaudeFormat {
    param([array]$CopilotTools)

    $claudeTools = [System.Collections.Generic.List[string]]::new()
    foreach ($tool in $CopilotTools) {
        $tool = $tool.Trim()
        if ($tool.StartsWith("mcp__")) {
            # MCP tools pass through as-is
            $claudeTools.Add($tool)
        } elseif ($ToolMap.ContainsKey($tool)) {
            foreach ($mapped in $ToolMap[$tool]) {
                if (-not $claudeTools.Contains($mapped)) {
                    $claudeTools.Add($mapped)
                }
            }
        }
    }
    return $claudeTools.ToArray()
}

# --- Directory Copy Helper ---

function Copy-DirectoryClean {
    param(
        [string]$Source,
        [string]$Destination
    )

    if (-not (Test-Path $Source)) { return 0 }

    # Remove existing target (whether directory or symlink)
    if (Test-Path $Destination) {
        $item = Get-Item $Destination -Force
        if ($item.LinkType) {
            # Remove symlink without following it
            $item.Delete()
        } else {
            Remove-Item $Destination -Recurse -Force
        }
    }

    Copy-Item -Path $Source -Destination $Destination -Recurse -Force
    return (Get-ChildItem $Destination -Recurse -File | Measure-Object).Count
}

# --- Main Sync Logic ---

$stats = @{ Instructions = 0; Prompts = 0; Agents = 0; Skills = 0; GithubFiles = 0 }

# Resolve source: either BasePath itself (base repo) or a submodule path
if ($SourcePath -eq "") {
    $srcRoot = $BasePath
} else {
    $srcRoot = Join-Path $BasePath $SourcePath
}

$srcGithub = Join-Path $srcRoot ".github"

if (-not (Test-Path $srcGithub)) {
    Write-Error "Source .github/ not found at: $srcGithub"
    exit 1
}

Write-Host "Syncing AI platform configs ..." -ForegroundColor Cyan
Write-Host "  Source: $srcGithub" -ForegroundColor DarkGray
Write-Host "  Target: $BasePath" -ForegroundColor DarkGray

# --- 0. Consumer repo: copy .github/ content from submodule ---

if ($SourcePath -ne "") {
    $targetGithub = Join-Path $BasePath ".github"
    New-Item -ItemType Directory -Force -Path $targetGithub | Out-Null

    # Copy directories
    foreach ($dir in @("skills", "agents", "instructions", "prompts")) {
        $src = Join-Path $srcGithub $dir
        if (Test-Path $src) {
            $count = Copy-DirectoryClean $src (Join-Path $targetGithub $dir)
            $stats.GithubFiles += $count
        }
    }

    # Copy files
    foreach ($file in @("copilot-instructions.md", "CONTRIBUTING.md")) {
        $src = Join-Path $srcGithub $file
        if (Test-Path $src) {
            Copy-Item -Path $src -Destination (Join-Path $targetGithub $file) -Force
            $stats.GithubFiles++
        }
    }

    # Copy root entry points
    foreach ($file in @("CLAUDE.md", "GEMINI.md", "AGENTS.md")) {
        $src = Join-Path $srcRoot $file
        if (Test-Path $src) {
            Copy-Item -Path $src -Destination (Join-Path $BasePath $file) -Force
            $stats.GithubFiles++
        }
    }

    Write-Host "  .github/ content copied from submodule ($($stats.GithubFiles) files)" -ForegroundColor DarkGray
}

# Use the target .github/ as source for all transforms
$srcGithub = Join-Path $BasePath ".github"

# --- 1. Skills (direct copy, no transform) ---

$srcDir = Join-Path $srcGithub "skills"
foreach ($target in @((Join-Path $BasePath ".claude\skills"), (Join-Path $BasePath ".agent\skills"))) {
    $stats.Skills += Copy-DirectoryClean $srcDir $target
}

# --- 2. Instructions -> Rules (with frontmatter transform) ---

$srcDir = Join-Path $srcGithub "instructions"
$claudeDir = Join-Path $BasePath ".claude\rules"
$geminiDir = Join-Path $BasePath ".agent\rules"

# Clear targets
if (Test-Path $claudeDir) { Get-ChildItem $claudeDir -Filter "*.md" | Remove-Item -Force }
if (Test-Path $geminiDir) { Get-ChildItem $geminiDir -Filter "*.md" | Remove-Item -Force }

if (Test-Path $srcDir) {
    foreach ($file in Get-ChildItem $srcDir -Filter "*.instructions.md") {
        $parsed = Parse-Frontmatter (Get-Content $file.FullName -Raw)
        $cleanName = $file.Name -replace "\.instructions\.md$", ".md"

        # Claude: applyTo -> paths
        $claudeFm = [ordered]@{}
        if ($parsed.Frontmatter.Contains("applyTo")) {
            $applyTo = $parsed.Frontmatter["applyTo"]
            if ($applyTo -is [array]) {
                $claudeFm["paths"] = $applyTo
            } else {
                $claudeFm["paths"] = @($applyTo)
            }
        }
        Write-SyncedFile (Join-Path $claudeDir $cleanName) (Format-Frontmatter $claudeFm) (Rewrite-PathsForClaude $parsed.Body)

        # Gemini: strip applyTo, content only
        Write-SyncedFile (Join-Path $geminiDir $cleanName) "" (Rewrite-PathsForGemini $parsed.Body)

        $stats.Instructions++
    }
}

# --- 3. Prompts -> Commands (with frontmatter transform) ---

$srcDir = Join-Path $srcGithub "prompts"
$claudeDir = Join-Path $BasePath ".claude\commands"
$geminiDir = Join-Path $BasePath ".agent\prompts"

if (Test-Path $claudeDir) { Get-ChildItem $claudeDir -Filter "*.md" | Remove-Item -Force }
if (Test-Path $geminiDir) { Get-ChildItem $geminiDir -Filter "*.md" | Remove-Item -Force }

if (Test-Path $srcDir) {
    foreach ($file in Get-ChildItem $srcDir -Filter "*.prompt.md") {
        $parsed = Parse-Frontmatter (Get-Content $file.FullName -Raw)
        $cleanName = $file.Name -replace "\.prompt\.md$", ".md"

        # Claude: keep description, drop mode
        $claudeFm = [ordered]@{}
        if ($parsed.Frontmatter.Contains("description")) {
            $claudeFm["description"] = $parsed.Frontmatter["description"]
        }
        Write-SyncedFile (Join-Path $claudeDir $cleanName) (Format-Frontmatter $claudeFm) (Rewrite-PathsForClaude $parsed.Body)

        # Gemini: keep description, drop mode
        $geminiFm = [ordered]@{}
        if ($parsed.Frontmatter.Contains("description")) {
            $geminiFm["description"] = $parsed.Frontmatter["description"]
        }
        Write-SyncedFile (Join-Path $geminiDir $cleanName) (Format-Frontmatter $geminiFm) (Rewrite-PathsForGemini $parsed.Body)

        $stats.Prompts++
    }
}

# --- 4. Agents (with frontmatter + tools transform) ---

$srcDir = Join-Path $srcGithub "agents"
$claudeDir = Join-Path $BasePath ".claude\agents"

if (Test-Path $claudeDir) { Get-ChildItem $claudeDir -Filter "*.md" | Remove-Item -Force }

if (Test-Path $srcDir) {
    foreach ($file in Get-ChildItem $srcDir -Filter "*.agent.md") {
        $parsed = Parse-Frontmatter (Get-Content $file.FullName -Raw)
        $cleanName = $file.Name -replace "\.agent\.md$", ".md"

        $claudeFm = [ordered]@{}

        # name: lowercase
        if ($parsed.Frontmatter.Contains("name")) {
            $claudeFm["name"] = $parsed.Frontmatter["name"].ToLower()
        }

        # description: keep
        if ($parsed.Frontmatter.Contains("description")) {
            $claudeFm["description"] = $parsed.Frontmatter["description"]
        }

        # tools: map to Claude tool names
        if ($parsed.Frontmatter.Contains("tools")) {
            $tools = $parsed.Frontmatter["tools"]
            if ($tools -is [string]) { $tools = @($tools) }
            $claudeTools = Map-ToolsToClaudeFormat $tools
            if ($claudeTools.Count -gt 0) {
                $claudeFm["tools"] = $claudeTools
            }
        }

        # skills: pass through
        if ($parsed.Frontmatter.Contains("skills")) {
            $skills = $parsed.Frontmatter["skills"]
            if ($skills -is [string]) { $skills = @($skills) }
            $claudeFm["skills"] = $skills
        }

        # Drop: handoffs (Copilot-only)

        Write-SyncedFile (Join-Path $claudeDir $cleanName) (Format-Frontmatter $claudeFm) (Rewrite-PathsForClaude $parsed.Body)

        $stats.Agents++
    }
}

# --- 5. Populate Claude Code plugin folder (plugins/ai-toolkit/) ---
#
# Plugin manifests don't accept paths outside the plugin directory (the install
# step copies the plugin to a cache dir and parent-traversal paths break).
# So mirror the transformed .claude/ content into the plugin folder.

$pluginRoot = Join-Path $BasePath "plugins\ai-toolkit"
if (-not (Test-Path $pluginRoot)) {
    New-Item -ItemType Directory -Force -Path $pluginRoot | Out-Null
    Write-Host "  plugins/ai-toolkit/ created (was missing)" -ForegroundColor Yellow
}

$stats.PluginFiles = 0
foreach ($component in @("agents", "commands", "skills")) {
    $src = Join-Path $BasePath ".claude\$component"
    $dst = Join-Path $pluginRoot $component
    $stats.PluginFiles += Copy-DirectoryClean $src $dst
}

# Rewrite .claude/ path references to ${CLAUDE_PLUGIN_ROOT}/ inside copied content
$utf8NoBom = [System.Text.UTF8Encoding]::new($false)
$stats.PluginRewrites = 0
foreach ($component in @("agents", "commands", "skills")) {
    $componentDst = Join-Path $pluginRoot $component
    if (-not (Test-Path $componentDst)) { continue }
    Get-ChildItem $componentDst -Recurse -File -Filter "*.md" | ForEach-Object {
        $content = [System.IO.File]::ReadAllText($_.FullName, $utf8NoBom)
        $rewritten = Rewrite-PathsForPlugin $content
        if ($rewritten -ne $content) {
            [System.IO.File]::WriteAllText($_.FullName, $rewritten, $utf8NoBom)
            $stats.PluginRewrites++
        }
    }
}

# --- Summary ---

Write-Host ""
Write-Host "Sync complete:" -ForegroundColor Green
Write-Host "  Skills (copied):           $($stats.Skills) files" -ForegroundColor White
Write-Host "  Instructions -> Rules:     $($stats.Instructions) files" -ForegroundColor White
Write-Host "  Prompts -> Commands:       $($stats.Prompts) files" -ForegroundColor White
Write-Host "  Agents:                    $($stats.Agents) files" -ForegroundColor White
if ($stats.GithubFiles -gt 0) {
    Write-Host "  .github/ (from submodule): $($stats.GithubFiles) files" -ForegroundColor White
}
if (-not $stats.ContainsKey("PluginFiles")) { $stats.PluginFiles = 0 }
if ($stats.PluginFiles -eq 0) {
    Write-Host "  Plugin (ai-toolkit):       0 files  (WARNING: nothing copied)" -ForegroundColor Yellow
} else {
    $rewriteSuffix = if ($stats.ContainsKey("PluginRewrites") -and $stats.PluginRewrites -gt 0) {
        "  ($($stats.PluginRewrites) path-rewritten)"
    } else { "" }
    Write-Host "  Plugin (ai-toolkit):       $($stats.PluginFiles) files$rewriteSuffix" -ForegroundColor White
}
Write-Host ""
Write-Host "Targets updated:" -ForegroundColor DarkGray
Write-Host "  .claude/skills/  .claude/rules/  .claude/commands/  .claude/agents/" -ForegroundColor DarkGray
Write-Host "  .agent/skills/   .agent/rules/   .agent/prompts/" -ForegroundColor DarkGray
Write-Host "  plugins/ai-toolkit/{agents,commands,skills}/" -ForegroundColor DarkGray
