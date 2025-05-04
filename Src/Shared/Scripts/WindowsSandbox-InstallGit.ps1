param (
    [Parameter(Mandatory = $true, HelpMessage = "Caminho raiz do projeto onde deve conter os scripts de execução das funções internas.")]
    [string] $ScriptRootPath,
    
    [Parameter(Mandatory = $true, HelpMessage = "Caminho raiz do projeto onde será realizado todo o processo.")]
    [string] $ProjectPath
)

Import-Module "$ScriptRootPath/Src/System/Modules/WindowsSandbox-CommonScripts.psm1"
Import-Module "$ScriptRootPath/Src/System/Modules/WindowsSandbox-BinaryHandling.psm1"
Import-Module "$ScriptRootPath/Src/Shared/Modules/WindowsSandbox-GitModule.psm1"

###

# 8. Obtendo a URL da última versão do Git via API do GitHub
Write-Output "Definindo a última versão do Git."
$InstallerURL = Get-GitReleaseVersionURL

# 9. Definindo o Caminho completo do instalador
$InstallerPath = "$ScriptRootPath/Output/Programs"
# 5. Verificando diretório de instalação para criar o diretório caso necessário
Write-Output "Verificando se o diretório do instalador existe."

New-InstallerPath -InstallerPath $InstallerPath
Write-Output "Caminho do instalador: $InstallerPath."

# 10. Baixando o instalador do Git
Write-Output "Definindo o caminho do instalador Git"
$InstallerFile = "$InstallerPath/GitInstaller.exe"

Write-Output "Baixando o Git mais recente..."
Receive-Installer -InstallerURL $InstallerURL -InstallerPath $InstallerFile

# 11. Instalando o Git em modo silencioso
Write-Output "Instalando o Git..."
Invoke-Executable -ExecutableFile $InstallerFile -ArgumentList @("/VERYSILENT") -Wait:$true

# 12. Adicionando Git ao PATH e verificando instalação
Write-Output "Adicionando Git ao PATH."
$env:Path += ";$env:ProgramFiles\Git\bin;$env:ProgramFiles\Git\cmd"
$env:ProgramFiles
# 13. Vefificando se o git foi instalado corretamente
#    Se não estiver no PATH, para a execução do pipeline logando o erro
try {
    $GitVersion = & git --version | Out-String
    Write-Output "Versão do git: $GitVersion"
}
catch {
    Write-Output "Erro: Git não foi instalado corretamente ou não está no PATH."

    exit 1
}
