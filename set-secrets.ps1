# Sets the three secrets claude-actions needs: Pro token, Team token, sync PAT.
# Values go from your paste straight to GitHub (encrypted); nothing is written to disk.
# Run it again any time to rotate a token; skip the steps you don't need.
#   powershell -ExecutionPolicy Bypass -File set-secrets.ps1
$ErrorActionPreference = 'Stop'
$repo = 'puIad/claude-actions'
$patUrl = 'https://github.com/settings/personal-access-tokens/new?name=claude-actions+sync' +
  '&description=Hourly+sync+of+the+Claude+workflow+and+token+secrets+into+every+repo' +
  '&target_name=puIad&expires_in=366&contents=write&secrets=write&workflows=write'

foreach ($tool in 'claude', 'gh') {
  if (-not (Get-Command $tool -ErrorAction SilentlyContinue)) { throw "'$tool' is not on PATH. Install it and run this again." }
}

function Read-Token($label, $prefix) {
  while ($true) {
    $secure = Read-Host "Paste the $label (hidden)" -AsSecureString
    $bstr = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($secure)
    try { $value = [Runtime.InteropServices.Marshal]::PtrToStringBSTR($bstr).Trim() }
    finally { [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($bstr) }
    if ($value.StartsWith($prefix)) { return $value }
    Write-Host "That doesn't start with '$prefix', so it's probably not the right thing. Try again." -ForegroundColor Yellow
  }
}

function Save-Secret($name, $value) {
  gh secret set $name -R $repo --body $value
  if ($LASTEXITCODE -ne 0) { throw "Setting $name failed (gh exit $LASTEXITCODE). Run the script again." }
  Write-Host "$name saved." -ForegroundColor Green
}

function Skip-Step($title) {
  Write-Host "`n=== $title ===" -ForegroundColor Cyan
  return (Read-Host 'Press Enter to do this step, or type s to skip') -eq 's'
}

if (-not (Skip-Step '1/3  Pro account token')) {
  Write-Host 'A browser sign-in opens next. Make sure it is your PRO account, then copy the token it prints.'
  & claude setup-token
  Save-Secret 'CLAUDE_CODE_OAUTH_TOKEN' (Read-Token 'Pro token' 'sk-ant-oat')
}

if (-not (Skip-Step '2/3  Team account token')) {
  Write-Host 'Same again, but sign in with your TEAM account this time.'
  Write-Host 'If the browser is still signed in to Pro: copy the URL that setup-token prints and open it in a private window signed in to Team.'
  & claude setup-token
  Save-Secret 'CLAUDE_CODE_OAUTH_TOKEN_TEAM' (Read-Token 'Team token' 'sk-ant-oat')
}

if (-not (Skip-Step '3/3  Sync token (GitHub PAT)')) {
  Write-Host 'Opening the pre-filled token page. On it:'
  Write-Host '  - Repository access: choose "All repositories" (this is what covers future repos)'
  Write-Host '  - Check Contents, Secrets and Workflows are "Read and write"'
  Write-Host '  - Generate token, copy it'
  Start-Process $patUrl
  Save-Secret 'SYNC_TOKEN' (Read-Token 'GitHub token' 'github_pat_')
}

Write-Host "`nSecrets now in ${repo}:" -ForegroundColor Cyan
gh secret list -R $repo
