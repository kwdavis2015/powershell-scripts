<# 
script to download all of the hosts in a DT management zone into a file for resource comparison
script will list CPU cores and memory amount per host 
this was done as part of an active/active go live project, to ensure both datacenters had servers of the same size / capacity
#>

$path = '' #assign a path to an excel file that is already created and has sheets named correctly, see foreach loops

#correct mzNam in below URL's when setting up 
$dt_url_preprod = 'https://dynatrace-domain.com/e/environmentID/api/v2/entities?pageSize=100&entitySelector=type%28%22HOST%22%29%2mzname%28%22NAME%22%29'
$dt_url_prod = 'https://dynatrace-domain.com/e/environmentID/api/v2/entities?pageSize=100&entitySelector=type%28%22HOST%22%29%2mzname%28%22NAME%22%29'

$token = @{
    preprod = '' #insert API token strings
    prod = ''
}

#open excel worksheet 
$ExcelObj = New-Object -ComObject Excel.application
$ExcelObj.visible = $false 
$ExcelWB = $ExcelObj.Workbooks.Open($Path + 'Host Inventory.xlsx')
$ExcelWS = $ExcelWB.Sheets.Items("PreProd")

$headers = @{
    'accept' = '*/*'
    'Authorization' = 'Api-Token ' + $token.preprod
}

#grab all hosts in specific pre prod management zone 
$host_obj = Invoke-WebRequest -Uri $dt_url_preprod -Method Get -ContentType 'application/json' -Headers $headers
$host_obj = $host_obj.content | ConvertFrom-Json

#create array of all host ID values 
$host_ids = @()
$count = $host_obj.totalCount
for ($i = 0; $i -lt $count; $i++) {
    $host_ids = $host_ids + $host_obj.entities[$i].entityId
}

#look up eaach individual host ID value and write required data to excel sheet 
#starting row count after table headers
$row = 2
foreach($id in $host_ids) {
    $URL = 'https://dynatrace-domain.com/e/environmentID/api/v2/entities/' + $id
    $host_data = Invoke-WebRequest -Uri $URL -Method Get -ContentType 'application/json' -Headers $headers
    $host_data = $host_data.Content | ConvertFrom-Json
    $host_name = $host_data.properties.detectedName 

    #add datacenter 1 or datacenter 2 data to each server entry in inventory
    if (($hostname.Contains('dc1'))) {
        $ExcelWS.Cells.Item($row, 4) = 'datacenter 1'
    }

    elseif(($hostname.contains('dc2'))) {
        $ExcelWS.Cells.Item($row, 4) = 'datacenter 2'
    }

    else {
        $ExcelWS.Cells.Item($row, 4) = 'unknown DC' 
    }

    $ExcelWS.Cells.Item($row, 1) = $host_data.properties.detectedName
    $ExcelWS.Cells.Item($row, 2) = $host_data.properties.cpuCores
    $ExcelWS.Cells.Item($row, 3) = $host_data.properties.memoryTotal + '/(1e+9)' #updates value from bytes to GB's 

    $row++ 
}


#following section for PROD dt environment 
ExcelWS = $ExcelWB.Sheets.Items("Prod")

$headers = @{
    'accept' = '*/*'
    'Authorization' = 'Api-Token ' + $token.prod
}

#grab all hosts in specific prod management zone 
$host_obj = Invoke-WebRequest -Uri $dt_url_prod -Method Get -ContentType 'application/json' -Headers $headers
$host_obj = $host_obj.content | ConvertFrom-Json

#create array of all host ID values 
$host_ids = @()
$count = $host_obj.totalCount
for ($i = 0; $i -lt $count; $i++) {
    $host_ids = $host_ids + $host_obj.entities[$i].entityId
}

#look up eaach individual host ID value and write required data to excel sheet 
#starting row count after table headers
$row = 2
foreach($id in $host_ids) {
    $URL = 'https://dynatrace-domain.com/e/environmentID/api/v2/entities/' + $id
    $host_data = Invoke-WebRequest -Uri $URL -Method Get -ContentType 'application/json' -Headers $headers
    $host_data = $host_data.Content | ConvertFrom-Json
    $host_name = $host_data.properties.detectedName 

    #add datacenter 1 or datacenter 2 data to each server entry in inventory
    if (($hostname.Contains('dc1'))) {
        $ExcelWS.Cells.Item($row, 4) = 'datacenter 1'
    }

    elseif(($hostname.contains('dc2'))) {
        $ExcelWS.Cells.Item($row, 4) = 'datacenter 2'
    }

    else {
        $ExcelWS.Cells.Item($row, 4) = 'unknown DC' 
    }

    $ExcelWS.Cells.Item($row, 1) = $host_data.properties.detectedName
    $ExcelWS.Cells.Item($row, 2) = $host_data.properties.cpuCores
    $ExcelWS.Cells.Item($row, 3) = $host_data.properties.memoryTotal + '/(1e+9)' #updates value from bytes to GB's 

    $row++ 
}

#save the file and closes out excel application on computer 
$ExcelObj.visible = $false 
$ExcelWB.Save()
$ExcelWB.close($true)
$ExcelObj.Quit()