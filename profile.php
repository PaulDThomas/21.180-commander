<?php
/*
** Description  : Page to edit user details
**
** Script name  : edit.php
** Author       : Paul Thomas
** Date         : 12th December 2003
**
** $Id: profile.php 274 2015-02-03 08:56:38Z paul $
**
*/

// Start page
require_once("m/php/checklogin.php");

// Redirect if not ready
if ($username == '' or $username == 'FAIL') {
    header("Location:login.php");
}

// Set dummy posted variables
$username=isset($_POST['username'])?$_POST['username']:'';
$ed_email1=isset($_POST['ed_email1'])?$_POST['ed_email1']:'';
$ed_email2=isset($_POST['ed_email2'])?$_POST['ed_email2']:'';
$newpass=isset($_POST['newpass'])?$_POST['newpass']:'';
$confirm=isset($_POST['confirm'])?$_POST['confirm']:'N';
$map_type=isset($_POST['map_type'])?$_POST['map_type']:'';
$dt_format=isset($_POST['dt_format'])?$_POST['dt_format']:'';
$new_format=isset($_POST['new_format'])?$_POST['new_format']:'';
$message = '';

// Get current values
$query = "
Select username, email1, email2, map_type, dt_format
From sp_users
Where userno=$userno
";
$result = $mysqli -> query($query);
$row = $result -> fetch_row();
$current_username = $row[0];
$current_email1 = $row[1];
$current_email2 = $row[2];
$current_map_type = $row[3];
$current_dt_format = $row[4];
$result -> close();

/**
Validate an email address.
From... http://www.linuxjournal.com/article/9585?page=0,3
Provide email address (raw input)
Returns true if the email address has the email
address format and the domain exists.
*/
function validEmail($email)
{
   $isValid = true;
   $atIndex = strrpos($email, "@");
   if (is_bool($atIndex) && !$atIndex)
   {
      $isValid = false;
   }
   else
   {
      $domain = substr($email, $atIndex+1);
      $local = substr($email, 0, $atIndex);
      $localLen = strlen($local);
      $domainLen = strlen($domain);
      if ($localLen < 1 || $localLen > 64)
      {
         // local part length exceeded
         $isValid = false;
      }
      else if ($domainLen < 1 || $domainLen > 255)
      {
         // domain part length exceeded
         $isValid = false;
      }
      else if ($local[0] == '.' || $local[$localLen-1] == '.')
      {
         // local part starts or ends with '.'
         $isValid = false;
      }
      else if (preg_match('/\\.\\./', $local))
      {
         // local part has two consecutive dots
         $isValid = false;
      }
      else if (!preg_match('/^[A-Za-z0-9\\-\\.]+$/', $domain))
      {
         // character not valid in domain part
         $isValid = false;
      }
      else if (preg_match('/\\.\\./', $domain))
      {
         // domain part has two consecutive dots
         $isValid = false;
      }
      else if (!preg_match('/^(\\\\.|[A-Za-z0-9!#%&`_=\\/$\'*+?^{}|~.-])+$/',
                 str_replace("\\\\","",$local)))
      {
         // character not valid in local part unless
         // local part is quoted
         if (!preg_match('/^"(\\\\"|[^"])+"$/',
             str_replace("\\\\","",$local)))
         {
            $isValid = false;
         }
      }
      if ($isValid && !(checkdnsrr($domain,"MX") || checkdnsrr($domain,"A")))
      {
         // domain not found in DNS
         $isValid = false;
      }
   }
   return $isValid;
}

// Change username
if ($username <> '' and $username <> $current_username) {
    $query1 = "Select username From sp_users Where upper(username)=upper('$username')";
    $result1 = $mysqli -> query($query1);
    if ($mysqli -> query("Select username From sp_users Where upper(username)=upper('$username')") -> num_rows > 0) {
        $message .= "Username already in use!<br/>";
    } else {
        $result1a = $mysqli -> query("Update sp_users set username = '$username' Where userno=$userno;");
        $message .= "Username updated successfully.<br/>";
        $_SESSION['sp_username'] = $username;
        $current_username = $username;
    }
}

// Email address 1 changed
If ($ed_email1 <> $current_email1 and $ed_email1<> '' and validemail($ed_email1) ) {
    $mysqli -> query("Update sp_users Set email1='$ed_email1' Where userno=$userno");
    $current_email1 = $ed_email1;
    $message .= "Email updated successfully.<BR/>";
    }
// Email address 2 changed
If ($ed_email2 <> $current_email2 and $ed_email2 <> '' and ($ed_mail==' ' or validemail($ed_email2)) ) {
    $mysqli -> query("Update sp_users Set email2='$ed_email2' Where userno=$userno;");
    $current_email2 = $ed_email2;
    $message .= "Alternative Email updated successfully.<BR/>";
    }
// Change password
If ($newpass == $confirm and $newpass <> '') {
    $mysqli -> query("Update sp_users Set pass='$newpass' Where userno=$userno;");
    $message .= "Your password has been successfully changed.<BR/>";
    }
// Failed password change
Else If ($newpass <> $confirm and $newpass <> '') {
    $message .= "Password and confirmation did not match.<BR/>";
    }
// Change map type
If ($map_type != $current_map_type and $map_type <>'') {
    $mysqli -> query("Update sp_users Set map_type='$map_type' Where userno=$userno");
    $message .= "Map type updated.<BR/>";
    $current_map_type = $map_type;
    }
// Date/time format
If ($new_format != $current_dt_format and $new_format <> '') {
    $mysqli -> query("Update sp_users Set dt_format='$new_format' Where userno=$userno");
    $message .= "Date/time style updated.<BR/>";
    $current_dt_format = $new_format;
    $_SESSION['dt_format'] = $new_format;
    }

// End of header
?><!DOCTYPE html>
<html lang="en">
<head>
    <title>21.180 Profile</title>
    <?php require_once("m/php/header_base.php"); ?>
    <script type="text/javascript" src="m/js/forum.js"></script>
</head>
<body>
<div class="container">

    <?php require_once("m/php/navbar.php"); ?>
    <ul class="breadcrumb">
        <li><a href="index.php">Home</a></li>
        <span class="divider">/</span>
        <li>Edit Profile</li>
    </ul><!-- Breadcrumbs -->


    <div class="row">
        <div class="span8" id="ordersPanel">
            <h1>Edit Profile</h1>
            <?php if ($message != '') echo "<em>$message</em>"; ?>
            <form action="profile.php" id="mainForm" method="post">
                <table class="well" style="margin:10px;padding:10px">
                    <tr>
                        <td class="span3" style="padding-left:10px">Username</td>
                        <td class="span5" style="padding:10px 0"><strong><?php echo $_SESSION['sp_username']; ?></strong></td>
                    </tr>
                    <tr>
                        <td><label for="username" style="padding-left:10px">New username</label></td>
                        <td><input class="input-xlarge" type="text" name="username" id="username"/><td>
                    </tr>
                    <tr>
                        <td><label for="ed_email1" style="padding-left:10px">Email</label></td>
                        <td><input class="input-xlarge" type="text" name="ed_email1" value="<?php echo $current_email1; ?>"/><td>
                    </tr>
                    <tr>
                        <td><label for="ed_email2" style="padding-left:10px">Alternative Email</label></td>
                        <td><input class="input-xlarge" type="text" name="ed_email2" value="<?php echo $current_email2; ?>" /><td>
                    </tr>
                    <tr>
                        <td><label for="newpass" style="padding-left:10px">New Password</label></td>
                        <td><input class="input-xlarge" type="password" name="newpass" /><td>
                    </tr>
                    <tr>
                        <td><label for="confirm" style="padding-left:10px">Confirm Password</label></td>
                        <td><input class="input-xlarge" type="password" name="confirm" /><td>
                    </tr>
                    <tr>
                        <td><label for="map_type" style="padding-left:10px">Map picture format</label></td>
                        <td><select class="input-xlarge" name="map_type" />
                            <?php
                $pic_types = array("JPG","PNG");
                foreach ($pic_types as $value) echo "<option ".($current_map_type==$value?'selected':'')." >$value</option>";
                ?>
                        </select><td>
                    </tr>
                    <tr>
                        <td><label for="new_format" style="padding-left:10px">Date / time style</label></td>
                        <td><select class="input-xlarge" name="new_format" />
                            <?php
                $date_types = array("l jS F Y h:i:s a"=>"Thursday 3rd July 2004 05:34:56 pm","jS F Y h:i:s a"=>"3rd July 2004 05:34:56 pm","jS F Y H:i:s"=>"3rd July 2004 17:34:56","F j Y h:i:s a"=>"July 3 2004 05:34:56 pm","F j Y H:i:s"=>"July 3 2004 17:34:56","Y-m-d H:i:s"=>"2004-07-03 17:34:56");
                foreach ($date_types as $key => $value) echo "<option value='$key' ".($current_dt_format==$key?'selected':'')." >$value</option>";
                ?>
                        </select><td>
                    </tr>
                    <tr>
                        <td colspan="2" align="center" style="padding-bottom:10px"><input type="submit" class="btn btn-success" value="Update" /></td>
                    </tr>
                </table>
            </form>
        </div><!-- span8 -->

        <div class="span4" id="rightPanel">
            <?php require("m/php/forum_panel.php"); ?>
        </div><!-- Right panel -->

        </div><!-- row -->

        <?php require_once("m/php/footer_base.php"); ?>
    </div><!-- Container -->
<script type="text/javascript"><!--
function onError(data, status) {
    // handle an error
}

$(document).ready(function() {
    // Load forum messages
    forumInit();
});

-->
</script>
</body>
</html>
<?php

// Close page
$mysqli -> close();
session_write_close();
?>
