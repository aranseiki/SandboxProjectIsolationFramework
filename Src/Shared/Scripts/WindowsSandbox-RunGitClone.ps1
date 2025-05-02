# 15. Definindo o caminho do repositório a partir da URL + caminho do projeto
Write-Output "Tratando o caminho do repositório."
$NomeRepo = $RepoUrl -split '/' | Select-Object -Last 1
$NomeRepo = $NomeRepo -replace '.git', ''

$RepoPath = "$ProjectPath/$NomeRepo"
Write-Output "Caminho do repositório: $RepoPath"
Copy-LogToLogPath -DefaultLogPath $DefaultLogPath -LogPath $LogPath

# 16. Removendo diretório de destino, se necessário
Write-Output "Verificando se o diretório de destino já existe."
Copy-LogToLogPath -DefaultLogPath $DefaultLogPath -LogPath $LogPath
if (Test-Path $RepoPath) {
    Write-Output "Removendo diretório existente: $RepoPath"
    Copy-LogToLogPath -DefaultLogPath $DefaultLogPath -LogPath $LogPath
    Remove-Item -Path $RepoPath -Recurse -Force -ErrorAction SilentlyContinue | Out-Null

    Write-Output "Aguardando o diretório do repositório ser removido..."
    Copy-LogToLogPath -DefaultLogPath $DefaultLogPath -LogPath $LogPath

    $WaitPathResult = Wait-Path -Path $RepoPath -TimeoutLimit 5 -Mode 'Exists'
    if (-not $WaitPathResult) {
        Write-Output "Erro: O diretório do repositório não foi removido."
        Copy-LogToLogPath -DefaultLogPath $DefaultLogPath -LogPath $LogPath

        exit 1
    }
}

# 17. Criando o diretório do repositório
Write-Output "Criando diretório do projeto..."
Copy-LogToLogPath -DefaultLogPath $DefaultLogPath -LogPath $LogPath
New-Item -Path $RepoPath -ItemType 'Directory' -Force -ErrorAction SilentlyContinue | Out-Null

# 18. Enquanto o caminho não existir ou 5 segundos aguardando
Write-Output "Aguardando o diretório do repositório ser criado..."
Copy-LogToLogPath -DefaultLogPath $DefaultLogPath -LogPath $LogPath
$Contagem = 0
$ContagemLimite = 10
while (
    (-not (Test-Path -Path $RepoPath))-and
    ($Contagem -lt $ContagemLimite)
) {
    Start-Sleep -Seconds 1
    $contagem = $Contagem + 1
    Write-Output "Tentativa $Contagem de $ContagemLimite."
    Copy-LogToLogPath -DefaultLogPath $DefaultLogPath -LogPath $LogPath
}

if ($Contagem -gt $ContagemLimite) {
    Write-Output "Erro: O diretório do repositório não foi criado."
    Copy-LogToLogPath -DefaultLogPath $DefaultLogPath -LogPath $LogPath

    exit 1
}

# 19. Tenta clonar o repositório com captura detalhada de erros
#   Se der erro por 5 vezes, para a execução logando o erro
Write-Output "Clonando o repositório."
Copy-LogToLogPath -DefaultLogPath $DefaultLogPath -LogPath $LogPath
$SaidaGitClone = git clone $RepoUrl $RepoPath 2>&1
if ($LASTEXITCODE -ne 0) {
    Write-Output $SaidaGitClone
    Write-Output "Abortando..."
    Copy-LogToLogPath -DefaultLogPath $DefaultLogPath -LogPath $LogPath

    exit 1
}
Write-Output "Repositório $RepoPath clonado com sucesso."
Copy-LogToLogPath -DefaultLogPath $DefaultLogPath -LogPath $LogPath
