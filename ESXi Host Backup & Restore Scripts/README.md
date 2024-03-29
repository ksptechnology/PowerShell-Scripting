# Outline
These scripts are used to backup the ESXi config on all the hosts managed by KSP

# How It Works
## Daily Backup Task
- hosts.bat contains all the host addresses and different root passwords
- Hosts need to have SSH enabled
- Currently runs from KSPFS02 as a scheduled task
- .bat files are stored in C:\scripts
- hosts.bat calls backupesxi.bat and pass the host address and root password
- backupesxi.bat will pull the config and store it as a .cfg file on KSPFS02 at "E:\KSPTECH\ftproot\esxibackup"

## Restoring Config
- Run restoreesxi.bat with two arguments:
    - First argument is the host address
    - Second argument is the root password for the host 
- Example:
```
 .\retoreesxi.bat 10.10.10.10 root-password
```

# Deployment
- Copy the .bat files to C:\scripts on the server which will run this script
- Ensure the required vmWare stuff is installed in the location expected by backupesxi.bat
- Update the dummy passwords in hosts.bat
    - Note that if a password contains the character '^' then it becomes a bit more tricky as that character needs to be escaped multiple times for it to work. You need a total of 8 ^ characacters in order for this to work properly. Therefore, if your password was "3qi^ogh" you would need to have the password in hosts.bat set to "3qi^^^^^^^^ogh". My best guess is that this is because the string gets interpreted multiple times. Your best bet for troubleshooting this is to just watch the script run and see what it is showing for the value of the password at runtime.

# Change Log
## 2022-06-27-MG
- Added a note on how to handle passwords that have ^ as a character in them

## 2022-06-24-MG
- Put this all into the git repo with sanitized credentials
- Updated hosts.bat with the new host addresses and removed old ones
- Changed backupesxi.bat to use two positional arguments, first for the host address and second for the root password
- Changed hosts.bat to declare variables for the passwords
- Changed restoreesxi.bat to require two positional arguments, first for the host address and second for the root password
