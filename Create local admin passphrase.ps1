# Force TLS 1.2 for secure HTTPS connections
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

# Define the local path for the dictionary file.
$localDictionaryFile = "./english.txt"

# Download the dictionary file using the provided raw URL if it doesn't already exist locally.
if (-not (Test-Path $localDictionaryFile)) {
    try {
        Write-Host "Downloading dictionary file..."
        Invoke-WebRequest "https://raw.githubusercontent.com/jaydienGH/capwgen/refs/heads/main/english.txt?token=GHSAT0AAAAAADAEK355LHRBLUFTHUDPDCHQZ6LHFZA" -OutFile $localDictionaryFile -ErrorAction Stop
        Write-Host "Dictionary downloaded successfully."
    }
    catch {
        throw "Failed to download dictionary file. Exception: $($_.Exception.Message)"
    }
}

function Generate-ClientAdminPassword {
    param(
        [string]$DictionaryFile = "./english.txt"
    )
    
    try {
        # Read the contents of the dictionary file.
        $dictionaryContent = Get-Content -Path $DictionaryFile -ErrorAction Stop
    }
    catch {
        throw "Failed to read dictionary file from $DictionaryFile. Exception: $($_.Exception.Message)"
    }
    
    # Process the file: trim each line and remove empty lines.
    $words = $dictionaryContent | ForEach-Object { $_.Trim() } | Where-Object { $_ -ne "" }
    
    if ($words.Count -lt 3) {
        throw "The dictionary must contain at least three words."
    }
    
    # Select three random words.
    $selectedWords = $words | Get-Random -Count 3

    # Apply mild complexity:
    # 1. Capitalize the first letter of the first word.
    $selectedWords[0] = $selectedWords[0].Substring(0,1).ToUpper() + $selectedWords[0].Substring(1)
    
    # 2. Append a random special character to the end of the third word.
    $specialChars = "!@#$%^&*()-_=+[]{}|;:,.<>?/"
    $specialChar = ($specialChars.ToCharArray() | Get-Random)
    $selectedWords[2] = $selectedWords[2] + $specialChar

    # Combine the words with hyphens.
    $password = $selectedWords -join "-"

    # Append 2 random digits at the end.
    $digit1 = Get-Random -Minimum 0 -Maximum 10
    $digit2 = Get-Random -Minimum 0 -Maximum 10
    $password += "$digit1$digit2"

    return $password
}

try {
    $username = "clientadmin"
    
    # Generate the new password using the local dictionary file.
    $newPassword = Generate-ClientAdminPassword -DictionaryFile $localDictionaryFile
    
    # Convert the plain text password to a secure string.
    $securePassword = ConvertTo-SecureString $newPassword -AsPlainText -Force
    
    # If the user exists, reset the password; otherwise, create the account.
    if (Get-LocalUser -Name $username -ErrorAction SilentlyContinue) {
        Set-LocalUser -Name $username -Password $securePassword
    }
    else {
        New-LocalUser -Name $username -Password $securePassword -FullName "Client Admin" -Description "Created by automated script."
    }
    
    # Add the account to the local Administrators group, suppressing error output.
    Add-LocalGroupMember -Group "Administrators" -Member $username -ErrorAction SilentlyContinue
    
   
}
catch {
    Write-Error "An error occurred: $_"
}
 # Output the new password for further use.
    Write-Output $newPassword