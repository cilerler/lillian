#!/usr/bin/env pwsh
# Auto-increments the ai-toolkit plugin's PATCH version in every manifest that
# declares it. Invoked by tools/git/pre-commit.ps1 when a commit changes plugin
# sources (.github/skills | prompts | agents | instructions); that hook stages
# the result. Safe to run by hand — it only rewrites the files; stage them yourself.
#
# Only the patch digit is bumped automatically — minor and major stay manual, so
# they remain deliberate decisions you make when a change actually warrants one.
#
# Keeps these version fields in lockstep:
#   plugins/ai-toolkit/.claude-plugin/plugin.json  -> .version
#   plugins/ai-toolkit/.codex-plugin/plugin.json   -> .version
#   .claude-plugin/marketplace.json                -> .metadata.version and .plugins[0].version
# (The Antigravity manifest plugins/ai-toolkit/plugin.json carries no version field.)

$ErrorActionPreference = "Stop"

$repoRoot = git rev-parse --show-toplevel

# Canonical source for the current version; every target is rewritten to match.
$canonical = Join-Path $repoRoot "plugins/ai-toolkit/.claude-plugin/plugin.json"

$targetRelPaths = @(
    "plugins/ai-toolkit/.claude-plugin/plugin.json",
    "plugins/ai-toolkit/.codex-plugin/plugin.json",
    ".claude-plugin/marketplace.json"
)

# Read the current major.minor.patch from the canonical manifest.
$canonicalRaw = Get-Content -Path $canonical -Raw
if ($canonicalRaw -notmatch '"version"\s*:\s*"(\d+)\.(\d+)\.(\d+)"') {
    Write-Host "❌ Could not read a semver version from $canonical" -ForegroundColor Red
    exit 1
}
$major = [int]$Matches[1]
$minor = [int]$Matches[2]
$patch = [int]$Matches[3]

$current = "$major.$minor.$patch"
$next    = "$major.$minor.$($patch + 1)"

Write-Host "🔖 Bumping plugin version $current -> $next (patch)" -ForegroundColor Cyan

# Rewrite every "version": "x.y.z" field in each target to $next, preserving all
# other formatting (targeted string replace, not a JSON reserialize that would
# reflow the file). In these manifests every "version" key IS a version to bump.
$pattern = '("version"\s*:\s*")\d+\.\d+\.\d+(")'
foreach ($rel in $targetRelPaths) {
    $file = Join-Path $repoRoot $rel
    $raw = Get-Content -Path $file -Raw
    $updated = [regex]::Replace($raw, $pattern, "`${1}$next`${2}")
    if ($updated -ne $raw) {
        Set-Content -Path $file -Value $updated -NoNewline
        Write-Host "   updated $rel" -ForegroundColor Gray
    }
}

Write-Host "✅ Plugin version bumped to $next." -ForegroundColor Green
exit 0
