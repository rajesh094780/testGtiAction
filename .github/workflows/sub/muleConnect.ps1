param (
        [string]$mule_host,
        [string]$Mule_Org_Name,
        [string]$mule_BusinessGroup,
        [string]$mule_username,
        [string]$mule_password,
        [string]$mule_Env_Name
)  

$parent_orgID = ""

#login anypoint plateform
function login_muleApp {
    [CmdletBinding()]
    Param([string]$username, [string]$password)    
    $uri = 'https://' + ${mule_host} + '/accounts/login'

    $body = @{
        username = "$username"
        password = $password
    } | ConvertTo-Json
    
    $login_result = Invoke-RestMethod -Uri $uri -Method Post -Body $body -ContentType 'application/json'
    $MULE_BEARER_TOKEN = $login_result.access_token
    return $MULE_BEARER_TOKEN
}


function get_organizationId {
    [CmdletBinding()]
    Param([string]$authToken)    
    $uri = 'https://' + ${mule_host} + '/accounts/api/me'
    $headers = @{
        'Authorization' = $("Bearer " + $authToken)
    }
    $org_result = Invoke-RestMethod -Uri $uri -Method Get -Headers $headers -ContentType 'application/json'
    
    $MULE_Org_Id = $($org_result.user.contributorOfOrganizations | where { $_.name -eq $Mule_Org_Name }).id
    $MULE_Org_Id = $org_result.user.organizationId
    $MULE_Owner_Id = $org_result.user.organization.ownerId
    return $MULE_Org_Id, $MULE_Owner_Id

}



function get_BusinessGroup {
    [CmdletBinding()]
    Param([string]$authToken, [string]$orgId)    
    $uri = 'https://' + ${mule_host} + '/accounts/api/organizations/' + $orgId
    $headers = @{
        'Authorization' = $("Bearer " + $authToken)        
    }
    $mule_bg = ''
    $MULE_BusinessGroup_Id = $null
    $org_result = Invoke-RestMethod -Uri $uri -Method Get -Headers $headers -ContentType 'application/json'
    foreach ($bus_Group_Id in $org_result.subOrganizationIds) {
        $businessOrg_uri = 'https://' + ${mule_host} + '/accounts/api/organizations/' + $bus_Group_Id
        $business_result = Invoke-RestMethod -Uri $businessOrg_uri -Method Get -Headers $headers -ContentType 'application/json'
        if ($mule_BusinessGroup -eq $business_result.name) {
            $mule_bg = 'yes'
        }
        
    }
    if ($mule_bg -eq 'yes') {
        return 'yes'
    }
    else {
        return 'no'
    }

        

}


function get_BusinessGroupIdifExist {
    [CmdletBinding()]
    Param([string]$authToken, [string]$orgId)    
    $uri = 'https://' + ${mule_host} + '/accounts/api/organizations/' + $orgId
    $headers = @{
        'Authorization' = $("Bearer " + $authToken)        
    }
    $mule_bg = ''
    $MULE_BusinessGroup_Id = $null
    $org_result = Invoke-RestMethod -Uri $uri -Method Get -Headers $headers -ContentType 'application/json'
    foreach ($bus_Group_Id in $org_result.subOrganizationIds) {
        $businessOrg_uri = 'https://' + ${mule_host} + '/accounts/api/organizations/' + $bus_Group_Id
        $business_result = Invoke-RestMethod -Uri $businessOrg_uri -Method Get -Headers $headers -ContentType 'application/json'
        if ($mule_BusinessGroup -eq $business_result.name) {
            $MULE_BusinessGroup_Id = $business_result.id
        }
        
    }
    return $MULE_BusinessGroup_Id

        

}

function create_BusinessGroup {
    param (
        [string]$businessGrouName,
        [string]$ownerId,
        [string]$parentOrganizationId,
        [string]$authToken

    )
    $uri = 'https://' + ${mule_host} + '/accounts/api/organizations'
    $headers = @{
        'Authorization' = $("Bearer " + $authToken)
    }
    $body = @{
        name                 = "$businessGrouName"
        ownerId              = "$ownerId"
        parentOrganizationId = "$parentOrganizationId"
        entitlements         = @{
            createEnvironments = $true
            createSubOrgs      = $true
        } 
    } | ConvertTo-Json
    $Mule_Business_Result = Invoke-RestMethod -Uri $uri -Method Post -Headers $headers -Body $body -ContentType 'application/json'
    $Mule_Business_Result



    
}

function create_env {
    param (
        [string]$busGrpID,
        [string]$authToken,
        [string]$mule_Env_Name

    )
    $uri = 'https://' + ${mule_host} + '/accounts/api/organizations/' + ${busGrpID} + '/environments'
    $headers = @{
        'Authorization' = $("Bearer " + ${authToken})
    }
    $Mule_Env_Response = Invoke-RestMethod -Uri $uri -Method Get -Headers $headers -ContentType 'application/json'
    #$Mule_Env_Response.data.name
    if ($Mule_Env_Response.data.name -eq  $mule_Env_Name){
        Write-Host "mule environtment already exist $($Mule_Env_Response.data.name)"
    }
    else{
        Write-Host "mule environtment does not Exist $($mule_Env_Name)"
        $uri = 'https://'+${mule_host}+'/accounts/api/organizations/' + ${busGrpID} +'/environments'
        $headers = @{
            'Authorization' = $("Bearer " + ${authToken})
        }
        if($mule_env_Name -eq 'Production'){

            $Mule_IsProdcution=$true
            $type='Production'
        }
        else{
        $Mule_IsProdcution=$false
        $type='Sandbox'
        }
        $body = @{
            name = $Mule_Env_Name
            isProduction = $Mule_IsProdcution
        
        } | ConvertTo-Json
        $Mule_Env_Response = Invoke-RestMethod -Uri $uri -Method Post -Headers $headers -Body $body -ContentType 'application/json'
    }

}
$authToken = login_muleApp -username $mule_username -password $mule_password
$MULE_Org_Id, $MULE_Owner_Id = get_organizationId -authToken $authToken


#Checking Business Exist or not
$mulegb_existOrnot = get_BusinessGroup -authToken $authToken -orgId $MULE_Org_Id
if ($mulegb_existOrnot -eq 'yes') {
    Write-Host "Business Group already Exist: $mule_BusinessGroup"
    $MULE_BusinessGroup_Id = get_BusinessGroupIdifExist -authToken $authToken -orgId $MULE_Org_Id    
    create_env -busGrpID $MULE_BusinessGroup_Id -authToken $authToken -mule_Env_Name $mule_Env_Name

}
else {
    Write-Host "Business Group Does not  Exist creating  $mule_BusinessGroup"
    $bgid=create_BusinessGroup -businessGrouName $mule_BusinessGroup -ownerId $MULE_Owner_Id -parentOrganizationId $MULE_Org_Id -authToken $authToken
    create_env -busGrpID $bgid.id -authToken $authToken -mule_Env_Name $mule_Env_Name
}
