<#
    Script Name: BIORAND Randomizer Seed Generator
    Author: Laezor
    Discord: Laezor#5385
    Version: 1.2
    Created: 2024-12-18
    Updated: 2024-12-21

    Description:
    This PowerShell script automates the process of generating and downloading randomized seeds for Resident Evil 4 Remake.
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
    - Edit the `reseed-config.json` file to set the path to the Resident Evil 4 installation and Biorand token.
#>

# Constants
$Profiles = @{
    "Main Game - Balanced Combat Randomizer by 7rayD" = 7
    "Main Game - Challenging Randomizer by 7rayD"     = 455
    "Separate Ways - Challenging *WIP by 7rayD"       = 9919
    "Separate Ways - Balanced *WIP by 7rayD"          = 10415
}

$DeleteLogsFromExtraction = @(
    "config.json",
    "output_leon.log",
    "input_leon.log",
    "process_leon.log"
)

$BaseApi = "https://api.biorand.net"
$biorand_sign_in = "$BaseApi/auth/signin"
$configPathName = "./reseed-config.json"
$GamePath = "C:\\Path\\To\\RE4\\Install"


#functions

function Check-ForUpdates {
    $currentVersion = "1.2" # Current script version
    $tagsUrl = "https://api.github.com/repos/laezor/biorand-seed/tags"
    $scriptUrl = "https://raw.githubusercontent.com/laezor/biorand-seed/main/biorand-seed.ps1" # URL to download the latest script
    try {
        $response = Invoke-RestMethod -Uri $tagsUrl -Method GET
        $latestTag = $response[0].name
        $latestVersion = $latestTag.TrimStart('v') # Assuming tags are prefixed with 'v', e.g., 'v1.3'
        Write-Host "Current Version: $currentVersion"
        Write-Host "Latest Version from GitHub: $latestVersion"
        if ($latestVersion -gt $currentVersion) {
            Write-Host "A new version ($latestVersion) is available. Downloading update..." -ForegroundColor Cyan
            
            # Alternative way to get the script path
            $scriptPath = $PSCommandPath
            if (-not $scriptPath) {
                throw "Script path is null or empty."
            }
            Invoke-WebRequest -Uri $scriptUrl -OutFile $scriptPath -UseBasicParsing
            Write-Host "Update downloaded. Please restart the script." -ForegroundColor Green
            exit 0
        }
        else {
            Write-Host "You are using the latest version." -ForegroundColor Green
        }
    }
    catch {
        Write-Host "Failed to check for updates: $_" -ForegroundColor Red
    }
 
 
}
 

function Delete-Logs {
    param ($RE4Path)

    foreach ($file in $DeleteLogsFromExtraction) {
        $filePath = Join-Path -Path $RE4Path -ChildPath $file
        if (Test-Path $filePath) {
            Remove-Item $filePath -Force
            Write-Host "Deleted: $filePath" -ForegroundColor Green
        }
        else {
            Write-Host "File not found: $filePath" -ForegroundColor Yellow
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
        Write-Host "Configuration file not found. Creating a default reseed-config.json..." -ForegroundColor Yellow

        $defaultConfig = @{
            RE4InstallPath = $GamePath
            BiorandToken   = ""
        } | ConvertTo-Json -Depth 2

        $defaultConfig | Out-File -FilePath $configPath -Encoding UTF8
        Write-Host @"
Default configuration file created at $configPath.
"@
     
    }

    $config = Get-Content $configPath | ConvertFrom-Json

    if (-not $config.RE4InstallPath -or $config.RE4InstallPath -eq $GamePath) {
        $config.RE4InstallPath = Read-Host "Enter your RE4 installation path right where Game Executable is."
        $config | ConvertTo-Json -Depth 2 | Out-File -FilePath $configPathName -Encoding UTF8
    }
    if (-not $config.RE4InstallPath) {
        Write-Host "Invalid configuration. Please update $configPath with valid values." -ForegroundColor Red
        exit 1
    }

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
                RE4InstallPath = $GamePath
                BiorandToken   = ""
            }
        }

        $config.BiorandToken = $response.token
        $config | ConvertTo-Json -Depth 2 | Out-File -FilePath $configPath -Encoding UTF8

        Write-Host "Login successful! Token saved to reseed-config.json." -ForegroundColor Green
    }
    else {
        Write-Host "Login failed. Please check your email and code." -ForegroundColor Red
        exit 1
    }
}

function Get-BiorandProfile {
    param ($ProfileID, $Token)
    
    $url = "$BaseApi/profile"
    $headers = @{ "Authorization" = "Bearer $Token" }

    $response = Invoke-RestMethod -Uri $url -Method GET -Headers $headers
    $biorand_profile = $response | Where-Object { $_.id -eq $ProfileID }

    if (-not $biorand_profile) {
        throw "Profile with ID $ProfileID not found in Biorand API response."
    }

    return $biorand_profile
}

function Generate-BiorandSeed {
    param ($Seed, $Biorand_profile, $Token)
    
    $url = "$BaseApi/rando/generate"
    $headers = @{
        "Authorization" = "Bearer $Token"
        "Content-Type"  = "application/json"
    }
    $body = @{
        profileId = $Biorand_profile.id
        seed      = $Seed
        config    = $Biorand_profile.config
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

function Unzip-Seed {
    param ($ZipPath, $Dest)

    Expand-Archive -Path $ZipPath -DestinationPath $Dest -Force
}

# Main Script
Check-ForUpdates
Write-Host "Select a randomizer profile:"
$Profiles.GetEnumerator() | ForEach-Object {
    Write-Host "$($_.Value): $($_.Key)"
}
Write-Host ""
$selectedProfileID = Read-Host "Enter profile ID (default is 7)"
if (-not $selectedProfileID) {
    $selectedProfileID = 7
}
if (-not ($Profiles.Values -contains [int]$selectedProfileID)) {
    Write-Host "Invalid profile ID. Exiting..." -ForegroundColor Red
    exit 1
}

Write-Host "Generating new seed..." -ForegroundColor Cyan

$config = Load-Configuration

if (-not $config.BiorandToken) {
    Write-Host "No Biorand token found in configuration. Initiating login..."
    Login-Biorand
    $config = Load-Configuration
}


Write-Host "RE4 path: $($config.RE4InstallPath)"
Write-Host "Profile ID: $selectedProfileID"
Write-Host ""

Write-Host "Getting randomizer profile..."
try {
    $biorand_profile = Get-BiorandProfile -ProfileID $selectedProfileID -Token $config.BiorandToken
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
    $generation = Generate-BiorandSeed -Seed $seed -Biorand_profile $biorand_profile -Token $config.BiorandToken
}
catch {
    Write-Host "Error generating seed: $_" -ForegroundColor Red
    exit 1
}

$PollingIntervalSeconds = 5
$MaxAttempts = 10

Write-Host "Waiting for seed to generate..."

$downloadUrl = $null

for ($attempt = 1; $attempt -le $MaxAttempts; $attempt++) {
    try {
        $status = Query-SeedStatus -GenerationID $generation.id -Token $config.BiorandToken
       

        if ($status.status -eq 1) {
            Write-Host "Seed is queued for generation." 
        }
        elseif ($status.status -eq 2) {
            Write-Host "Seed is being generated." 
        }
        elseif ($status.status -eq 3) {
            Write-Host "`nSeed is done generating." -ForegroundColor Green
            $downloadUrl = $status.downloadUrl
            break
        }
        else {
            throw "Unknown seed status."
        }
   

    }
    catch {
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
    Unzip-Seed -ZipPath $zipPath -Dest $config.RE4InstallPath
    Write-Host "Reseeding completed successfully!"
    Delete-Logs -RE4Path $config.RE4InstallPath
    Write-Host "Have fun in your biorand permadeath run! - https://re4r.biorand.net" -ForegroundColor Green
}
catch {
    Write-Host "Failed to unzip seed: $_" -ForegroundColor Red
    exit 1
}
