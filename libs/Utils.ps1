#
Function Test-Admin {
    # https://serverfault.com/questions/95431/in-a-powershell-script-how-can-i-check-if-im-running-with-administrator-privil
    $currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
    return $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

Function Get-CommonNameFromCert($cert) {
    $regex = [regex]'(?<=CN=).*?(?=,\s(OU|O|L|S|C)=)'
    $commonName = $cert.SubjectName.Name
    $result = $regex.Match($commonName)
    if ($result.Success) {
        $commonName = $result.Captures[0].value.Replace("`"", "")
    }
    return $commonName
}

Function Show-CertDetails($cert) {

    $commonName = Get-CommonNameFromCert $cert
    Write-Host "Thumbprint: $($cert.Thumbprint)" -ForegroundColor DarkGreen
    Write-Host "  Common Name: $($commonName)"
    Write-Host "  Valid from $($cert.NotBefore) to $($cert.NotAfter)"
    Write-Host "  SerialNumber: $($cert.SerialNumber)"
}

Function Import-CertFileToDisallowed($filePath) {
    $tmp = Import-Certificate -FilePath $filePath -CertStoreLocation "Cert:\LocalMachine\Disallowed"
}

Function Remove-RevokedCertDisallowd($cert) {
    Remove-Item (Join-Path "Cert:\LocalMachine\Disallowed" $cert.Thumbprint)
}
