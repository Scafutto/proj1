# Initialize an empty array to store usernames
$usernames = @()

# Specify the path to your CSV file
$csvFilePath = 'C:\Users\scafutto\Desktop\ous.csv'

# Import the CSV data
$csvData = Import-Csv -Path $csvFilePath

# Loop through each element in the first column
foreach ($parentOU in ($csvData | Select-Object -ExpandProperty 'OU' -Unique)) {
    Write-Output "Parent OU: $parentOU"
    Write-Output "------------------"

    # Output the command to create the parent OU
    Write-Output "New-ADOrganizationalUnit -Name `"$parentOU`" -Path 'DC=netw2500ms,DC=local'"

    # Create an array to store unique values from the second column where the first column matches the current element
    $groupNames = $csvData | Where-Object { $_.OU -eq $parentOU } | Select-Object -ExpandProperty 'Department' -Unique
    
    # Loop through each group and output the corresponding command
    foreach ($groupName in $groupNames) {
        Write-Output "Group: $groupName"
        Write-Output "------------------"
        Write-Output "New-ADGroup -Name `"$groupName`" -Path 'OU=`"$parentOU`",DC=netw2500ms,DC=local' -GroupScope Global -GroupCategory Security"

        # Nested loop to consider lines where both Column1 and Column2 match the current parentOU and groupName
        foreach ($entry in $csvData) {
            if ($entry.OU -eq $parentOU -and $entry.Department -eq $groupName) {
                # Extract first name and change last name to have only the first letter capitalized
                $fullName = $entry.Employee
                $firstName = ($fullName -split " ")[0]
                $lastName = ($fullName -split " ")[1]

                # Capitalize the first letter of the last name
                $lastName = $lastName.Substring(0,1).ToUpper() + $lastName.Substring(1).ToLower()

                # Create a username based on the initial letter and surname
                $username = $firstName.Substring(0,1).ToLower() + $lastName.ToLower()

                if ($usernames -contains $username) {
                    Write-Output "`"$username already exists`""
                }

                $usernames += $username

                # Output the command to create the user account
                # Write-Output "New-ADUser -SamAccountName `"$username`" -UserPrincipalName `"$username@netw2500ms.local`" -Name `"$fullName`" -GivenName `"$firstName`" -Surname `"$lastName`" -Enabled $true -ChangePasswordAtLogon $true -Path 'OU=`"$parentOU`",DC=netw2500ms,DC=local' -AccountPassword (ConvertTo-SecureString 'Password1' -AsPlainText -Force) -Server 'YourDomainController' -ErrorAction Stop"

                # Output the command to add the user to the group
                # Write-Output "Add-ADGroupMember -Identity `"$groupName`" -Members `"$username`" -Server 'YourDomainController' -ErrorAction Stop"
            }
        }
    }

    Write-Output "----------------------"
}
