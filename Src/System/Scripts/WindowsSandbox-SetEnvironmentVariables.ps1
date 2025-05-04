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
$DefaultTempPath = New-DefaultTempPath -DefaultTempPath "$ScriptRootPath/Output/Temp"
$DefaultLogPath = New-DefaultLogPath -DefaultLogPath "$ScriptRootPath/Output/Logs"

# 3. Definindo as variáveis de ambiente
Write-Output "Definindo os parâmetros das variáveis de ambiente."
foreach ($CurrentVariable in $PipelineConfiguration.Variables) {
    $EnvironmentVariableName = $CurrentVariable.Name
    $EnvironmentVariableValue = $CurrentVariable.Value
    $EnvironmentVariableType = $CurrentVariable.Type
    $EnvironmentVariableRequied = $CurrentVariable.Required

    if (-not $EnvironmentVariableName) {
        Write-Output "Erro: Nome de variável de ambiente não definido."
        New-TempErrorFile -Path $DefaultTempPath -ErrorFileName 'EnvironmentVariableName'
        Write-Output "Abortando..."

        exit 1
    }

    if (
        ('' -eq $EnvironmentVariableRequied) -or
        ($null -eq $EnvironmentVariableRequied) -or
        ($EnvironmentVariableRequied -isnot [bool])
    ) {
        Write-Output "Erro: Requerimento da variável de ambiente '$($EnvironmentVariableName)' não definido."
        New-TempErrorFile -Path $DefaultTempPath -ErrorFileName $EnvironmentVariableName
        Write-Output "Abortando..."

        exit 1
    }

    if ((-not $EnvironmentVariableValue) -and ($EnvironmentVariableRequied)) {
        Write-Output "Erro: Variável de ambiente '$($EnvironmentVariableName)' não definida mas é requirida."
        New-TempErrorFile -Path $DefaultTempPath -ErrorFileName $EnvironmentVariableName
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
        New-TempErrorFile -Path $DefaultTempPath -ErrorFileName $EnvironmentVariableName
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

    $EnvironmentVariableReturn = Set-EnvironmentVariable `
        -EnvironmentVariableName $EnvironmentVariableName `
        -EnvironmentVariableValue $EnvironmentVariableValue `
        -EnvironmentVariableType $EnvironmentVariableType

    Write-Output $EnvironmentVariableReturn.Message

    if ($EnvironmentVariableReturn.MessageType.ToUpper() -eq "ERROR") {
        New-TempErrorFile -Path $DefaultTempPath -ErrorFileName $EnvironmentVariableName

        exit 1
    }

    # Definindo a variável de ambiente no escopo global
    Write-Output "Definindo as variáveis de ambiente no escopo gloal."
    Set-Variable -Name $EnvironmentVariableName -Value $EnvironmentVariableValue -Scope Global
    Write-Output "Variável de ambiente '$($EnvironmentVariableName)' criada com sucesso."
}

# 4. Verificando diretório temporário para criar o diretório caso necessário
$TempPath = New-TempPath -TempPath $TempPath

# 5. Verificando diretório de log para criar o diretório caso necessário
Write-Output "Verificando se o diretório de log existe."
$LogPath = New-LogPath -LogPath $LogPath

# 6. Definindo o formato da data atual
Write-Output "Definindo o formato da data atual."
$DateFormat = $DefaultCurrentDateFormat
if ($CurrentDateFormat) {
    $DateFormat = $CurrentDateFormat
}

# 7. Criando o arquivo de log, inicializando o transcript com ele
$CurrentDate = Get-CurrentDate -CurrentDateFormat $DateFormat
$DefaultLogPath = "$ScriptRootPath/Output/Logs"
$PipelineLogName = "$ProjectName-SandboxLog_$($CurrentDate).txt"
$LogFile = "$DefaultLogPath/$PipelineLogName"

Start-Transcript -Path $LogFile -Append -Force
Write-Output "Iniciando transcript de log."

# 8. Aguardando o caminho de log ser criado
$WaitPathResult = Wait-Path -Path $LogPath -TimeoutLimit 5 -Mode 'Exists'
if (-not $WaitPathResult) {
    Write-Output "Erro: O diretório do repositório não foi criado."
    New-TempErrorFile -Path $LogPath -ErrorFileName "LogPathWait"

    exit 1
}

# 9. Copiando o arquivo de log para o diretório de log Host
Copy-LogToLogPath -DefaultLogPath $LogFile -LogPath $LogPath -AutoLog

# 10. Finalizando o transcript de log
Write-Output "Finalizando o transcript de log."
Copy-LogToLogPath -DefaultLogPath $LogFile -LogPath $LogPath
Stop-Transcript
