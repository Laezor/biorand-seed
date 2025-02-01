<#
    Script Name: BIORAND Randomizer Seed Generator
    Author: Laezor
    Discord: Laezor#5385
    Version: 2.0
    Created: 2024-12-18
    Updated: 2025-02-01

    Description:
    This PowerShell script automates the process of generating and downloading randomized seeds for Resident Evil games.
    It supports multiple randomizer profiles, such as Balanced Combat and Challenging profiles, and interacts
    with the Biorand API for randomization.

    License:
    MIT License

    Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"),
    to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense,
    and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
    
    The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
    
    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
    FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
    WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
    
    Notes:
    - Ensure you have PowerShell 5.1+ installed.
    - Requires access to the Biorand API and a valid API token.
    - Edit the `biorand-config.json` file to set the path to the Resident Evil 4 and 2 installations and Biorand token.
    #>
    
# Constants
$DeleteLogsFromExtraction = @(
    "config.json",
    "*.log"
)
    
$BaseApi = "https://api.biorand.net"
$biorand_sign_in = "$BaseApi/auth/signin"
$configPathName = "./biorand-config.json"
$RE4GamePath = "C:\\Path\\To\\RE4\\Install"
$RE2GamePath = "C:\\Path\\To\\RE2\\Install"
$PollingIntervalSeconds = 5
$downloadUrl = $null

#functions
function Get-BiorandGames {
    param ($Token)
    
    $url = "$BaseApi/game"
    $headers = @{ "Authorization" = "Bearer $Token" }
    $response = Invoke-RestMethod -Uri $url -Method GET -Headers $headers
    return $response
}

function Get-BiorandProfiles {
    param (
        $Token,
        $GameId
    )
    
    $url = "$BaseApi/profile?game=$GameId"
    $headers = @{ "Authorization" = "Bearer $Token" }
    $response = Invoke-RestMethod -Uri $url -Method GET -Headers $headers
    return $response
}

function Delete-Logs {
    param ($GamePath)

    foreach ($pattern in $DeleteLogsFromExtraction) {
        $files = Get-ChildItem -Path $GamePath -Filter $pattern -File
        foreach ($file in $files) {
            try {
                Remove-Item $file.FullName -Force
                Write-Host "Deleted: $($file.Name)" -ForegroundColor Green
            }
            catch {
                Write-Host "Failed to delete: $($file.Name) - $_" -ForegroundColor Yellow
            }
        }
    }
}

function Generate-Seed {
    $seed = -join ((0..5) | ForEach-Object { Get-Random -Minimum 0 -Maximum 10 })
    return $seed
}

function Load-Configuration {
    $configPath = $configPathName
    if (-not (Test-Path $configPath)) {
        Write-Host "Configuration file not found. Creating a default biorand-config.json..." -ForegroundColor Yellow

        $defaultConfig = @{
            RE4InstallPath = $RE4GamePath
            RE2InstallPath = $RE2GamePath
            BiorandToken   = ""
        } | ConvertTo-Json -Depth 2

        $defaultConfig | Out-File -FilePath $configPath -Encoding UTF8
        Write-Host @"
Default configuration file created at $configPath.
"@
     
    }

    $config = Get-Content $configPath | ConvertFrom-Json

    if (-not $config.RE4InstallPath -or $config.RE4InstallPath -eq $RE4GamePath) {
        $config.RE4InstallPath = Read-Host "Enter your RE4 installation path right where Game Executable is."
    }
    if (-not $config.RE2InstallPath -or $config.RE2InstallPath -eq $RE2GamePath) {
        $config.RE2InstallPath = Read-Host "Enter your RE2 installation path right where Game Executable is."
    }
    if (-not $config.RE4InstallPath -or -not $config.RE2InstallPath) {
        Write-Host "Invalid configuration. Please update $configPath with valid values." -ForegroundColor Red
        exit 1
    }

    $config | ConvertTo-Json -Depth 2 | Out-File -FilePath $configPathName -Encoding UTF8
    return $config
}

function Login-Biorand {
    $email = Read-Host "Enter your Biorand email"

    Write-Host "Sending login request to Biorand..." -ForegroundColor Cyan
    $response = Invoke-RestMethod -Uri $biorand_sign_in -Method POST -Headers @{ "Content-Type" = "application/json" } -Body (@{ email = $email } | ConvertTo-Json -Depth 2)

    Write-Host "A login code has been sent to your email." -ForegroundColor Green
    $code = Read-Host "Enter the code from your email"

    Write-Host "Verifying login code..." -ForegroundColor Cyan
    $response = Invoke-RestMethod -Uri $biorand_sign_in -Method POST -Headers @{ "Content-Type" = "application/json" } -Body (@{ email = $email; code = $code } | ConvertTo-Json -Depth 2)

    if ($response.token) {
        $configPath = $configPathName
        $config = if (Test-Path $configPath) {
            Get-Content $configPath | ConvertFrom-Json
        }
        else {
            @{
                RE4InstallPath = $RE4GamePath
                RE2InstallPath = $RE2GamePath
                BiorandToken   = ""
            }
        }

        $config.BiorandToken = $response.token
        $config | ConvertTo-Json -Depth 2 | Out-File -FilePath $configPath -Encoding UTF8

        Write-Host "Login successful! Token saved to biorand-config.json." -ForegroundColor Green
    }
    else {
        Write-Host "Login failed. Please check your email and code." -ForegroundColor Red
        exit 1
    }
}

function Get-BiorandProfile {
    param (
        $ProfileID,
        $Token,
        $GameId
    )
    
    $url = "$BaseApi/profile/$ProfileID"
    $headers = @{ "Authorization" = "Bearer $Token" }

    $response = Invoke-RestMethod -Uri $url -Method GET -Headers $headers
    return $response
}

function Generate-BiorandSeed {
    param ($Seed, $Biorand_profile, $Token, $GameId)
    
    $url = "$BaseApi/rando/generate"
    $headers = @{
        "Authorization" = "Bearer $Token"
        "Content-Type"  = "application/json"
    }
    $body = @{
        profileId = $Biorand_profile.id
        seed      = $Seed
        config    = $Biorand_profile.config
        gameId    = $GameId
    } | ConvertTo-Json -Depth 2

    $response = Invoke-RestMethod -Uri $url -Method POST -Headers $headers -Body $body
    return $response
}

function Query-SeedStatus {
    param ($GenerationID, $Token)

    $url = "$BaseApi/rando/$GenerationID"
    $headers = @{ "Authorization" = "Bearer $Token" }

    $response = Invoke-RestMethod -Uri $url -Method GET -Headers $headers
    return $response
}

function Download-SeedZip {
    param ($Seed, $Version, $DownloadUrl)

    $downloadDir = Join-Path -Path "./biorand-seeds" -ChildPath "$Seed-v$Version"
    New-Item -ItemType Directory -Path $downloadDir -Force | Out-Null

    $zipFileName = "biorand-re4r-$Seed.zip"
    $zipPath = Join-Path -Path $downloadDir -ChildPath $zipFileName

    $wc = New-Object net.webclient
    $wc.Downloadfile($DownloadUrl, $zipPath)
    return $zipPath
}

function Get-BiorandStats {   
    $url = "$BaseApi/rando/stats"
    
    try {
        $response = Invoke-RestMethod -Uri $url -Method GET 
        Write-Host "`nBiorand Community Statistics:" -ForegroundColor Cyan
        Write-Host "Total Seeds Generated: $($response.randoCount)" -ForegroundColor Green
        Write-Host "Total Profiles Created: $($response.profileCount)" -ForegroundColor Green
        Write-Host "Total Users: $($response.userCount)" -ForegroundColor Green
        Write-Host ""
    }
    catch {
        Write-Host "Unable to fetch Biorand statistics" -ForegroundColor Yellow
    }
}

# Main Script
Write-Host "Current Version: v1.5" -ForegroundColor Green
Get-BiorandStats
$config = Load-Configuration
if (-not $config.BiorandToken) {
    Write-Host "No Biorand token found in configuration. Initiating login..."
    Login-Biorand
    $config = Load-Configuration
}
Write-Host ""

# Get available games
$games = Get-BiorandGames -Token $config.BiorandToken

Write-Host "`nAvailable Games:" -ForegroundColor Cyan
for ($i = 0; $i -lt $games.Count; $i++) {
    Write-Host "$($i + 1). $($games[$i].name)"
}

$selectedGameIndex = Read-Host "`nSelect a game (1-$($games.Count))"
$selectedGame = $games[$selectedGameIndex - 1]
$gamePath = if ($selectedGame.moniker -eq "re4r") { $config.RE4InstallPath } else { $config.RE2InstallPath }

Write-Host "`nSelected game: $($selectedGame.name)" -ForegroundColor Green

# Get available profiles for the selected game
Write-Host "Getting profiles for game: $($selectedGame.id)" -ForegroundColor Cyan
$profiles = Get-BiorandProfiles -Token $config.BiorandToken -GameId $selectedGame.id

Write-Host "`nAvailable profiles:"
if ($profiles.Count -eq 0) {
    Write-Host "No profiles found!" -ForegroundColor Red
} else {
    $profiles | ForEach-Object {
        Write-Host "$($_.id): $($_.name) by $($_.userName)" -ForegroundColor Red
    }
}
Write-Host ""
$selectedProfileID = Read-Host "Enter profile ID (default is 7)"
if (-not $selectedProfileID) {
    $selectedProfileID = 7
}
if (-not ($profiles.id -contains [int]$selectedProfileID)) {
    Write-Host "Invalid profile ID. Exiting..." -ForegroundColor Red
    exit 1
}

Write-Host "Generating new seed..." -ForegroundColor Cyan

Write-Host "Game path: $gamePath"
Write-Host "Profile ID: $selectedProfileID"
Write-Host ""

Write-Host "Getting randomizer profile..."
try {
    $biorand_profile = Get-BiorandProfile -ProfileID $selectedProfileID -Token $config.BiorandToken -GameId $selectedGame.id
    Write-Host "Profile info downloaded."
    Write-Host "Profile name: $($biorand_profile.name)"
    Write-Host "Profile description: $($biorand_profile.description)"
}
catch {
    Write-Host "Error during profile retrieval: $_" -ForegroundColor Red
    exit 1
}
Write-Host ""

$seed = Generate-Seed
Write-Host "Generated seed: $seed"

$confirmation = Read-Host "Continue? (y/n)"
if ($confirmation -ne "y") {
    Write-Host "Reseeding aborted." -ForegroundColor Yellow
    exit 0
}

Write-Host ""
Write-Host "Generating seed on Biorand..."
try {
    $response = Generate-BiorandSeed -Seed $seed -Biorand_profile $biorand_profile -Token $config.BiorandToken -GameId $selectedGame.id
    $generation = $response
}
catch {
    Write-Host "Error generating seed: $_" -ForegroundColor Red
    exit 1
}

$progressParams = @{
    Activity        = "Generating Biorand Seed"
    Status          = "Waiting for generation to complete..."
    PercentComplete = 0
}
$genStatus = $true
while ($genStatus) {
    try {
        $status = Query-SeedStatus -GenerationID $generation.id -Token $config.BiorandToken
        
        switch ($status.status) {
            1 { 
                Write-Progress @progressParams -CurrentOperation "Seed is queued for generation" -PercentComplete 25
            }
            2 { 
                Write-Progress @progressParams -CurrentOperation "Seed is being generated" -PercentComplete 50
            }
            3 { 
                Write-Progress -Activity "Generating Biorand Seed" -Status "Complete!" -PercentComplete 100 -Completed
                Write-Host "`nSeed is done generating." -ForegroundColor Green
                
                # Get the patch file URL (first asset)
                $patchAsset = $status.assets | Where-Object { $_.key -eq "1-patch" }
                if ($patchAsset) {
                    $downloadUrl = $patchAsset.downloadUrl
                    Write-Host "Found patch file: $($patchAsset.fileName)" -ForegroundColor Green
                    Write-Host $patchAsset.description -ForegroundColor Cyan
                } else {
                    throw "Patch file not found in assets"
                }
                
                $genStatus = $false
            }
            4 {
                Write-Progress -Activity "Generating Biorand Seed" -Status "Failed!" -PercentComplete 100 -Completed
                if ($status.failReason) {
                    Write-Host "`nSeed generation failed: $($status.failReason)" -ForegroundColor Red
                } else {
                    Write-Host "`nSeed generation failed with unknown reason" -ForegroundColor Red
                }
                exit 1
            }
            default { throw "Unknown seed status." }
        }
    }
    catch {
        Write-Progress -Activity "Generating Biorand Seed" -Status "Error" -PercentComplete 100 -Completed
        Write-Host "`nError querying status: $_" -ForegroundColor Red
        exit 1
    }

    Start-Sleep -Seconds $PollingIntervalSeconds
}


if (-not $downloadUrl) {
    Write-Host "`nSeed generation timed out. Aborting." -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "Downloading seed zip..."
try {
    $zipPath = Download-SeedZip -Seed $seed -Version $generation.version -DownloadUrl $downloadUrl
    Write-Host "Seed zip downloaded to $zipPath"
}
catch {
    Write-Host "Error downloading seed zip: $_" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "Unzipping seed zip..."
try {
    Expand-Archive -Path $ZipPath -DestinationPath $gamePath -Force
    Write-Host "Reseeding completed successfully!"
    Delete-Logs -GamePath $gamePath
    Write-Host "Have fun in your biorand permadeath run! - https://$($selectedGame.moniker).biorand.net" -ForegroundColor Green
}
catch {
    Write-Host "Failed to unzip seed: $_" -ForegroundColor Red
    exit 1
}
