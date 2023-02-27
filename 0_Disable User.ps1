#Allowing script to run
Set-ExecutionPolicy Bypass -scope Process -Force

#getting the username to disable and make sure it is the right one
while($val -ne 'y')
{
    $shortname= Read-Host -Prompt "Enter username to disable (without prefix)"
    $fullname = $shortname+"@bdo.co.il"
    #making sure the user does really exist
try {
    Get-ADUser -Identity $shortname | Select-Object name
}
catch [Microsoft.ActiveDirectory.Management.ADIdentityResolutionException] {
    Write-Host "Error: User does not exist. Plese reopen the program"-ForegroundColor White -BackgroundColor DarkCyan
    Start-Sleep -Seconds 3
    Exit
}
    Write-Host "Please make sure selected user to disable is:" -ForegroundColor White -BackgroundColor DarkCyan
    #getting the user first and last name
    $dispName = Get-ADUser -Identity $shortname | Select-Object name |Format-List |Out-String 
    $dispName = $dispName.replace("name : ","")
    Write-Host $dispName -ForegroundColor White -BackgroundColor DarkCyan
    Write-Host "y   to confirm, else  to exit:" -ForegroundColor White -BackgroundColor DarkCyan
    $val= Read-Host 
    if(($val -ne 'y') -or ($val -ne 'Y')){
        Exit
    }
}

#setting the string for the results text file
$textFileOutput = "Disabled on:   "+(Get-Date)+"      By:   "+($env:UserName)
$textFileOutput +="`n"+"`n"+"For user:  "+ $fullname+"`n"
$textFileOutput +="Groups which were removed:"+"`n"
$textFileOutput += Get-ADPrincipalGroupMembership $shortname | Select-Object name |Out-String
$textFileOutput | Out-File -FilePath C:\Users\Omer\Desktop\$shortname.txt #dummy path
Start-Sleep 1

#Remove user groups membership
Write-Host "Ignore the error which says cannot remove the user's primary group"-ForegroundColor White -BackgroundColor DarkCyan
Get-ADPrincipalGroupMembership $shortname | ForEach-Object {Remove-ADGroupMember $_ -Members $shortname -Confirm:$false}
Write-Host "Removing Groups completed" -ForegroundColor Green -BackgroundColor Black
Start-Sleep 3

#Move user OU based on current date
$Date = Get-Date
$month = $Date.month
$Year = $Date.year
Get-ADUser -Identity $shortname | Move-ADObject -TargetPath "OU=$Month,OU=$Year,OU=permanent,OU=Disabled,OU=OUs,DC=bdo,DC=co,DC=il"
Write-Host "Moving to disable OU completed" -ForegroundColor Green -BackgroundColor Black

#Disable user
Disable-ADAccount -Identity $shortname
Write-Host "Disableing user completed" -ForegroundColor Green -BackgroundColor Black

#Connect to 365 PowerShell and start litigation hold
Write-Host "connecting to Exchange Online"-ForegroundColor White -BackgroundColor DarkCyan
    Connect-ExchangeOnline
    Set-Mailbox $fullname -LitigationHoldEnabled $true
    Write-Host "Enabling litigation hold completed (might take up to 4 hours)" -ForegroundColor Green -BackgroundColor Black

    
    Write-Host "-!-!-!- Disabling proccess completed -!-!-!-" -ForegroundColor Green -BackgroundColor Black
    Start-Sleep 2
    Exit