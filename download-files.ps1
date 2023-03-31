<#.SYNOPSIS
This is a PowerShell script that downloads files from a JSON file using the URLs provided in the JSON, and saves them in a specified directory.

.EXAMPLE
.\\download-files.ps1 -JsonUrl "https://insidiousmeme.com/presenta/ai/powershell/test.json" -OutputDir "C:\MyDownloads" -Verbose

This example downloads files from the JSON file located at https://example.com/files.json and saves them to the directory C:\MyDownloads.

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
            "Name": "yakGPT.ico",
            "Url": "https://insidiousmeme.com/presenta/ai/powershell/yakGPT.ico"
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
            "Url": "https://insidiousmeme.com/presenta/ai/powershell/myTech.TodayTools.url"
        },
        {
            "Name": "myTechToday-portrait-02.ico",
            "Url": "https://insidiousmeme.com/presenta/ai/powershell/myTechToday-portrait-02.ico"
        },
        {
            "Name": "myTech.Today.url",
            "Url": "https://insidiousmeme.com/presenta/ai/powershell/myTech.Today.url"
        }
    ]
}

.PARAMETER OutputDir
The directory where the downloaded files will be saved. If not specified, it will use the directory specified in the environment variable "myTechToday" or MyDocuments\Downloads if the variable is not set.

.OUTPUTS
This script does not return any objects, but writes downloaded files to the specified directory.

.NOTES
This script requires PowerShell 3.0 or higher.
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory = $true)]
    [string]$JsonUrl,
    [Parameter()]
    [string]$OutputDir
)

try {
    # If the $OutputDir is null, use "myTechToday" environment variable as the directory. If "myTechToday" variable does not exist, use MyDocuments\Downloads.
    if (!$OutputDir) {
        if ($myTechToday = [Environment]::GetEnvironmentVariable("myTechToday")) {
            $today = Get-Date -format "yyyy-MM-dd"
            $OutputDir = Join-Path $myTechToday "downloads\$today"
        } else {
            $OutputDir = [Environment]::GetFolderPath("MyDocuments") + "\Downloads"
        }
    }

    # Check if $OutputDir exists, otherwise create it.
    if (-not (Test-Path $OutputDir -PathType Container)) {
        Write-Verbose "Output directory not found. Creating $OutputDir"
        $null = New-Item -ItemType Directory -Path $OutputDir
    }

    # Make web request and store the JSON data in $files variable
    $json = Invoke-RestMethod $JsonUrl

    # Check if the $json object is null or if it does not contain files array, if so output an error message.
    if (!$json.Files) {
        Write-Error "Error: JSON file may be empty or incorrectly formatted."
    }
    else {
        foreach ($file in $json.Files) {

            $fileName = $file.Name
            $fileUrl = $file.Url
            $fileOutputPath = Join-Path $OutputDir $fileName
            
            # Test if the file exists on the internet\n            $fileAvailable = $true
            try {
                $null = Invoke-WebRequest $fileUrl -UseBasicParsing -ErrorAction Stop
            } catch {
                $fileAvailable = $false
            }

            # If the file exists on the internet, download it, otherwise print a warning message
            if ($fileAvailable) {
                # Testing if the file exists already
                if (!(Test-Path -Path $fileOutputPath)) {
                    # Download file to $OutputDir.\n                    Invoke-WebRequest $fileUrl -OutFile $fileOutputPath
                    # Test and validate the file after downloading to ensure it was downloaded successfully
                    if (!(Test-Path -Path $fileOutputPath)) {
                        Write-Warning "Download of $fileUrl to $fileOutputPath failed!"
                    } else {
                        Write-Verbose "Downloaded $fileName successfully from $fileUrl to $fileOutputPath"
                    }
                } else {
                    Write-Warning "File $fileName already exists in $OutputDir"
                }
            } else {
                Write-Warning "File $fileName unavailable for download from $fileUrl. Skipping..."
            }
        }
    }
}

catch [System.Exception]{
    Write-Error "An error occurred: $($_.Exception.Message)"
    exit 1
}

# Return success.
exit 0