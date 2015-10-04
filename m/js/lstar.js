function lstarInit() {
    // $Id: lstar.js 116 2012-09-19 19:52:47Z paul $
    $("#lstarOK").click(function(e) {
        $(this).attr("disabled", "disabled");
        $(this).val('Updating...');
        var formData = $('#lstarForm').serialize();
        $.ajax({
            type: "POST",
            url: "m/ajax/lstar_update.php",
            cache: false,
            data: formData,
            error: onError,
            success: function(xml) {
                $('.slotVal').each( function() {
                    if ($(xml).find($(this).attr('id')).text() != $(this).attr('data-start')) {
                        $(this).parent().effect("highlight", {color:"#33dd33"}, 1000);
                        $(this).attr('data-start', $(xml).find($(this).attr('id')).text() );
                        if ($(this).is("div")) $(this).text( $(xml).find($(this).attr('id')).text() );
                    } else {
                        $(this).parent().effect("highlight", {color:"#3333dd"}, 1000);
                    }
                    $("#lstarOK").val('Update');
                    $("#lstarOK").removeAttr('disabled');
                });
            }
        });
    });
};
