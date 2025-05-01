### PIPELINE IMPORTS ###

$ScriptRootPath = $PSScriptRoot
# $ScriptRootPath = "E:\projects\users\aranseiki\SandboxProjectIsolationFramework\WindowsConfigManager"

Import-Module `
    -Name "$ScriptRootPath/Src/System/Modules/WindowsSandbox-CommonScripts.psm1" `
    -Force

# 1. Importando configurações de ambiente do arquivo .JSON
$PipelineConfiguration = Get-PipelineConfiguration `
    -ConfigurationFile $("$ScriptRootPath/Config/System/WindowsSandbox-PipelineConfig.json") `
    -ConfigurationType 'JSON'

& "$ScriptRootPath/Src/System/Scripts/WindowsSandbox-SetEnvironmentVariables.ps1" `
    -ScriptRootPath $ScriptRootPath `
    -PipelineConfiguration $PipelineConfiguration

# & "$ScriptRootPath/WindowsConfigManager-SandboxPipeline" `
#     -ScriptRootPath $ScriptRootPath `
#     -PipelineConfiguration $PipelineConfiguration
