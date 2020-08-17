========
Aconitum
========
-----------
Wolf's Bane
-----------

In a Citrix XenDesktop environment when connecting networked files, BrokerWolf_ will often encounter errors when accessing networked resources, presenting users with *Error # 1104*. Typically, connectivity to the file server hosting the BrokerWolf database will have been interrupted, and there will be stale, opened SMB-shared files preventing the program from reading data correctly. The easiest fix for this is to have all users close their programs and close the open files by hand, and that is what **Aconitum** does

.. _BrokerWolf: https://www.lwolf.com/products/accounting-reporting/complete-back-office

Running the scripts
===================
When run, the *Fix-BrokerWolf.ps1* script will first attempt to kill any instances of running BrokerWolf processes. It will then connect to the remote file server, query for any open shared files, and close them. Following this, the desktop users should be able to launch the program successfully again

Because the *Fix-BrokerWolf.ps1* script will attempt to kill processes is does not own, it must be run as a local admin. You can do this yourself by opening an elevated PowerShell and running the script, but to make this easier, there is a simple *Run.ps1* script which will do this for you. When deployed, you can simply *Right-Click > Run with PowerShell* the *Run.ps1* script, and it should proceed without any issues

Deploying the scripts
=====================
Deploying the script is done in two parts:

 - Copying the **Aconitum** source folder to the target terminal server. This can be done by cloning our repo, uploading with FTP, copying with SMB, or any number of other methods

 - Creating the config file *(see below)*

Configuring the scripts
=======================
The *Fix-BrokerWolf.ps1* script relies on a JSON config file to run. You should never have to touch this config to just run the scripts, however you do have to create it yourself when deploying **Aconitum**. This file is located at ``<Aconitum source dir>\src\props.json`` and is not included in the repository

The simplest way to create this is to copy the provided *props_example.json* file and to rename it *props.json*. Its contents will then need to be configured to your environment:

 - **ProcessNames** is an array of the names of the BrokerWolf processes. Note that the *.exe* extension is omitted from the filenames
 - **FileServer** is the DNS hostname of the remote computer hosting the BrokerWolf database
 - **FolderPath** is the **absolute local** path to the ``lone wolf`` directory on the file server. These are the shared files that will have their orphaned SMB sessions closed

To our knowledge, the only processes that BrokerWolf starts are **lw.exe** and **lwrms.exe**. If this is incorrect, or if the program changes with updates, the config file's **ProcessNames** field will need to be updated

Notes
=====
 - Keep in mind that with JSON files, ``'\'`` characters must be escaped, so a Windows filepath of ``C:\BrokerWolf Installation\data\lone wolf`` must be configured as ``C:\\BrokerWolf Installation\\data\\lone wolf`` in the config
 - When deploying the scripts on a new server with ThreatLocker_, you may have to approve the scripts before they will run successfully. When doing so, use the existing application name **Aconitum**

.. _ThreatLocker: https://www.threatlocker.com/

============ ======== ============
Modified by: Date:    Description:
------------ -------- ------------
Dallas Young 08/14/20 Creation
============ ======== ============