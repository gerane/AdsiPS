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
		$FunctionContent = Get-Content function:$funct
		$AST = [System.Management.Automation.Language.Parser]::ParseInput($FunctionContent, [ref]$null, [ref]$null)
		
		Context "$funct - Help"{
			
			# Parameters separated by a space
			$ParamText = $AST.ParamBlock.extent.text -split '\r\n' # split on carriage return
			$ParamText = $ParamText.trim() # Trim the edges
			$ParamTextSeparator = $ParamText | select-string ',$' #line that finish by a ','
			
			if ($ParamTextSeparator)
			{
				Foreach ($ParamLine in $ParamTextSeparator.linenumber)
				{
					it "Parameter - Separated by space (Line $ParamLine)"{
						$ParamText[$ParamLine] -match '^$|\s+' | Should Be $true
					}
				}
			}
		} #Context
	} #FOREACH
} #Describe
