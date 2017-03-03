function Get-ADSIOrganizationalUnit
{
<#
.SYNOPSIS
	This function will query Active Directory for Organization Unit Objects

.DESCRIPTION
	This function will query Active Directory for Organization Unit Objects

.PARAMETER Name
	Specify the Name of the OU
	
.PARAMETER DistinguishedName
	Specify the DistinguishedName path of the OU
	
.PARAMETER All
	Will show all the OU in the domain
	
.PARAMETER GroupPolicyInheritanceBlocked
	Will show only the OU that have Group Policy Inheritance Blocked enabled.
	
.PARAMETER Credential
    Specify the Credential to use
	
.PARAMETER DomainDistinguishedName
    Specify the DistinguishedName of the Domain to query
	
.PARAMETER SizeLimit
    Specify the number of item(s) to output
	
.EXAMPLE
	Get-ADSIOrganizationalUnit

    This returns all the OU in the Domain (Result Size is 100 per default)

.EXAMPLE
	Get-ADSIOrganizationalUnit -name FX

    This returns the OU with the name FX

.EXAMPLE
	Get-ADSIOrganizationalUnit -name FX*

    This returns the OUs where the name starts by FX

.NOTES
	Francois-Xavier Cat
	LazyWinAdmin.com
	@lazywinadm
	github.com/lazywinadmin/AdsiPS
#>
	[CmdletBinding(DefaultParameterSetName = "All")]
	PARAM (
		[Parameter(ParameterSetName = "Name")]
		[System.String]$Name,
		
		[Parameter(ParameterSetName = "DistinguishedName")]
		[System.String]$DistinguishedName,
		
		[Parameter(ParameterSetName = "All")]
		[System.String]$All,
		
		[System.Management.Automation.SwitchParameter]$GroupPolicyInheritanceBlocked,
		
		[Parameter(ValueFromPipelineByPropertyName = $true)]
		[Alias("Domain", "DomainDN")]
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
			
			
			If ($Name)
			{
				$Search.filter = "(&(objectCategory=organizationalunit)(name=$Name))"
				IF ($psboundparameters["GroupPolicyInheritanceBlocked"])
				{
					$Search.filter = "(&(objectCategory=organizationalunit)(name=$Name)(gpoptions=1))"
				}
			}
			IF ($DistinguishedName)
			{
				$Search.filter = "(&(objectCategory=organizationalunit)(distinguishedname=$distinguishedname))"
				IF ($psboundparameters["GroupPolicyInheritanceBlocked"])
				{
					$Search.filter = "(&(objectCategory=organizationalunit)(distinguishedname=$distinguishedname)(gpoptions=1))"
				}
			}
			IF ($all)
			{
				$Search.filter = "(&(objectCategory=organizationalunit))"
				IF ($psboundparameters["GroupPolicyInheritanceBlocked"])
				{
					$Search.filter = "(&(objectCategory=organizationalunit)(gpoptions=1))"
				}
			}
			IF ($DomainDistinguishedName)
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
			If (-not $PSBoundParameters["SizeLimit"])
			{
				Write-Warning -Message "Default SizeLimit: 100 Results"
			}
			
			foreach ($ou in $($Search.FindAll()))
			{
				# Define the properties
				#  The properties need to be lowercase!!!!!!!!
				$Properties = @{
					"Name" = $ou.properties.name -as [System.String]
					"DistinguishedName" = $ou.properties.distinguishedname -as [System.String]
					"ADsPath" = $ou.properties.adspath -as [System.String]
					"ObjectCategory" = $ou.properties.objectcategory -as [System.String]
					"ObjectClass" = $ou.properties.objectclass -as [System.String]
					"ObjectGuid" = $ou.properties.objectguid
					"WhenCreated" = $ou.properties.whencreated -as [System.String] -as [datetime]
					"WhenChanged" = $ou.properties.whenchanged -as [System.String] -as [datetime]
					"usncreated" = $ou.properties.usncreated -as [System.String]
					"usnchanged" = $ou.properties.usnchanged -as [System.String]
					"dscorepropagationdata" = $ou.properties.dscorepropagationdata
					"instancetype" = $ou.properties.instancetype -as [System.String]
				}
				
				# Output the info
				New-Object -TypeName PSObject -Property $Properties
			}
		}#TRY
		CATCH
		{
			$PSCmdlet.ThrowTerminatingError($_)
		}
	}#PROCESS
	END
	{
		Write-Verbose -Message "[END] Function Get-ADSIOrganizationalUnit End."
	}
}