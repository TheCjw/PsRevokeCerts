
. "$PSScriptRoot\libs\Utils.ps1"

Function Revoke-Certs {
    param (
        [Parameter(Mandatory = $true,
            ValueFromPipeline = $true)]
        [string]
        $Path
    )

    if (!(Test-Admin)) {
        Write-Host -ForegroundColor Red "Admin rights are required."
        return
    }

    if (!(Test-Path $Path)) {
        Write-Host -ForegroundColor Red "$($Path) is not exits."
        return
    }

    if (Test-Path $Path -PathType Container) {
        # Target path is directory
        Get-ChildItem $Path -Filter *.crt | ForEach-Object {
            Write-Host -ForegroundColor DarkGreen "Processing $($_.FullName)"
            $cert = Get-PfxCertificate $_.FullName
            Show-CertDetails $cert

            Import-CertFileToDisallowed $_.FullName
        }
    }
    else {
        Write-Host -ForegroundColor DarkGreen "Processing $($Path)"
        $cert = Get-PfxCertificate $path
        Show-CertDetails $cert

        Import-CertFileToDisallowed $Path
    }
}

Function Remove-RevokedCerts {
    param (
        [Parameter(Mandatory = $true,
            ValueFromPipeline = $true)]
        [string]
        $Keyword
    )

    if (!(Test-Admin)) {
        Write-Host -ForegroundColor Red "Admin rights are required."
        return
    }

    Get-ChildItem "Cert:\LocalMachine\Disallowed" | ForEach-Object {
        $cert = $_
        $commonName = Get-CommonNameFromCert $cert
        if ($commonName -match $Keyword) {
            Write-Host "Removing $($cert.Thumbprint), common name is $($commonName)"
            Remove-RevokedCertDisallowd $cert
        }
    }
}

Function Find-RevokedCerts {
    param (
        [Parameter(Mandatory = $true,
            ValueFromPipeline = $true)]
        [string]
        $Keyword
    )
    Get-ChildItem "Cert:\LocalMachine\Disallowed" | ForEach-Object {
        $cert = $_
        $commonName = Get-CommonNameFromCert $cert
        if ($commonName -match $Keyword) {
            Show-CertDetails $cert
        }
    }
}

Function Get-RevokedCerts {
    Get-ChildItem "Cert:\LocalMachine\Disallowed" | ForEach-Object {
        Show-CertDetails $_
    }
}

Function Export-CertFileFromPE {
    param (
        [Parameter(Mandatory = $true,
            ValueFromPipeline = $true)]
        [string]
        $FilePath,

        [string]
        $OutPath
    )

    if (!(Test-Path $FilePath -PathType Leaf)) {
        Write-Host -ForegroundColor Red "$($FilePath) is not exist."
        return
    }

    $result = Get-AuthenticodeSignature $FilePath
    if (!$result.SignerCertificate) {
        Write-Host -ForegroundColor Red "Get cert from $($FilePath) failed."
        return
    }

    $cert = $result.SignerCertificate

    Show-CertDetails $cert

    if (0 -eq $OutPath.Length) {
        $OutPath = "$($cert.Thumbprint).crt"
    }
    else {
        if (!(Test-Path $OutPath -PathType Container)) {
            Write-Host -ForegroundColor Red "$($OutPath) is not exist."
            return
        }

        $OutPath = [io.path]::combine($OutPath, "$($cert.Thumbprint).crt")
    }

    $tmp = Export-Certificate -Cert $cert -FilePath $OutPath
    Write-Host "Cert is saved to $($OutPath)"
}

$FunctionsToExport = @(
    "Revoke-Certs",
    "Remove-RevokedCerts",
    "Find-RevokedCerts",
    "Get-RevokedCerts",
    "Export-CertFileFromPE"
)

Export-ModuleMember -Function $FunctionsToExport
