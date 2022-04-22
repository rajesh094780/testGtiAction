param (
    $jsonObject
)
$hastable=$jsonObject |  ConvertFrom-Json
$dbdetails=New-Object System.Collections.ArrayList
$filespath=New-Object System.Collections.ArrayList
$sourcDB=New-Object System.Collections.ArrayList
foreach($i in $hastable.DBDetails){  
    $dbdetails.Add($i.targetDbName)
    $sourcDB=$i.sourceDbName
    $filespath.Add($(Split-Path $i.targetDbPath))
    $filespath.Add($(Split-Path $i.targetLogPath))
}
$filespath
