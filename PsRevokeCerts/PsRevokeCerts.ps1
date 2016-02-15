#
# PsRevokeCerts.ps1
#


function Test-IsAdmin {
  ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")
}

if (!(Test-IsAdmin)) {
  Write-Host "Please run this script with admin priviliges" -ForegroundColor Red
  Exit
}

$regex = [regex]'(?<=CN=).*?(?=,\s(OU|O|L|S|C)=)'

$currentPath = Get-Location

$certPath = Join-Path $currentPath "\Certificates\CodeSigning"
$certFiles = Get-ChildItem $certPath -Filter *.crt

Get-ChildItem $certPath -Filter *.crt | ForEach-Object {
  $certFile = Join-Path $certPath $_
  $info = Get-PfxCertificate $certFile
  $commonName = $info.SubjectName.Name

  $result = $regex.Match($commonName)
  if ($result.Success) {
    $commonName = $result.Captures[0].value.Replace("`"", "")
  }

  if (-Not (Test-Path (Join-Path Cert:\LocalMachine\Disallowed $info.Thumbprint))) {
    Write-Host "Revoke" $commonName -ForegroundColor DarkYellow
    Write-Host "  Valid from" $info.NotBefore "to" $info.NotAfter
    Write-Host "  SerialNumber:" $info.SerialNumber
    Write-Host "  Thumbprint:" $info.Thumbprint
    $choise = Read-Host "[Y/N]"
    if ($choise -eq "Y") {
      $result = Import-Certificate -FilePath $certFile -CertStoreLocation Cert:\LocalMachine\Disallowed
    }
  }
}