#
# PsRevokeCerts.ps1
#


function Test-IsAdmin {
  ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")
}

function Revoke-Cert ([string] $certFile, [int] $askUser) {
  if (!(Test-Path (Join-Path Cert:\LocalMachine\Disallowed $info.Thumbprint))) {
    if ($askUser -eq 1) {
      $choise = Read-Host "[Y/N]"
      if ($choise -eq "Y") {
        $temp = Import-Certificate -FilePath $certFile -CertStoreLocation Cert:\LocalMachine\Disallowed
      }
    }
    else {
      $temp = Import-Certificate -FilePath $certFile -CertStoreLocation Cert:\LocalMachine\Disallowed
    }
  }
  else {
    Write-Host "This certificate is already revoked." -ForegroundColor Red
  }
}

Write-Host "   ___       __                 _          ___          _       " -ForegroundColor DarkGray
Write-Host "  / _ \___  /__\ _____   _____ | | _____  / __\___ _ __| |_ ___ " -ForegroundColor DarkGray
Write-Host " / /_)/ __|/ \/// _ \ \ / / _ \| |/ / _ \/ /  / _ | '__| __/ __|" -ForegroundColor DarkGray
Write-Host "/ ___/\__ / _  |  __/\ V | (_) |   |  __/ /__|  __| |  | |_\__ \" -ForegroundColor DarkGray
Write-Host "\/    |___\/ \_/\___| \_/ \___/|_|\_\___\____/\___|_|   \__|___/" -ForegroundColor DarkGray
Write-Host "An Powershell script to revoke CodeSigning certificates."
Write-Host "  TheCjw, https://github.com/TheCjw/PsRevokeCerts"

$certPath = Resolve-Path ".\Certificates\CodeSigning"

if (!(Test-Path $certPath)) {
  Write-Host "Please put this script in *\RevokeChinaCerts\Windows directory." -ForegroundColor Red
  Exit
}

# Show menu.
$message = "Make your choice:"

$optionRevoke = New-Object System.Management.Automation.Host.ChoiceDescription "Revoke &All", `
    "Revoke all CodeSigning certificates."

$optionChoise = New-Object System.Management.Automation.Host.ChoiceDescription "&Choice", `
    "Revoke CodeSigning certificates(Choice version)."

$optionRestore = New-Object System.Management.Automation.Host.ChoiceDescription "&Restore All", `
    "Restore all CodeSigning revoking."

$optionsExit = New-Object System.Management.Automation.Host.ChoiceDescription "&Exit", `
    "Just exit."

$options = [System.Management.Automation.Host.ChoiceDescription[]]($optionRevoke, $optionChoise, $optionRestore, $optionsExit)

$userChoice = $host.ui.PromptForChoice("", $message, $options, 0) 

if ($userChoice -eq 3) {
  Exit
}

$regex = [regex]'(?<=CN=).*?(?=,\s(OU|O|L|S|C)=)'

Get-ChildItem $certPath -Filter *.crt | ForEach-Object {
  $certFile = Join-Path $certPath $_
  $info = Get-PfxCertificate $certFile
  $commonName = $info.SubjectName.Name

  $result = $regex.Match($commonName)
  if ($result.Success) {
    $commonName = $result.Captures[0].value.Replace("`"", "")
  }

  Write-Host ("Processing {0}" -f $_) -ForegroundColor DarkGreen
  Write-Host "  Common Name: " $commonName -ForegroundColor DarkYellow
  Write-Host ("  Valid from {0} to {1}" -f $info.NotBefore, $info.NotAfter)
  Write-Host "  SerialNumber:" $info.SerialNumber
  Write-Host "  Thumbprint:" $info.Thumbprint

  switch ($userChoice) {
    0 { 
      Revoke-Cert $certFile 0
    }
    1 {
      Revoke-Cert $certFile 1
    }
    2 {
      if (Test-Path (Join-Path Cert:\LocalMachine\Disallowed $info.Thumbprint)) {
        Remove-Item (Join-Path Cert:\LocalMachine\Disallowed $info.Thumbprint)
      }
    }
  }
  Write-Host
}