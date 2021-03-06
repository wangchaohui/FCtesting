﻿param(
  $logDir,
  $linuxagentpath,
  $distroes,
  $password,
  $tests="linux_Certs_page.iso,PositiveTests"
)

 write-host "linuxagentpath  $linuxagentpath distro $distro "
cd C:\DeploymentScripts_FC123_withPdu

 $nodesinfo = .\StartFCClient.cmd nodes?;
 $str_nodesinfo=[System.String]::Join(";",$nodesinfo);
 $str_nodesinfo  -match '(?m).*(00000000-\S*).*'
 $nodeid=$Matches[1]
 $waitReady=100;

#$nodeid="00000000-0000-0000-0000-008cfa086314"
 $output = .\StartFCClient.cmd nodeip? /node:$nodeid
 $str_nodesip=[System.String]::Join(";", $output);
 $str_nodesip  -match '(?m).*'+$nodeid+' - (.*);; .*'
$nodeip=$Matches[1]

 while($waitReady-- -gt 0)
{
  .\StartFCClient.cmd deleteuseraccount:$nodeid /username:rdTestUser 
  .\StartFCClient.cmd createuseraccount:$nodeid /username:rdTestUser /password:$password /expiration:30000 
  net use /DELET \\$nodeip
  net use \\$nodeip /user:rdTestUser $password
  if ($LASTEXITCODE -eq 0) {break};
  sleep 30;
  write-host "$(date) Wait for $nodeid ready"
  
};

Set-Service RemoteAccess -StartupType Automatic;
Start-Service RemoteAccess;
sleep 5
write-host $(Get-Service RemoteAccess).Status;
cd $linuxagentpath

$tests.split(";")|%{ 
$test=$_.trim();
$distroes.split(";")|%{
$distro= $_.trim();
$testContent+= "$distro,$test,"+$distro.replace(".","")+"`r`n"
}
}

Set-Content -Value "OSBlobName,ISOBlobName,TestName,TenantName`r`n$testContent" .\temp_data.csv

Write-Host "logDir=$logDir"
.\RunTestsWithCSV.ps1 $logDir .\temp_data.csv 

