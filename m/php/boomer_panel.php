<h2>Boomer status</h2>
<?php
// Boomer status panel
// $Id: boomer_panel.php 203 2014-03-23 07:55:38Z paul $

// See if there are any boomers
$result = $mysqli -> query("Select Count(boomerno) From sp_boomers Where gameno=$gameno and userno=$userno") or die ($mysqli->error);
$row = $result -> fetch_row();
$boomers = $row[0];
$result -> close();

if ($boomers == 0) { ?><div align="center">No Boomers Active</div><?php }
else {
?><form id="boomerForm" class="form-horizontal">
<table class="table table-bordered table-condensed">
    <thead>
        <tr>
            <th rowspan='2'>Boomer</th>
            <th rowspan='2'>Nukes</th>
            <th rowspan='2'>Neutron Bombs</th>
            <th colspan='5'>Position</th>
        </tr>
        <tr>
            <th>&nbsp;</th>
            <th>Visible</th>
            <th>Owner</th>
            <th>Boomers</th>
            <th>Navies</th>
        </tr>
    </thead>
    <tbody>
        <?php
// Get boomer information
$result = $mysqli -> query("
Select bm.boomerno, m.terrname, bm.nukes, bm.neutron
      ,Case bm.visible When 'Y' Then 'Yes' When 'N' Then 'No' Else bm.visible End As visible
      ,m.powername, m.major, m.minor
From sp_boomers bm
Left Join sv_map m On bm.gameno=m.gameno and bm.terrno=m.terrno
Where bm.gameno=$gameno
 and bm.userno=$userno
Order By bm.boomerno
") or die ($mysqli -> error);
while ($row = $result -> fetch_assoc()) { ?>
        <tr>
            <td><?php echo $row['boomerno']; ?></td>
            <td><?php echo $row['nukes']; ?></td>
            <td><?php echo $row['neutron']; ?></td>
            <td><?php echo $row['terrname']; ?></td>
            <td><?php echo $row['visible']; ?></td>
            <td><?php echo $row['powername']; ?></td>
            <td><?php echo $row['major']; ?></td>
            <td><?php echo $row['minor']; ?></td>
        </tr>
<?php } $result -> close(); } ?>
    </tbody>
</table>
</form>