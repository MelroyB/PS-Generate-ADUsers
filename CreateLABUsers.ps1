# Global variables
# User properties
$ou = "OU=Users,OU=LAB,DC=lab,DC=local"        # Which OU to create the users in
$orgShortName = "LAB"                          # This is used to build a user's sAMAccountName
$dnsDomain = "lab.local"                       # Domain is used for e-mail address and UPN
$company = "LAB"                               # Used for the user object's company attribute
$departments = (                               # Departments and associated job titles to assign to the users
                  @{"Name" = "Finance & Accounting"; Positions = ("Manager", "Accountant", "Data Entry")},
                  @{"Name" = "Human Resources"; Positions = ("Manager", "Administrator", "Officer", "Coordinator")},
                  @{"Name" = "Sales"; Positions = ("Manager", "Representative", "Consultant")},
                  @{"Name" = "Marketing"; Positions = ("Manager", "Coordinator", "Assistant", "Specialist")},
                  @{"Name" = "Engineering"; Positions = ("Manager", "Engineer", "Scientist")},
                  @{"Name" = "Consulting"; Positions = ("Manager", "Consultant")},
                  @{"Name" = "IT"; Positions = ("Manager", "Engineer", "Technician")},
                  @{"Name" = "Planning"; Positions = ("Manager", "Engineer")},
                  @{"Name" = "Contracts"; Positions = ("Manager", "Coordinator", "Clerk")},
                  @{"Name" = "Purchasing"; Positions = ("Manager", "Coordinator", "Clerk", "Purchaser")}
               )

# Other parameters
$userCount = 1500                         # How many users to create

# Files used
$firstNameFile = "Firstnames.txt"            # Format: FirstName
$lastNameFile = "Lastnames.txt"              # Format: LastName
$passwordsFile = "Passwords.txt"
$employeeNumber = 1000                       # Startnumber






function get-sanitizedUTF8Input{
    Param(
        [String]$inputString
    )
    $replaceTable = @{"ß"="ss";"Ş"="S";"à"="a";"á"="a";"â"="a";"ã"="a";"ä"="a";"å"="a";"æ"="ae";"ç"="c";"è"="e";"é"="e";"ê"="e";"ë"="e";"ì"="i";"í"="i";"î"="i";"ï"="i";"ð"="d";"ñ"="n";"ò"="o";"ó"="o";"ô"="o";"õ"="o";"ö"="o";"ø"="o";"ù"="u";"ú"="u";"û"="u";"ü"="u";"ý"="y";"þ"="p";"ÿ"="y"}

    foreach($key in $replaceTable.Keys){
        $inputString = $inputString -Replace($key,$replaceTable.$key)
    }
    $inputString = $inputString -replace '[^a-zA-Z0-9]', ''
    return $inputString
}


Set-StrictMode -Version 2
Import-Module ActiveDirectory
"[+] Imported AD."
Push-Location (Split-Path ($MyInvocation.MyCommand.Path))

#get current error preferences
$currentErrorPref = $ErrorActionPreference
#set error preferences to silentlycontinue
$ErrorActionPreference = "SilentlyContinue"

# Read input files
$FirstNames = Import-CSV $firstNameFile
"[+] Loaded first names file."
$LastNames = Import-CSV $lastNameFile
"[+] Loaded last names file."
$Passwords = gc $passwordsFile
"[+] Loaded password file."


# Create sub OU's for departments
foreach ($department in $departments){
$Depname = $department.Name 
$departmentOU = "OU=$Depname,$OU"
    if (Get-ADOrganizationalUnit -Filter "distinguishedName -eq '$departmentOU'") {
      Write-Host "$departmentOU already exists."
    } else {
      New-ADOrganizationalUnit -Name $Depname -Path $OU
    }
}


# Create Users
$i = 1
#tell us what it's doing
Write-Host "Creating $($userCount) users..."
#run until the number of accounts provided via the numberofusers param are created
do
{
$fname = $FirstNames | Get-Random
$firstname = $fname.Firstname
$FirstChar = [char[]]$FirstName[0]
$lname = $LastNames | Get-Random
$lastname = $lname.Lastname
$passw = $Passwords | Get-Random
$samAccountName = $FirstChar + "." + $lastname


$samAccountName = get-sanitizedUTF8Input -inputString $samAccountName
$password = ConvertTo-SecureString $passw -AsPlainText -Force
$name = $firstname + " " + $lastname
#$description = $password
 


 			# Department & title
			$departmentIndex = Get-Random -Minimum 0 -Maximum $departments.Count
			$department = $departments[$departmentIndex].Name
			$title = $departments[$departmentIndex].Positions[$(Get-Random -Minimum 0 -Maximum $departments[$departmentIndex].Positions.Count)]




$ouUser = "OU=$department,$ou"



New-ADUser -SamAccountName $samAccountName -UserPrincipalName "$sAMAccountName@$dnsDomain" -Name $name -GivenName $firstname -Surname $lastname -DisplayName $name -Company $company -Department $department -Title $title -EmployeeNumber $employeeNumber -EmailAddress "$samAccountName@$dnsDomain" -AccountPassword $password  -Path $ouUser -Enabled $true -PasswordNeverExpires $true -ChangePasswordAtLogon $false -ErrorAction SilentlyContinue -ErrorVariable err
Write-host "User: $i"
Write-host "Created User: $name"Write-host " Logon      : $samAccountName"Write-host " Password   : $passw"Write-host " Department : $department"
Write-host " Title      : $title"
Write-host " Employee   : $employeeNumber"

$percentage=($i/$userCount)*100
Write-Progress -Activity "Create user: $i / $userCount"  -PercentComplete $percentage
		
			$employeeNumber = $employeeNumber+1

$i++
}
#run until numberofusers are created
while ($i -le $userCount)
#set erroractionprefs back to what they were
$ErrorActionPreference = $currentErrorPref
