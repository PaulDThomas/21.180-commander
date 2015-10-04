<?php

// Send mail script
// $Id: utl_mail.php 78 2012-05-21 23:24:11Z paul $

function utl_mail ($gameno, $userno, $message, $noprint="Y") {
    // Open database
    global $mysqli;

    // Get mail address(es)
    $query = "Select Distinct email1, email2
              From sp_resource a
              Right Join sp_users b On a.userno=b.userno
              Where 1=1 ";
    if ($gameno > 0) $query .= " and a.gameno=$gameno ";
    if ($userno > 0) $query .= " and b.userno=$userno ";

    $result = $mysqli -> query($query);

    // Add footer to mail
    $message .= "\r\n\r\nMessage from 21.180 Commander:\r\nhttp://game.asup.co.uk";

    // Add subject
    if ($gameno != 0) $subject = "Message from game number $gameno\r\n";
    else $subject = "21.180 General message\r\n";

    while ($row = $result -> fetch_row()) {
        foreach ($row as $key => $val) {
            if ($val <> "" ) {
                $rx = mail ("$val"
                           ,$subject
                           ,wordwrap("$message", 80)."\r\n"
                           ,null
                           ,"-fsuprem@asup.co.uk"
                           );

                if ($noprint == "") {
                    echo "<I>Sending mail... $rx</I><BR />";
                    echo "<I>To: $val</I><BR />";
                    echo "<PRE><I>$message</I><BR /></PRE>";
                }
            }
        }
    }
}
