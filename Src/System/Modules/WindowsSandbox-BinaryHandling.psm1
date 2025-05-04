function Invoke-Executable {
    param (
        [string] $ExecutableFile,
        [array] $ArgumentList,
        [bool] $Wait = $true
    )
    Start-Process -FilePath $ExecutableFile -ArgumentList $ArgumentList -Wait:$Wait
}

function New-InstallerPath {
    param (
        [string] $InstallerPath
    )

    if (-not (Test-Path $InstallerPath)) {
        New-Item -Path $InstallerPath -ItemType Directory  -Force | Out-Null
        Write-Output "Criando diretório de log: $InstallerPath"
        
        return $true
    }

    return $false
}

function Receive-Installer {
    param (
        [string] $InstallerURL,
        [string] $InstallerPath,
        [bool] $UseBasicParsing = $false,
        [System.Collections.IDictionary] $Headers = @{ "User-Agent" = "WindowsSandbox" }
    )

    try {
        Invoke-WebRequest -Uri $InstallerURL -OutFile $InstallerPath -UseBasicParsing:$UseBasicParsing -Headers $Headers

        return $true
    } catch {
        return $false
    }
}

Export-ModuleMember `
    -Function Invoke-Executable, `
        New-InstallerPath, `
        Receive-Installer
