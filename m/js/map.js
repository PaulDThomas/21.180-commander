// $Id: map.js 218 2014-04-13 14:23:58Z paul $
// Function to resize map and container
// Based on jQuery Mapz v1.0, by Danny van Kooten, http://dannyvankooten.com/jquery-plugins/mapz/
function constrain(iw,il,it) {
    //console.log("IN iw:"+iw+" il:"+il+" it:"+it);

    // Get current position in viewport
    var vw = $('#mapViewport').width();
    var vh = $('#mapViewport').height();

    // Work out new height
    var ih = Math.floor(iw *1060/1489);

    $('#mapDiv').css({
        left : -(iw) + vw,
        top : -(ih) + vh,
        width : 2 * iw - vw,
        height : 2 * ih - vh
    });

    $("#mapImage").css({left:Math.min(il,iw-vw) ,top :Math.min(it,ih-vh), width:iw, height:ih});
    //console.log("After IW:"+$("#mapImage").css('width')+" IH:"+$("#mapImage").css('height')+" L:"+$("#mapImage").css('left')+" T:"+$("#mapImage").css('top'));

    // Change areas position
    $("#map1 area").each(function() {
        var coords = $(this).attr('start-coords').split(',');
        for(var i=0; i<coords.length; i++) {
            coords[i] = parseFloat(coords[i]) * $("#mapImage").height() / 1060 ;
        }
        $(this).attr("coords", coords.join(','));
    });
}

function mapHeight() {
    $("#mapViewport").height($("#mapViewport").width() *1060/1489);

    var vw = $('#mapViewport').width();
    var vh = $('#mapViewport').height();
    var iw = 1489;
    var ih = 1060;

    // Ensure that the map container is large enough for full map, using full image size
    $('#mapDiv').css({
        left : -(iw) + vw,
        top : -(ih) + vh,
        width : 2 * iw - vw,
        height : 2 * ih - vh
    });

    //alert ("Viewport VW:"+vw+" VH:"+vh);

    // Put the image in the right place
    constrain($('#mapViewport').width(),0,0);
}

function mapInit() {
    // Load all maps
    mapLoad();

    // Function for clicking on an area
    $("area").click(function(e) {
        // Update modal infor
        $('#terrTitle').text( $(this).attr('data-title') );
        // Add info into the modal body from AJAX call
        $("#terrBody").empty();
        var guest = $(this).attr('data-owned');
        $.ajax({
            type: "POST",
            url: "m/ajax/territory_html.php",
            cache: false,
            data: 'terrno='+$(this).attr('data-content'),
            success: function(data,Status) {
                $("#terrBody").append().html(data);
                if (guest=='guest') {$('.terrVal').closest('tr').hide();}
                // Hide or show Update button
                if ($('#terrBody').find('select').length > 0) $('#terrOK').show();
                else $('#terrOK').hide();
            },
            error: onError
        });
        // Show modal
        $('#terrModal').modal('show');
    });

    // Add dragging
    $('#mapImage').draggable({containment:"#mapDiv"});

    // Actions for zoom in and out
    $('#mapViewport').mousewheel(function(event, delta) {
        // Get initial mouse position on Image
        var parentOffset = $(this).parent().offset();
        var relX = event.pageX - parentOffset.left;
        var relY = event.pageY - parentOffset.top;
        var vw = $(this).width();
        var vh = $(this).height();
        //alert ("X:" + relX + "  Y:" + relY);

        // Work out change
        var dw = (delta>0?50:-50);
        var dh = (delta>0?50:-50) * 1060/1489;

        // Calculate new width & height
        var nw = Math.max( $("#mapViewport").width() , $("#mapImage").width()+dw);
        var nh = Math.floor(nw * 1060/1489);

        // Calculate new position
        var p  = $('#mapImage').position();
        var nl = Math.max(0, p.left + dw*((vw-relX)/vw));
        var nt = Math.max(0, p.top + dh*((vh-relY)/vh));

        // Change view
        constrain(nw,nl,nt);

        // Stop default event
        return false;
    });

    // Cope with window resize event
    $(window).resize(function() {mapHeight();});
}

function mapLoad() {
    //console.log("Loading maps...");
    $(".supremMap").each(function() {
        console.log("Found map: "+$(this).attr("data-mapHash"));
        var e=$(this).attr("id")
            ,l="map_"+$(this).attr("data-mapHash")
            ,g=$(this).attr("data-gameno")
            ,x=$(this).attr("data-width")
            ;
        var mapStored = localStorage.getItem(l);
        var map = document.getElementById(e);
        console.log("looking for map : "+l);

        if (!window.FileReader || !window.XMLHttpRequest) {
            //console.log("No FileReader, setting source: "+e);
            map.setAttribute("src","m/ajax/map.php?xgame="+g+"&xsize="+x);
            // Trigger resize function for initial window
            mapHeight();
        } else if (mapStored) {
            //console.log("Map retrieved: " + l);
            map.setAttribute("src",mapStored);
            // Trigger resize function for initial window
            mapHeight();
            //console.log("Map placed: " + e);
        } else {
            var xhr = new XMLHttpRequest()
                ,blob
                ,fileReader = new FileReader()
                ,url
                ;
            url = "m/ajax/map.php?xgame="+g+"&xsize="+x;
            //console.log("Getting map: " + url);
            xhr.open("GET", url, true);
            xhr.responseType = "arraybuffer";

            xhr.addEventListener("load", function () {
                //console.log("loading..."+xhr.status);
                if (xhr.status === 200) {
                    blob = new Blob([xhr.response], {type: "image/png"});
                    fileReader.onload = function (evt) {
                        //console.log("FileReader loading");
                        var result = evt.target.result;
                        map.setAttribute("src", result);
                            // Trigger resize function for initial window
                            mapHeight();
                        try {
                            localStorage.setItem(l,result);
                        } catch (e) {
                            //console.log("Storage fail: "+l);
                        }
                    }
                    // Load BLOB as URL
                    fileReader.readAsDataURL(blob);
                }
            },false);
            // Send XHR
            xhr.send();
        }
    });

    $('#mapRefresh').click(function(){console.log("Refresh");storageClean('f');mapLoad();});
};