#
# PsRevokeCerts.ps1
#

Write-Host -ForegroundColor DarkGray "   ___       __                 _          ___          _       "
Write-Host -ForegroundColor DarkGray "  / _ \___  /__\ _____   _____ | | _____  / __\___ _ __| |_ ___ "
Write-Host -ForegroundColor DarkGray " / /_)/ __|/ \/// _ \ \ / / _ \| |/ / _ \/ /  / _ | '__| __/ __|"
Write-Host -ForegroundColor DarkGray "/ ___/\__ / _  |  __/\ V | (_) |   |  __/ /__|  __| |  | |_\__ \"
Write-Host -ForegroundColor DarkGray "\/    |___\/ \_/\___| \_/ \___/|_|\_\___\____/\___|_|   \__|___/"
Write-Host -ForegroundColor DarkGray "An Powershell script to revoke CodeSigning certificates."
Write-Host -ForegroundColor DarkGray "  TheCjw, https://github.com/TheCjw/PsRevokeCerts"
Write-Host

# https://serverfault.com/questions/95431/in-a-powershell-script-how-can-i-check-if-im-running-with-administrator-privil
$currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())

if ($currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator) -eq $False) {
  Write-Host -ForegroundColor Red "Please run this script as admin."
  Exit
}

$certsDirectory = [io.path]::combine($PSScriptRoot, ".\RevokeChinaCerts\Windows\Certificates\CodeSigning")

if ((Test-Path $certsDirectory) -eq $False) {
  Write-Host -ForegroundColor Red "RevokeChinaCerts directory is not exists, run `git submodule update --init ` first."
  Exit
}

# Show menu.
$message = "Make your choice:"

$optionRevoke = New-Object System.Management.Automation.Host.ChoiceDescription "Revoke &All", `
    "Revoke all CodeSigning certificates."

$optionRestore = New-Object System.Management.Automation.Host.ChoiceDescription "&Restore All", `
    "Restore all CodeSigning revoking."

$optionsExit = New-Object System.Management.Automation.Host.ChoiceDescription "&Exit", `
    "Just exit."

$options = [System.Management.Automation.Host.ChoiceDescription[]]($optionRevoke, $optionRestore, $optionsExit)

$userChoice = $host.ui.PromptForChoice("", $message, $options, 0) 

if ($userChoice -eq 3) {
  Exit
}

$regex = [regex]'(?<=CN=).*?(?=,\s(OU|O|L|S|C)=)'

Get-ChildItem $certsDirectory -Filter *.crt | ForEach-Object {
  $certFilePath = $_.FullName
  $info = Get-PfxCertificate $certFilePath
  $commonName = $info.SubjectName.Name

  $result = $regex.Match($commonName)
  if ($result.Success) {
    $commonName = $result.Captures[0].value.Replace("`"", "")
  }

  Write-Host -ForegroundColor DarkGreen "Processing $($_.BaseName)"
  Write-Host -ForegroundColor DarkYellow "  Common Name: $($commonName)" 
  Write-Host "  Valid from $($info.NotBefore) to $($info.NotAfter)"
  Write-Host "  SerialNumber: $($info.SerialNumber)" 
  Write-Host "  Thumbprint: $($info.Thumbprint)"

  switch ($userChoice) {
    0 { 
      $temp = Import-Certificate -FilePath $certFilePath -CertStoreLocation Cert:\LocalMachine\Disallowed
    }
    1 {
      if (Test-Path (Join-Path Cert:\LocalMachine\Disallowed $info.Thumbprint)) {
        Remove-Item (Join-Path Cert:\LocalMachine\Disallowed $info.Thumbprint)
      }
    }
  }
  Write-Host
}