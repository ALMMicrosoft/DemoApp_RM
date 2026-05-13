# Creates 5 local branches from the current HEAD, each with one SAST-benchmark finding.
# Push the repo, then open one PR per branch against main to measure CodeQL + Copilot.
# Requires: git, this repo already has an initial commit on main.

$ErrorActionPreference = "Stop"
$Root = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $Root

function Copy-PrArtifact([int]$n) {
  $src = Join-Path $Root "tooling\benchmark-pr-artifacts\pr-$('{0:D2}' -f $n)"
  if (-not (Test-Path $src)) { throw "Missing artifact folder: $src" }
  Get-ChildItem -Path $src -Recurse -File | ForEach-Object {
    $rel = $_.FullName.Substring($src.Length).TrimStart("\", "/")
    $dest = Join-Path $Root $rel
    $destDir = Split-Path -Parent $dest
    if (-not (Test-Path $destDir)) { New-Item -ItemType Directory -Path $destDir -Force | Out-Null }
    Copy-Item -LiteralPath $_.FullName -Destination $dest -Force
  }
}

if (-not (Test-Path (Join-Path $Root ".git"))) {
  git init
  git add package.json .gitignore src tooling create-benchmark-prs.ps1 .github
  git commit -m "Initial baseline and SAST benchmark artifacts (no benchmark routes on main)."
  git branch -M main
}

# Ensure main is clean of benchmark .js routes (only .gitkeep under src/benchmark)
git checkout main 2>$null
Get-ChildItem (Join-Path $Root "src\benchmark") -Filter "*.js" -ErrorAction SilentlyContinue | Remove-Item -Force
Get-ChildItem (Join-Path $Root "public") -Recurse -ErrorAction SilentlyContinue | Remove-Item -Recurse -Force
if (-not (Test-Path (Join-Path $Root "src\benchmark"))) { New-Item -ItemType Directory -Path (Join-Path $Root "src\benchmark") -Force | Out-Null }
if (-not (Test-Path (Join-Path $Root "src\benchmark\.gitkeep"))) { New-Item -ItemType File -Path (Join-Path $Root "src\benchmark\.gitkeep") -Force | Out-Null }

git add -A
git diff --cached --quiet
if ($LASTEXITCODE -ne 0) {
  git commit -m "Reset benchmark routes on main (baseline for PR measurement)."
}

$prs = @(
  @{ n = 1; branch = "benchmark/pr-01-sqli-concat"; msg = "SAST benchmark: SQL injection via string concatenation." },
  @{ n = 2; branch = "benchmark/pr-02-sqli-template"; msg = "SAST benchmark: SQL injection via template interpolation." },
  @{ n = 3; branch = "benchmark/pr-03-hardcoded-secret"; msg = "SAST benchmark: hardcoded synthetic API key." },
  @{ n = 4; branch = "benchmark/pr-04-xss-reflected"; msg = "SAST benchmark: reflected XSS in HTML response." },
  @{ n = 5; branch = "benchmark/pr-05-dom-xss"; msg = "SAST benchmark: DOM XSS pattern (innerHTML + query param)." }
)

foreach ($pr in $prs) {
  git checkout main
  git branch -D $pr.branch 2>$null
  git checkout -b $pr.branch
  Copy-PrArtifact $pr.n
  git add -A
  git commit -m $pr.msg
  Write-Host "Created branch $($pr.branch)"
}

git checkout main
Write-Host "Done. Push: git push -u origin --all && open 5 PRs from each benchmark/* branch to main."
