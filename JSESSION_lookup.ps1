#script to look up JSESSION values, stored as a request attribute in a Dynatrace monitoring environment
$token = '' #insert Dynatrace API token with read metrics capability
$path = '' #insert path to a blank text file that you will store the JSESSION values to

#format date variable like this: 2022-04-28

$startDate = '2022-07-27'
$endDate = '2022-07-28'

#update the URL with your respective environment and metric lookup details
$DT_URL = 'https://dynatrace-domain.com/e/environmentID/api/v2/metrics/query?metricSelector=calc%3Aservice.jsessionid_greaterthan1min%3AsplitBy%28JSESSIONID%29%3Acount%3Aauto%3Asort%28value%28avg%2Cdescending%29%29%3Alimit%281000%29&from'+$startDate+'T00%3A00%3A00-04%3A00&to='+$endDate+'T00%3A00%3A00-04%3A00&entitySelector=type%28%22SERVICE%22%29'
$headers = @{
  'accept' = '*/*'
  'Authorization' = 'Api-Token ' + $token
  }

$data = Invoke-WebRequest -Uri $DT_URL -Method Get -ContentType 'application/json' -Headers $headers

$resp = $data.content | Convert-FromJson
$count = $resp.totalCount
$jsession_results = $resp.result 

#testing
Write-Output $count 

for ($i=0; $i -lt $count; $i++) {
	$jsession_lookup = $jsession_lookup.data[$i]
	$value = $jsession_lookup.dimensions
	Add-Content -Path $path "$value"
	}
