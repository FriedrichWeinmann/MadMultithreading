function Start-MadOutputThread
{
<#
	.SYNOPSIS
		Start a thread to export items from given queues to given CSV files
	
	.DESCRIPTION
		Start a thread to export items from given queues to given CSV files
	
	.PARAMETER Reports
		Array of custom objects specifying the Queue and Path of each report
		Required for multiple reports
	
	.PARAMETER Queue
		The BlockingCollection to monitor
		Required for a single report
	
	.PARAMETER Path
		Full path and name of the output CSV file
		Required for a single report
	
	.NOTES
		v 1.0  4/30/18  Tim Curwick  Created
		v 1.1  5/23/18  Tim Curwick  Modified to collect all available objects in queue before exporting
		(Preventing chatty queue and inefficient disk writes from blocking other queues)
#>
	[cmdletbinding()]
	Param (
		[parameter(Mandatory = $True, ParameterSetName = 'Collection')]
		$Reports,
		
		[parameter(Mandatory = $True, ParameterSetName = 'Single')]
		$Queue,
		
		[parameter(Mandatory = $True, ParameterSetName = 'Single')]
		[string]
		$Path
	)
	
	#  If the Single parameter set is used
	#    Build $Reports from $Queue and $Path
	If ($PSCmdlet.ParameterSetName -eq 'Single')
	{
		$Reports = @(@{
			Queue = $Queue
			Path  = $Path
		})
	}
	
	##  Define script to run in the output thread
	
	$OutputThreadScript = {
        <#
            .PARAMETER Reports
                Array of custom objects specifying the Queue and Path of each report
                Required
        #>
		[cmdletbinding()]
		Param (
			[array]
			$Reports
		)
		
		#  Initialize collection
		$Items = [System.Collections.ArrayList]@()
		
		#  Initialize empty PSObject so we can use it as a ref variable
		$Item = [pscustomobject]@{ }
		
		#  While we're still watching for work...
		While ($Reports.ForEach{ $_.Queue.IsCompleted } -contains $False)
		{
			#  For each specified report...
			ForEach ($Report in $Reports)
			{
				#  Start with an empty bucket
				If ($Items)
				{
					$Items.Clear()
				}
				
				#  While there are items in the queue
				#    Take the item and add it to the collection
				While ($Report.Queue.TryTake([ref]$Item))
				{
					$Items.Add($Item)
				}
				
				#  If output items were received
				#    Export items to output file
				If ($Items)
				{
					$Items | Export-CSV -Path $Report.Path -Append -Force -Encoding UTF8 -NoTypeInformation
				}
			}
			
			#  Take a breath before checking for more items to process
			Start-Sleep -Milliseconds 200
		}
	}
	
	
	#  Create runspace pool
	$RunspacePool = [runspacefactory]::CreateRunspacePool(1, 1)
	$RunspacePool.Open()
	
	#  Start the output thread
	#  Return the thread object
	New-MadThread -ScriptBlockUnique $OutputThreadScript -RunspacePoolUnique $RunspacePool -ParametersUnique @{ Reports = $Reports }
}
