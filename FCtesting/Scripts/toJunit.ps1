﻿Param(
  [Parameter(Mandatory=$True)]
  [string]$filename,
  [string]$resultfile="result.xml",
  [string]$casename="FCtesting"
)

Write-Host "toJunit.ps1 $filename $resultfile $casename"

Function Write-JunitXml([System.Collections.ArrayList] $Results,
                        [System.Collections.HashTable] $HeaderData,
                        [System.Collections.HashTable] $Statistics, $ResultFilePath)
{
$template = @'
<testsuite name="" file="">
<testcase classname="" isoname="" name="" time="">
    <failure type=""></failure>
</testcase>
</testsuite>
'@

  $guid = [System.Guid]::NewGuid().ToString("N")
  $templatePath = [System.IO.Path]::Combine([System.IO.Path]::GetTempPath(), $guid + ".txt");

  $template | Out-File $templatePath -encoding UTF8
  # load template into XML object
  $xml = New-Object xml
  $xml.Load($templatePath)
  # grab template user
  $newTestCaseTemplate = (@($xml.testsuite.testcase)[0]).Clone()  

  $className = $HeaderData.className
  $xml.testsuite.name = $className
  $xml.testsuite.file = $HeaderData.className

  if ($results.count -gt 0)
  {
    foreach($result in $Results) 
    {
      $newTestCase = $newTestCaseTemplate.clone()
      $newTestCase.classname = $result.classname.ToString()+"."+($result.isoname -split "\.")[0]
      $newTestCase.isoname = $result.isoname.ToString()
      $newTestCase.name = $result.Test.ToString()
      $newTestCase.time = $result.Time.ToString()
      if($result.Result -match "PASS")
      {   #Remove the failure node
          $newTestCase.RemoveChild($newTestCase.ChildNodes.item(0)) | Out-Null
      }
      else
      {
          $newTestCase.failure.InnerText =  $result.Result
      }
      $xml.testsuite.AppendChild($newTestCase) > $null
    }
  }

  # remove users with undefined name (remove template)
  $xml.testsuite.testcase | Where-Object { $_.Name -eq "" } | ForEach-Object  { [void]$xml.testsuite.RemoveChild($_) }
  # save xml to file
  Write-Host "Path" $ResultFilePath

  $xml.Save($ResultFilePath)

  Remove-Item $templatePath #clean up
}

$sample = '
TESTCASE 01: Verify cert works - PASS
TESTCASE 02: Verify ssh connectivity successful - PASS
e new password and reset password - PASS
TESTCASE 15: Verify that new user can be added - Fail
TESTCASE Deprovision(a) - Fail
'

[Array]$results=$();
$lines=$sample.Split("`n");
$lines|%{
  $tenant=$casename
  if($_ -match '.*TenantName=(.*)')
  {
    $tenant=$Matches[1];      
  }
  if($_ -match 'TESTCASE (.*) - (.*)')
  {
    echo "$($Matches[1]) $($Matches[2])"
    $results+=@{Test= $($Matches[1]);Time=-1;Result=$($Matches[2]);className=$tenant;};
  }
}
[Array]$results=$();

Get-Content $filename|%{
  if($_ -match '.*TenantName=(.*)')
  {
    $tenant=$Matches[1];    
  }
  if($_ -match '.*ISOBlobName=(.*)')
  {
    $isoname=$Matches[1];    
  }
  if($_ -match 'TESTCASE (.*) - (.*)')
  {
    echo "$($Matches[1]) $($Matches[2]) $tenant"
    $results+=@{Test= $($Matches[1]);Time=-1;Result=$($Matches[2]);className=$tenant;isoname=$isoname;};
  }
  if($_ -match '(.*) is (PASS|FAIL)')
  {
    echo "$($Matches[1]) $($Matches[2]) $tenant"
    $results+=@{Test= $($Matches[1]);Time=-1;Result=$($Matches[2]);className=$tenant;isoname=$isoname;};
  }
}

$HeaderData=@{className=$casename; isoname=$isoname}
Write-JunitXml -Results $results -HeaderData $HeaderData -ResultFilePath $resultfile

