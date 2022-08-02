function Export-OnmicrosoftSmtp() {
    #================================================================================================================================================#
    #                                                                                                                     | Export *.onmicrosoft.com #
    #                                                                                                                     | Addresses                #
    #================================================================================================================================================#

    ##################################################################################
    # HowTo, Step 4b                                                                 #
    # SET $usercredential VARIABLE                                                   #
    # \\kspad06\c$\Scripts\O365\exportonmicrosoftaddresses.ps1                       #
    ##################################################################################

    $onmicrosoft_csv_name = "onmicrosoft_addressess.csv"
    $onmicrosoft_csv_path = "."
    $onmicrosoft_csv_fullpath = "${onmicrosoft_csv_path}\${onmicrosoft_csv_name}"

    # NOTE(dallas): The original script did this: 
    #                       
    #                       $mailboxes = Get-Mailbox -Filter { EmailAddresses -like "*.onmicrosoft.com" }
    #
    #               but the filter is pointless, as all mailboxes in a new tenant will have *.onmicrosoft.com UPN suffixes,
    #               and all tenant mailboxes will be returned, INCLUDING the Discovery Search Mailbox. I've just changed the 
    #               filter to return all mailboxes excluding the Search Mailbox
    #

    #!!!!!
    #!  $addresses = get-aduser -searchbase "$company_ou" -Filter * | ? { -not ($_.DistinguishedName -like "*Service Accounts*") }
    #!!!!!
    #!!!!!
    $mailboxes = (Get-O365Mailbox -Filter { -not (DisplayName -like "Discovery Search Mailbox") } | sort Alias) 
    #!!!!!
    # BUG?(dallas): Because the original script used Get-Mailbox to find .onmicrosoft.com addresses, any non-licensed users would not
    #               have been listed, becauase they wouldn't have mailboxes
    #
    #               Not sure if the correct thing to do is generate this list with Get-User (filtering out service accounts, admin
    #               accounts, etc) or to keep using Get-Mailbox and making sure all users are first licensed after syncing

    # NOTE(dallas): The original filter was '...? { $_ -like "*.onmicrosoft.com" }...'. How this was working for him before,  
    #               I have no idea (I'm guessing not very good), because this will also map any "SIP:<user>@<tenant>.onmicrosoft.com"
    #               addresses as well.  '...? {$_ -like "smtp*.onmicrosoft.com"}...' should fix this, but may be buggy.
    #
    #               ~~Not sure how case factors into these comparators~~
    #               Seems to work fine, both "SMTP: " and "smtp: " addersses are returned

    $addresses = ($mailboxes | select DisplayName, @{n = "smtp"; e = { $_.EmailAddresses | ? { $_ -like "smtp*.onmicrosoft.com" } } })

    # TEST(dallas): Make sure the email_addresses are generated properly. __Concatenating 'all addresses' is probably not necessary now that
    #                                                                       all users are first being licensed by hand, also they should only
    #                                                                       have the one .onmicrosoft.com address, right?__
    # NOTE(dallas): This is a messy way to change the "SMTP:<address1> smtp:<address2> smtp:..." object array from the address list into
    #               a space-sparated string that can be easily pasted into the Fly template. 
    $addresses | % {
        $str = ""
        $e = $null
        if($_.smtp)
        {
            # $_.smtp currently in the "SMTP:<address1> smtp:<address2> smtp:..." format
            # Split into separate "SMTP:<address1>" "smtp:<address2>" tokens
            $e = $_.smtp.split(' ')
            # TODO(dallas): pick better names
            $e | % {
                # For each token, split again into string arrays of ("smtp", "<address>")
                $t = $_.split(':')
                # Since the first element of this array will always be "SMTP"/"smtp", it can be discarded
                # Add the second (email address) element to the return string
                $str += $t[1]

                # TODO(dallas): This is stupid. Find a better way to space-separate email address string elements
                $str += " "
            }
            $str = $str.trim()
        }

        # Add the completed email string as a member of the current address entry for serialization to the CSV
        $_ | Add-Member @{email_addresses=$str}
    }

    # NOTE(dallas): not sure if Fly requires the UPN or if any proxy address will do (e.g. rob). Guess we'll find out...
    $addresses | Export-CSV $onmicrosoft_csv_fullpath
}

