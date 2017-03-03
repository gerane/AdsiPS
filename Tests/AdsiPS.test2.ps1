[CmdletBinding()]
PARAM (
	$ModuleName = "ADSIPS",
	$GithubRepository = "github.com/lazywinadmin/"
)

# Make sure one or multiple versions of the module are note loaded
Get-Module -Name $ModuleName | remove-module

# Find the Manifest file
$ManifestFile = "$(Split-path (Split-Path -Parent -Path $MyInvocation.MyCommand.Definition))\$ModuleName\$ModuleName.psd1"

# Import the module and store the information about the module
$ModuleInformation = Import-module -Name $ManifestFile -PassThru

# Get the functions present in the Manifest
$ExportedFunctions = $ModuleInformation.ExportedFunctions.Values.name

# Testing the Module
Describe "$ModuleName Module - HELP" -Tags "Module" {
	#$Commands = (get-command -Module ADSIPS).Name
	
	FOREACH ($funct in $ExportedFunctions)
	{
		# Retrieve the content of the current function
		$FunctionContent = Get-Content function:$funct
		
		Context "$funct - Comment Based Help - Indentation Checks"{
			
			# Validate Help start at the beginning of the line
			It "Help - Starts at the beginning of the line"{
				$Pattern = ".Synopsis"
				($FunctionContent -split '\r\n' | select-string $Pattern).line -match "^$Pattern" | Should Be $true
			}
		}
	}
}
