<?php
// World Cup panel
// $Id: worldcup_panel.php 189 2014-01-28 20:24:22Z paul $
?>
<h2>Sign up for the World Cup 2012</h2>
<h3>Entries will be accepted until 28th February 2014</h3>

<p>It's now time for the 10th Supremacy World Cup.</P>
<p>Games will use the current 21.180 Commander rules, and default game options.</P>
<p>To sign up you must have a current 21.180 account, and you'll need to provide some additional information like your name.
<p>I'll announce the tournament structure once entries have closed</P>

<form id='wcForm'>
<table class="table table-bordered table-condensed">
    <tr>
        <th>Username</th>
        <td><?php echo $username; ?></td>
    </tr>
    <tr>
        <th>First name</th>
        <td><div class="controls"><input type='text' class='wcVal' data-start='' name="first_name" class="input-large" value=''/></div></td>
    </tr>
    <tr>
        <th>Last name</th>
        <td><div class="controls"><input type='text' class='wcVal' data-start='' name="last_name" class="input-large" value=''/></div></td>
    </tr>
    <tr>
        <th>Region</th>
        <td><div class="controls"><input type='text' class='wcVal' data-start='' name="region" class="input-large" value=''/></div></td>
    </tr>
    <tr>
        <th>Country</th>
        <td><div class="controls"><input type='text' class='wcVal' data-start='' name="country" class="input-large" value=''/></div></td>
    </tr>
</table>

<div class="controls" align="center">
    <input id="wcPost" type='button' value='Join' class="btn"/>
</div>

</form>

<script type="text/javascript">
<!--
$('#wcPost').click( function () {
    $(this).attr("disabled", "disabled");
    $(this).val('Updating...');
    var formData = $("#wcForm").serialize();
    $.ajax({
        type: "POST",
        url: "m/ajax/worldcup_update.php",
        cache: false,
        data: formData,
        error: onError,
        success: function(xml) {
            $('.wcVal').each( function() {
                if ($(xml).find($(this).attr('name')).text() != $(this).attr('data-start')) {
                    $(this).closest('td').effect("highlight", {color:"#33dd33"}, 1000);
                    $(this).attr('data-start', $(xml).find($(this).attr('name')).text() );
                    $(this).attr('value', $(xml).find($(this).attr('name')).text() );
                } else {
                    $(this).closest('td').effect("highlight", {color:"#3333dd"}, 1000);
                }
            });
        $('#wcPost').val('Update');
        $('#wcPost').removeAttr('disabled');
        }
    });
    return false;
});
-->
</script>
