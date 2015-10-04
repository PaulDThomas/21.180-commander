<?php

// $Id: login.php 274 2015-02-03 08:56:38Z paul $
// Log in page

// Process a log out...
if (isset($_GET['logout'])) {
    session_start();
    unset($_COOKIE['in_user']);
    unset($_COOKIE['in_pass']);
    setcookie("in_user","",time()-3000);
    setcookie("in_pass","",time()-3000);
    setcookie("offset","",time()-3000);
    setcookie("dt_format","",time()-3000);
    unset($_SESSION['sp_userno']);
    unset($_SESSION['sp_username']);
    unset($_SESSION['sp_gameno']);
    unset($_SESSION['sp_powername']);
    session_destroy();
    session_write_close();
}

// Get database information
require("m/php/checklogin.php");

// Re-direct if logged in (must be a cookie)
if (isset($_SESSION['sp_userno'])) {
    header("location:index.php");
    $mysqli -> close();
    exit;
}

// Get population statistics
$query1 = "Select Count(Distinct t.userno), Count(Distinct t.gameno)
           From sp_board t, sp_resource r, sp_game g, sp_users u
           Where lower(username) not like binary '%test%'
            and t.userno > 0
            and r.gameno > 0
            and r.gameno=t.gameno
            and g.gameno=t.gameno
            and r.userno=u.userno
            and g.phaseno < 9
           ;";
$result1 = $mysqli->query($query1);
$row1 = $result1->fetch_row();
$result1 -> close();

$query2 = "Select Count(*) From sp_newq;";
$result2 = $mysqli->query($query2);
$row2 = $result2->fetch_row();
$result2 -> close();

$query3 = "Select Count(*)
           From sp_users
           Where username not like binary '%test%'
            and last_login_uts is not null
           ;";
$result3 = $mysqli->query($query3);
$row3 = $result3->fetch_row();
$result3-> close();

$query4 = "Select Count(Distinct r.userno)
           From sp_resource r, sp_game g
           Where worldcup!=0
            and dead!='Y'
            and g.gameno=r.gameno
           ;";
$result4 = $mysqli->query($query4);
$row4 = $result4->fetch_row();
$result4-> close();

$mysqli -> close();

?><!DOCTYPE html>
<html lang="en">
    <head>
        <title>21.180 Commander</title>
        <?php require("m/php/header_base.php"); ?>
        <script type="text/javascript"><!--
function onError(data, status) {
    // handle an error
}

$(document).ready(function() {
    now = new Date();
    document.mainForm.offset.value = now.getTimezoneOffset();

    $("#signupOK").click(function(){
        $.ajax({
            type: "POST",
            url: "m/ajax/signup_form.php",
            cache: false,
            data: 'f=sign&email='+$('#signupEmail').val()+'&username='+$('#signupUsername').val(),
            success: function(data,Status) {
                $("#signupP").empty().append(data);
            },
            error: onError
        });
        return false;
    });

    $("#uselessOK").click(function(){
        $.ajax({
            type: "POST",
            url: "m/ajax/signup_form.php",
            cache: false,
            data: 'f=forgot&email='+$('#uselessEmail').val(),
            success: function(data,Status) {
                $("#uselessP").empty().append(data);
            },
            error: onError
        });
        return false;
    });

    if (document.mainForm.in_user) document.mainForm.in_user.focus();
});
        --></script>
    </head>
    <body>
    <div class="container">
    <?php require_once("m/php/navbar.php"); ?>
        <div class="row">
            <div class="span12"><div class="hero-unit">
                <h1 style="padding:20px">21.180 Commander</h1>
                <p>This web site is home to an on-line fully automated version of Supremacy: The Game of Superpowers&reg;</p>
                <p>If you are new to the site, please feel free to browse the current and past games, or sign up and enter the game queues and you will be automatically entered into the next available game.</p>
            </div></div><!-- Hero Unit -->
        </div>
        <div class="row">
            <div class="span6" align="center">
                <form name="mainForm" action="index.php" method='post' class="form-horizontal well">
                    <div class="control-group">
                      <label for="in_user" class="control-label">Name:</label>
                      <div class="controls"><input class="input span3" type='text' name='in_user'/></div>
                    </div><!-- in_user -->
                    <div class="control-group">
                      <label for="in_user" class="control-label">Password:</label>
                      <div class="controls"><input class="input span3" type='password' name='in_pass'/></div>
                    </div><!-- in_pass -->
                    <div class="control-group">
                      <label for="stay" class="control-label">Remember me</label>
                      <div class="controls"><input type='checkbox' name='stay'/></div>
                    </div><!-- stay -->
                    <div class="control-group" align="center">
                      <div class="controls"><input class='btn btn-success' type='submit' value="Log in"/></div>
                    </div><!-- submit -->
                    <input type="hidden" name="offset" id="offset" value="0"/>
                </form><!-- Entry form -->
            </div><!-- User details -->

            <div class="span6">
                <div class="well">
                    <p><?php echo $row3[0];?> people signed up</p>
                    <p><?php echo $row1[1];?> active games</p>
                    <p><?php echo $row1[0];?> active players</p>
                    <p><?php echo $row2[0];?> player<?php if ($row2[0]!=1) echo "s"; ?> in the game queues</p>
                    <p><?php echo $row4[0];?> player<?php if ($row4[0]!=1) echo "s"; ?> left in the World Cup</p>
                </div>
            </div>
        </div><!-- Row -->
        <?php require_once("m/php/footer_base.php"); ?>

        <div class="modal fade hide" id="signup">
            <div class="modal-header">
                <button class="close" data-dismiss="modal">&times;</button>
                <h3>Sign up</h3>
            </div>
            <div class="modal-body">
                <div id="signupF">
                    <form class="form-horizontal">
                        <div class="control-group">
                            <div class="control-label"><label for="signupUsername">Enter your desired username</label></div>
                            <div class="controls"><input class="input-medium" type="text" id="signupUsername"/></div>
                        </div>
                        <div class="control-group">
                            <div class="control-label"><label for="signupEmail">Enter your email address</label></div>
                            <div class="controls"><input class="input-medium"  type="text" id="signupEmail"/></div>
                        </div>
                    </form>
                </div>
                <div id="signupP">
                </div>
            </div>
            <div class="modal-footer">
                <a href="#" class="btn btn-primary" id="signupOK">Register</a>
                <a href="#" class="btn btn-warning" data-dismiss="modal">Cancel</a>
            </div>
        </div><!-- Sign up modal -->

        <div class="modal fade hide" id="useless">
            <div class="modal-header">
                <button class="close" data-dismiss="modal">&times;</button>
                <h3>Resend password</h3>
            </div>
            <div class="modal-body">
                <div id="uselessF">
                    <p>Enter your email address <input type="text" id="uselessEmail"/></p>
                </div>
                <div id="uselessP">
                </div>
            </div>
            <div class="modal-footer">
                <a href="#" class="btn btn-primary" id="uselessOK">Retrieve</a>
                <a href="#" class="btn btn-warning" data-dismiss="modal">Cancel</a>
            </div>
        </div><!-- Sign up modal -->

    </div><!-- Container -->
    </body>
</html>
