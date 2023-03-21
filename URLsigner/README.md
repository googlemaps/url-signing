# URLsigner
### a PowerShell module to add digital signatures
### to Google Static Maps and Static Street View URLs  
---
## Installation
Copy the URLsigner folder containing the staticSigner.psm1 file to your PowerShell user module path
* On Windows systems, copy the URLsigner folder to ```$HOME\Documents\PowerShell\Modules```
* On non-Windows systems, copy URLsigner to ```$HOME/.local/share/powershell/Modules```
---
## Set default URL Signing Secret (optional)
To add a digital signature to a Google Static Maps or Static Street View URL,
you need to use the **URL Signing Secret** from your Google API project.

The staticSigner.psm1 file has a dummy URL Signing Secret set as the default:  
```$script:secretKey = "aBcDeFgHiJkLmNoPqRsTuVwXyZ-="```  
This is the correct format for a Signing Secret and can be used to generate a sample signed URL,
but the signed URL will not be valid.

You can specify a valid URL Signing Secret each time you import the module,
or you can edit staticSigner.psm1 to include your URL Signing Secret as the default.

#### **To set the default URL Signing Secret to the one from your Google Cloud project:**
1. Go to the [Maps APIs Credentials](https://console.cloud.google.com/google/maps-apis/credentials) page of your API project.
2. Select the Maps Static API or Static Street View API from the list at the top marked "All Google Maps Platform APIs"
3. Copy the 28-character Current Secret (including the "=" sign at the end)  
![URL Signing Secret in API project](./01-CurrentSecret.png)  
4. Open the URLsigner/URLsigner.psm1 file in a code editor 
5. Find the line starting with  
```$script:secretKey = ```  
and replace the dummy signing secret with the one from your project
6. Save the URLsigner.psm1 file
---  
## Importing the module and preparing to sign URLs
After you've saved the ```URLsigner``` folder containing the ```URLsigner.psm1``` file to your PowerShell profile path, you can import the module from a PowerShell command line:  
**```PS> Import-Module URLsigner```**  
![Import-Module command](./02-Import-Module.png)  
Before signing a Static Maps or Static Street View URL, you need to run the ```Set-SecretKey``` command:  
**```PS> Set-SecretKey "jdW0fdx88bGYVwTCxIjWSpBJMoo="```**  
![Set-SecretKey command](./03-Set-SecretKey.png)  
(this secret key has already been regenerated -- get your actual URL Signing Secret from the [Maps-APIs Credentials](https://console.cloud.google.com/google/maps-apis/credentials) page of your project)  
If you've already edited URLsigner.psm1 to replace the dummy default key with your actual URL Signing Secret, you can use:  
**```PS> Set-SecretKey```**  
to use the default you've set.  

---  

## Signing a URL
After you've imported the module and run Set-SecretKey, you can use the ```signStaticUrl``` function to add a digital signature to a Static Maps or Static Street View URL:  
**```PS> $url_1 = "https://maps.googleapis.com/maps/api/staticmap?center=Royal+Greenwich+Observatory,London,England&zoom=14&size=640x640&scale=2&language=en-EN&key=AIzaSyAY4gcXw6gp_mlQ8qKisL5sE23LMC1MM9U"```**  
![Set a variable $url equal to a URL string](./04-url1.png)  
(note: this API key AIza...C1MMU has already been regenerated and is expired)  

**```PS> signStaticUrl $url_1```**  
```https://maps.googleapis.com/maps/api/staticmap?center=Royal+Greenwich+Observatory,London,England&zoom=14&size=640x640&scale=2&language=en-EN&key=AIzaSyAY4gcXw6gp_mlQ8qKisL5sE23LMC1MM9U&signature=omVx1LZnFWT2kmnBXdwaUiDMNxE=```  
![run the signStaticUrl function on $url1](./05-signStaticUrl.png)  

The URLsignermodule creates two aliases, ```Protect-StaticUrl``` and ```Protect-Url```, for the ```signStaticUrl``` function:  

**```PS> Protect-StaticUrl $url_1```**  
```https://maps.googleapis.com/maps/api/staticmap?center=Royal+Greenwich+Observatory,London,England&zoom=14&size=640x640&scale=2&language=en-EN&key=AIzaSyAY4gcXw6gp_mlQ8qKisL5sE23LMC1MM9U&signature=omVx1LZnFWT2kmnBXdwaUiDMNxE=```  
![use the Protect-StaticUrl alias on $url1](./06-Protect-StaticUrl.png)  

You can see that both ```signStaticUrl``` and ```Protect-StaticUrl``` generate the same signature ```omVx1LZnFWT2kmnBXdwaUiDMNxE=``` for $url_1 

**```PS> $url_2 = "https://maps.googleapis.com/maps/api/staticmap?center=Eiffel+Tower,Paris,France&zoom=14&size=640x640&scale=2&language=en-EN&key=AIzaSyAY4gcXw6gp_mlQ8qKisL5sE23LMC1MM9U"```**  

**```PS> Protect-Url $url_2```**  
```https://maps.googleapis.com/maps/api/staticmap?center=Eiffel+Tower,Paris,France&zoom=14&size=640x640&scale=2&language=en-EN&key=AIzaSyAY4gcXw6gp_mlQ8qKisL5sE23LMC1MM9U&signature=BhiRbuHKA-9TBW1kmeitFN1ObuA=```  

![use the Protect-Url alias instead of signStaticUrl](./07-ProtectUrl.png)
---

## Re-signing a previously signed URL

If the URL was already signed using a different URL Signing Secret, the ```signStaticUrl``` function (and its aliases) will remove the old signature before creating a new signature and adding it to the URL:  
**```PS> Set-SecretKey```**  
```$secretKey set to default value (edit URLsigner.psm1 to change default value)```  
**```PS> $signed_url = Protect-StaticUrl $url_2```**  
**```PS> $signed_url```**    
```https://maps.googleapis.com/maps/api/staticmap?center=Eiffel+Tower,Paris,France&zoom=14&size=640x640&scale=2&language=en-EN&key=AIzaSyAY4gcXw6gp_mlQ8qKisL5sE23LMC1MM9U&signature=JR7YxKgwk7gQjqhYWu3NFhydsW8=```  
**```PS> Set-SecretKey "jdW0fdx88bGYVwTCxIjWSpBJMoo="```***  
```$secretKey has been set```  
**```PS> $signed_url = Protect-StaticUrl $signed_url```**  
**```PS> $signed_url```**  
```https://maps.googleapis.com/maps/api/staticmap?center=Eiffel+Tower,Paris,France&zoom=14&size=640x640&scale=2&language=en-EN&key=AIzaSyAY4gcXw6gp_mlQ8qKisL5sE23LMC1MM9U&signature=BhiRbuHKA-9TBW1kmeitFN1ObuA=```  

---  

## Test-StaticUrl
If the URL is missing a required Static Maps parameter, such as the &size= parameter, the signStaticUrl function will return an error:  
**```PS> $badUrl = "https://maps.googleapis.com/maps/api/staticmap?center=Eiffel+Tower,Paris,France&zoom=14&scale=2&language=en-EN&key=AIzaSyAY4gcXw6gp_mlQ8qKisL5sE23LMC1MM9U"```**  

**```PS> signStaticUrl $badUrl```**  
```signStaticUrl: Invalid Static URL:```  
```signStaticUrl: >> https://maps.googleapis.com/maps/api/staticmap?center=Eiffel+Tower,Paris,France&zoom=14&scale=2&language=en-EN&key=AIzaSyAY4gcXw6gp_mlQ8qKisL5sE23LMC1MM9UsignStaticUrl: use: 'Test-StaticUrl <URL> -Verbose' for more information```  
![run signStaticUrl on a URL missing a required parameter creates an error](./08-badUrl.png)  

As the error message notes, you can use ```Test-StaticUrl``` with the ```-Verbose``` parameter for more information:  
**```PS> Test-StaticUrl $badUrl```**  
```VERBOSE: URL being tested:VERBOSE: https://maps.googleapis.com/maps/api/staticmap?center=Eiffel+Tower,Paris,France&zoom=14&scale=2&language=en-EN&key=AIzaSyAY4gcXw6gp_mlQ8qKisL5sE23LMC1MM9U```  
```VERBOSE: URL must include a size parameter like "&size=640x400```  
![use Test-StaticUrl $badUrl -Verbose to get an idea of the problem](./09-TestUrl.png)

---

## Using signStaticUrl and Test-StaticUrl in pipelines
The ```signStaticUrl``` function, its aliases, and the ```Test-StaticUrl``` function can be used in a PowerShell pipeline.  

For example, if you have a list of Static Maps URLs in a text file:
![list the URLs in unsignedUrls.txt.png](./10-unsignedUrls.txt.png)
You can use:  
**```Get-Content ./unsignedURLs.txt | Protect-StaticUrl```**  
to sign each URL  
![Get the URLs and run Protect-StaticUrl in a PowerShell pipeline](./11-Get-Content.png)  

Of course, you can redirect the signed URLs to a new file:  
**```Get-Content ./unsignedURLs.txt | Protect-StaticUrl >signedURLs.txt```**  

---  

## Using signStaticUrl on objects in a pipeline
If you have a .CSV file containing lines of data about a number of locations (including a URL field in each row), you can use PowerShell's ```ForEach-Object```, ```Import-CSV``` and ```Export-CSV``` commands with ```signStaticUrl``` to create a new .CSV file with signed URLs.  

For example, if you have a ```locations.csv``` file with a list of retail locations, each with a store_number and a map_URL field, you can create ```locations_with_signature.csv``` using:  

**```PS > Import-Csv ./locations.csv |  ```**  
**```>> ForEach-Object {```**  
**```>> $_.map_url = signStaticUrl $_.map_url;  $_```**  
**```>> } | Export-Csv ./locations_with_signature.csv```**  

---