$scriptUrl = "https://raw.githubusercontent.com/Laezor/biorand-seed/main/biorand-seed.ps1"
$script = (Invoke-RestMethod -Uri $scriptUrl); Invoke-Expression $script