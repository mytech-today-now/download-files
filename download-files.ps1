<#
.SYNOPSIS
This script downloads files from a JSON file using the URLs provided in the JSON, and saves them in a specified directory.

.PARAMETER JsonUrl
The URL of the JSON file containing the download URLs.

.PARAMETER OutputDir
The directory where the downloaded files will be saved. If not specified, it will use the directory specified in the environment variable "myTechToday" or MyDocuments\Downloads if the variable is not set.

.EXAMPLE
.\download-files.ps1 -JsonUrl "https://example.com/files.json" -OutputDir "C:\MyDownloads" -Verbose

This example downloads files from the JSON file located at https://example.com/files.json and saves them to the directory C:\MyDownloads. 

.OUTPUTS
This script does not return any objects, but writes downloaded files to the specified directory.

.NOTES
This script requires PowerShell 3.0 or higher.

#>

[CmdletBinding()]
param(
    [Parameter(Mandatory=$true)]
    [string]$JsonUrl,

    [Parameter()]
    [string]$OutputDir
)

if (-not $OutputDir) {
    # Check if "myTechToday" environment variable is set
    if ($myTechToday = [Environment]::GetEnvironmentVariable("myTechToday")) {
        # Get current date and format it
        $today = Get-Date -format "yyyy-MM-dd"
        # Construct the output directory path
        $OutputDir = Join-Path $myTechToday "downloads\$today"
    }
    else {
        # Use MyDocuments\Downloads as default download directory
        $OutputDir = [Environment]::GetFolderPath("MyDocuments") + "\Downloads"
    }
}

try {
    # Check if OutputDir exists, otherwise create it
    if (-not (Test-Path $OutputDir -PathType Container)) {
        Write-Verbose "Output directory not found. Creating $OutputDir"
        $null = New-Item -ItemType Directory -Path $OutputDir
    }

    # Get the JSON data and convert it to PowerShell objects
    $webRequest = [System.Net.WebRequest]::Create($JsonUrl)
    $webResponse = $webRequest.GetResponse()
    $jsonStream = $webResponse.GetResponseStream()

    $jsonReader = New-Object System.IO.StreamReader($jsonStream)
    $json = $jsonReader.ReadToEnd()
    $jsonReader.Close()

    $files = ConvertFrom-Json $json

    # Loop through files and download them
    foreach ($file in $files) {
        $fileName = $file.Name
        $fileUrl = $file.Url
        $fileOutputPath = Join-Path $OutputDir $fileName
        Invoke-WebRequest $fileUrl -OutFile $fileOutputPath
        Write-Verbose "Downloaded $fileName $fileOutputPath"
    }
} 
catch {
    # Handle exceptions
    Write-Error "An error occurred: $($_.Exception.Message)"
    exit 1
}

# Exit with code 0 indicating success
exit 0
