<?php
// $Id: dbconnect.php 74 2012-05-01 07:08:48Z paul $
// Start new database connection
$mysqli = new mysqli("localhost","asupcouk_pauluk","GURy345k","asupcouk_asup");
/* check connection */
if (mysqli_connect_errno()) {
    printf("Connect failed: %s\n", mysqli_connect_error());
    exit();
}

// Process message queue, send emails if required
// Requires an open database connection
function process_message_queue ($gameno) {

    // Open database
    global $mysqli;

    // Get message queue
    $result = $mysqli -> query("Select gameno, userno, message, to_email, messageno From sp_message_queue Where gameno=$gameno");
    if (!$result) {
        echo "E9".$mysqli -> error;
    }

    // Process each message
    if ($result->num_rows > 0) while ($row=$result->fetch_row()) {

        // Email if required
        if ($row[3]==1) {
            send_mail($row[1], $row[2]);
        }

        // Check for XML message to share
        libxml_use_internal_errors(true);
        $messagexml = SimpleXML_Load_String($row[2]);
        if ($messagexml and $row[1]==-7) {
            $apower = $messagexml -> AttPowername;
            if (isset($apower)) $mysqli -> query("Insert Into sp_messages (gameno, userno, message) Select gameno, userno, '".addslashes($row[2])."' From sp_resource Where gameno=$gameno and powername='$apower'");
            $dpower = $messagexml -> DefPowername;
            if (isset($dpower)) $mysqli -> query("Insert Into sp_messages (gameno, userno, message) Select gameno, userno, '".addslashes($row[2])."' From sp_resource Where gameno=$gameno and powername='$dpower'");
        }

        // Add all other o message table
        else $mysqli -> query ("Insert Into sp_messages (gameno, userno, message) Values ($gameno, $userno, '".addslashes($row[2])."')");

        // Remove from message queue
        $mysqli -> query("Delete From sp_message_queue Where messageno=${row[4]}");
    }

    // Close result set
    $result -> close();
}

// Send email to a user
// Requires database connection
function suprem_mail ($userno, $message, $gameno) {

    // Assume open database
    global $mysqli;

    // Get gameno for header
    $gameno =

    // Add footer to mail
    $message .= "\r\n\r\nMessage from 21.180 Commander:\r\nhttp://game.asup.co.uk";

    // Add subject
    if (isset($_SESSION['sp_gameno'])) $subject = "Message from game number $gameno\r\n";
    else $subject = "21.180 General message\r\n";

    // Get mail address(es)
    $result -> $mysqli -> query("Select Distinct email1, email2 From sp_users Where and userno=$userno");
    if ($result->num_rows > 0) $row = $result -> fetch_row();

    foreach ($row as $key => $val) {
        if ($val <> "" ) {
            $rx = mail ("$val"
                       ,$subject
                       ,wordwrap("$message", 80)."\r\n"
                       ,null
                       ,"-fsuprem@asup.co.uk"
                       );
        }
    }

    // Close results
    $result -> close();
}
?>