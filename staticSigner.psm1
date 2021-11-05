# This Powershell module creates a function, signStaticUrl, that can be used to digitally sign Google Static Maps or Street View Static URLs
# To use this module from a PowerShell command prompt,
# save ths module file (staticSigner.psm1) to your PowerShell module path, then run:
# PS > Import-Module staticSigner
#
# or save the module file to any local directory, cd to that directory, and run:
# PS > Import-Module ./staticSigner
#
# After importing the module, you can use 
# PS > Get-Help Set-SecretKey
# or
# PS > Get-Help signStaticUrl
# for more information on these functions
# 
# Once the module has been imported, use Set-SecretKey to set the URL Signing Secret before signing any URLs:
# PS > Set-SecretKey "[URL Signing Secret from your Google API project]"
# 
# After importing the module and using Set-SecretKey, you can sign one or more URLs using the signStaticUrl function:
# PS > signStaticUrl "https://maps.googleapis.com/maps/api/staticmap?center=Royal+Observatory+Greenwich,London&size=640x640&zoom=18&key=[YOUR API KEY]"
# PS > signStaticUrl "https://maps.googleapis.com/maps/api/staticmap?center=Eiffel+Tower,Paris&size=500x500&zoom=19&maptype=satellite&key=[YOUR API KEY]"
# ...
# 
# If you have a file 'unsignedURLs.txt" containing Static Maps URLs, you can create a file 'signedURLs.txt' by:
# PS > Set-SecretKey "[URL Signing Secret from your Google API project]"
# PS > Get-Content ./unsignedURLs.txt | signStaticUrl | Out-File signedURLs.txt
# 
# 
# If you have a .CSV file containing lines of data about a number of locations, including a field for mapUrl, 
# you can add a signature to the mapUrl field for each line and create a new .CSV file using:
# PS > Set-SecretKey "[URL Signing Secret from your Google API project]"
# PS > Import-Csv ./locations.csv | ForEach-Object {$_.mapUrl = signStaticUrl $_.mapUrl;  $_} | Export-Csv ./locations_with_signature.csv
#############################


# create a PowerShell multiline string variable $code that contains the C# code needed to create a _SignUrl .NET class
# (adapted from https://developers.google.com/maps/documentation/maps-static/get-api-key#c )
$code = @"
using System;
using System.Collections.Generic;
using System.Security.Cryptography;
using System.Text;
using System.Text.RegularExpressions;
using System.Web;

public class _SignUrl

{
    public string Sign(string url, string secretKey ) {
      ASCIIEncoding encoding = new ASCIIEncoding();

      // converting key to bytes will throw an exception,
      // need to replace '-' and '_' characters first.
      string usableSecretKey = secretKey.Replace("-", "+").Replace("_", "/");
      byte[] secretKeyBytes = Convert.FromBase64String(usableSecretKey);

      Uri uri = new Uri(url);
      byte[] encodedPathAndQueryBytes = encoding.GetBytes(uri.LocalPath + uri.Query);

      // compute the hash
      HMACSHA1 algorithm = new HMACSHA1(secretKeyBytes);
      byte[] hash = algorithm.ComputeHash(encodedPathAndQueryBytes);

      // convert the bytes to string and make url-safe
      // by replacing '+' and '/' characters
      string signature = Convert.ToBase64String(hash).Replace("+", "-").Replace("/", "_");
           
      // Add the signature to the existing URI.
      return uri.Scheme+"://"+uri.Host+uri.LocalPath + uri.Query +"&signature=" + signature;
   }
}
"@

# add the .NET class _SignUrl to this PowerShell session
Add-Type -TypeDefinition $code

# define the $secretKey variable at script-level 
$secretKey = ""

function Set-SecretKey {
<#
.SYNOPSIS
Sets the Google Maps URL Signing Secret needed by signStaticUrl()
.DESCRIPTION
This function sets the "URL Signing Secret" that is needed by signStaticUrl()

The URL Signing Secret is an alphanumeric code ending in "=", 
like "AbCdEfGhIjKlMnOpQrStUvWxYz9="

You can retrieve the URL Signing Secret from your Google API project
by visiting https://console.cloud.google.com/google/maps-apis/credentials,
and selecting the Maps Static API or Street View Static API from the list labeled "All Google Maps Platform APIs"

To set the Signing Secret to a default value (listed below):
Set-SecretKey

To set the Signing Secret to a different value:
Set-SecretKey [URL Signing Secret from your Google API project]

.LINK
https://developers.google.com/maps/documentation/maps-static/get-api-key#gen-sig
.LINK
https://console.cloud.google.com/google/maps-apis/credentials
#>    
    [cmdletBinding()]
    Param( [string]$secret )

    # set the script-level $secretKey to the supplied value if one has been supplied as a parameter to this function
    if($secret){
        if($secret -match "^[\w-]{27}=$") {
            $script:secretKey = $secret
            '$secretKey has been set'
        } else {
            "$secret is not an expected value for a Static Maps URL Signing Secret"
            ""
            'A Static Maps URL Signing Secret is a 28-character alphanumeric string ending in "=", like "AbCdEfGhIjKlMnOpQrStUvWxYz3=" '
            ""
            'You can retrieve the URL Signing Secret from your Google API project'
            'by visiting https://console.cloud.google.com/google/maps-apis/credentials,'
            'and selecting the Maps Static API or Street View Static API from the list labeled "All Google Maps Platform APIs"'
        }
    } else {
        # you can edit the following line to set the URL Signing Secret to the one from your project
        $script:secretKey = "aBcDeFgHiJkLmNoPqRsTuVwXyZ-="
        '$secretKey set to default value (edit staticSigner.psm1 to change default value)'
    }
}

# display the current $secretKey
function Get-SecretKey { $secretKey }

function Test-StaticUrl {
<#
.SYNOPSIS
Boolean function to check Static Map or Static Street View URL for validity
.DESCRIPTION
Function returns PowerShell $true if passed URL string is valid, $false if not. 
This is not a definitive check - for example, 
the function checks to see that the URL contains an API key or client ID parameter in the correct format, 
but does not verify that the API key or client ID is still active and has billing enabled.

.EXAMPLE
Test a single URL:
PS > $landmark = "https://maps.googleapis.com/maps/api/staticmap?center=Tour+Eiffel,Paris&zoom=17&size=400x400&key=AIzaSy_ABCDEFGHIJKLMNOPQRSTUVXYZ123456"
PS > Test-StaticUrl $landmark
.EXAMPLE
Use the -Verbose option to 
PS > $landmark = "https://maps.googleapis.com/maps/api/staticmap?center=Tour+Eiffel,Paris&zoom=17&size=400x400&key=bogus_API_key_too_short"
PS > Test-StaticUrl $landmark -Verbose
.EXAMPLE
Import from a .CSV file (with "store number" and "url" properties), select the lines with valid URLs, sign those URLs, then export to a new file:
PS > Set-SecretKey "AbCdEfGhIjKlMnOpQrStUvWxYz9="
PS > Import-Csv ./unsignedStores.csv | Where-Object {Test-StaticUrl $_.url} | ForEach-Object {$_.url = signStaticUrl $_.url; $_} | Export-Csv ./signedStores.csv

.LINK
https://developers.google.com/maps/documentation/maps-static/start
.LINK
https://developers.google.com/maps/documentation/streetview/overview
#>
    [cmdletBinding()]
    Param(
        [Parameter(
            Mandatory=$true,
            Position=0,
            ValueFromPipeline=$true
        )]
        [string]$url
    )
    # assume URL is good until proven otherwise
    $validURL = $true

    Write-Verbose "URL being tested:"
    Write-Verbose "$url"

    # start by checking to see whether the URL includes an API key or client ID parameter
    # current Google API keys are 39-character Base64 strings that start with AI
    # Google Maps client IDs are IDs like "gme-samplecompany" from Google Maps Premium Plan projects
    # They are NOT the same as the "OAuth 2.0 Client IDs" found on the Credentials page of your Google Cloud API project
    if ( $url -notmatch "[?&]client=gme-[A-Za-z0-9]+|[?&]key=AI[\w-]{37}[^\w-]|[?&]key=AI[\w-]{37}$" ) {
        Write-Verbose 'URL does not contain a valid Premium Plan Client ID (like "gme-abcd...") or 39-character API key (like "&key=AIza...") parameter'
        $validURL = $false
    }

    # now see if the first part of the URL could be a valid Static Map or Street View URL
    if ( $url -notmatch "^https://maps.googleapis.com/maps/api/[staticmap|streetview]?") {
        Write-Verbose 'URL must start with "https://maps.googleapis.com/maps/api/staticmap?" or "https://maps.googleapis.com/maps/api/streetview?"'
        $validURL = $false
    }

    # size=###x### is a required parameter for both Static Street View and Static Maps
    if ( $url -notmatch "[?&]size=\d+x\d+") {
        Write-Verbose 'URL must include a size parameter like "&size=640x400" '
        $validURL = $false
    }

    # check for other required parameters for Static Maps - need both center and zoom unless markers are specified
    if ( $url -match "^https://maps.googleapis.com/maps/api/staticmap\?") {
        if ( $url -notmatch "[?&]markers=") {
            if (( $url -notmatch "[?&]center=" ) -or ( $url -notmatch "[?&]zoom=\d+" ) ) {
                Write-Verbose 'Each Static Maps URL must include both "&center=..." and "&zoom=" parameters, unless markers have been specified'
                $validUrl = $false
            }
        }
    }
    # check for the other required parameters for Static Street View - need either location or pano
    if ( $url -match "^https://maps.googleapis.com/maps/api/streetview\?" ) {
        if ( ( $url -notmatch "[?&]location=" ) -and ( $url -notmatch "[?&]pano=" ) ) {
            Write-Verbose 'Each Static Street View URL must include either "&location=..." or "&pano=..." parameters '
            $validURL = $false
        }
    }
    if($validURL) {Write-Verbose "No problems found with URL"}
    return $validURL
}

Set-Alias -Name Test-Url -Value Test-StaticUrl

function signStaticUrl {
<#
.SYNOPSIS
Function to digitally sign Google Static Maps / Static Street View URLS

.DESCRIPTION
signStaticUrl is a PowerShell function to compute a digital signature for a Google Static Map or Static Street View URL, 
add the digital signature to the URL, then return the signed URL. 

signStaticurl uses Test-StaticUrl to verify that the $url is valid. You can use 
  -ErrorAction SilentlyContinue 
to suppress the error message when piping in a file of URLs in a pipeline

If the input URL has already been signed (that is, it has a "&signature=..." parameter at the end), the function removes the
previous signature parameter, signs the remaining URL, and appends the new signature in place of the old signature

signStaticUrl can be used as a command-line function, or in a PowerShell pipeline - see EXAMPLEs for more

NOTE: before signing the first URL, you must use 'Set-SecretKey' to set the URL Signing Secret
Use 'Get-Help Set-SecretKey' for more information

.EXAMPLE
PS > Set-SecretKey "ThIsNoTaVaLiDsEcReTkEy-3579="
PS > signStaticUrl "https://maps.googleapis.com/maps/api/staticmap?center=51.47,0.0&zoom=14&size=500x400..."

returns:
https://maps.googleapis.com/maps/api/staticmap?center=51.47,0.0&zoom=14&size=500x400...&signature=...

.EXAMPLE
PS > Set-SecretKey "AbCdEfGhIjKlMnOpQrStUvWxYz3="
PS > Get-Content ./unsignedUrls.txt | signStaticUrl -ErrorAction SilentlyContinue | Out-File ./signedUrls.txt

This uses signStaticUrl in a PowerShell pipeline to sign one or more URLs from a text file
and save the signed URLs to a new file (overwrites the signedUrls.txt file if it exists)
The '-ErrorAction SilentlyContinue' suppresses the error message for invalid URLs

.LINK
https://developers.google.com/maps/documentation/maps-static/get-api-key#gen-sig

#>
    [cmdletBinding()]
    Param(
        [Parameter(
            Mandatory=$true,
            Position=0,
            ValueFromPipeline=$true,
            ValueFromPipelineByPropertyName=$true
        )]
        [string]$url
    )

    begin {
        if ( $secretKey.Length -eq 0) {
            Write-Error 'You must use Set-SecretKey to set the $secretkey before signing URLs' -ErrorAction Stop
        }
        $script:signer = New-Object _SignUrl
    }
    process {
        if ( -not(Test-StaticUrl $url)){
            Write-Error "Invalid Static URL:"
            Write-Error ">> $url"
            Write-Error "use: 'Test-StaticUrl <URL> -Verbose' for more information"
        } else {
        # if the URL has been signed previously, remove the signature parameter before signing with the current key
        $url = $url -replace '&signature=.*$', ''
        $script:signer.Sign($url, $secretKey)
        }
    }
    end {}
}

Set-Alias -Name Protect-StaticUrl -Value signStaticUrl
Set-Alias -Name Protect-Url -Value signStaticUrl

"", "Run Set-SecretKey before using signStaticUrl() function for the first time", "Use 'Get-Help signStaticUrl' to learn more", "" | Write-Host