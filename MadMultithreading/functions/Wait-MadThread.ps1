function Wait-MadThread
{
<#
	.SYNOPSIS
		Wait for given threads to complete, optionally disposing of them
	
	.DESCRIPTION
		Wait for given threads to complete, optionally disposing of them
	
	.PARAMETER Thread
		Array of custom objects containing the PowerShell, Handler and Runspace for each thread to wait for
		Required
	
	.PARAMETER NoDispose
		Switch - If present, the PowerShell and Runspace objects are not disposed of after completion
	
	.PARAMETER TimeoutSeconds
		Int32 - Maximum number of seconds to
	
	.NOTES
		v 1.0  4/30/18  Tim Curwick  Created
#>
	[cmdletbinding()]
	Param (
		[array]
		$Thread,
		
		[switch]
		$NoDispose
	)
	
	While ($Thread.Handler.IsCompleted -contains $False)
	{
		Start-Sleep -Milliseconds 200
	}
	
	If (-not $NoDispose)
	{
		$Thread.PowerShell.Dispose()
		$Thread.RunspacePool.Dispose()
	}
}
