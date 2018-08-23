function New-MadThread
{
<#
	.SYNOPSIS
		Start given PowerShell script in a new thread
	
	.DESCRIPTION
		Start given PowerShell script in a new thread
	
	.PARAMETER ScriptBlockUnique
		ScriptBlock to run in the new thread
		Required
	
	.PARAMETER RunspacePoolUnique
		RunspacePool to use for the new thread
		Required
	
	.PARAMETER ParametersUnique
		Hashtable - Parameters for the new thread
	
	.PARAMETER UseEmbeddedParameters
		Switch
		If present, parameter names are derived from ScriptBlockUnique
		and parameter values are set to matching variable values.
		
		Matching variables must exist with correct values.
		
		Thread parameter names cannot be 'ScriptBlockUnique',
		'RunspacePoolUnique', 'ParametersUnique', or 'UseEmbeddedParameters'.
	
	.NOTES
		v 1.0  3/23/18  Tim Curwick  Created
		v 1.1  4/30/18  Tim Curwick  Added Runspace to return object
		v 1.2  8/ 1/18  Tim Curwick  Modified to improve performance from a module
#>
	[cmdletbinding(DefaultParameterSetName = 'Explicit')]
	param (
		[Parameter(Mandatory = $true)]
		[ScriptBlock]
		$ScriptBlockUnique,
		
		[Parameter(Mandatory = $true)]
		[System.Management.Automation.Runspaces.RunspacePool]
		$RunspacePoolUnique,
		
		[Parameter(Mandatory = $true, ParameterSetName = 'Explicit')]
		[Hashtable]
		$ParametersUnique,
		
		[Parameter(ParameterSetName = 'Implicit')]
		[Switch]
		$UseEmbeddedParameters
	)
	
	if ($UseEmbeddedParameters)
	{
		#  Build parameter hashtable
		$ScriptBlockUnique.Ast.ParamBlock.Parameters |
		ForEach-Object { $_.Name.ToString().Trim('$') } |
		ForEach-Object -Begin {
			$ParametersUnique = @{ }
		} -Process {
			$ParametersUnique += @{ $_ = $PSCmdlet.SessionState.PSVariable.GetValue($_) }
		}
	}
	
	#  Create thread
	$PowerShell = [PowerShell]::Create()
	$PowerShell.RunspacePool = $RunspacePoolUnique
	
	#  Add script
	[void]$PowerShell.AddScript($ScriptBlockUnique)
	
	#  Add parameters
	if ($ParametersUnique.Count)
	{
		[void]$PowerShell.AddParameters($ParametersUnique)
	}
	
	#  Start thread
	$Handler = $PowerShell.BeginInvoke()
	
	#  Return thread hooks
	[PSCustomObject]@{
		PowerShell   = $PowerShell
		Handler	     = $Handler
		RunspacePool = $RunspacePoolUnique
	}
}
