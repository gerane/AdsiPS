function Get-ADSIObject
{
<#
.SYNOPSIS
	This function will query any kind of object in Active Directory

.DESCRIPTION
	This function will query any kind of object in Active Directory

.PARAMETER  SamAccountName
	Specify the SamAccountName of the object.
	This parameter also search in Name and DisplayName properties
	Name and Displayname are alias.

.PARAMETER  DistinguishedName
	Specify the DistinguishedName of the object your are looking for
	
.PARAMETER Credential
    Specify the Credential to use

.PARAMETER DomainDistinguishedName
    Specify the DistinguishedName of the Domain to query
	
.PARAMETER SizeLimit
    Specify the number of item(s) to output
	
.EXAMPLE
	Get-ADSIObject -SamAccountName Fxcat

.EXAMPLE
	Get-ADSIObject -Name DC*
	
.NOTES
	Francois-Xavier Cat
	LazyWinAdmin.com
	@lazywinadm
	github.com/lazywinadmin/AdsiPS
#>
	
	[CmdletBinding()]
	PARAM (
		[Parameter(ParameterSetName = "SamAccountName")]
		[Alias("Name", "DisplayName")]
		[System.String]$SamAccountName,
		
		[Parameter(ParameterSetName = "DistinguishedName")]
		[System.String]$DistinguishedName,
		
		[Parameter(ValueFromPipelineByPropertyName = $true)]
		[Alias("Domain", "DomainDN", "SearchRoot", "SearchBase")]
		[System.String]$DomainDistinguishedName = $(([adsisearcher]"").Searchroot.path),
		
		[Alias("RunAs")]
		[System.Management.Automation.PSCredential]
		[System.Management.Automation.Credential()]
		$Credential = [System.Management.Automation.PSCredential]::Empty,
		
		[Alias("ResultLimit", "Limit")]
		[int]$SizeLimit = '100'
	)
	BEGIN { }
	PROCESS
	{
		TRY
		{
			# Building the basic search object with some parameters
			$Search = New-Object -TypeName System.DirectoryServices.DirectorySearcher -ErrorAction 'Stop'
			$Search.SizeLimit = $SizeLimit
			$Search.SearchRoot = $DomainDistinguishedName
			
			IF ($PSBoundParameters['SamAccountName'])
			{
				$Search.filter = "(|(name=$SamAccountName)(samaccountname=$SamAccountName)(displayname=$samaccountname))"
			}
			IF ($PSBoundParameters['DistinguishedName'])
			{
				$Search.filter = "(&(distinguishedname=$DistinguishedName))"
			}
			IF ($PSBoundParameters['DomainDistinguishedName'])
			{
				IF ($DomainDistinguishedName -notlike "LDAP://*") { $DomainDistinguishedName = "LDAP://$DomainDistinguishedName" }#IF
				Write-Verbose -Message "Different Domain specified: $DomainDistinguishedName"
				$Search.SearchRoot = $DomainDistinguishedName
			}
			IF ($PSBoundParameters['Credential'])
			{
				$Cred = New-Object -TypeName System.DirectoryServices.DirectoryEntry -ArgumentList $DomainDistinguishedName, $($Credential.UserName), $($Credential.GetNetworkCredential().password)
				$Search.SearchRoot = $Cred
			}
			
			foreach ($Object in $($Search.FindAll()))
			{
				# Define the properties
				#  The properties need to be lowercase!!!!!!!!
				$Properties = @{
					"DisplayName" = $Object.properties.displayname -as [System.String]
					"Name" = $Object.properties.name -as [System.String]
					"ObjectCategory" = $Object.properties.objectcategory -as [System.String]
					"ObjectClass" = $Object.properties.objectclass -as [System.String]
					"SamAccountName" = $Object.properties.samaccountname -as [System.String]
					"Description" = $Object.properties.description -as [System.String]
					"DistinguishedName" = $Object.properties.distinguishedname -as [System.String]
					"ADsPath" = $Object.properties.adspath -as [System.String]
					"LastLogon" = $Object.properties.lastlogon -as [System.String]
					"WhenCreated" = $Object.properties.whencreated -as [System.String]
					"WhenChanged" = $Object.properties.whenchanged -as [System.String]
				}
				
				# Output the info
				New-Object -TypeName PSObject -Property $Properties
			}
		}
		CATCH
		{
			$PSCmdlet.ThrowTerminatingError($_)
		}
	}
	END
	{
		Write-Verbose -Message "[END] Function Get-ADSIObject End."
	}
}