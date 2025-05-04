function Get-GitReleaseVersionURL {
    param (
        [string] $GitApiUrl = "https://api.github.com/repos/git-for-windows/git/releases/latest",
        [hashtable] $GitApiHeader = @{ "User-Agent" = "WindowsSandbox" },
        [string] $FilterName = "*64-bit.exe",
        [string] $GetURLProperty = "browser_download_url"
    )

    $GitReleaseInfo = Invoke-RestMethod -Uri $GitApiUrl -Headers $GitApiHeader
    $InstallerURL = $GitReleaseInfo.assets `
        | Where-Object { $_.name -like $FilterName } `
        | Select-Object -First 1 -ExpandProperty $GetURLProperty

    return $InstallerURL
}

function Get-GitRepositoryName {
    param (
        [string] $GitRepositoryUrl
    )

    $RepositoryName = $GitRepositoryUrl -split '/' | Select-Object -Last 1
    $RepositoryName = $RepositoryName -replace '.git', ''

    return $RepositoryName
}

Export-ModuleMember `
    -Function Get-GitReleaseVersionURL, `
        Get-GitRepositoryName
