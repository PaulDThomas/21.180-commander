<?php
// Footer base file
// $Id: footer_base.php 106 2012-08-18 14:08:39Z paul $
?><footer class="footer">
    <p>Feedback to: <a href='mailto:suprem@asup.co.uk'>suprem@asup.co.uk</a></p>
    <p>Current time: <?php
echo gmdate((isset($_SESSION['dt_format'])?$_SESSION['dt_format']:'jS F Y h:i:s a'), time() - (isset($_SESSION['offset'])?$_SESSION['offset']:0)*60);
$timezone = (isset($_SESSION['offset'])?$_SESSION['offset']:0)/-60;
if ($timezone>0) print "  (GMT +$timezone)";
else if ($timezone==0) print "  (GMT)";
else print "  (GMT $timezone)";
?></p>
<p>Cookies are used on this site when your are logged in, and to track visits.</p>
</footer>
