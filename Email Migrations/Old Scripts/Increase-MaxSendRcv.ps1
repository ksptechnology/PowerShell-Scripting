function Increase-MaxSendRcv([bool]$whatif = $false) {
    #================================================================================================================================================#
    #                                                                                                                     | Increase Send/Receive    #
    #                                                                                                                     | Limits                   #
    #================================================================================================================================================#

    ##################################################################################
    # HowTo, Step 3b                                                                 #
    # \\kspad06\c$\Scripts\O365\increase max send and receive.ps1                    #
    ##################################################################################

    $mailbox_stats_csv_name = "o365_mailbox_stats.csv"
    $mailbox_stats_csv_path = "."
    $mailbox_stats_csv_fullpath = "${mailbox_stats_csv_path}\${mailbox_stats_csv_name}"
    # TODO(dallas): What's the point of this information?
    Get-O365Mailbox | sort Alias | Get-O365MailboxStatistics | select DisplayName, TotalItemSize | sort totalitemsize | Export-CSV $mailbox_stats_csv_fullpath

    if(-not $whatif)
    {
        # NOTE(dallas): Original MaxReceiveSize: 36MB (37,748,736 bytes), MaxSendSize: 35MB (36,700,160 bytes)
        #                  !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
        #                  !! DiscoverySearchMailbox{<GUID>} WAS 100MB (104,857,600 bytes)/100MB (104,857,600 bytes) !!
        #                  !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
        Get-O365Mailbox     | Set-O365Mailbox -MaxReceiveSize 150MB -MaxSendSize 150MB

        # NOTE(dallas): Original (all 4 Online, OnlineEnterprise, OnlineEssentials, and OnlineDeskless plans)
        #               MaxReceiveSize: 36MB (37,748,736 bytes), MaxSendSize: 36MB (37,748,736 bytes)
        Get-O365MailboxPlan | Set-O365MailboxPlan -MaxReceiveSize 150MB -MaxSendSize 150MB
    } else {
        Get-O365Mailbox     | Set-O365Mailbox     -MaxReceiveSize 150MB -MaxSendSize 150MB -WhatIf
        Get-O365MailboxPlan | Set-O365MailboxPlan -MaxReceiveSize 150MB -MaxSendSize 150MB -WhatIf
    }

    # TODO(dallas): these original size limits should be reset at the end of the process, right ?
}