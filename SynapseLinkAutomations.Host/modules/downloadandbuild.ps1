$repoUrl = "https://codeload.github.com/LeeKnight344/Synapse-Link-D365-Automations/zip/240a173126ef6965c523f5e996ed6a41e23528f2"
$zipPath = "$env:TEMP\repo.zip"
$destPath = "C:\SynapseAutomation"
Invoke-WebRequest -Uri $repoUrl -OutFile $zipPath
Expand-Archive -Path $zipPath -DestinationPath $destPath -Force
Set-Location "$destPath\Synapse-Link-D365-Automations-240a173126ef6965c523f5e996ed6a41e23528f2"
dotnet publish Synapse-Link-D365-Automations.sln
cd "c:\SynapseAutomation\Synapse-Link-D365-Automations-240a173126ef6965c523f5e996ed6a41e23528f2\SynapseLinkAutomations\bin\Release\net8.0"
