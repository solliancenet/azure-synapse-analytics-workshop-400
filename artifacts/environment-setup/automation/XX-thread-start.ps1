$lines = Get-content c:\temp\Synapse\usernames.txt;

foreach($line in $lines)
{
    $vals = $line.split("`t")
    $username = $vals[0];
    $password = $vals[1];
    
    $cmd = "-File `"C:\github\solliancenet\azure-synapse-analytics-workshop-400\artifacts\environment-setup\automation\06-environment-poc-01-delta.ps1`" -username `"$username`" -password `"$password`"";
    start-process powershell -argument $cmd;
}
    
