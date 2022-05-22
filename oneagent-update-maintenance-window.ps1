<#script to assign OneAgent maintenance window(s) to two groups of hosts
this script requires two oneagent update windows to already be created, with their objectId values saved and used in the 2 foreach loops
also requires two .txt files of the hosts in Group A and Group B, to be used to grab the host entity ID values from DT API
when running the script the only expected output in powershell is http 204 responses for each host in the groups A and B list, indicating successfull setting of the windows 
v1.0 completed 4/6/22
#>

#API token value
$token = ''

#feed the host name objects from a text list of host names, e.g.: 
#hostname1
#hostname2
#etc
#do NOT have blank new lines in file or will cause errors
$host_A = Get-Content -Path 'C:\users\kevin.davis\documments\scripts\scriptfiles\groupAhosts.txt'
$host_B = Get-Content -Path 'C:\users\kevin.davis\documments\scripts\scriptfiles\groupBhosts.txt'

#grab entityID for each host in groups A and B
$host_id_A = @()
foreach ($i in $host_A) {
    #update URL details to correct DT instance values
    $DT_URL = 'https://dynatrace-domain.com/e/environmentID/api/v2/entities?entitySelector=type%28%22HOST%22%29%2CentityName.startsWith%28%22'+$i+'%22%29&API-Token='+$token
    $ent = Invoke-RestMethod $DT_URL
    $host_id_A = $host_id_A + $ent.entities.entityId
}

$host_id_B = @()
foreach ($i in $host_B) {
    #update URL details to correct DT instance values
    $DT_URL = 'https://dynatrace-domain.com/e/environmentID/api/v2/entities?entitySelector=type%28%22HOST%22%29%2CentityName.startsWith%28%22'+$i+'%22%29&API-Token='+$token
    $ent = Invoke-RestMethod $DT_URL
    $host_id_B = $host_id_B + $ent.entities.entityId
}

#this section looks up the objectId values for the agent update maintenance windows, based on the name values provided
#declare vars for objectId A and B and assign them values from API query

$objectId_A = ''
$objectId_B = ''
$window_A =  'host_A_window'
$window_B = 'host_B_window'
$DT_URL = 'https://dynatrace-domain.com/e/environmentID/api/v2/settings/objects?schemaIds=builtin%3Adeployment.mananagement.update-windows&scopes=environment&fields=objectId%2cvalue'

$headers = @{
    'accept' = '*/*'
    'Authorization' = 'Api-Token ' + $token 
}

$windows = Invoke-WebRequest -Uri $DT_URL -Method Get -ContentType "application/json" -Headers $headers
$windows = $windows.content | ConvertFrom-Json
$count = $windows.totalCount 

for ($i = 0; $i -lt $count; $i++) {
    $name = $windows.items[$i].value.name
    
    if ($name -eq $window_A) {
        $objectId_A = $windows.items[$i].objectId
    }

    if ($name -eq $window_B) {
        $objectId_B = $windows.items[$i].objectId
    }
}


#assign the hosts in group A to maintenance window A 
foreach ($i in $host_id_A) {
    #execute first request to validate a good response from API; if it succeeds, proceed to second loop to PUT update 

    $DT_URL = 'https://dynatrace-domain.com/e/environmentID/api/config/v1/hosts'+$i+'/autoupdate/validator'
    $headers = @{
        'accept' = '*/*'
        'Authorization' = 'API-Token ' + $token
    }
    $body = @{
        'setting' = 'ENABLED'
        'version' = $null
        'updateWindows' = @{
            'windows' = @(
                @{'id' = $objectId_A}
                )
        }
    }

    $test_response = Invoke-WebRequest -Uri $DT_URL -Method Post -ContentType 'application/json' -Headers $headers -Body ($body | ConvertTo-Json -Depth 4)

    if ($test_response.StatusCode -eq 204) {
        $DT_URL = 'https://dynatrace-domain.com/e/environmentID/api/config/v1/hosts'+$i+'/autoupdate'
        Invoke-WebRequest -Uri $DT_URL -Method Put -ContentType 'application/json' -Headers $headers -Body ($body | ConvertTo-Json -Depth 4)
    }
}

#assign the hosts in group B to maintenance window B 
foreach ($i in $host_id_B) {
    #execute first request to validate a good response from API; if it succeeds, proceed to second loop to PUT update 

    $DT_URL = 'https://dynatrace-domain.com/e/environmentID/api/config/v1/hosts'+$i+'/autoupdate/validator'
    $headers = @{
        'accept' = '*/*'
        'Authorization' = 'API-Token ' + $token
    }
    $body = @{
        'setting' = 'ENABLED'
        'version' = $null
        'updateWindows' = @{
            'windows' = @(
                @{'id' = $objectId_B}
                )
        }
    }

    $test_response = Invoke-WebRequest -Uri $DT_URL -Method Post -ContentType 'application/json' -Headers $headers -Body ($body | ConvertTo-Json -Depth 4)

    if ($test_response.StatusCode -eq 204) {
        $DT_URL = 'https://dynatrace-domain.com/e/environmentID/api/config/v1/hosts'+$i+'/autoupdate'
        Invoke-WebRequest -Uri $DT_URL -Method Put -ContentType 'application/json' -Headers $headers -Body ($body | ConvertTo-Json -Depth 4)
    }
}