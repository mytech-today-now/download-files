<#

.SYNOPSIS
This is a PowerShell script that downloads files from a JSON file using the URLs provided in the JSON, and saves them in a specified directory.

.EXAMPLE
.\\download-files.ps1 -JsonUrl "https://insidiousmeme.com/presenta/ai/powershell/test.json" -OutputDir "C:\MyDownloads" -Verbose

This example downloads files from the JSON file located at https://example.com/files.json and saves them to the directory C:\MyDownloads.

.PARAMETER JsonUrl
The URL of the JSON file containing the download URLs.  

JsonUrl file in the format of the following:

{
  "Files": [
    {
      "Name": "chatgpt-purple.ico\",
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
      "Url": "https://insidiousmeme.com/presenta/ai/powershell/yakGPT.ico"
    },
    {
      "Name": "myTech.Today Tools.url",
      "Url": "https://insidiousmeme.com/presenta/ai/powershell/myTech.TodayTools.url"
    },
    {
      "Name": "tools.ico",
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

# If the $OutputDir is null, use "myTechToday" environment variable as the directory. If "myTechToday" variable does not exist, use MyDocuments\Downloads.
if (!$OutputDir) {
    if ($myTechToday = [Environment]::GetEnvironmentVariable("myTechToday")) {
        $today = Get-Date -format "yyyy-MM-dd"
        $OutputDir = Join-Path $myTechToday "downloads\$today"
    } else {
        $OutputDir = [Environment]::GetFolderPath("MyDocuments") + "\Downloads"
    }
}

try {

    # Check if $OutputDir exists, otherwise create it.
    if (-not (Test-Path $OutputDir -PathType Container)) {
        Write-Verbose "Output directory not found. Creating $OutputDir"
        $null = New-Item -ItemType Directory -Path $OutputDir
    }

    # Make web request and store the JSON data in $files variable
    $webRequest = [System.Net.WebRequest]::Create($JsonUrl)
    $webResponse = $webRequest.GetResponse()
    $jsonStream = $webResponse.GetResponseStream()

    $jsonReader = New-Object System.IO.StreamReader($jsonStream)
    $json = $jsonReader.ReadToEnd()
    $jsonReader.Close()

    $filesObject = ConvertFrom-Json $json

    # Check if the $files object is null, if so output an error message.
    if (!$filesObject) {
        Write-Error "Error: JSON file may be empty or incorrectly formatted."
    }
    #if it exists test to see if a file si there first then download if it doesn't exist
    else {        
        foreach ($file in $filesObject.Files) {

            $fileName = $file.Name
            $fileUrl = $file.Url
            $fileOutputPath = Join-Path $OutputDir $fileName
            
            # Testing if the file exists already
            If (!(Test-Path -Path $fileOutputPath)) {
                # Download file to $OutputDir.
                Invoke-WebRequest $fileUrl -OutFile $fileOutputPath
                 # To ensure that the file got downloaded successfully, test and validate the file again after downloading and report any errors
                If(!(Test-Path -Path $fileOutputPath)){Throw "Download of $fileUrl to $fileOutputPath failed!"}
                Write-Verbose "Downloaded $fileName successfully from $fileUrl to $fileOutputPath"
            }
            else{
                Write-Warning "File $fileName already exists in $OutputDir"
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