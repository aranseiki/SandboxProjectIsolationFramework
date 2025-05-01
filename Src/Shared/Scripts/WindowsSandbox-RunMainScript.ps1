# 20. Captura o nome do script de execução na raiz do repositório clonado
Write-Output "Capturando o nome do script de execução do projeto."
Copy-LogToLogPath -DefaultLogPath $DefaultLogPath -LogPath $LogPath
$CaminhoScript = Get-ChildItem -Path $RepoPath -Filter "*$($ProjectScriptPath)" | Select-Object -First 1 -ExpandProperty FullName

# 21. Verifica se o script foi encontrado
#    Se não for encontrado, para a execução do pipeline logando o erro
if (-not $CaminhoScript) {
    Write-Output "Nenhum script de execução encontrado no repositório."
    Copy-LogToLogPath -DefaultLogPath $DefaultLogPath -LogPath $LogPath

    exit 1
}
Write-Output "Script encontrado: $CaminhoScript"
Copy-LogToLogPath -DefaultLogPath $DefaultLogPath -LogPath $LogPath

# 22. Executando o script encontrado
Write-Output "Executando o script encontrado: $CaminhoScript"
Copy-LogToLogPath -DefaultLogPath $DefaultLogPath -LogPath $LogPath
try {
    $processoScript = Start-Process -FilePath "powershell.exe" -ArgumentList "-ExecutionPolicy Bypass -File `"$CaminhoScript`" $ArgumentScript" -PassThru

    if ($processoScript) {
        Write-Output "Script iniciado com sucesso (PID: $($processoScript.Id))."
        Copy-LogToLogPath -DefaultLogPath $DefaultLogPath -LogPath $LogPath
    } else {
        Write-Output "Falha ao iniciar o script — o processo não retornou objeto."
        Copy-LogToLogPath -DefaultLogPath $DefaultLogPath -LogPath $LogPath

        exit 1
    }
} catch {
    Write-Output "Erro ao iniciar o processo: $_"
    Copy-LogToLogPath -DefaultLogPath $DefaultLogPath -LogPath $LogPath

    exit 1
}