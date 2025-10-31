param(
    [string]$Message = "Auto: commit changes"
)

Set-Location -Path $PSScriptRoot\..\
git add -A
git commit -m $Message
if ($LASTEXITCODE -ne 0) {
    Write-Output "No changes to commit or commit failed."
} else {
    Write-Output "Committed: $Message"
}
