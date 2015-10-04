<?php

// $Id: lstar_list.php 71 2012-04-09 22:09:48Z paul $
// Mobile resource card feed1

// Connect to database
session_start();
require("dbconnect.php");

// Set session
if (!isset($_SESSION['offset']) and isset($_COOKIE['offset'])) { $_SESSION['offset'] = $_COOKIE['offset']; }
if (!isset($_SESSION['dt_format']) and isset($_COOKIE['dt_format'])) { $_SESSION['dt_format'] = $_COOKIE['dt_format']; }

// Get game and user information
$gameno = isset($_SESSION['sp_gameno']) ? $_SESSION['sp_gameno']:'';
$userno = isset($_SESSION['sp_userno']) ? $_SESSION['sp_userno']:'';
$result = $mysqli -> query("Select powername, Count(*) From sp_cards Where gameno=$gameno and userno=$userno");
if ($result -> num_rows > 0) {
    $row = $result -> fetch_row();
    $powername = $row[0];
    $maxloan = $1000*min(12,floor($row[1]/2));
    $result -> close();
}

// Get resource card info
$query="
Select p.terrname, p.terrno
, Case
   When p.terrtype='xx' Then 'Default'
   When pw.powername='$powername' Then 'Home territories'
   Else ''
  End
, Case
   When p.terrtype='xx' Then '$powername'
   When b.userno=0 Then 'Locals'
   When b.userno=-1 and Length(p.terrtype)=4 Then 'Warlords'
   When b.userno=-1 Then 'Pirates'
   When b.userno=-9 Then 'Nuked'
   When b.userno=-10 Then 'Neutron'
   Else r.powername
  End
, Case
   When p.terrtype='xx' Then 'n/a' Else sf_format_troops(p.terrtype, b.major, b.minor)
  End
, count(l.terrno)
From (Select terrname, terrtype, terrno From sp_places Union Select 'Blanket Coverage', 'xx', 0) p
Left Join sp_board b On p.terrno=b.terrno and b.gameno=$gameno
Left Join sp_resource r On r.userno=b.userno and r.gameno=$gameno
Left Join sp_powers pw On pw.terrtype=p.terrtype
Left Join sp_lstars l On p.terrno=l.terrno and l.gameno=$gameno and l.userno=$userno
Group By 1, 2, 3, 4, 5
Order By
 Case
  When p.terrname='Blanket' Then '0'
  When pw.powername='$powername' Then '1'
  When b.userno=$userno Then '2'
  When b.userno in (0,-1) Then '3'
  When r.powername is not null Then r.powername
  Else b.userno
 End
 ,Case When pw.powername='$powername' Then 1 Else 2 End
 ,b.major*5+b.minor desc
 ,p.terrname
;";
$result = $mysqli -> query($query);

// Output to window
$last_type = '';
$row_num=0;
if ($result->num_rows > 0) { while ($row=$result->fetch_row()) {
?>
    <?php
    $row_num++;
    if ($row_num == 1) {
        ?>
                    <form id="lstarForm">
                    <div data-role='fieldcontain'>
                        <div class="ui-bar ui-bar-b">
                           <p>
                                <label for="lterr0">Blanket Coverage</label>
                                <input id="lterr0" type="range" min=0 max="<?php echo $lstar_slots; ?>" value="<?php echo $lstar_slots; ?>"/>
                            </p>
                        </div>
                <?php
        $last_type = (($row[2]!='')?$row[2]:$row[3]);
    } else {
        if ($last_type != (($row[2]!='')?$row[2]:$row[3])) {
            echo "</div>";
            echo "<h3>".(($row[2]!='')?$row[2]:$row[3])."</h3>";
            echo "<div class='ui-grid-b'>";
        }
        $last_type = (($row[2]!='')?$row[2]:$row[3]);
        ?>
            <div class="ui-block-a"><div class="ui-bar ui-bar-a"><p><?php echo $row[0]; ?></p></div></div>
            <div class="ui-block-b"><div class="ui-bar ui-bar-b"><p><?php echo $row[4]; ?></p></div></div>
            <div class="ui-block-c">
                <div class="ui-bar ui-bar-b">
                    <p style="margin:9px 0px 10px">
                        <label for="lterr<?php echo $row[1]; ?>" class="ui-hidden-accessible"><?php echo $row[0]; ?></label>
                        <input class="slots_allocated" name="lterr<?php echo $row[1]; ?>" type="number" value="<?php echo $row[5]; ?>" min="0"/>
                    </p>
                </div>
            </div>
        <?php
    if ($row_num == $result->num_rows) echo "</div></form>";
    }
}
?>

<?php } else {
?>No territories found!<?php
}

// Close result
$result -> close();
// Close connection
$mysqli -> close();
// Close session
session_write_close();

?>
