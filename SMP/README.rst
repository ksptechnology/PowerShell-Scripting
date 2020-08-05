Service Monitor Plus
====================
*Service Monitor Plus (SMP)* is a PowerShell project created to keep watch over services on remote computers. When a service is stopped, it will attempt to restart it, and send email reports according to your configuration. It was created because following a reboot, there are a ton of servers in our network that don’t restart their services, even if they are *supposed* to be automatic. Rather than actually fix the issues, we opted to work around them instead

The scripts can be found in our Github repo_ or on the scripting drive at Z:\\SMP. The project provides two different scripts:

.. _repo: https://github.com/ksptechnology/PowerShell-Scripting/tree/master/SMP

  **Config-Browser.ps1** provides a simple GUI for managing config files. By default, the files are stored in the config directory relative to the scripts’ location. This should be sufficient 95% of the time, but the location can be changed by modifying the *config.json* file

  **service_monitor_plus.ps1** is the process that will actually monitor the services. Unless you have the ability to connect to     remote systems (which in our environment, *you won’t* unless you run it as a domain admin), this script is not meant to be run by hand without some tinkering. It also uses the *config.json* file by default to specify the config file location

============
Service Sets
============
The scripts work with the concept of *Service Sets*. The sets contain both a list of *services* and a list of *targets* which should be checked for the specified services. If all services on all targets are started when the monitor is run, nothing will happen. If a single service on a single target is not started, an email report with details of the service and target will be sent out with a transcript of the action taken on the remote computer

Service sets are stored as plain *.json* files in the default config directory. Though it’s possible to create/modify sets via these files directly, because they’re easy to misconfigure, the **Config-Browser.ps1** GUI was created to cut down on mistakes. As error reporting in the SMP script is admittedly lacking, it’s strongly advised to use this tool only. You’ve been warned

======================================
Modifying the default config directory
======================================
The config directory is by default in the same directory as the running script. To change this, simply modify the *ConfigDir* property of the file. There are a few things to keep in mind when doing this:

-  You **must** use the **full path** to the config directory; relative paths will not work. For local folders, this may be something like *‘E:\\scripts\\SMP\\config’*. For network folders, this may be something like *‘\\\\myserver\\SMP$\\config’*

- The desired location can only be a folder on the local server, or an SMB-shared folder available across the network to the server

In either case, the user configured to automatically run the script must have *read/write NTFS effective* access to the config folder. If the folder is a network share being accessed with a UNC path, the user must also be granted *read/write share permissions*

==========
Deployment
==========
SMP is meant to be deployed via a Scheduled Task on a server with network access to all servers being monitored. It must run as a domain/network user with the rights to connect to remote machines, likely a Domain Admin in your environment

Once configured, you can set it to run as often as required. If configured properly, the task can also be started by hand to run if new sets are created. This is preferable to running the script from your own elevated PowerShell session

=====
Notes
=====
Currently, if a set monitors a target for a service that does not exist, no action is taken. The only report of this misconfiguration is PowerShell errors logged in the transcript, which is only sent out if there are actual service errors found, and which will most likely be overlooked. Be careful and test thoroughly when creating or configuring service sets

============ ======== ============
Modified by: Date:    Description:
------------ -------- ------------
Dallas Young 07/30/20 Creation
============ ======== ============
