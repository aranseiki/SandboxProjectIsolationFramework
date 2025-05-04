param (
    [Parameter(Mandatory = $true, HelpMessage = "Caminho raiz do projeto onde deve conter os scripts de execução das funções internas.")]
    [string] $ScriptRootPath,
    
    [Parameter(Mandatory = $true, HelpMessage = "Caminho raiz do projeto onde será realizado todo o processo.")]
    [string] $ProjectPath,
    
    [Parameter(Mandatory = $true, HelpMessage = "URL de clone para o projeto no git.")]
    [PSCustomObject] $GitRepositoryUrl,

    [Parameter(Mandatory = $false, HelpMessage = "Filtro para localizar o arquivo para execução.")]
    [PSCustomObject] $ProjectFileFilter,

    [Parameter(Mandatory = $false, HelpMessage = "URL de clone para o projeto no git.")]
    [PSCustomObject] $ArgumentScript = $null
)

### PIPELINE IMPORTS ###

Import-Module -Name "$ScriptRootPath/Src/System/Modules/WindowsSandbox-CommonScripts.psm1" `
    -Force `
    -ErrorAction Stop

Import-Module -Name "$ScriptRootPath/Src/Shared/Modules/WindowsSandbox-GitModule.psm1" `
    -Force `
    -ErrorAction Stop

### PIPELINE SCRIPT ###

$RepositoryName = Get-GitRepositoryName -GitRepositoryUrl $GitRepositoryUrl

$RepositoryPath = "$ProjectPath/$RepositoryName"

Write-Output "Caminho do repositório: $RepositoryPath"

# 20. Captura o nome do script de execução na raiz do repositório clonado
Write-Output "Capturando o nome do script de execução do projeto."
$CaminhoScript = Get-ChildItem -Path $RepositoryPath -Filter "*$($ProjectFileFilter)" | Select-Object -First 1 -ExpandProperty 'FullName'

# 21. Verifica se o script foi encontrado
#    Se não for encontrado, para a execução do pipeline logando o erro
if (-not $CaminhoScript) {
    Write-Output "Nenhum script de execução encontrado no repositório."

    exit 1
}
Write-Output "Script encontrado: $CaminhoScript"

# 22. Executando o script encontrado
Write-Output "Executando o script encontrado: $CaminhoScript"
try {
    $processoScript = Start-Process -FilePath "powershell.exe" -ArgumentList "-ExecutionPolicy Bypass -File `"$CaminhoScript`" $ArgumentScript" -PassThru

    if ($processoScript) {
        Write-Output "Script iniciado com sucesso PID: $($processoScript.Id)."
    } else {
        Write-Output 'Falha ao iniciar o script — o processo não retornou objeto.'

        exit 1
    }
} catch {
    Write-Output "Erro ao iniciar o processo: $_"

    exit 1
}
