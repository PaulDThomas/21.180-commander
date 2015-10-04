<!-- Commander Navigation Bar -->
<!-- $Id: navbar.php 203 2014-03-23 07:55:38Z paul $ -->
<div class="navbar navbar-fixed-top">
<div class="navbar-inner">
  <div class="container">
    <a class="brand" href="http://game.asup.co.uk/index.php">21.180 Commander</a>
    <ul class="nav">

      <li class="dropdown"><!-- Game dropdown -->
        <a href='#' class="dropdown-toggle" data-toggle="dropdown">Games<b class="caret"></b></a>
        <ul class="dropdown-menu">
            <?php
            if (isset($_SESSION['sp_userno'])) {
            // Assume database connection is open
            $nb_result = $mysqli -> query("Select r.gameno, dead, beta, phaseno From sp_resource r Left Join sp_game g On r.gameno=g.gameno Where userno=${_SESSION['sp_userno']}");
            while ($nb_row = $nb_result -> fetch_assoc()) { ?>
                <li><a href="<?php if ($nb_row['beta']==0) echo "game.php?gameselect=${nb_row['gameno']}";
                     else if ($nb_row['beta']==-1) echo "legacy/next.php?gameselect=${nb_row['gameno']}";
                     else if ($nb_row['beta']==1) echo "beta/game.php?gameselect=${nb_row['gameno']}";
               ?>">Game <?php echo $nb_row['gameno']; if ($nb_row['dead'] != 'N') {echo " - Defeated";} else if ($nb_row['phaseno']==9) {echo " - Victorious";} ?></a></li><?php }
            $nb_result -> close(); ?>
            <li><a href="queue.php">Queue</a></li>
            <?php } ?>
          <li><a href="finished.php">Rankings</a></li>
          <li><a href="guest.php">Browse Games</a></li>
        </ul>
        <?php if (!isset($_SESSION['sp_userno']) and stripos($_SERVER['PHP_SELF'],'login.php') > 0 ) {?><!-- Not signed in -->
            <li><a data-toggle="modal" href="login.php#signup">Sign up</a></li>
            <li><a data-toggle="modal" href="login.php#useless">Forgotten Password</a></li>
        <?php } ?>
      </li><!-- Game dropdown -->

      <?php if (isset($_SESSION['sp_gameno']) && isset($_SESSION['sp_powername'])) { ?><!-- In Game dropdowns -->
        <?php if ($RESOURCE['dead']=='N') { ?>
        <li class="dropdown">
          <a href='#' class="dropdown-toggle" data-toggle="dropdown">Actions<b class="caret"></b></a>
          <ul class="dropdown-menu">
            <?php if ($GAME['deadline_uts'] < time() and $GAME['process']=='') { ?> <li><a data-toggle="modal" href="#ac_force">Force Pass</a></li><?php } ?>
            <li><a href="game.php">Orders</a></li>
            <li><a href="banking.php">Banking</a></li>
            <li><a href="messages.php">Send Communication</a></li>
            <li><a href="defense.php">Defense status</a></li>
            <li><a href="lstar_admin.php">Satellite status</a></li>
            <li><a href="resign.php">Resign</a></li>
          </ul>
        </li>
        <?php } ?>
        <li class="dropdown">
          <a href='#' class="dropdown-toggle" data-toggle="dropdown">Information<b class="caret"></b></a>
          <ul class="dropdown-menu">
            <li><a href="mapholder.php">Map</a></li>
            <li><a href="boomer_admin.php">Boomer status</a></li>
            <li><a href="resource.php">Resources</a></li>
            <li><a href="status.php">Status &amp; Parameters</a></li>
            <li><a href="companies.php">Companies</a></li>
            <li><a href="market.php">Market &amp; Loans</a></li>
            <li><a href="ma.php">Movement costs</a></li>
          </ul>
        </li>
      <?php } ?><!-- In Game dropdowns -->
      <?php // World Cup
    if (isset($USER['username']) and time() <= strtotime('28-Feb-2014')) {
        $result = $mysqli->query("Select Count(*) From sp_worldcup");
        $row = $result -> fetch_row();
        ?> <li><a href="worldcup.php"><i class="icon-globe icon-white"></i> World Cup - <?php echo $row[0]; ?> signed up</a></li><?php
        $result -> close();
    }
    ?>
    </ul><!-- Left Nav -->

    <ul class="nav pull-right">
      <li><a href="http://game.asup.co.uk/wiki/"><i class="icon-question-sign icon-white"></i> Wiki</a></li>
      <?php if (isset($_SESSION['sp_userno'])) { ?>
        <li class="dropdown">
            <a href='#' class="dropdown-toggle" data-toggle="dropdown"><i class="icon-user icon-white"></i><b class="caret"></b></a>
            <ul class="dropdown-menu">
              <li><a href="login.php?logout=yes"><i class="icon-off"></i> Log out</a>
              <li><a href="profile.php"><i class="icon-cog"></i> Profile</a></li>
              <li><a href="holidays.php"><i class="icon-plane"></i> Holidays</a></li>
            </ul>
        </li>
      <?php } ?>
    <?php if ((isset($USER['admin'])?$USER['admin']:'') == 'Y') { ?><!-- Admin dropdowns -->
        <li class="dropdown">
          <a href='#' class="dropdown-toggle" data-toggle="dropdown"
           <?php
             $nb_result = $mysqli -> query("Select gameno From sp_game Where process is not null") or die($mysqli -> error);
             if ($nb_result -> num_rows > 0) {?>style="color: red; background-color:yellow;"<?php }
             $nb_result -> close();
           ?>><i class="icon-wrench icon-white"></i><b class="caret"></b></a>
          <ul class="dropdown-menu">
            <li><a href="deb_query.php">Query</a></li>
            <li><a href="old_orders.php">Old Orders</a></li>
            <li><a href="reset.php">Reset</a></li>
            <li><a href="deb_mail.php">Administrator Mail</a></li>
            <li><a data-toggle="modal" href="#ad_post">$_POST</a></li>
            <li><a data-toggle="modal" href="#ad_session">$_SESSION</a></li>
            <li><a data-toggle="modal" href="#ad_cookie">$_COOKIE</a></li>
            <li><a data-toggle="modal" href="#ad_server">$_SERVER</a></li>
            <li><a data-toggle="modal" href="#ad_query">$query_out</a></li>
          </ul>
        </li>
      <?php } ?><!-- Admin dropdowns -->
    </ul><!-- Right Nav -->
  </div>
</div>
</div><!-- Navbar -->

<?php if (isset($USER['admin'])?$USER['admin']:'' == 'Y') { ?>
<!-- Admin modals -->
<div class="modal fade hide" id="ad_post">
    <div class="modal-header">
        <button class="close" data-dismiss="modal">&times;</button>
        <h3>$_POST</h3>
    </div>
    <div class="modal-body">
        <pre><?php print_r($_POST); ?></pre>
    </div>
    <div class="modal-footer">
        <a href="#" class="btn btn-primary" data-dismiss="modal">Close</a>
    </div>
</div><!-- Modal -->
<div class="modal fade hide" id="ad_session">
    <div class="modal-header">
        <button class="close" data-dismiss="modal">&times;</button>
        <h3>$_SESSION</h3>
    </div>
    <div class="modal-body">
        <pre><?php print_r($_SESSION); ?></pre>
    </div>
    <div class="modal-footer">
        <a href="#" class="btn btn-primary" data-dismiss="modal">Close</a>
    </div>
</div><!-- Modal -->
<div class="modal fade hide" id="ad_cookie">
    <div class="modal-header">
        <button class="close" data-dismiss="modal">&times;</button>
        <h3>$_COOKIE</h3>
    </div>
    <div class="modal-body">
        <pre><?php print_r($_COOKIE); ?></pre>
    </div>
    <div class="modal-footer">
        <a href="#" class="btn btn-primary" data-dismiss="modal">Close</a>
    </div>
</div><!-- Modal -->
<div class="modal fade hide" id="ad_server">
    <div class="modal-header">
        <button class="close" data-dismiss="modal">&times;</button>
        <h3>$_SERVER</h3>
    </div>
    <div class="modal-body">
        <pre><?php print_r($_SERVER); ?></pre>
    </div>
    <div class="modal-footer">
        <a href="#" class="btn btn-primary" data-dismiss="modal">Close</a>
    </div>
</div><!-- Modal -->
<div class="modal fade hide" id="ad_query">
    <div class="modal-header">
        <button class="close" data-dismiss="modal">&times;</button>
        <h3>$query_out</h3>
    </div>
    <div class="modal-body">
        <pre><?php echo isset($query_out)?$query_out:''; ?></pre>
    </div>
    <div class="modal-footer">
        <a href="#" class="btn btn-primary" data-dismiss="modal">Close</a>
    </div>
</div><!-- Modal -->
<?php } ?>
<?php if ((isset($_SESSION['sp_powername'])?$GAME['deadline_uts']:time()-10) < time()) { ?>
    <!-- Force pass modal -->
    <div class="modal fade hide" id="ac_force">
    <div class="modal-header">
        <button class="close" data-dismiss="modal">&times;</button>
        <h3>Force Pass</h3>
    </div>
    <div class="modal-body" align="center">
        <form method='post' id='forceForm' action='game.php'>
            <input type="hidden" name="randgen" value="<?php echo isset($RESOURCE['randgen'])?$RESOURCE['randgen']:0; ?>"/>
            <input type="hidden" name="Force" value="Force"/>
            <input type="submit" value="Force Pass" name="PROCESS" class="btn btn-danger"/>
        </form>
    </div>
    </div><!-- Modal -->
<?php } ?>
<!-- Comfort Modal -->
<div class="modal fade hide" id="comfort">
    <div class="modal-header">
        <button class="close" data-dismiss="modal">&times;</button>
        <h3 id="comfortHead"></h3>
    </div>
    <div class="modal-body" id="comfortText">
    </div>
    <div class="modal-footer">
        <a href="#" class="btn btn-primary" data-dismiss="modal">Close</a>
    </div>
</div><!-- Modal -->