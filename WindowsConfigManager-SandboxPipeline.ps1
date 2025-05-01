# pipeline.ps1: Pipeline que instala Git, clona repositório e executa script

### PIPELINE IMPORTS ###
Import-Module -Name "$PSScriptRoot/scripts/System/Modules/WindowsSandbox-SandboxCommonScripts.psm1" -Force

### PIPELINE SCRIPT ###

# 2. Criando um diretório temporário para salvar arquivos do pipeline
$DefaultTempPath = New-DefaultTempPath -DefaultTempPath "C:/Temp"
$DefaultLogPath = New-DefaultLogPath -DefaultLogPath "$DefaultTempPath/Log"

# 3. Definindo as variáveis de ambiente
Write-Output "Definindo os parâmetros das variáveis de ambiente."
foreach ($VariavelAtual in $ConfiguracaoJSON.Variaveis) {
    $NomeVariavelAmbiente = $VariavelAtual.Nome
    $TipoVariavelAmbiente = $VariavelAtual.Tipo
    $VariavelRequerida = $VariavelAtual.Requerido

    if (-not $NomeVariavelAmbiente) {
        Write-Output "Erro: Nome de variável de ambiente não definido."
        New-Item -Path "$DefaultTempPath/NomeVariavelAmbiente.erro" -ItemType 'File' -Force | Out-Null
        Write-Output "Abortando..."

        exit 1
    }

    if ($TipoVariavelAmbiente.ToUpper() -eq 'MACHINE') {
        $TipoVariavelAmbiente = [System.EnvironmentVariableTarget]::Machine
    }
    elseif ($TipoVariavelAmbiente.ToUpper() -eq 'USER') {
        $TipoVariavelAmbiente = [System.EnvironmentVariableTarget]::User
    }
    elseif ($TipoVariavelAmbiente.ToUpper() -eq 'PROCESS') {
        $TipoVariavelAmbiente = [System.EnvironmentVariableTarget]::Process
    }
    else {
        Write-Output "Erro: Tipo de variável de ambiente para $($NomeVariavelAmbiente) inválido."
        New-Item -Path "$DefaultTempPath/$NomeVariavelAmbiente.erro" -ItemType 'File' -Force | Out-Null
        Write-Output "Abortando..."

        exit 1
    }

    if (
        ('' -eq $VariavelRequerida) -or
        ($null -eq $VariavelRequerida) -or
        ($VariavelRequerida -isnot [bool])
    ) {
        Write-Output "Erro: Requerimento da variável de ambiente '$($NomeVariavelAmbiente)' não definido."
        New-Item -Path "$DefaultTempPath/$NomeVariavelAmbiente.erro" -ItemType 'File' -Force | Out-Null
        Write-Output "Abortando..."

        exit 1
    }

    $ValorVariavelAmbiente = (
        [System.Environment]::GetEnvironmentVariable(
            $NomeVariavelAmbiente,
            $TipoVariavelAmbiente
        )
    )
    if ((-not $ValorVariavelAmbiente) -and ($VariavelRequerida)) {
        Write-Output "Erro: Variável de ambiente '$($NomeVariavelAmbiente)' não definida mas é requirida."
        New-Item -Path "$DefaultTempPath/$NomeVariavelAmbiente.erro" -ItemType 'File' -Force | Out-Null
        Write-Output "Abortando..."

        exit 1
    }

    if (
        ($NomeVariavelAmbiente.ToUpper() -eq 'TEMPPATH') -and
        (
            (-not $ValorVariavelAmbiente) -or
            ($ValorVariavelAmbiente -eq 'TEMPPATH')
        )
    ) {
        $ValorVariavelAmbiente = $null
    }

    if (
        ($NomeVariavelAmbiente.ToUpper() -eq 'LOGPATH') -and
        (
            (-not $ValorVariavelAmbiente) -or
            ($ValorVariavelAmbiente -eq 'LOGPATH')
        )
    ) {
        $ValorVariavelAmbiente = $null
    }

    if (
        ($NomeVariavelAmbiente.ToUpper() -eq 'CURRENTDATEFORMAT') -and
        (
            (-not $ValorVariavelAmbiente) -or
            ($ValorVariavelAmbiente.ToUpper() -eq 'CURRENTDATEFORMAT')
        )
    ) {
        $ValorVariavelAmbiente = $null
    }

    # Definindo a variável de ambiente no escopo global
    Write-Output "Definindo as variáveis de ambiente no escopo gloal."
    Set-Variable -Name $NomeVariavelAmbiente -Value $ValorVariavelAmbiente -Scope Global
    Write-Output "Variável de ambiente '$($NomeVariavelAmbiente)' criada com sucesso."
}

# 4. Verificando diretório temporário para criar o diretório caso necessário
Write-Output "Verificando se o diretório temporário existe."
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

# 5 Definindo o caminho do projeto a partir do diretório
#   temporário definido pelo usuário ou valor padrão
$ProjectPath = $DefaultTempPath
if ($TempPath) {
    $ProjectPath = $TempPath
}

& "$HostProjectPath\scripts\Shared\SandboxShared-InstallGit.ps1" `
    -ScriptRootPath $PSScriptRoot `
    -ProjectPath $ProjectPath `
    -DefaultLogPath $DefaultLogPath `
    -LogPath $LogPath

exit 0

# 5. Criando o arquivo de log, inicializando o transcript com ele
$CurrentDate = Get-CurrentDate -CurrentDateFormat $DateFormat
$PipelineLog = "$ProjectName-SandboxLog_$($CurrentDate).txt"
$LogFile = "$LogPath/$PipelineLog"

Start-Transcript -Path $LogFile -Append -Force
Write-Output "Iniciando transcript de log."

# 7. Copiando o arquivo de log para o diretório de log Host
Copy-LogToLogPath -DefaultLogPath $DefaultLogPath -LogPath $LogPath -AutoLog






# 23. Finalizando o transcript de log
# Write-Output "Finalizando o transcript de log."
# Copy-LogToLogPath -DefaultLogPath $DefaultLogPath -LogPath $LogPath
# Stop-Transcript
