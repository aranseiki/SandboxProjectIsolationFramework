# pipeline.ps1: Pipeline que configura o ambiente do Windows Sandbox

param (
    [Parameter(Mandatory = $true, HelpMessage = "Caminho raiz do projeto onde deve conter os scripts de execução das funções internas.")]
    [string] $ScriptRootPath,
    
    [Parameter(Mandatory = $true, HelpMessage = "Configuração da Pipeline.")]
    [PSCustomObject] $PipelineConfiguration
)

### PIPELINE IMPORTS ###
Import-Module -Name "$ScriptRootPath/Src/System/Modules/WindowsSandbox-CommonScripts.psm1" `
    -Force `
    -ErrorAction Stop

### PIPELINE SCRIPT ###

# 1. Importando configurações de ambiente do arquivo .JSON
$DefaultProjectName = $PipelineConfiguration.MetaData.Name
$DefaultCurrentDateFormat = 'yyyyMMdd'

# 2. Criando um diretório temporário para salvar arquivos do pipeline
Write-Output "Verificando se o diretório temporário existe."
$DefaultTempPath = "$ScriptRootPath/Output/Temp"
if (-not (Test-Path $DefaultTempPath)) { 
    New-Item -Path $DefaultTempPath -ItemType 'Directory'
    Write-Output "Criando diretório temporário: $DefaultTempPath"
}

# 3. Definindo as variáveis de ambiente
Write-Output "Definindo os parâmetros das variáveis de ambiente."
foreach ($CurrentVariable in $PipelineConfiguration.Variables) {
    $EnvironmentVariableName = $CurrentVariable.Name
    $EnvironmentVariableValue = $CurrentVariable.Value
    $EnvironmentVariableType = $CurrentVariable.Type
    $EnvironmentVariableRequied = $CurrentVariable.Required

    if (-not $EnvironmentVariableName) {
        Write-Output "Erro: Nome de variável de ambiente não definido."
        New-Item -Path "$DefaultTempPath/EnvironmentVariableName.error" -ItemType 'File' -Force | Out-Null
        Write-Output "Abortando..."

        exit 1
    }

    if (
        ('' -eq $EnvironmentVariableRequied) -or
        ($null -eq $EnvironmentVariableRequied) -or
        ($EnvironmentVariableRequied -isnot [bool])
    ) {
        Write-Output "Erro: Requerimento da variável de ambiente '$($EnvironmentVariableName)' não definido."
        New-Item -Path "$DefaultTempPath/$EnvironmentVariableName.error" -ItemType 'File' -Force | Out-Null
        Write-Output "Abortando..."

        exit 1
    }

    if ((-not $EnvironmentVariableValue) -and ($EnvironmentVariableRequied)) {
        Write-Output "Erro: Variável de ambiente '$($EnvironmentVariableName)' não definida mas é requirida."
        New-Item -Path "$DefaultTempPath/$EnvironmentVariableName.error" -ItemType 'File' -Force | Out-Null
        Write-Output "Abortando..."

        exit 1
    }

    if ($EnvironmentVariableType.ToUpper() -eq 'MACHINE') {
        $EnvironmentVariableType = [System.EnvironmentVariableTarget]::Machine
    } elseif ($EnvironmentVariableType.ToUpper() -eq 'USER') {
        $EnvironmentVariableType = [System.EnvironmentVariableTarget]::User
    } elseif ($EnvironmentVariableType.ToUpper() -eq 'PROCESS') {
        $EnvironmentVariableType = [System.EnvironmentVariableTarget]::Process
    } else {
        Write-Output "Erro: Tipo de variável de ambiente para $($EnvironmentVariableName) inválido."
        New-Item -Path "$DefaultTempPath/$EnvironmentVariableName.error" -ItemType 'File' -Force | Out-Null
        Write-Output "Abortando..."

        exit 1
    }

    if (
        ($EnvironmentVariableName.ToUpper() -eq 'TEMPPATH') -and
        (
            (-not $EnvironmentVariableValue) -or
            ($EnvironmentVariableValue.ToUpper() -eq 'TEMPPATH')
        )
    ) {
        $EnvironmentVariableValue = $null
    }

    if (
        ($EnvironmentVariableName.ToUpper() -eq 'LOGPATH') -and
        (
            (-not $EnvironmentVariableValue) -or
            ($EnvironmentVariableValue.ToUpper() -eq 'LOGPATH')
        )
    ) {
        $EnvironmentVariableValue = $null
    }

    if (
        ($EnvironmentVariableName.ToUpper() -eq 'CURRENTDATEFORMAT') -and
        (
            (-not $EnvironmentVariableValue) -or
            ($EnvironmentVariableValue.ToUpper() -eq 'CURRENTDATEFORMAT')
        )
    ) {
        $EnvironmentVariableValue = $null
    }

    if (
        ($EnvironmentVariableName.ToUpper() -eq 'PROJECTNAME') -and
        ($EnvironmentVariableValue.ToUpper() -eq 'PROJECTNAME')
    ) {
        $EnvironmentVariableValue = $DefaultProjectName
    }

    [System.Environment]::SetEnvironmentVariable(
        $EnvironmentVariableName,
        $EnvironmentVariableValue,
        $EnvironmentVariableType
    )

    # Definindo a variável de ambiente no escopo global
    Write-Output "Definindo as variáveis de ambiente no escopo gloal."
    Set-Variable -Name $EnvironmentVariableName -Value $EnvironmentVariableValue -Scope Global
    Write-Output "Variável de ambiente '$($EnvironmentVariableName)' criada com sucesso."
}

# 4. Verificando diretório temporário para criar o diretório caso necessário
Write-Output "Verificando se o diretório temporário existe."
if ($TempPath) {
    if (-not (Test-Path $TempPath)) {
        New-Item -Path $TempPath -ItemType Directory
        Write-Output "Criando diretório temporário: $TempPath"
    }
}

# 5. Verificando diretório de log para criar o diretório caso necessário
Write-Output "Verificando se o diretório de log existe."
if ($LogPath) {
    if (-not (Test-Path $LogPath)) {
        New-Item -Path $LogPath -ItemType Directory
        Write-Output "Criando diretório de log: $LogPath"
    }
}

# 6. Definindo o formato da data atual
Write-Output "Definindo o formato da data atual."
$DateFormat = $DefaultCurrentDateFormat
if ($CurrentDateFormat) {
    $DateFormat = $CurrentDateFormat
}

# 7. Criando o arquivo de log, inicializando o transcript com ele
$CurrentDate = Get-CurrentDate -CurrentDateFormat $DateFormat
$PipelineLog = "$ProjectName-SandboxLog_$($CurrentDate).txt"
$DefaultLogPath = "$ScriptRootPath/Output/Logs"
$LogFile = "$DefaultLogPath/$PipelineLog"

Start-Transcript -Path $LogFile -Append -Force
Write-Output "Iniciando transcript de log."

# 8. Copiando o arquivo de log para o diretório de log Host
Copy-LogToLogPath -DefaultLogPath $DefaultLogPath -LogPath $LogPath -AutoLog

# 9. Finalizando o transcript de log
Write-Output "Finalizando o transcript de log."
Copy-LogToLogPath -DefaultLogPath $DefaultLogPath -LogPath $LogPath
Stop-Transcript
