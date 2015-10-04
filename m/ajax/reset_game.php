<?php

// $Id: reset_game.php 103 2012-08-01 07:38:38Z paul $
// Look for log in details being passed
require_once("../php/checklogin.php");

// Move non admin people to home page
if ($USER['admin'] != 'Y') {
    echo "Incorrect information, exiting";
    print_r($_POST);
    exit;
}

// Set gameno from gameselect option
$gameno = isset($_POST['gameselect'])?$_POST['gameselect']:'0';

// Check game exists
$result = $mysqli -> query("Select gameno, process, deadline_uts, advance_uts From sp_game Where gameno=$gameno");
if ($result -> num_rows == 0) {
    echo "No game $gameno found";
    exit;
} else {
    $row = $result->fetch_row();
}

// Format advance_uts to english
if ($row[3] == 1) $advance = $row[3] . ' second';
else if ($row[3] < 60) $advance = $row[3] . ' seconds';
else if ($row[3] == 60) $advance = $row[3]/60 . ' minute';
else if ($row[3] < 3600) $advance = $row[3]/60 . ' minutes';
else if ($row[3] == 3600) $advance = $row[3]/60 . ' hour';
else $advance = $row[3]/3600 . ' hours';

// Close result
$result -> close();

// Check game needs a reset
//if ($row[1] == '') {
//    echo "Game $gameno is not on hold";
//    exit;
//}

// Print data as resetting...
?>
    <div class="ui-grid-a">
        <div class="row-fluid">
            <div class="ui-block-a span4">Current Deadline:</div>
            <div class="ui-block-b span8"><?php echo gmdate($_SESSION['dt_format'], $row[2] - $_SESSION['offset']*60); ?></div>
        </div>
        <div class="row-fluid">
            <div class="ui-block-a span4">Advance:</div>
            <div class="ui-block-b span8"><?php echo $advance; ?></div>
        </div>
        <?php
        // Reset process flag and change deadline
        $mysqli -> query("Update sp_game
                          Set process=null, deadline_uts=Greatest(unix_timestamp()+advance_uts,deadline_uts)
                          Where process is not null
                           and gameno=$gameno
                          ;");
        $result2 = $mysqli -> query("Select deadline_uts From sp_game Where gameno=$gameno");
        $row2 = $result2 -> fetch_row();
        $result2 -> close();
    ?>
        <div class="row-fluid">
            <div class="ui-block-a span4">New Deadline:</div>
            <div class="ui-block-b span8"><?php echo gmdate($_SESSION['dt_format'], $row2[0] - $_SESSION['offset']*60); ?></div>
        </div>
        <?php
        // Email next in turn
        $result3 = $mysqli -> query("Select Distinct o.gameno
                                            ,o.userno
                                            ,o.turnno
                                            ,o.phaseno
                                            ,g.deadline_uts
                                            ,u.timezone
                                            ,u.dt_format
                                            ,u.email1
                                            ,u.email2
                                     From sp_orders o
                                          ,sp_users u
                                          ,sp_game g
                                     Where o.gameno=$gameno
                                           and o.gameno=g.gameno
                                           and o.userno=u.userno
                                           and substring(o.order_code,1,7)='Waiting'
                                      ;");

        // Process people
        if ($result3->num_rows > 0) while ($row3=$result3->fetch_row()) {
            $message = "Game reset.\r\n";
            $message .= "Waiting for your orders in game number $gameno.\r\n";
            $message .= "Turn = ${row3[2]}\r\n";
            $message .= "Phase = ${row3[3]}\r\n";
            $message .= "Deadline = ".gmdate($row3[6], $row3[4])." (GMT)\r\n";
            $message .= "           ".gmdate($row3[6], $row3[4] - $row3[5]*60)." (Local)\r\n";
            $message .= "\r\n\r\nMessage from 21.180 Commander:\r\nhttp://game.asup.co.uk";

            // Show who is waiting
            ?><div class="row-fluid">
                <div class="ui-block-a span4">Waiting User Number</div>
                <div class="ui-block-b span8"><?php echo $row3[1]; ?></div>
            </div>
            <?php

            if ($row3[7] != '') {
                $rx = mail ("$row3[7]"
                           ,"Message from game $gameno"
                           ,wordwrap("$message", 80)."\r\n"
                           ,null
                           ,"-fsuprem@asup.co.uk"
                           );
                ?><div class="row-fluid"><div class="ui-block-a span4">Mail to:</div><div class="ui-block-b span8"><?php echo $row3[7]; ?></div><?php
            }

            if ($row3[8] != '') {
                $rx = mail ("$row3[8]"
                           ,"Message from game $gameno"
                           ,wordwrap("$message", 80)."\r\n"
                           ,null
                           ,"-fsuprem@asup.co.uk"
                           );
                ?><div class="row"><div class="ui-block-a span4">Mail to:</div><div class="ui-block-b span8"><?php echo $row3[8]; ?></div><?php
            }
        }
        ?>
    </div><!-- Grid -->
<?php

// Close connection
$mysqli -> close();
// Close session
session_write_close();

?>
