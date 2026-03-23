$ErrorActionPreference = "Stop"

Write-Host "`n🔍 Running pre-commit checks..." -ForegroundColor Cyan

$stagedFiles = @(git diff --cached --name-only --diff-filter=ACM)

# Check if any AI source-of-truth files were modified
$aiSourcePatterns = @(
    ".github/instructions/",
    ".github/prompts/",
    ".github/agents/",
    ".github/skills/"
)

$aiChanges = @($stagedFiles | Where-Object {
    $file = $_
    $aiSourcePatterns | Where-Object { $file.StartsWith($_) }
})

if ($aiChanges.Count -eq 0) {
    Write-Host "No AI source files changed. Skipping sync." -ForegroundColor Gray
    exit 0
}

Write-Host "Found $($aiChanges.Count) AI source file(s) changed. Running sync..." -ForegroundColor Yellow

$repoRoot = git rev-parse --show-toplevel
& "$repoRoot/tools/sync-ai-platforms.ps1"

if ($LASTEXITCODE -ne 0) {
    Write-Host "`n❌ Sync failed!" -ForegroundColor Red
    exit 1
}

# Stage all generated files
git add "$repoRoot/.claude" "$repoRoot/.agent"

Write-Host "`n✅ AI platforms synced and staged!" -ForegroundColor Green
exit 0
