param(	
    [Alias("a")]
    [string] $alarmActionArn = "",
	
	[Alias("m")]
    [string] $metricNamespace = "SecurityAlarms",

    [Alias("t")]
    [switch] $transcribe = $false,
	
    [Alias("h")]
    [switch] $help = $false
)

while ($alarmActionArn.Count -eq 0) {
	$alarmActionArn = Read-Host "Enter the ARN of the alarm action"
}

$logGroup = aws logs describe-log-groups --log-group-name-prefix "aws-cloudtrail"
$logGroup = ConvertFrom-Json($logGroup -join "")
$logGroup = $logGroup.logGroups

$files = Get-Childitem $Path -filter "*.json"

$files | Foreach-Object {

    $filter = Get-Content $_.FullName -raw
	$filter = $filter.Replace('"', '\"')
	
	$filterName = [System.IO.Path]::GetFileNameWithoutExtension($_.FullName)
	$filterName = $filterName.Substring(0,$filterName.Length-1)
	
	$duplicateFilter = aws logs describe-metric-filters --metric-name $filterName --metric-namespace $metricNamespace
	$duplicateFilter = ConvertFrom-Json($duplicateFilter -join "")
	$duplicateFilter = $duplicateFilter.metricFilters

	if ($duplicateFilter.Count -ne 0) {
		write-host("Metric already exists:", $filterName)
	} else {

		aws logs put-metric-filter --log-group-name $logGroup.logGroupName --filter-name $filterName --filter-pattern "$filter" --metric-transformations metricName=$filterName,metricNamespace=$metricNamespace,metricValue=1,defaultValue=0
		aws cloudwatch put-metric-alarm --alarm-name $filterName --alarm-description $filterName --metric-name $filterName --namespace $metricNamespace --statistic Average --period 300 --threshold 1 --comparison-operator GreaterThanOrEqualToThreshold  --evaluation-periods 1 --alarm-actions $alarmActionArn
	}
	
	Start-Sleep -s 1
}


 