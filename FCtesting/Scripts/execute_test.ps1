param(
  [Parameter(Mandatory=$True)]
  [String]$fcname,
  [Parameter(Mandatory=$True)]
  [String]$username,
  [Parameter(Mandatory=$True)]
  [String]$password,
  [Parameter(Mandatory=$True)]
  [String]$fcArgs
) 
.\wget.ps1 https://raw.githubusercontent.com/qingfuwang/FCtesting/master/FCtesting/Scripts/fctesting.ps1
..\PsExec.exe \\$fcname  -i 1 -w C:\LinuxAgentPS -u $username -p $password cmd /c copy /Y C:\LinuxAgentPS\SvdGenerator.exe c:\fc
dir fctesting.ps1
net use \\$fcname /user:$username  $password 
copy /Y fctesting.ps1 \\$fcname\c$\LinuxAgentPS
copy /Y %WALA% \\$fcname\c$\LinuxAgentPS\jenkins_waagent
$time = Get-date -Format yyyy-MM-dd-HH-mm-ss
$logDir = "log_$time"
echo >start_fctesting.cmd powershell -file c:\linuxAgentPS\fctesting.ps1 $logDir $fcArgs
..\PsExec.exe \\$fcname  -i 1 -w C:\DeploymentScripts_FC123_withPdu -u $username -p $password -cf start_fctesting.cmd 

Copy-Item -Path \\$fcname\c$\LinuxAgentPS\lOG -Filter *.log -Destination . –Recurse
