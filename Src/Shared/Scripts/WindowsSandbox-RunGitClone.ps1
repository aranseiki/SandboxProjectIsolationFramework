param (
    [Parameter(Mandatory = $true, HelpMessage = "Caminho raiz do projeto onde deve conter os scripts de execução das funções internas.")]
    [string] $ScriptRootPath,
    
    [Parameter(Mandatory = $true, HelpMessage = "Caminho onde será clonado o projeto.")]
    [PSCustomObject] $ProjectPath,

    [Parameter(Mandatory = $true, HelpMessage = "URL de clone para o projeto no git.")]
    [PSCustomObject] $GitRepositoryUrl
)

### PIPELINE IMPORTS ###
Import-Module -Name "$ScriptRootPath/Src/System/Modules/WindowsSandbox-CommonScripts.psm1" `
    -Force `
    -ErrorAction Stop

Import-Module -Name "$ScriptRootPath/Src/Shared/Modules/WindowsSandbox-GitModule.psm1" `
    -Force `
    -ErrorAction Stop

### PIPELINE SCRIPT ###

# 15. Definindo o caminho do repositório a partir da URL + caminho do projeto
Write-Output "Tratando o caminho do repositório."

$RepositoryName = Get-GitRepositoryName -GitRepositoryUrl $GitRepositoryUrl

$RepositoryPath = "$ProjectPath/$RepositoryName"

Write-Output "Caminho do repositório: $RepositoryPath"

# 16. Removendo diretório de destino, se necessário
Write-Output "Verificando se o diretório de destino já existe."
if (Test-Path $RepositoryPath) {
    Write-Output "Removendo diretório existente: $RepositoryPath"
    Remove-Item -Path $RepositoryPath -Recurse -Force -ErrorAction SilentlyContinue | Out-Null

    Write-Output "Aguardando o diretório do repositório ser removido..."
    $WaitPathResult = Wait-Path -Path $RepositoryPath -TimeoutLimit 5 -Mode 'NotExists'
    if (-not $WaitPathResult) {
        Write-Output "Erro: O diretório do repositório não foi removido."
        New-TempErrorFile -Path $LogPath -ErrorFileName "RepositoryPathWaitNotExists"
    
        exit 1
    }
}

# 17. Criando o diretório do repositório
Write-Output "Criando diretório do projeto..."
New-Item -Path $RepositoryPath -ItemType 'Directory' -Force -ErrorAction SilentlyContinue | Out-Null

# 18. Enquanto o caminho não existir ou 5 segundos aguardando
Write-Output "Aguardando o diretório do repositório ser criado..."
$WaitPathResult = Wait-Path -Path $RepositoryPath -TimeoutLimit 5 -Mode 'Exists'
if (-not $WaitPathResult) {
    Write-Output "Erro: O diretório do repositório não foi criado."
    New-TempErrorFile -Path $LogPath -ErrorFileName "RepositoryPathWaitExists"

    exit 1
}

# 19. Tenta clonar o repositório com captura detalhada de erros
#   Se der erro por 5 vezes, para a execução logando o erro
Write-Output "Clonando o repositório."
$SaidaGitClone = git clone $GitRepositoryUrl $RepositoryPath 2>&1
if ($LASTEXITCODE -ne 0) {
    Write-Output $SaidaGitClone
    Write-Output "Abortando..."

    exit 1
}

Write-Output "Repositório $RepositoryPath clonado com sucesso."
