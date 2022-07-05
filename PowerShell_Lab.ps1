<#
    .SYNOPSIS
    Calculates population density of entireworld population in selected country

    .DESCRIPTION
    Retrieves CIA World Factbook data from github as json
    Processes json data and gets total world population
	Processes json data and gets list of available country names with data
	Presents list of countries onscreen for selection
	Processes json data and gets area of country selected
    Calculates area per person if entire world lived in that country
	Outputs details to screen in using square meters and square feet

    .PARAMETER CountryName
    Specifies the name of a country to lookup in the json data, if no match found user will be presented with list

    .OUTPUTS
    Screen as text

    .EXAMPLE
    PS> .\Get-PopulationDensity.ps1 -CountryName "ireland"
    Retrieves CIA World Factbook data from github as json
    Processes json data and gets total world population
	Processes json data and gets list of available country names with data
	Processes json data looking for country name matching "ireland", if not found presents list of countries onscreen for selection
	Processes json data and gets area of country selected
    Calculates area per person if entire world lived in that country
	Outputs details to screen in using square meters and square feet

    .EXAMPLE
    PS> .\Get-PopulationDensity.ps1
    Retrieves CIA World Factbook data from github as json
    Processes json data and gets total world population
	Processes json data and gets list of available country names with data
	Presents list of countries onscreen for selection
	Processes json data and gets area of country selected
    Calculates area per person if entire world lived in that country
	Outputs details to screen in using square meters and square feet

#>

Param(
    #Parameter that can be modified to control which resource groups this runs against
    [Parameter(
        Mandatory=$false,
        HelpMessage="Enter the name of a country to calculate wolrd population density in that country"    
        )
    ]
    [String]
    $CountryName = ""
)


#CIA World Factbook and population density
#https://www.cia.gov/the-world-factbook/
#The World Factbook provides basic intelligence on the history, people, government, economy, energy, geography, environment, communications, transportation, military, terrorism, and transnational issues for 266 world entities.

#We are using Ian Coleman's resources to do this work
#https://github.com/iancoleman/cia_world_factbook_api

#Get it as JSON - https://github.com/iancoleman/cia_world_factbook_api/raw/master/data/factbook.json

#Using references from https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.utility/invoke-webrequest?view=powershell-7.0

$URI = "https://github.com/iancoleman/cia_world_factbook_api/raw/master/data/factbook.json"

Write-Host "Getting data from $($URI)"

$CIAFactsWeb = (Invoke-WebRequest -uri $URI -UseBasicParsing )

$CIAFacts = $CIAFactsWeb.Content | ConvertFrom-JSON

#establish data type, because we want to do math
#$CIAFacts.countries.world.data.people.population.total |get-member

$WorldPopulation = $CIAFacts.countries.world.data.people.population.total

$CountryNames = ($CIAFacts.countries | get-member | where-object{$_.MemberType -like "NoteProperty"}).name

if($CountryName -notlike ""){
	#test if countryname exists in data using an array to ensure a single match
	$testexists = @($CountryNames | where-object{$_ -like $CountryName})
	if($testexists.count -ne 1){$CountryName = ($CountryNames | out-gridview -PassThru -Title "Select a country from the list").ToLower()}
}else{
	$CountryName = ($CountryNames | out-gridview -PassThru -Title "Select a country from the list").ToLower()
}

Write-Host "$($CountryName) selected"

#establish data type, because we want to do math
#$CIAFacts.countries.$CountryName.data.geography.area.land.value |get-member

#Conversion factor from km to m2 = 1000000
$ConversionFactorKm2M2 = 1000000

#Conversion factor from m2 to ft2 = 10.7639
$ConversionFactorM2F2 = 10.7639

$CountryAreaM2 = (($CIAFacts.countries.$CountryName.data.geography.area.land.value) * $ConversionFactorKm2M2)

$DensityM2P = ($CountryAreaM2 / $WorldPopulation)
$DensityF2P = ($DensityM2P * $ConversionFactorM2F2)

Write-Host "World Population is $($WorldPopulation)"
Write-Host "Area of $($CountryName.substring(0,1).toupper())$($CountryName.substring(1).tolower()) is $($CountryAreaM2/$ConversionFactorKm2M2) square Km"

Write-Host "The number of square meters per person if everyone lived in $($CountryName.substring(0,1).toupper())$($CountryName.substring(1).tolower()): $(([Math]::Round($DensityM2P, 2)).tostring())" -foregroundcolor red
Write-Host "The number of square feet per person  if everyone lived in $($CountryName.substring(0,1).toupper())$($CountryName.substring(1).tolower()): $(([Math]::Round($DensityF2P, 2)).tostring())" -foregroundcolor yellow