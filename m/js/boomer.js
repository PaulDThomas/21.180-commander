function boomerInit() {
    // $Id: boomer.js 203 2014-03-23 07:55:38Z paul $
    $("#boomerOK").click(function(e) {
        $(this).attr("disabled", "disabled");
        $(this).val('Updating...');
        var formData = $('#boomerForm').serialize();
        $.ajax({
            type: "POST",
            url: "m/ajax/boomer_update.php",
            cache: false,
            data: formData,
            error: onError,
            success: function(xml) {
/*
                $('.slotVal').each( function() {
                    if ($(xml).find($(this).attr('id')).text() != $(this).attr('data-start')) {
                        $(this).parent().effect("highlight", {color:"#33dd33"}, 1000);
                        $(this).attr('data-start', $(xml).find($(this).attr('id')).text() );
                        if ($(this).is("div")) $(this).text( $(xml).find($(this).attr('id')).text() );
                    } else {
                        $(this).parent().effect("highlight", {color:"#3333dd"}, 1000);
                    }
                });
*/
                $("#boomerOK").val('Update');
                $("#boomerOK").removeAttr('disabled');
            }
        });
    });
};
