function terrInit() {
    // $Id: territory.js 218 2014-04-13 14:23:58Z paul $
    $("#terrOK").show();
    $("#terrOK").click(function(e) {
        $(this).attr("disabled", "disabled");
        $(this).val('Updating...');
        var formData = $('#terrForm').serialize();
        $.ajax({
            type: "POST",
            url: "m/ajax/territory_update.php",
            cache: false,
            data: formData,
            error: onError,
            success: function(xml) {
                $('.terrVal').each( function() {
                    if ($(xml).find($(this).attr('name')).text() != $(this).attr("data-start")) {
                        $(this).parent().parent().effect("highlight", {color:"#33dd33"}, 1000);
                        $(this).attr('data-start', $(xml).find($(this).attr('name')).text() );
                        if ($(this).hasClass('lstar')) {$('#mapRefresh').click();}
                    } else {
                        $(this).parent().parent().effect("highlight", {color:"#3333dd"}, 1000);
                     }
                });
                $('#terrOK').val('Update');
                $('#terrOK').removeAttr('disabled');
            }
        });
    });
};
