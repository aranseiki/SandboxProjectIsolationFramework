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

function New-LogPath {
    param (
        [string] $LogPath
    )

    if ($LogPath) {
        if (-not (Test-Path $LogPath)) {
            New-Item -Path $LogPath -ItemType Directory
            Write-Output "Criando diretório de log: $LogPath"
        }
    }

    return $LogPath
}

function New-TempPath {
    param (
        [string] $TempPath
    )

    if ($TempPath) {
        if (-not (Test-Path $TempPath)) {
            New-Item -Path $TempPath -ItemType Directory
            Write-Output "Criando diretório temporário: $TempPath"
        }
    }

    return $TempPath
}

Export-ModuleMember `
    -Function Copy-LogToLogPath,
        Get-CurrentDate,
        Get-PipelineConfiguration,
        New-DefaultLogPath,
        New-DefaultTempPath,
        New-LogPath,
        New-TempPath
