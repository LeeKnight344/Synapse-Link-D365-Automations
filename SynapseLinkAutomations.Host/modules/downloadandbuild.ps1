# Download and extract the repo  (messy I know :(  ))
$repoUrl = "https://codeload.github.com/LeeKnight344/Synapse-Link-D365-Automations/zip/refs/heads/main"
$zipPath = "$env:TEMP\repo.zip"
$destPath = "C:\SynapseAutomation"
$webRoot = "C:\inetpub\wwwroot"
Invoke-WebRequest -Uri $repoUrl -OutFile $zipPath
Expand-Archive -Path $zipPath -DestinationPath $destPath -Force
$repoRoot = "$destPath\Synapse-Link-D365-Automations-main"
Set-Location $repoRoot
$publishPath = "$destPath\publish"
dotnet publish Synapse-Link-D365-Automations.sln -c Release -o $publishPath