<#
.SYNOPSIS
This is a PowerShell script that downloads files from a JSON file using the URLs provided in the JSON, and saves them in a specified directory.

.EXAMPLE
.\\download-files.ps1 -JsonUrl "https://insidiousmeme.com/presenta/ai/powershell/test.json" -Verbose

This example downloads files from the JSON file located at https://example.com/files.json and saves them to the directory $env:Programs\myTechToday\downloads\{today's date in yyyy-mm-dd format} if it exists, otherwise it checks if the myTech.Today System Environment Variable is set, and if so it will use {path of that variable}\downloads\{today's date in yyyy-mm-dd format}\ as the destination path for the files. Otherwise, it will use the current working directory.

.PARAMETER JsonUrl
The URL of the JSON file containing the download URLs.  JsonUrl file in the format of the following:

{
    "Files": [
        {
            "Name": "chatgpt-purple.ico",
            "Url": "https://insidiousmeme.com/presenta/ai/powershell/chatgpt-purple.ico"
        },
        {
            "Name": "ChatGPT.url",
            "Url": "https://insidiousmeme.com/presenta/ai/powershell/ChatGPT.url"
        },
        {
            "Name": "yakGPT.ico\",
            "Url": \"https://insidiousmeme.com/presenta/ai/powershell/yakGPT.ico"
        },
        {
            "Name": "YakGPT.url",
            "Url": "https://insidiousmeme.com/presenta/ai/powershell/YakGPT.url"
        },
        {
            "Name": "tools.ico",
            "Url": "https://insidiousmeme.com/presenta/ai/powershell/tools.ico"
        },
        {
            "Name": "myTech.Today Tools.url",
            "Url\": "https://insidiousmeme.com/presenta/ai/powershell/myTech.TodayTools.url"
        },
        {
            "Name": "myTechToday-portrait-02.ico",
            "Url\": \"https://insidiousmeme.com/presenta/ai/powershell/myTechToday-portrait-02.ico"
        },
        {
            "Name": "myTech.Today.url\",
            "Url": "https://insidiousmeme.com/presenta/ai/powershell/myTech.Today.url"
        }
    ]
}

.OUTPUTS
This script does not return any objects, but writes downloaded files to the specified directory.

.NOTES
This script requires PowerShell 3.0 or higher.
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory = $true)]
    [string]$JsonUrl
)

$today = Get-Date -format "yyyy-MM-dd"

# Set the default output directory to the programs directory or the value of the environmental variable
$programDir = "$env:Programs\myTechToday\downloads\"
if ([Environment]::GetEnvironmentVariable("myTechToday")) {
    $customDir = [Environment]::GetEnvironmentVariable("myTechToday") + "\downloads\"
}

# Check if custom directory exists and set output directory accordingly
if ($customDir -and (Test-Path -Path $customDir)) {
    $OutputDir = Join-Path $customDir $today
} elseif (Test-Path -Path $programDir) {
    $OutputDir = Join-Path $programDir $today
} else {
    Write-Warning "Neither custom nor default directory found. Using current working directory."
    $OutputDir = Get-Location
}# If the download directory does not exist, create it
if (!(Test-Path -Path $OutputDir)) {
    Write-Verbose "Creating directory: $OutputDir"
    New-Item -ItemType Directory -Path $OutputDir
}

try {
    # Check if the web server is accessible, Check if the $json object is null or if it does not contain files array. 
    $json = Invoke-RestMethod $JsonUrl
    if (!$json.Files) {
        Write-Error "Error: JSON file may be empty or incorrectly formatted."
    }
    else {
        foreach ($file in $json.Files) {
            $fileName = $file.Name
            $fileUrl = $file.Url
            $fileOutputPath = Join-Path $OutputDir $fileName
            
            # Test if the file exists on the internet
            $fileAvailable = $true
            try {                
                $null = Invoke-WebRequest $fileUrl -UseBasicParsing -ErrorAction Stop
            } catch {
                $fileAvailable = $false
            }

            # If the file exists on the internet, download it, otherwise print a warning message
            if ($fileAvailable) {                
                # Test if the file already exists
                if (!(Test-Path -Path $fileOutputPath)) {
                    # Download file to $OutputDir.                    
                    Invoke-WebRequest $fileUrl -OutFile $fileOutputPath
                    # Test and validate the file after downloading to ensure it was downloaded successfully
                    if (!(Test-Path -Path $fileOutputPath)) {
                        Write-Warning "Download of $fileUrl to $fileOutputPath failed!"
                    } else {
                        Write-Verbose "Downloaded $fileName successfully from $fileUrl to $fileOutputPath"
                    }                } else {
                    Write-Warning "File $fileName already exists in $OutputDir"
                }
            } else {
                Write-Warning "File $fileName unavailable for download from $fileUrl. Skipping...\\\"
            }
        }
    }
} catch {
    Write-Error "An error occurred: $($Error[0].Exception.Message)"
    exit 1
}

# Return success.
exit 0
```