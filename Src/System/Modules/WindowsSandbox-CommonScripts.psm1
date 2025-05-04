# Função para copiar o Log, do caminho padrão para o caminho definido pelo usuário, se houver
function Copy-LogToLogPath {
    param (
        [string]$DefaultLogPath,
        [string]$LogPath,
        [switch]$AutoLog = $false
    )

    if ($LogPath) {
        if ($AutoLog) {
            Write-Output "Copiando arquivo de log para o Host: $LogPath."
        }

        Copy-Item -Path $DefaultLogPath -Destination $LogPath -Force | Out-Null
    }
}

# Função para coletar a data atual com formato definido pelo usuário
function Get-CurrentDate {
    param (
        $CurrentDateFormat
    )

    $CurrentDateName = 'CurrentDate'
    $CurrentDateType = [System.EnvironmentVariableTarget]::Machine

    $CurrentDateValue = (
        [System.Environment]::GetEnvironmentVariable(
            $CurrentDateName,
            $CurrentDateType
        )
    )
    
    if (-not $CurrentDateValue) {
        $CurrentDateValue = $(Get-Date -Format $CurrentDateFormat).ToString()

        [System.Environment]::SetEnvironmentVariable(
            $CurrentDateName,
            $CurrentDateValue,
            $CurrentDateType
        )
    }

    return $CurrentDateValue
}

function Get-PipelineConfiguration {
    param (
        [string] $ConfigurationFile,
        [string] $ConfigurationType
    )

    $ConfigurationRawContent = Get-Content -Path $ConfigurationFile -Raw

    $ConfigurationContent = switch ($ConfigurationType.ToUpper()) {
        'DEFAULT' { 
            $ConfigurationRawContent
        }
        'JSON' {
            $ConfigurationRawContent | ConvertFrom-Json
        }

        default {
            throw "Unknown configuration type: $ConfigurationType"
        }
    }

    return $ConfigurationContent
}

function New-DefaultLogPath {
    param (
        [string] $DefaultLogPath
    )

    if (-not (Test-Path $DefaultLogPath)) {
        New-Item -Path $DefaultLogPath -ItemType 'Directory' -Force | Out-Null
        Write-Output "Criando diretório de log temporário: $DefaultLogPath"
    }

    return $DefaultLogPath
}

function New-DefaultTempPath {
    param (
        [string] $DefaultTempPath
    )

    if (-not (Test-Path $DefaultTempPath)) {
        New-Item -Path $DefaultTempPath -ItemType 'Directory' -Force | Out-Null
        Write-Output "Criando diretório temporário: $DefaultTempPath"
    }

    return $DefaultTempPath
}

function New-LogPath {
    param (
        [string] $LogPath
    )

    if ($LogPath) {
        if (-not (Test-Path $LogPath)) {
            New-Item -Path $LogPath -ItemType 'Directory' -Force | Out-Null
        }
    }

    return $LogPath
}

function New-TempErrorFile {
    param (
        [string] $Path,
        [string] $ErrorFileName
    )

    if (-not (Test-Path -Path $Path)) {
        throw "The path needs to exist."
    }

    $ErrorFile = "$Path/$ErrorFileName.error"
    New-Item -Path $ErrorFile `
        -ItemType 'File' `
        -Force | Out-Null

    return $ErrorFile
}

function New-TempPath {
    param (
        [string] $TempPath
    )

    if ($TempPath) {
        if (-not (Test-Path $TempPath)) {
            New-Item -Path $TempPath -ItemType Directory -Force | Out-Null
        }
    }

    return $TempPath
}

function Set-EnvironmentVariable {
    param (
        [string] $EnvironmentVariableName,
        [string] $EnvironmentVariableValue,
        [System.EnvironmentVariableTarget] $EnvironmentVariableType
    )

    try {
        [System.Environment]::SetEnvironmentVariable(
            $EnvironmentVariableName,
            $EnvironmentVariableValue,
            $EnvironmentVariableType
        )
        $SetEnvironmentVariableResult = "Variável definida com sucesso."
        $SetEnvironmentVariableResultType = "OK"
    }
    catch {
        $SetEnvironmentVariableResult = "Erro ao definir variável: $($_.Exception.Message)"
        $SetEnvironmentVariableResultType = "ERROR"
    }
    
    return @{
        "Message" = $SetEnvironmentVariableResult
        "MessageType" = $SetEnvironmentVariableResultType
    }
}

function Wait-Path {
    param (
        [string] $Path,
        [int] $TimeoutLimit,
        [ValidateSet("Exists", "NotExists")]
        [string] $Mode
    )

    $PathExists = switch ($Mode.ToUpper()) {
        'EXISTS' { $true }
        'NOTEXISTS' { $false }
        Default {
            Throw "Modo de aguarde '$Mode' incorreto para caminho '$Path'."
        }
    }

    $TimeCount = 0
    while (
        ((Test-Path -Path $Path) -ne $PathExists) -and
        ($TimeCount -lt $TimeoutLimit)
    ) {
        Start-Sleep -Seconds 1
        $TimeCount = $TimeCount + 1

        if ((Test-Path -Path $Path) -eq $PathExists) {
            break
        }
    }

    $ReturnAction = $true
    if ($TimeCount -gt $TimeoutLimit) {
        $ReturnAction = $false
    }

    return $ReturnAction
}

Export-ModuleMember `
    -Function Copy-LogToLogPath,
        Get-CurrentDate,
        Get-PipelineConfiguration,
        New-DefaultLogPath,
        New-DefaultTempPath,
        New-LogPath,
        New-TempErrorFile,
        New-TempPath,
        Set-EnvironmentVariable,
        Wait-Path
