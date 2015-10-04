<script type="text/javascript"><!--
// $Id: orders_phase0.js 177 2013-12-28 16:07:52Z paul $
$(document).ready(function() {
    $('#Minerals').change(function() {
        if (isNaN($('#Minerals').val())) $('#Minerals').val('0');
        else if ($('#Minerals').val() > 9) $('#Minerals').val('9');
        else if ($('#Minerals').val() < 0) $('#Minerals').val('0');
        if ($('#Oil').val() > 9 - $('#Minerals').val() ) $('#Oil').val(9 - $('#Minerals').val());
        if ($('#Grain').val() != 9 - $('#Minerals').val() - $('#Oil').val() ) $('#Grain').val(9 - $('#Minerals').val() - $('#Oil').val());
    });

    $('#Oil').change(function() {
        if (isNaN($('#Oil').val())) $('#Oil').val('0');
        else if ($('#Oil').val() > 9) $('#Oil').val('9');
        else if ($('#Oil').val() < 0) $('#Oil').val('0');
        if ($('#Minerals').val() > 9 - $('#Oil').val() ) $('#Minerals').val(9 - $('#Oil').val());
        if ($('#Grain').val() != 9 - $('#Minerals').val() - $('#Oil').val() ) $('#Grain').val(9 - $('#Minerals').val() - $('#Oil').val());
    });

    $("#initOK").click(function(e) {
        $(this).attr("disabled", "disabled");
        $(this).val('Updating...');
        var formData = $('#initForm').serialize();
        $.ajax({
            type: "POST",
            url: "m/ajax/orders_phase0_update.php",
            cache: false,
            data: formData,
            error: onError,
            success: function(xml) {
                $('.initVal').each( function() {
                    if ($(xml).find($(this).attr('name')).text() != $(this).attr("data-start")) {
                        $(this).closest('.control-group').effect("highlight", {color:"#33dd33"}, 1000);
                        $(this).attr('data-start', $(xml).find($(this).attr('name')).text() );
                    } else {
                        $(this).closest('.control-group').effect("highlight", {color:"#3333dd"}, 1000);
                    }
                    $('#initOK').val('Process Orders');
                    $('#initOK').removeAttr('disabled');
                });
                // Comfort message
                $('#comfortHead').text('Processing');
                $('#comfortText').text($(xml).find('success').text());
                $('#comfort').modal('show');
            }
        });
    });
});
--></script>
