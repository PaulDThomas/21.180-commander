<?php // $Id: map_panel.php 203 2014-03-23 07:55:38Z paul $ ?>
<div class="map-viewport" id="mapViewport"><div id="mapDiv">
<img class="supremMap" usemap='#map1' id='mapImage' data-width="1489" data-mapHash="<?php echo $mapHash; ?>" data-gameno="<?php echo $gameno; ?>" src='m/themes/img/ajax-loader.gif'/>
</div>
<map name='map1' id='map1'>
<?php
// Get co-ordinates, forces and powers
$result = $mysqli -> query("Select m.terrno, terrname, x, y, terrtype, major, minor
                                   ,Case When powername='$powername' Then 'Yes' Else 'No' End As owned
                                   ,boomers
                            From sv_map m
                            Left Join (Select terrno, Count(boomerno) As boomers From sp_boomers Where gameno=$gameno and userno=$userno and visible!='Y' Group By 1) bm
                            On m.terrno=bm.terrno
                            Where gameno=$gameno") or die ($mysqli->error);
while ($row = $result -> fetch_assoc()) { ?>
<area shape='circle'
      data-content='<?php echo $row['terrno']; ?>'
      data-title='<?php echo $row['terrname'].(($USER['admin']=='Y')?(' ('.$row['terrno'].')'):''); ?>'
      data-owned='<?php echo $row['owned']; ?>'
      start-coords='<?php echo $row['x'].",".$row['y']; ?>,20'
      coords='<?php echo $row['x'].",".$row['y']; ?>,20'
      title='<?php echo "${row['terrname']}".(($USER['admin']=='Y')?(' ('.$row['terrno'].')'):'')."\r\n"
                  .((strlen($row['terrtype'])==3)
                     ?($row['major']>0?"Visible Boomers: ${row['major']}\r\n":"").($row['boomers']>0?"Hidden Boomers: ${row['boomers']}\r\n":"")."Navies: ${row['minor']}"
                     :($row['major']>0?"Tanks: ${row['major']}\r\n":"")."Armies: ${row['minor']}");
        ?>'
      nohref
      rel='tooltip'
      />
<?php } ?>
</map>
</div>
<!-- Map Panel -->
