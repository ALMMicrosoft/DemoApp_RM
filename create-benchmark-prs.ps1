# Creates 5 local branches from the current HEAD, each with one SAST-benchmark finding.
# Push the repo, then open one PR per branch against main to measure CodeQL + Copilot.
# Requires: git, this repo already has an initial commit on main.

$ErrorActionPreference = "Stop"
$Root = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $Root

# Git prints non-fatal messages (e.g. "Already on 'main'") to stderr; PowerShell can treat that as a terminating error when $ErrorActionPreference is Stop.
function Invoke-GitNoThrow {
  param([Parameter(Mandatory = $true)][string[]]$Args)
  $prev = $ErrorActionPreference
  $ErrorActionPreference = "SilentlyContinue"
  try {
    & git @Args 2>&1 | Out-Null
    return $LASTEXITCODE
  }
  finally {
    $ErrorActionPreference = $prev
  }
}

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
Invoke-GitNoThrow @("checkout", "-q", "main") | Out-Null
Get-ChildItem (Join-Path $Root "src\benchmark") -Filter "*.js" -ErrorAction SilentlyContinue | Remove-Item -Force
# Only remove benchmark static assets (avoid wiping all of /public — reparse points could delete unrelated paths).
$pr05Public = Join-Path $Root "public\benchmark-pr05"
if (Test-Path $pr05Public) {
  Remove-Item $pr05Public -Recurse -Force
}
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
  Invoke-GitNoThrow @("checkout", "-q", "main") | Out-Null
  Invoke-GitNoThrow @("branch", "-D", $pr.branch) | Out-Null
  git checkout -q -b $pr.branch
  if ($LASTEXITCODE -ne 0) { throw "git checkout -b $($pr.branch) failed with exit $LASTEXITCODE" }
  Copy-PrArtifact $pr.n
  git add -A
  git commit -m $pr.msg
  Write-Host "Created branch $($pr.branch)"
}

Invoke-GitNoThrow @("checkout", "-q", "main") | Out-Null
Write-Host "Done. Push: git push -u origin --all && open 5 PRs from each benchmark/* branch to main."
