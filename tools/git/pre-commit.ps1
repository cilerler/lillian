$ErrorActionPreference = "Stop"

# Pre-commit orchestrator. When a commit changes the AI sources that feed the
# plugin (.github/skills | prompts | agents | instructions), it points to each
# generator under tools/ in turn, then stages what they (re)wrote. Each step is
# a standalone script that also runs on its own (e.g. manually, or in CI).

Write-Host "`n🔍 Running pre-commit checks..." -ForegroundColor Cyan

$staged  = @(git diff --cached --name-only --diff-filter=ACM)
$sources = @(".github/skills/", ".github/prompts/", ".github/agents/", ".github/instructions/")
$changed = @($staged | Where-Object { $file = $_; $sources | Where-Object { $file.StartsWith($_) } })

if ($changed.Count -eq 0) {
    Write-Host "No AI source files changed. Skipping sync." -ForegroundColor Gray
    exit 0
}

Write-Host "Found $($changed.Count) AI source file(s) changed. Running sync + version bump..." -ForegroundColor Yellow

$repoRoot = git rev-parse --show-toplevel

# --- Steps that run (each is a standalone script under tools/) ---

& "$repoRoot/tools/sync-ai-platforms.ps1"       # regenerate plugin bundle, .claude/rules, .agents/workflows
if ($LASTEXITCODE -ne 0) {
    Write-Host "`n❌ Sync failed!" -ForegroundColor Red
    exit 1
}

& "$repoRoot/tools/bump-plugin-version.ps1"     # patch-bump the plugin version across its manifests
if ($LASTEXITCODE -ne 0) {
    Write-Host "`n❌ Version bump failed!" -ForegroundColor Red
    exit 1
}

# --- Stage everything the steps (re)wrote ---

git add "$repoRoot/.claude" "$repoRoot/.agents" "$repoRoot/plugins/ai-toolkit" "$repoRoot/.claude-plugin/marketplace.json" "$repoRoot/.github/skills/INDEX.md" "$repoRoot/README.md"

Write-Host "`n✅ AI platforms synced, version bumped, and staged." -ForegroundColor Green
exit 0
