# Info

This script can be used to monitor a local Windows service. Copy it to
a server and install a scheduled task that runs it as often as you
need. When it detects that the service is stopped, it will try to
restart the service, and it will then send a notification to the
address(es) you specify in the list on _line 7_.

The results of the script are recorded with the Start-Transcript
command, and output is sent as an email attachment. `$temptranscript` is
the file that will hold the most recent job's log, `$transcript` holds a
history of all jobs. Delete this file if it gets too large and you
don't need the logs. 

# Customization

Currently, you don't need to reconfigure anything below _line 24_,
except for the email message's body. That is configured on _line
67_. When I have time, I'll think of a better way to handle this

