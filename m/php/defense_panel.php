<H2>Territory Defense Status</H2>
<!-- $Id: defense_panel.php 190 2014-02-03 18:14:41Z paul $ -->
<form method="post" class="form-horizontal" id="terrForm">
<input type="hidden" name="randgen" id="randgen" value="<?php echo $RESOURCE['randgen']; ?>" />

<h4>Land Territories</h4>
<table class="table table-bordered">
    <thead>
        <tr>
            <th width='20%'>Territory</th>
            <th width='7%'>Tanks</th>
            <th width='7%'>Armies</th>
            <th width='7%' class='hidden-phone'>Minerals</th>
            <th width='7%' class='hidden-phone'>Oil</th>
            <th width='7%' class='hidden-phone'>Grain</th>
            <th width='15%'>
                <div class="dropdown">
                    <div data-toggle="dropdown" class="dropdown-toggle">Defense<b class="caret"></b></div>
                    <ul class="dropdown-menu" align="left">
                        <li><a class="defDef">Defend</a></li>
                        <li><a class="defRes">Resist</a></li>
                        <li><a class="defSur">Surrender</a></li>
                    </ul>
                </div>
            </th>
            <th width='15%'>
                <div class="dropdown">
                    <div data-toggle="dropdown" class="dropdown-toggle">Attack Tanks<b class="caret"></b></div>
                    <ul class="dropdown-menu" align="left">
                        <li><a class="amYes">Yes</a></li>
                        <li><a class="amNo">No</a></li>
                    </ul>
                </div>
            </th>
            <th width='15%'>Right of Passage</th>
        </tr>
    </thead>
    <tbody>
<?php
$result = $mysqli -> query("Select * From sv_map Where gameno=$gameno and userno=$userno and Length(terrtype)=4 and info=1");
if ($result -> num_rows > 0) while ($TERRITORY = $result -> fetch_assoc()) { ?>
    <tr>
        <td><?php echo $TERRITORY['terrname']; ?></td>
        <td><?php echo $TERRITORY['major']; ?></td>
        <td><?php echo $TERRITORY['minor']; ?></td>
        <td class='hidden-phone'><?php echo $TERRITORY['minerals']; ?></td>
        <td class='hidden-phone'><?php echo $TERRITORY['oil']; ?></td>
        <td class='hidden-phone'><?php echo $TERRITORY['grain']; ?></td>
        <td><div><?php terrDefenseBtn($TERRITORY) ?></div></td>
        <td><div><?php terrAttMajBtn($TERRITORY) ?></div></td>
        <td><div><?php terrROPBtn($TERRITORY) ?></div></td>
    </tr>
<?php }?>
    </tbody>
</table>

<h4>Seas and Oceans</h4>
<table class="table table-bordered">
    <thead>
        <tr>
            <th width='20%'>Territory</th>
            <th width='7%'>Navies</th>
            <th width='7%' class='hidden-phone'>Minerals</th>
            <th width='7%' class='hidden-phone'>Oil</th>
            <th width='7%' class='hidden-phone'>Grain</th>
            <th width='15%'>
                <div class="dropdown">
                    <div data-toggle="dropdown" class="dropdown-toggle">Defense<b class="caret"></b></div>
                    <ul class="dropdown-menu" align="left">
                        <li><a class="defDef">Defend</a></li>
                        <li><a class="defRes">Resist</a></li>
                        <li><a class="defSur">Surrender</a></li>
                    </ul>
                </div>
            </th>
            <th width='15%'>Right of Passage</th>
        </tr>
    </thead>
    <tbody>
<?php
$result = $mysqli -> query("Select * From sv_map Where gameno=$gameno and userno=$userno and Length(terrtype)=3 and info=1");
if ($result -> num_rows > 0) while ($TERRITORY = $result -> fetch_assoc()) { ?>
    <tr>
        <td><?php echo $TERRITORY['terrname']; ?></td>
        <td><?php echo $TERRITORY['minor']; ?></td>
        <td class='hidden-phone'><?php echo $TERRITORY['minerals']; ?></td>
        <td class='hidden-phone'><?php echo $TERRITORY['oil']; ?></td>
        <td class='hidden-phone'><?php echo $TERRITORY['grain']; ?></td>
        <td><div><?php terrDefenseBtn($TERRITORY) ?></div></td>
        <td><div><?php terrROPBtn($TERRITORY) ?></div></td>
    </tr>
<?php }?>
    </tbody>
</table>

<div class="row-fluid"><div class="span12" align="center"><input class="btn btn-primary" type="button" value="Update" name="PROCESS" id="terrOK" /></div></div>

</form>
