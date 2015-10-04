<?php

// Sign up or forgotten password processing
// $Id: signup_form.php 130 2013-05-12 11:39:20Z paul $

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

if (!validemail($_POST['email'])) {
    // Check email address
    echo "At least try to put in a real email address... not ${_POST['email']}";

} else if (isset($_POST['username'])?Strlen($_POST['username'])<2:false) {
    // Check username if posted
    echo "At least try to put in a name for your account...";

} else if (isset($_POST['username'])?Strlen($_POST['username'])>25:false) {
    // Check small enough
    echo "At least try to put in a reasonable name for your account...";

} else if ($_POST['f']=='sign') {
    $username = $_POST['username'];
    $email = $_POST['email'];

    // Get database connection
    ob_start();
    require_once("../php/dbconnect.php");
    require_once("../php/utl_mail.php");
    ob_end_clean();

    // Check username is not assigned
    $result = $mysqli -> query("Select username From sp_users Where username = '$username'");
    $result2 = $mysqli -> query("Select username From sp_users Where email1='$email' or email2='$email'");
    if ($result -> fetch_row()) {
        echo "Sorry, <strong>$username</strong> is already taken.";
    } else if ($result2 -> fetch_row()) {
        echo "Email <em>$email</em> is already in use.";
    } else {
        /* Set up account */
        // Password
        $password = "";
        for ($i = 0; $i < 10; $i++) {
            // Pick random number between 1 and 62
            $randomNumber = rand(1, 62);
            // Select random character based on mapping.
            if ($randomNumber < 11) {
                    // [ 1,10] => [0,9]
                    $password .= Chr($randomNumber + 48 - 1);
            } else if ($randomNumber < 37) {
                    // [11,36] => [A,Z]
                    $password .= Chr($randomNumber + 65 - 10);
            } else {
                    // [37,62] => [a,z]
                    $password .= Chr($randomNumber + 97 - 36);
            }
        }

        $message = "Created user name is '$username'.";
        $mysqli -> query("Insert into sp_users (username, pass, email1) values ('$username', '$password', '$email');");
        $result3 = $mysqli -> query("Select userno From sp_users Where username='$username'");
        $row = $result3 -> fetch_row();
        $userno = $row[0];

        // Send welcome email
        $mail = "
Welcome to 21.180 Commander

Your details are
Username: $username
Password: $password
Email   : $email


You can access the game at http:\\game.asup.co.uk

Please check/change your details in the Profile section, then feel free
to enter a game queue.  You will then be notified when your game is ready.

Documentation is available on-line, but I assume that you have a basic
understanding of the rules, and there are still things that need adding in
so if you have any questions please feel free to ask.

Rules are (approximately) v3.0 with a few necessary tweeks for the automation
and local rule changes.

Please get in touch via suprem@asup.co.uk if you have any comments, queries
or encounter any problems...
";
        utl_mail(0, $userno, $mail);
        $result3 -> close();
        echo "Email for <strong>$username</strong> sent to <em>${_POST['email']}</em>.";
    }

    // Clean up
    $result -> close();
    $result2 -> close();
    $mysqli -> close();

} else if ($_POST['f']=='forgot') {
    /* Forgotten email address */
    $email = $_POST['email'];

    // Get database connection
    ob_start();
    require_once("../php/dbconnect.php");
    require_once("../php/utl_mail.php");
    ob_end_clean();

    // Check database
    $result4 = $mysqli -> query("Select userno, username, pass From sp_users Where upper(email1)=upper('$email') or upper(email2)=upper('$email')");

    // Email to returned rows
    if ($row = $result4 -> fetch_row()) {
        $mailtext = "Username and password conrimation\r\n";
        $mailtext .= "Your username is: ${row[1]}\r\n";
        $mailtext .= "Your password is: ${row[2]}\r\n";
        utl_mail(0, $row[0], $mailtext, "NOPRINT");
        echo "Username verification sent to <em>$email</em>.";
    } else {
        echo "No match for email address <em>$email</em> found.";
    }
} else {
    echo "What are you doing, exactly? Hmmmm....";
}

?>