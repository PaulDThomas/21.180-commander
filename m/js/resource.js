function resourceInit() {
    // $Id: resource.js 86 2012-06-07 23:24:07Z paul $

    // Set up refresh function
    function resRefresh (xml) {
        // Look for a value for each resource slot in the XML
        $('.resourceVal').each (function() {
            $(this).text( $(xml).find( $(this).attr('id') ).text() );
        });
    }

    // Get initial resources
    $.ajax({
        type: "POST",
        url: "m/ajax/resource_xml.php",
        cache: false,
        dataType: "xml",
        success: resRefresh,
        error: onError
    });

    // Set up drop-down changes
    $('.powerLink').click( function() {
        $.ajax({
            type: "POST",
            url: "m/ajax/resource_xml.php",
            cache: false,
            dataType: "xml",
            data: "powername=" + $(this).text(),
            success: resRefresh,
            error: onError
        });
    });

};
