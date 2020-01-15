# 'Fires near me' UFO Script
#
# Uses data from NSW RFS
# Makes some assumptions (uses the centre point of the fire as reported for the distance measurement
# Assumes earth is perfectly spherical
#
# Changes UFO LED colours based on fires within selected radius.
#


#radius in kilometers
$radius = 100

#my location
$myLat = -35.2411045
$myLon = 149.138622

# Dynatrace UFO address (IP or FQDN)
$ufoaddr = "192.168.137.30"



#[CmdletBinding()] 


# Functions

function restApiGet {
    param ([Parameter(Mandatory=$true)][string]$url)

    Write-Verbose "url [$url]"
    try { 
        $result = Invoke-WebRequest $url 
        if ( $result.Headers["X-RateLimit-Remaining"] = 0 ) { Write-Output $result.Headers["X-RateLimit-Reset"]; Sleep 1000 }
        $result | ConvertFrom-Json
    } 
    catch { Write-Host "Exception: \n $_ \n ${result} ${result.Headers}" } 
    
    return $result
}

function getDist($lat1, $lon1, $lat2, $lon2) {
# approximates great circle distance between two points, assumes earth is perfectly spherical

    #Write-Host "$lat1, $lon1, $lat2, $lon2"

    $R = 6371000
    $lat1r = ([Math]::PI / 180) * ($lat1)
    $lat2r = ([Math]::PI / 180) * ($lat2)
    $latd  = ([Math]::PI / 180) * ($lat2 - $lat1)
    $lond  = ([Math]::PI / 180) * ($lon2 - $lon1)

    $a = [Math]::sin($latd / 2) * [Math]::sin($latd / 2) +
                 [Math]::cos($lat1r) * [Math]::cos($lat2r) *
                 [Math]::sin($lond / 2) * [Math]::sin($lond / 2)
    $c = 2 * [Math]::Atan2([Math]::Sqrt($a), [Math]::Sqrt(1-$a))

    return $R * $c

}


[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

#start of main code

$rfseventsurl = "https://www.rfs.nsw.gov.au/feeds/majorIncidents.json"
$eventsdata = restApiGet($rfseventsurl)


$total = 0
ForEach ($event in $eventsdata.features) {
    $coords = ""
    if ($event.geometry.coordinates.Count -gt 1 ) { $coords = $event.geometry.coordinates } 
    else { $coords = $event.geometry.geometries[0].coordinates }

    #$dist = getDist $myLat $myLon $event.geometry.coordinates[1] $event.geometry.coordinates[0]
    $dist = getDist $myLat $myLon $coords[1] $coords[0] 

    #Write-Host $event.properties.title ($dist/1000)

    if ($dist -le ($radius * 1000)) {
        $total = $total + 1
        Write-Host "***** $($event.properties.title) $($dist/1000) km"
    }

}

#$total = 4
Write-Host $total

if ( $total -le 16 ) {
    $colour="top_init=1&top=0|$total|FF0000&top_whirl=450" #show upto 16 reds slowly rotating
} else {
    $colour="top_init=1&top=0|2|FF0000|3|2|FF0000|6|2|FF0000|9|2|FF0000|12|2|FF0000&top_whirl=500" #default to worst - red-whirling
}
#send to UFO
$result = Invoke-WebRequest "http://$ufoaddr/api?$colour"
