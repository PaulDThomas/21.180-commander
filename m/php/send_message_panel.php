<h2>Send Communication</h2>
<!-- $Id: send_message_panel.php 282 2015-04-20 09:05:21Z paul $ -->
<?php 
$grey = ($RESOURCE['espionage_tech'] >= $GAME['grey_comms_level'])?'Y':'N';
$white = ($RESOURCE['espionage_tech'] >= $GAME['white_comms_level'])?'Y':'N';
$black = ($RESOURCE['espionage_tech'] >= $GAME['black_comms_level'])?'Y':'N';
?>
<form method="post" class="form-horizontal" id="sendForm" data-white="<?php echo $white; ?>"  data-grey="<?php echo $grey; ?>"  data-black="<?php echo $black; ?>" >
<input type="hidden" name="randgen" id="randgen" class="terrVal" value="<?php echo $RESOURCE['randgen']; ?>" />

<div class="row-fluid">
    <div class="span3">
        <div class="control-group">
            <div class="controls pull-right" style='margin-left:0px'>
<?php
// Print send global
if ($grey == 'Y') { ?>
    <label class="control-label" for="global"><i>Global</i>
        <input name="global" id="global" type="checkbox"/>
    </label>
<?php
}
// Print available powernames
if ($white == 'Y' or $black == 'Y') {
    $result = $mysqli -> query("Select powername From sp_resource Where gameno=$gameno and powername != '$powername' and (dead = 'N' or $phaseno=9)") or die($mysqli -> error);
    if ($result -> num_rows > 0) while ($row = $result -> fetch_assoc()) {?>
    <label class="control-label" for="<?php echo $row["powername"]; ?>"><?php echo $row["powername"]; ?>
        <input name="<?php echo $row["powername"]; ?>" class="powerChk" type="checkbox"/>
    </label>
<?php }
} else {echo "Specific communication not available";}
?>
            </div>
        </div>
    </div>

    <div class="span9 control-group" align="center">
        <textarea rows="10" style="width:100%" id="sndText" name="sndText"></textarea>
        <?php if ($white == 'Y' or $grey == 'Y') { ?>
            <input type="button" id="sndOK" class="btn btn-primary sndBtn" value="Send" style="margin-top:10px" />
        <?php } ?>
        <?php if ($black == 'Y') { ?>
            <input type="button" id="sndAnon" class="btn btn-primary sndBtn" value="Send Anonymous" style="margin-top:10px" />
        <?php } ?>
        <?php if ($RESOURCE['espionage_tech'] >= $GAME['yellow_comms_level']) { ?>
            <input type="button" id="sndAs" class="btn btn-primary sndBtn" value="Send As" style="margin-top:10px" />
        <?php } ?>
    </div>

</div><!-- Panel row -->
</form>

<ul class="pager">
    <li class="previous"><a href="#" id="commsOlder">&larr; <span class='visible-desktop'>Older</span></a></li>
    <a href='#' id='commsFewer'>&darr; <span class='visible-desktop'>Show fewer</span></a>
    <a class='disabled' id='commsN'>Updating...</a>
    <a href='#' id='commsMore'><span class='visible-desktop'>Show more</span> &uarr;</a>
    <li class="next"><a href="#" id="commsNewer"><span class='visible-desktop'>Newer </span>&rarr;</a></li></ul>
</ul>
<ul id="commsList" class="commanderList"></ul>
