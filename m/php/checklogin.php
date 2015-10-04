<?php

// Start up script for all pages
// $Id: checklogin.php 243 2014-07-13 14:55:45Z paul $

// Start page
session_start();
ignore_user_abort(true);

// Connect to database
ob_start();
require("dbconnect.php");
ob_end_clean();

// Remove magic quotes
if (get_magic_quotes_gpc()) {
    $process = array(&$_GET, &$_POST, &$_COOKIE, &$_REQUEST);
    while (list($key, $val) = each($process)) {
        foreach ($val as $k => $v) {
            unset($process[$key][$k]);
            if (is_array($v)) {
                $process[$key][stripslashes($k)] = $v;
                $process[] = &$process[$key][stripslashes($k)];
            } else {
                $process[$key][stripslashes($k)] = stripslashes($v);
            }
        }
    }
    unset($process);
}

// Check for __utma
if (isset($_COOKIE['__utma'])?strlen($_COOKIE['__utma']):0>10) {
    $_SESSION['__utma']=$_COOKIE['__utma'];
} else {
    $password = "";
    for ($i = 0; $i < 45; $i++) {
        // Pick random number between 1 and 62
        $randomNumber = rand(1, 62);

        // Select random character based on mapping.
        if ($randomNumber < 11) {
            // [ 1,10] => [0,9]
            $password .= Chr($randomNumber + 48 - 1);
            }
        elseif ($randomNumber < 37) {
            // [11,36] => [A,Z]
            $password .= Chr($randomNumber + 65 - 10);
            }
        else {
            // [37,62] => [a,z]
            $password .= Chr($randomNumber + 97 - 36);
            }
        }
        $_SESSION["__utma"]="$password";
    }
setcookie("__utma",$_SESSION['__utma'],time()+30*86400);

// Check passed log in details against the database.
if(isset($_POST['in_user'])) $in_user = $_POST['in_user'];
else if(isset($_SESSION['sp_username'])) $in_user = $_SESSION['sp_username'];
else if (isset($_COOKIE['in_user'])) $in_user = $_COOKIE['in_user'];
else $in_user = 'FAIL';

// Get current values for inpass
$in_pass=''; $userno='0';
if (isset($_POST['in_pass'])) $in_pass = $_POST['in_pass'];
else if (isset($_COOKIE['in_pass'])) $in_pass = $_COOKIE['in_pass'];
else $in_pass = '';

// Get current value for userno
if (isset($_SESSION['sp_userno'])) $userno = $_SESSION['sp_userno'];

// Unset legacy fail values
if ((isset($_SESSION['sp_userno'])?$_SESSION['sp_userno']:-1) == 0) {
    unset($_SESSION['sp_userno']);
    unset($_SESSION['sp_username']);
    }

// Check values against the database
$result = $mysqli -> query ("Select * From sp_users Where username='$in_user' and (pass='$in_pass' or userno=$userno);") or die ("CHECKLOGIN:1".$mysqli -> error);

// Check is the username and password combination are successful
if ($result -> num_rows > 0) {
    // User found
    $USER = $result -> fetch_assoc();
    $_SESSION['sp_username'] = $USER['username'];
    $_SESSION['sp_userno'] = $USER['userno'];
    $_SESSION['offset'] = isset($_POST['offset']) ? $_POST['offset'] : (isset($_SESSION['offset']) ? $_SESSION['offset'] : (isset($_COOKIE['offset']) ? $_COOKIE['offset'] : 0));
    $_SESSION['dt_format'] = $USER['dt_format'];
    $username = $USER['username'];
    $userno = $USER['userno'];

    if (isset($_POST['in_user'])) {
        // Set last login timestamp
        $mysqli -> query ("Update sp_users Set last_login_uts = unix_timestamp(), timezone=${_SESSION['offset']}, last_login_ip='".$_SERVER['REMOTE_ADDR']."', last_hostname='".gethostbyaddr($_SERVER['REMOTE_ADDR'])."' Where userno = $userno;") or die("CHECKLOGIN:2".$mysqli -> error);
        $mysqli -> query ("Insert Into sp__utma (userno, __utma, login_ip, hostname, login_uts, user_agent) Values ($userno, '${_SESSION['__utma']}', '${_SERVER['REMOTE_ADDR']}', '".gethostbyaddr($_SERVER['REMOTE_ADDR'])."', unix_timestamp(), '${_SERVER['HTTP_USER_AGENT']}');") or die("CHECKLOGIN:3".$mysqli -> error);
    }

    // Set cookie if requested
    if (isset($_POST['stay'])) {
        setcookie("in_user",$in_user,time()+30*86400);
        setcookie("in_pass",$in_pass,time()+30*86400);
        setcookie("offset",$_SESSION['offset']);
        setcookie("df_format",$_SESSION['dt_format']);
    }
} else if (isset($_POST['in_user'])){
    // Failed log in attempt
    // User FAIL is pre-defined in users table...
    unset($_SESSION['sp_username']);
    unset($_SESSION['sp_userno']);
    unset($_SESSION['sp_gameno']);
    unset($_SESSION['sp_powername']);
    $username = '';
    $userno = '';
    $gameno = '0';
    $powername = '';
    $turnno = '';
    $phaseno = '';
    $mapHash = '';
} else {
    // Default values
    $_SESSION['sp_username'] = 'Guest';
    $_SESSION['dt_format'] = 'jS F Y h:i:s a';
    $_SESSION['offset'] = '0';
    unset($_SESSION['sp_userno']);
    unset($_SESSION['sp_gameno']);
    unset($_SESSION['sp_powername']);
    $username = '';
    $userno = '0';
    $gameno = '0';
    $powername = '';
    $turnno = '';
    $phaseno = '';
    $mapHash = '';
    $offset = 0;
    $USER = array('admin'=>'N','userno'=>'','username'=>'','dt_format'=>'jS F Y h:i:s a','offset'=>'0');
}

// Resolve game details
if (isset($_GET['gameselect'])) {
    $_SESSION['sp_gameno'] = $_GET['gameselect'];
} else if (isset($_GET['gamerevolution']) and isset($_GET['powername'])) {
    // Look for revolution
    require_once("m/php/process_revolution.php");
    $_SESSION['sp_gameno'] = $_GET['gamerevolution'];
}
$gameno = isset($_SESSION['sp_gameno']) ? $_SESSION['sp_gameno'] : '0';

// Get game and resource arrays
if ($gameno != '0') {
    // Get mapHash for game
    $query = "Select gameno, turnno, phaseno, mapHash From sv_map_hash Where gameno=$gameno";
    $result = $mysqli -> query($query) or die("Cannot get mapHash query:".$mysqli->error);
    if ($result->num_rows > 0) $row=$result->fetch_assoc() or die("Cannot get mapHash value");
    $mapHash = "G".$row['gameno']."T".$row['turnno']."P".$row['phaseno'].'H'.$row['mapHash'];
    $result -> close();
    $result = $mysqli -> query("Select * From sp_resource Where gameno=$gameno and userno=$userno") or die("CHECKLOGIN:4".$mysqli -> error);
    if ($result -> num_rows < 1) {
        $powername = '';
        $turnno = '';
        $phaseno = '';
        unset($_SESSION['sp_powername']);
        // Do not reset game if called form the GUEST page
        if (!strpos(isset($_SERVER['HTTP_REFERER'])?$_SERVER['HTTP_REFERER']:'','guest.php') and !strpos($_SERVER['REQUEST_URI'],'guest.php')) {
            unset($_SESSION['sp_gameno']);
            $gameno = '';
            $mapHash = '';
        }
    } else {
        $RESOURCE = $result -> fetch_assoc();
        $result -> close();
        $_SESSION['sp_powername'] = $RESOURCE['powername'];
        $powername = $RESOURCE['powername'];

        // Update MIA
        $mysqli -> query("Update sp_resource Set mia=0 Where gameno=$gameno and userno=$userno") or die("CHECKLOGIN:5".$mysqli -> error);

        // Get game parameters
        $result = $mysqli -> query("Select * From sp_game Where gameno=$gameno") or die("CHECKLOGIN:6 - Select * From sp_game Where gameno=$gameno :".$mysqli -> error);
        $GAME = $result -> fetch_assoc();
        $result -> close();
        $turnno = $GAME['turnno'];
        $phaseno = $GAME['phaseno'];
    }
} else {
    $powername = '';
    $turnno = '';
    $phaseno = '';
    $mapHash = '';
    unset($_SESSION['sp_gameno']);
    unset($_SESSION['sp_powername']);
}

// Close connection in page
//$mysqli -> close();

?>
