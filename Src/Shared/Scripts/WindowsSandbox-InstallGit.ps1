param (
    [Parameter(Mandatory = $true, HelpMessage = "Caminho raiz do projeto onde deve conter os scripts de execução das funções internas.")]
    [string] $ScriptRootPath,
    
    [Parameter(Mandatory = $true, HelpMessage = "Caminho raiz do projeto onde será realizado todo o processo.")]
    [string] $ProjectPath,

    [Parameter(Mandatory = $true, HelpMessage = "Caminho padrão para a gravação de logs gerados.")]
    [string] $DefaultLogPath,
    
    [Parameter(Mandatory = $false, HelpMessage = "Caminho para a cópia de logs gerados no caminho padrão.")]
    [string] $LogPath = $null
)

Import-Module "$ScriptRootPath/scripts/System/Modules/WindowsSandbox-SandboxCommonScripts.psm1"
Import-Module "$ScriptRootPath/scripts/System/Modules/WindowsSandbox-BinaryHandling.psm1"
Import-Module "$ScriptRootPath/scripts/Shared/Modules/WindowsSandbox-GitModule.psm1"

###

New-DefaultLogPath -DefaultLogPath $DefaultLogPath
New-LogPath -LogPath $LogPath

# 8. Obtendo a URL da última versão do Git via API do GitHub
Write-Output "Definindo a última versão do Git."
Copy-LogToLogPath -DefaultLogPath $DefaultLogPath -LogPath $LogPath
$URLInstalador = Get-GitReleaseVersionURL

# 9. Definindo o Caminho completo do instalador
$InstallerPath = "$ScriptRootPath/Output/Programs"
# 5. Verificando diretório de instalação para criar o diretório caso necessário
Write-Output "Verificando se o diretório do instalador existe."
Copy-LogToLogPath -DefaultLogPath $DefaultLogPath -LogPath $LogPath
New-InstallerPath -InstallerPath $InstallerPath

Write-Output "Caminho do instalador: $InstallerPath."
Copy-LogToLogPath -DefaultLogPath $DefaultLogPath -LogPath $LogPath

# 10. Baixando o instalador do Git
Write-Output "Baixando o Git mais recente..."
$InstallerFile = "$InstallerPath/GitInstaller.exe"
Copy-LogToLogPath -DefaultLogPath $DefaultLogPath -LogPath $LogPath
Receive-Installer -InstallerURL $URLInstalador -InstallerPath $InstallerFile

# 11. Instalando o Git em modo silencioso
Write-Output "Instalando o Git..."
Copy-LogToLogPath -DefaultLogPath $DefaultLogPath -LogPath $LogPath

Invoke-Executable -ExecutableFile $InstallerFile -ArgumentList @("/VERYSILENT") -Wait:$true

# 12. Adicionando Git ao PATH e verificando instalação
Write-Output "Adicionando Git ao PATH."
Copy-LogToLogPath -DefaultLogPath $DefaultLogPath -LogPath $LogPath
$env:Path += ";$env:ProgramFiles\Git\bin;$env:ProgramFiles\Git\cmd"
$env:ProgramFiles
# 13. Vefificando se o git foi instalado corretamente
#    Se não estiver no PATH, para a execução do pipeline logando o erro
try {
    $GitVersion = & git --version | Out-String
    Write-Output "Versão do git: $GitVersion"
    Copy-LogToLogPath -DefaultLogPath $DefaultLogPath -LogPath $LogPath
}
catch {
    Write-Output "Erro: Git não foi instalado corretamente ou não está no PATH."
    Copy-LogToLogPath -DefaultLogPath $DefaultLogPath -LogPath $LogPath

    exit 1
}
