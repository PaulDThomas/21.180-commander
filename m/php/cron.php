<?php

// Regular scheduled script
// $Id: cron.php 252 2014-08-24 21:18:23Z paul $

// Connect to the database, no need to check the user as called by an Admin or cron job
require_once("utl_xml_table.php");
require_once("deb_run_query.php");
ob_start();
require_once("dbconnect.php");
ob_end_clean();

// First, create any new games
deb_run_query("call sr_new_game('Y')");

// Look for run away games
$mysqli -> query("Update sp_game Set process=9 Where turnno/20 = Floor(turnno/20) and turnno>20");

// Look for queues to move
$query = "
select g.gameno
 ,g.turnno
 ,g.phaseno
 ,case when deadline_uts+auto_force < unix_timestamp() then 'FORCE' else '' end as autoforce
 ,sum(order_code in ('Orders received','Passed')) as processed
 ,count(r.userno) as players
from sp_game g
left join sp_resource r
 on g.gameno=r.gameno
 and r.dead='N'
left join sp_orders o
 on g.gameno=o.gameno
 and r.userno=o.userno
 and o.ordername='ORDSTAT'
 and o.turnno=g.turnno
 and o.phaseno=g.phaseno
where g.phaseno < 9
 and beta>=0
 and process is null
group by 1, 2, 3
";


$result = $mysqli -> query($query,MYSQLI_STORE_RESULT)  or die ("CRON 001: ".$mysqli->error);
if ($result-> num_rows > 0) while ($row = $result -> fetch_assoc()) {
    echo "\r\nGame: ${row['gameno']}  Turn: ${row['turnno']}  Phase: ${row['phaseno']}  Players: ${row['players']}  Processed: ${row['processed']}";

    // Further processing if ready
    if ($row['players'] == $row['processed'] or $row['autoforce']=='FORCE') {
        echo "\r\nProcessing queue for game: ${row['gameno']}";
        if ($row['autoforce']=='FORCE') {
            $forceXML = new SimpleXMLElement("<?xml version='1.0'?><FORCE><Forcer>AUTOFORCE</Forcer></FORCE>");
            $result3 = $mysqli -> query("Select powername, userno, username From sv_current_orders Where gameno=${row['gameno']} and order_code like 'Waiting%'") or die ("CRON 002: ".$mysqli -> error);
            if ($result3 -> num_rows > 0) {
                while ($row3 = $result3 -> fetch_assoc()) $forceXML -> addChild(str_replace(" ","",$row3['powername']),$row3['userno'].'/'.$row3['username']);
                $result3 -> close();
            }
            $mysqli -> query("Insert Into sp_old_orders (gameno, turnno, phaseno, userno, ordername, order_code) Values (${row['gameno']}, ${row['turnno']}, ${row['phaseno']}, 0, 'AUTOFORCE', '".$forceXML->asXML()."')");
        }
        $mysqli -> query("call sr_move_queue(${row['gameno']})") or die ("CRON 003: ".$mysqli->error);
    }

};
$result -> free();

// Set up message body
$headers = "MIME-Version: 1.0\r\n";
$headers .= "Content-Type: text/html\r\n";
$body = '<!DOCTYPE html>
<html lang="en">
    <head>
        <meta name="viewport" content="0=device-width, initial-scale=1.0" />
        <title>21.180 Commander : Message from game '.$row['gameno'].'</title>
    </head>
    <style>
html{-ms-text-size-adjust:100%;-webkit-text-size-adjust:100%;font-size:100%}
a:focus{outline:5px auto 0;outline-offset:-2px}
a:hover,a:active{outline:0}
body{background-color:#ffd;color:#333;font-family:"Helvetica Neue", Helvetica, Arial, sans-serif;font-size:13px;line-height:18px;margin:0;padding-top:40px}
a{color:#08c;text-decoration:none}
a:hover{color:#005580;text-decoration:underline}
.row-fluid{width:100%;zoom:1}
.row-fluid [class*=span]{-moz-box-sizing:border-box;-ms-box-sizing:border-box;-webkit-box-sizing:border-box;box-sizing:border-box;display:block;float:left;margin-left:2.07446808464%;min-height:28px;width:100%}
.row-fluid [class*=span]:first-child{margin-left:0}
.row-fluid .span12{width:99.9468085006%}
.container-fluid{padding-left:20px;padding-right:20px;zoom:1}
h4{color:inherit;font-family:inherit;font-size:14px;font-weight:700;line-height:18px;margin:0;text-rendering:optimizelegibility}
ul{list-style:disc;margin:0 0 9px 25px;padding:0}
strong{font-weight:700}
table{background-color:transparent;border-collapse:collapse;border-spacing:0;max-width:100%}
.table{margin-bottom:18px;width:100%}
.table th,.table td{border-top:1px solid #ddd;line-height:18px;padding:8px;text-align:left;vertical-align:top}
.table th{background-color:#fed;font-weight:700}
.table-bordered{-moz-border-radius:4px;-webkit-border-radius:4px;border:1px solid #ddd;border-collapse:collapsed;border-left:0;border-radius:4px}
.table-bordered th,.table-bordered td{border-left:1px solid #ddd}
.table-bordered caption + thead tr:first-child th,.table-bordered caption + tbody tr:first-child th,.table-bordered caption + tbody tr:first-child td,.table-bordered colgroup + thead tr:first-child th,.table-bordered colgroup + tbody tr:first-child th,.table-bordered colgroup + tbody tr:first-child td,.table-bordered thead:first-child tr:first-child th,.table-bordered tbody:first-child tr:first-child th,.table-bordered tbody:first-child tr:first-child td{border-top:0}
navbar{margin-bottom:18px;overflow:visible;position:relative;z-index:2}
.navbar-inner{-moz-border-radius:4px;-moz-box-shadow:0 1px 3px rgba(0,0,0,0.25), inset 0 -1px 0 rgba(0,0,0,0.1);-webkit-border-radius:4px;-webkit-box-shadow:0 1px 3px rgba(0,0,0,0.25), inset 0 -1px 0 rgba(0,0,0,0.1);background-color:#2c2c2c;background-image:linear-gradient(top,#333333,#222222);background-repeat:repeat-x;border-radius:4px;box-shadow:0 1px 3px rgba(0,0,0,0.25), inset 0 -1px 0 rgba(0,0,0,0.1);filter:progid:dximagetransform.microsoft.gradient(startColorstr="#333333",endColorstr="#222222",GradientType=0);min-height:40px;padding-left:20px;padding-right:20px}
.navbar .container{width:auto}
.navbar{color:#999}
.navbar .brand:hover{text-decoration:none}
.navbar .brand{color:#999;display:block;float:left;font-size:20px;font-weight:200;line-height:1;margin-left:-20px;padding:8px 20px 12px}
.table-bordered thead:first-child tr:first-child th:first-child,.table-bordered tbody:first-child tr:first-child td:first-child{-moz-border-radius-topleft:4px;-webkit-border-top-left-radius:4px;border-top-left-radius:4px}
.table-bordered thead:first-child tr:first-child th:last-child,.table-bordered tbody:first-child tr:first-child td:last-child{-moz-border-radius-topright:4px;-webkit-border-top-right-radius:4px;border-top-right-radius:4px}
.table-bordered thead:last-child tr:last-child th:first-child,.table-bordered tbody:last-child tr:last-child td:first-child{-moz-border-radius:0 0 0 4px;-moz-border-radius-bottomleft:4px;-webkit-border-bottom-left-radius:4px;-webkit-border-radius:0 0 0 4px;border-bottom-left-radius:4px;border-radius:0 0 0 4px}
.table-bordered thead:last-child tr:last-child th:last-child,.table-bordered tbody:last-child tr:last-child td:last-child{-moz-border-radius-bottomright:4px;-webkit-border-bottom-right-radius:4px;border-bottom-right-radius:4px}
.breadcrumb{-moz-border-radius:3px;-moz-box-shadow:inset 0 1px 0 #fff;-webkit-border-radius:3px;-webkit-box-shadow:inset 0 1px 0 #fff;background-color:#ffd;background-image:linear-gradient(top,#ffffdd,#f5f5f5);background-repeat:repeat-x;border:1px solid #ddd;border-radius:3px;box-shadow:inset 0 1px 0 #fff;filter:progid:dximagetransform.microsoft.gradient(startColorstr="#ffffdd",endColorstr="#f5f5f5",GradientType=0);list-style:none;margin:0 0 18px;padding:7px 14px}
.breadcrumb li{display:inline;text-shadow:0 1px 0 #fff;zoom:1}
.navbar-fixed-top,.navbar-fixed-bottom{left:0;margin-bottom:0;position:fixed;right:0;z-index:1030}
.navbar-fixed-top .navbar-inner,.navbar-fixed-bottom .navbar-inner{-moz-border-radius:0;-webkit-border-radius:0;border-radius:0;padding-left:0;padding-right:0}
.navbar-fixed-top{top:0}
.breadcrumb .divider{color:#999;padding:0 5px}
.row-fluid:before,.row-fluid:after,.container-fluid:before,.container-fluid:after{content:"";display:table}
.row-fluid:after,.container-fluid:after{clear:both}
    </style><body><div class="container">';
$body .= '<div class="navbar navbar-fixed-top"><div class="navbar-inner"><div class="container"><a class="brand" href="http://game.asup.co.uk/index.php">21.180 Commander</a></div></div></div>';

// Get messages to send
$result = $mysqli -> query("
Select gameno, email1, email2, message, to_email, messageno, username
From sp_messages m
 , sp_users u
Where m.userno=u.userno and to_email < 0
 and (email1!='' or email2!='')
UNION
Select m.gameno, email1, email2, message, to_email, messageno, username
From sp_messages m
left join sp_resource r on r.gameno=m.gameno and extractValue(message,'/COMMS/From/Powername') != r.powername
left join sp_users u on r.userno=u.userno
where to_email < 0
 and m.userno=0
 and extractValue(message,'/COMMS/To/Powername')='Global'
 and (email1!='' or email2!='')

;") or die ("CRON 004: ".$mysqli->error);
if ($result -> num_rows > 0) while ($row = $result -> fetch_assoc()) {

    // Set up email address
    if ($row['email1']!='') $email_to = "${row['username']} <${row['email1']}>";
    if ($row['email1']!='' and $row['email2']!='') $email_to .= ' , ';
    if ($row['email2']!='') $email_to .= "${row['username']} <${row['email2']}>";

    // Set up title
    $title = "Message from Game ${row['gameno']}";

    // Set up body header
    $email = $body."<ul class='breadcrumb'><li><a href='http://game.asup.co.uk/game.php?gameselect=${row['gameno']}'>Message from Game ${row['gameno']}</a></li></ul>";

    // Add message
    $email .= "<div class='row'><div class='span12'>".utl_xml_table($row['message'])."</div></div>";

    // Finish body
    $email .= "</div></body></html>";

    // Debug info
    echo "Sending email to $email_to : ".htmlentities($email)."\n\r";
    $rx = mail ($email_to
               ,$title
               ,wordwrap($email,70)
               ,$headers
               ,"-fsuprem@asup.co.uk"
               );

    // Update to email marker - -1 becomes visible, -9 is deleted
    if ($row['to_email']==-1) $mysqli -> query("Update sp_messages Set to_email=$rx Where messageno=${row['messageno']}") or die ("CRON 005: ".$mysqli->error);
    else if ($row['to_email']==-9) $mysqli -> query("Delete From sp_messages Where messageno=${row['messageno']}") or die ("CRON 006: ".$mysqli->error);

    $mysqli -> close();
}

?>