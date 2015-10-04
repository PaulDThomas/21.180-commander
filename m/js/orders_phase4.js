<script type="text/javascript">
    <!--
    // $Id: orders_phase4.js 269 2015-01-06 22:43:44Z paul $

    function recalc() {
        var to = $('#terrtype_to').val();
        var Action = $('#Action').val();
        var fly = ['Fly', 'Aerial'];
        var sail = ['Sail', 'Transport', 'Naval', 'Amphibious', 'Land'];
        var march = ['March', 'Ground', 'Sea'];
        var moves = ['March', 'Sail', 'Transport', 'Fly'];
        var attacks = ['Ground', 'Naval', 'Aerial', 'Amphibious', 'Land', 'Sea'];
        var attack_minus_distance = ['Ground', 'Naval'];
        var strategic = ['Warhead', 'Satellite', 'Boomer'];
        var carry = ['Transport', 'Amphibious'];

        // Sort out labels for results
        if (to == 'LAND') {
            $('#minorName').text('Armies');
            $('#majorName').text('Tanks');
            $('#attMajorName').text('Attack Tanks first?');
        } else if (to == 'SEA') {
            $('#minorName').text('Navies');
            $('#majorName').text('Boomers');
            $('#attMajorName').text('Attack Boomers first?');
        } else {
            $('#minorName').text('');
            $('#majorName').text('');
            $('#attMajorName').text('');
        }

        // Check numbers
        $('input[type=number]').each(function () {
            if ($(this).isNaN) { $(this).val('0'); }
            if (parseInt($(this).val(),10) > $(this).attr('max')) { $(this).val($(this).attr('max')); }
            if (parseInt($(this).val(),10) < $(this).attr('min')) { $(this).val($(this).attr('min')); }
        });

        // Enable process button if somewhere to attack and some troops or targets
        if (Action == 'Pass') {
            $('#processOrders').val('Pass').removeAttr('disabled');
        } else if ($.inArray(Action, moves) >= 0) {
            $('#processOrders').val('Move');
            if ($('#powername').text() != '' && Math.max($('#Tanks').val(), $('#Boomers').val(), $('#Armies').val(), $('#Navies').val()) > 0) {
                $('#processOrders').removeAttr('disabled', 'disabled');
            } else {
                $('#processOrders').attr('disabled', 'disabled');
            }
        } else if ($.inArray(Action, ['Land', 'Sea']) >= 0) {
            $('#processOrders').val('Attack');
            if ($('#powername').text() != ''
                && Math.max($('#Armies').val(), $('#Navies').val()) > 0
                && ( ($('#terr_to option:selected').attr('minor')>0 && Action=='Land')
                     | ($('#sea_to option:selected').attr('minor')>0 && Action=='Sea')
                    )
                ) {
                $('#processOrders').removeAttr('disabled', 'disabled');
            } else {
                $('#processOrders').attr('disabled', 'disabled');
            }
        } else if ($.inArray(Action, attacks) >= 0) {
            $('#processOrders').val('Attack');
            if ($('#powername').text() != ''
                && Math.max($('#Tanks').val(), $('#Armies').val(), $('#Boomers').val(), $('#Navies').val()) > 0
                ) {
                $('#processOrders').removeAttr('disabled', 'disabled');
            } else {
                $('#processOrders').attr('disabled', 'disabled');
            }
        } else if (Action == 'Ambush') {
            $('#processOrders').val('Ambush');
            if ($('#ambushBoomer option:selected').attr('data-powername')=='') {
                $('#processOrders').attr('disabled', 'disabled');
            } else {
                $('#processOrders').removeAttr('disabled');
            }
        } else if (Action == 'Boomer') {
            $('#processOrders').val('Launch');
            if ($('#launchBoomer option:selected').attr('data-powername')=='') {
                $('#processOrders').attr('disabled', 'disabled');
            } else {
                var n = 0;
                var ok = 0;
                $('.targetRow').each(function () {
                    n++;
                    if ($(this).find('.targetTerr').val() != '-- None --' && (parseInt($(this).find('.nuke').val(),10) + parseInt($(this).find('.neutron').val(),10)) > 0 && !$(this).find('.error').hasClass('error')) {
                        ok++;
                        $('#processOrders').removeAttr('disabled');
                    } else if ($(this).find('.targetTerr').val() == '-- None --' && parseInt($(this).find('.nuke').val(),10) + parseInt($(this).find('.neutron').val(),10) == 0) ok++;
                });
                if (ok < n) {
                    $('#processOrders').attr('disabled', 'disabled');
                }
            }
        } else if (Action == 'Warhead') {
            $('#processOrders').val('Launch').attr('disabled', 'disabled');
            var n = 0;
            var ok = 0;
            $('.targetRow').each(function () {
                n++;
                if ($(this).find('.targetTerr').val() != '-- None --' && (parseInt($(this).find('.nuke').val(),10) + parseInt($(this).find('.neutron').val(),10)) > 0 && !$(this).find('.error').hasClass('error')) {
                    ok++;
                    $('#processOrders').removeAttr('disabled');
                } else if ($(this).find('.targetTerr').val() == '-- None --' && parseInt($(this).find('.nuke').val(),10) + parseInt($(this).find('.neutron').val(),10) == 0) ok++;
            });
            if (ok < n) {
                $('#processOrders').attr('disabled', 'disabled');
            }
        } else if (Action == 'Space') {
            $('#processOrders').val('Launch').attr('disabled', 'disabled');
            if ($('#space_nukes').val() > 0) {
                $('#processOrders').removeAttr('disabled', 'disabled');
            }
        } else if (Action == 'Satellite') {

        } else $('#processOrders').attr('disabled', 'disabled');

        // Calculate distance
        if ($.inArray(Action, sail) >= 0) $('#distance').text($('#sea_to option:selected').attr('distance'));
        else if ($.inArray(Action, march) >= 0) $('#distance').text($('#terr_to option:selected').attr('distance'));
        else if ($.inArray(Action, fly) >= 0) $('#distance').text($('#terr_to option:selected').attr('distance'));
        else if (Action=='Ambush') $('#distance').text($('#ambushBoomer option:selected').attr('data-distance'));
        else $('#distance').text('');
        var distance = parseInt(0 + $('#distance').text());

        // Check boat volumes
        if ($.inArray(Action, carry) >= 0 && $('#Tanks').val() * 2 + parseInt($('#Armies').val()) > $('#Navies').val() * 4) {
            $('.troops').closest('.control-group').addClass('error');
            $('#processOrders').attr('disabled', 'disabled');
        } else $('.troops').closest('.control-group').removeClass('error');

        // Calculate spend
        $('.costRow').each(function () {
            // Flying
            if ($.inArray(Action, fly) >= 0) {
                $(this).find('.Spend').text(Math.ceil($(this).attr('fly_j') * $('#Tanks').val() * distance + $(this).attr('fly_n') * $('#Armies').val() * distance));

            // Sailing
            } else if ($.inArray(Action, sail) >= 0) {
                $(this).find('.Spend').text(Math.ceil($(this).attr('sail_n') * $('#Navies').val() * (distance - ($.inArray(Action, attack_minus_distance) >= 0))));
                if ($.inArray(Action,carry) >= 0 && $(this).find('.Spend').text()==='0') { $(this).find('.Spend').text(Math.ceil($(this).attr('sail_n'))); }
                if (parseInt($("#Boomers").val()) > 0 && $(this).find('.Spend').text()==='0') { $(this).find('.Spend').text(Math.ceil($(this).attr('sail_n'))); }
            // Marching
            } else if ($.inArray(Action, march) >= 0) {
                $(this).find('.Spend').text(Math.ceil($(this).attr('march_j') * $('#Tanks').val() * (distance - ($.inArray(Action, attack_minus_distance) >= 0)) + $(this).attr('march_n') * $('#Armies').val() * (distance - ($.inArray(Action, attack_minus_distance) >= 0))));

            } else $(this).find('.Spend').text('0');

            // Add attack
            if ($.inArray(Action, attacks) >= 0) {
                $(this).find('.Spend').text(parseInt($(this).find('.Spend').text()) + 1);
            }

            // Remaining
            $(this).find('.Remaining').text(parseInt($(this).find('.Available').text()) - parseInt($(this).find('.Spend').text()));
            if (parseInt($(this).find('.Remaining').text()) < 0) {
                $(this).addClass('alert-error');
                $('#processOrders').attr('disabled', 'disabled');
            } else $(this).removeClass('alert-error');
            });

        };

        function ordersInit() {

            // Set up recalculation points
            $('#Action').change(function () {
                var Action = $('#Action').val();

                // Reset all values
                $('#terr_from').val('-- Select --');
                $('#terr_to').closest('.row-fluid').insertAfter($('#sea_to').closest('.row-fluid'));
                $('#sea_from').empty().append('<option>-- Select --</option>');
                $('#sea_to').empty().append('<option>-- Select --</option>');
                $('#terr_to').empty().append('<option>-- Select --</option>');
                $('#def_power').val('-- Select --');
                $('#ambushBoomer').val('-- Select --');
                $('#launchBoomer').val('-- Select --');
                $('#target1').val('-- None --').change()
                $('#Tanks').val('0');
                $('#Armies').val('0');
                $('#Boomers').val('0');
                $('#Navies').val('0');
                $('#powername').text('');
                $('#major').text('');
                $('#minor').text('');
                $('#distance').text('');
                $('#ambushNukes').text('');
                $('#ambushNeutron').text('');
                $('#processOrders').closest('.row-fluid').slideDown();

                // Show appropriate things for action
                if (Action == 'Pass') {
                    $('.terrRow').slideUp();
                    $('.armiesRow').slideUp();
                    $('.tanksRow').slideUp();
                    $('.seaRow').slideUp();
                    $('.ambushRow').slideUp();
                    $('.launchRow').slideUp();
                    $('.warheadRow').slideUp();
                    $('.spaceblastRow').slideUp();
                    $('.superpowerRow').slideUp();
                    $('.visBoomersRow').slideUp();
                    $('.naviesRow').slideUp();
                    $('.resultRow').slideUp();
                } else if (Action == 'March' | Action == 'Ground' | Action == 'Fly' | Action == 'Aerial') {
                    $('.terrRow').slideDown();
                    $('.armiesRow').slideDown();
                    if (Action != 'Aerial') $('.tanksRow').slideDown();
                    else $('.tanksRow').slideUp();
                    $('.seaRow').slideUp();
                    $('.ambushRow').slideUp();
                    $('.launchRow').slideUp();
                    $('.warheadRow').slideUp();
                    $('.spaceblastRow').slideUp();
                    $('.superpowerRow').slideUp();
                    $('.naviesRow').slideUp();
                    $('.visBoomersRow').slideUp();
                    $('.resultRow').slideDown();
                    $('#terrtype_to').val('LAND');
                } else if (Action == 'Sail' | Action == 'Naval') {
                    $('.terrRow').slideUp();
                    $('.armiesRow').slideUp();
                    $('.tanksRow').slideUp();
                    $('.seaRow').slideDown();
                    $('.ambushRow').slideUp();
                    $('.launchRow').slideUp();
                    $('.warheadRow').slideUp();
                    $('.spaceblastRow').slideUp();
                    $('.superpowerRow').slideUp();
                    $('.visBoomersRow').slideDown();
                    $('.naviesRow').slideDown();
                    $('.resultRow').slideDown();
                    $('#terrtype_to').val('SEA');
                    $('#startSeaFrom').find('option').clone().appendTo('#sea_from');
                    $('#sea_from').val('-- Select --');
                } else if (Action == 'Transport' | Action == 'Amphibious') {
                    $('.terrRow').slideDown();
                    $('.armiesRow').slideDown();
                    $('.tanksRow').slideDown();
                    $('.seaRow').slideDown();
                    $('.ambushRow').slideUp();
                    $('.launchRow').slideUp();
                    $('.warheadRow').slideUp();
                    $('.spaceblastRow').slideUp();
                    $('.superpowerRow').slideUp();
                    $('.visBoomersRow').slideUp();
                    $('.naviesRow').slideDown();
                    $('.resultRow').slideDown();
                    $('#terrtype_to').val('LAND');
                } else if (Action == 'Ambush') {
                    $('.terrRow').slideUp();
                    $('.armiesRow').slideUp();
                    $('.tanksRow').slideUp();
                    $('.seaRow').slideUp();
                    $('.ambushRow').slideDown();
                    $('.launchRow').slideUp();
                    $('.warheadRow').slideUp();
                    $('.spaceblastRow').slideUp();
                    $('.superpowerRow').slideUp();
                    $('.visBoomersRow').slideUp();
                    $('.naviesRow').slideUp();
                    $('.resultRow').slideDown();
                    $('#terrtype_to').val('SEA');
                    $('.boomerOption[data-ambushok="No"]').hide();
                    $('.boomerOption[data-ambushok="OK"]').show();
                } else if (Action == 'Boomer') {
                    $('.terrRow').slideUp();
                    $('.armiesRow').slideUp();
                    $('.tanksRow').slideUp();
                    $('.seaRow').slideUp();
                    $('.ambushRow').slideUp();
                    $('.launchRow').slideDown();
                    $('.warheadRow').slideDown();
                    $('.spaceblastRow').slideUp();
                    $('.superpowerRow').slideUp();
                    $('.visBoomersRow').slideUp();
                    $('.naviesRow').slideUp();
                    $('.resultRow').slideUp();
                    $('.boomerOption').show();
                    $('.warheadOption').hide();
                    $('.nuke').attr('max','0');
                    $('.neutron').attr('max','0');
                } else if (Action == 'Warhead') {
                    $('.terrRow').slideUp();
                    $('.armiesRow').slideUp();
                    $('.tanksRow').slideUp();
                    $('.seaRow').slideUp();
                    $('.ambushRow').slideUp();
                    $('.launchRow').slideUp();
                    $('.warheadRow').slideDown();
                    $('.spaceblastRow').slideUp();
                    $('.superpowerRow').slideUp();
                    $('.visBoomersRow').slideUp();
                    $('.naviesRow').slideUp();
                    $('.resultRow').slideUp();
                    $('.warheadOption').show();
                    $('.nuke').attr('max',$("#Action option[val='Warhead']").attr('nukes'));
                    $('.neutron').attr('max',$("#Action option[val='Warhead']").attr('neutron'));
                } else if (Action == 'Space') {
                    $('.terrRow').slideUp();
                    $('.armiesRow').slideUp();
                    $('.tanksRow').slideUp();
                    $('.seaRow').slideUp();
                    $('.ambushRow').slideUp();
                    $('.launchRow').slideUp();
                    $('.warheadRow').slideUp();
                    $('.spaceblastRow').slideDown();
                    $('.superpowerRow').slideUp();
                    $('.visBoomersRow').slideUp();
                    $('.naviesRow').slideUp();
                    $('.resultRow').slideUp();
                } else if (Action == 'Satellite') {
                    $('.terrRow').slideUp();
                    $('.armiesRow').slideUp();
                    $('.tanksRow').slideUp();
                    $('.seaRow').slideUp();
                    $('.ambushRow').slideUp();
                    $('.launchRow').slideUp();
                    $('.warheadRow').slideUp();
                    $('.spaceblastRow').slideUp();
                    $('.superpowerRow').slideDown();
                    $('.visBoomersRow').slideUp();
                    $('.naviesRow').slideUp();
                    $('.resultRow').slideUp();
                    $('#processOrders').closest('.row-fluid').slideUp();
                } else if (Action == 'Land') {
                    $('#terr_from').closest('.row-fluid').slideUp();
                    $('#sea_from').closest('.row-fluid').slideDown();
                    $('#terr_to').closest('.row-fluid').slideDown();
                    $('#sea_to').closest('.row-fluid').slideDown();
                    $('.armiesRow').slideUp();
                    $('.tanksRow').slideUp();
                    $('.ambushRow').slideUp();
                    $('.launchRow').slideUp();
                    $('.warheadRow').slideUp();
                    $('.spaceblastRow').slideUp();
                    $('.superpowerRow').slideUp();
                    $('.visBoomersRow').slideUp();
                    $('.naviesRow').slideDown();
                    $('.resultRow').slideDown();
                    $('#terrtype_to').val('LAND');
                    $('#startSeaFrom').find('option').clone().appendTo('#sea_from');
                    $('#sea_from').val('-- Select --');
                } else if (Action == 'Sea') {
                    $('#terr_to').closest('.row-fluid').insertAfter($('#terr_from').closest('.row-fluid'));
                    $('#terr_from').closest('.row-fluid').slideDown();
                    $('#sea_from').closest('.row-fluid').slideUp();
                    $('#sea_to').closest('.row-fluid').slideDown();
                    $('#terr_to').closest('.row-fluid').slideDown();
                    $('.ambushRow').slideUp();
                    $('.launchRow').slideUp();
                    $('.armiesRow').slideDown();
                    $('.tanksRow').slideUp();
                    $('.warheadRow').slideUp();
                    $('.spaceblastRow').slideUp();
                    $('.superpowerRow').slideUp();
                    $('.visBoomersRow').slideUp();
                    $('.naviesRow').slideUp();
                    $('.resultRow').slideDown();
                    $('.majorRow').slideDown();
                    $('#terrtype_to').val('SEA');
                }

                if (Action == 'Ground' | Action == 'Aerial' | Action == 'Naval' | Action == 'Amphibious' | Action == 'Ambush') {
                    $('.majorRow').slideDown();
                } else {
                    $('.majorRow').slideUp();
                }

                // Recalculate
                recalc();
            });

            // Territory change functions
            $('#terr_from').change(function () {
                // Reset values
                $('#Tanks').attr('max', $(this).find('option:selected').attr('major'));
                $('#Tanks').val('0');
                $('#Armies').attr('max', $(this).find('option:selected').attr('minor'));
                $('#Armies').val('0');
                $('#Boomers').attr('max', '0');
                $('#Boomers').val('0');
                $('#Navies').attr('max', '0');
                $('#Navies').val('0');
                $('#sea_from').empty().append('<option>-- Select --</option>');
                $('#sea_to').empty().append('<option>-- Select --</option>');
                $('#terr_to').empty().append('<option>-- Select --</option>');
                $('#powername').text('');
                $('#major').text('');
                $('#minor').text('');
                $('#distance').text('');

                // Get destinations
                var Action = $('#Action').val();
                var postData = $('#Action').serialize() + "&terrname=" + $('#terr_from').val().replace(' ', '+');
                $.ajax({
                    type: "POST",
                    url: "m/ajax/distance_xml.php",
                    cache: false,
                    data: postData,
                    dataType: "xml",
                    success: function (xml) {
                        if (Action == "Transport" | Action == "Amphibious") {
                            $(xml).find('option').each(function () {
                                $('#sea_from').append($(this)[0].xml || (new XMLSerializer()).serializeToString($(this)[0]));
                            });
                        } else if (Action == "Sea") {
                            $(xml).find('option').each(function () {
                                if ($(this).attr('TerrType').length == 4) $('#terr_to').append($(this)[0].xml || (new XMLSerializer()).serializeToString($(this)[0]));
                                else $('#sea_to').append($(this)[0].xml || (new XMLSerializer()).serializeToString($(this)[0]));
                            });
                        } else {
                            $(xml).find('option').each(function () {
                                $('#terr_to').append($(this)[0].xml || (new XMLSerializer()).serializeToString($(this)[0]));
                            });
                        }
                    },
                    error: onError
                });
            });

            $('#sea_from').change(function () {
                // Reset values
                $('#Boomers').attr('max', $(this).find('option:selected').attr('major'));
                $('#Boomers').val('0');
                $('#Navies').attr('max', $(this).find('option:selected').attr('minor'));
                $('#Navies').val('0');
                $('#sea_to').empty().append('<option>-- Select --</option>');
                $('#terr_to').empty().append('<option>-- Select --</option>');
                $('#powername').text('');
                $('#major').text('');
                $('#minor').text('');
                $('#distance').text('');

                // Get destinations
                var Action = $('#Action').val();
                var postData = $('#Action').serialize() + "&terrname=" + $('#sea_from').val().replace(' ', '+');
                $('#sea_to').empty().append('<option>-- Select --</option>');
                $('#terr_to').empty().append('<option>-- Select --</option>');
                $.ajax({
                    type: "POST",
                    url: "m/ajax/distance_xml.php",
                    cache: false,
                    data: postData,
                    dataType: "xml",
                    success: function (xml) {
                        $('#sea_to').empty().append('<option>-- Select --</option>');
                        $('#terr_to').empty().append('<option>-- Select --</option>');
                        $(xml).find('option').each(function () {
                            if ($(this).attr('TerrType').length == 4) $('#terr_to').append($(this)[0].xml || (new XMLSerializer()).serializeToString($(this)[0]));
                            else $('#sea_to').append($(this)[0].xml || (new XMLSerializer()).serializeToString($(this)[0]));
                        });
                    },
                    error: onError
                });
            });

            $('#sea_to').change(function () {
                // Reset values
                $('#powername').text('');
                $('#major').text('');
                $('#minor').text('');
                $('#distance').text('');

                // Get destinations if none are found
                var postData = $('#Action').serialize() + "&terrname=" + $('#sea_to').val().replace(' ', '+');
                var Action = $('#Action').val();
                // Get new territories if required
                if (Action == "Transport" | Action == "Amphibious" | Action == "Land") {
                    $.ajax({
                        type: "POST",
                        url: "m/ajax/distance_xml.php",
                        cache: false,
                        data: postData,
                        dataType: "xml",
                        success: function (xml) {
                            $('#terr_to').empty().append('<option>-- Select --</option>');
                            $(xml).find('option').each(function () {
                                if ($(this).attr('TerrType').length == 4 && $(this).text() != $('#terr_from').val()) $('#terr_to').append($(this)[0].xml || (new XMLSerializer()).serializeToString($(this)[0]));
                            });
                        },
                        error: onError
                    });
                }
                // Set result values
                else {
                    $('#powername').text($('#sea_to option:selected').attr('powername'));
                    $('#major').text($('#sea_to option:selected').attr('major'));
                    $('#minor').text($('#sea_to option:selected').attr('minor'));
                }
                // Recalculate
                recalc();
            });

            $('#terr_to').change(function () {
                // Reset values
                $('#powername').text('');
                $('#major').text('');
                $('#minor').text('');
                $('#distance').text('');

                // Get destinations if none are found
                var postData = $('#Action').serialize() + "&terrname=" + $('#terr_to').val().replace(' ', '+');
                var Action = $('#Action').val();
                // Get new territories if required
                if (Action == "Sea") {
                    $.ajax({
                        type: "POST",
                        url: "m/ajax/distance_xml.php",
                        cache: false,
                        data: postData,
                        dataType: "xml",
                        success: function (xml) {
                            $('#sea_to').empty().append('<option>-- Select --</option>');
                            $(xml).find('option').each(function () {
                                if ($(this).attr('TerrType').length == 3) $('#sea_to').append($(this)[0].xml || (new XMLSerializer()).serializeToString($(this)[0]));
                            });
                        },
                        error: onError
                    });
                }
                // Set result values
                else {
                    $('#powername').text($('#terr_to option:selected').attr('powername'));
                    $('#major').text($('#terr_to option:selected').attr('major'));
                    $('#minor').text($('#terr_to option:selected').attr('minor'));
                }
                // Recalculate
                recalc();
            });

            $('#Tanks').change(recalc);
            $('#Armies').change(recalc);
            $('#Boomers').change(recalc);
            $('#Navies').change(recalc);

            // Ambush page actions
            $('#ambushBoomer').change(function () {
                $('.warheadOption').hide();
                $('#target1').val("-- None --").change();
                var Action = $('#Action').val();
                $('#ambushNukes').text($('#ambushBoomer option:selected').attr('data-nukes'));
                $('#ambushNeutron').text($('#ambushBoomer option:selected').attr('data-neutron'));
                $('.nuke').attr('max',$("#ambushBoomer option:selected").attr('data-nukes'));
                $('.neutron').attr('max',$("#ambushBoomer option:selected").attr('data-neutron'));
                if (Action=='Ambush') {
                    // Info for ambush
                    $('#powername').text($('#ambushBoomer option:selected').attr('data-powername'));
                    $('#major').text($('#ambushBoomer option:selected').attr('data-major'));
                    $('#minor').text($('#ambushBoomer option:selected').attr('data-minor'));
                } else if ($('#ambushBoomer option:selected').attr('data-warhead')=='Calced') {
                    $(".warheadOption[data-boomerno"+$('#ambushBoomer').val()+"='OK']").show();
                } else {
                    // Check what warhead targets are available
                    var postData = $('#Action').serialize() + "&terrname=" + $('#ambushBoomer option:selected').text().replace(' ', '+');
                    // Submit AJAX
                    $('.targetTerr').attr('readonly','readonly');
                    $.ajax({
                        type: "POST",
                        url: "m/ajax/distance_xml.php",
                        cache: false,
                        data: postData,
                        dataType: "xml",
                        success: function (xml) {
                            $(xml).find('option').each(function() {
                                $(".warheadOption[terrno='"+$(this).attr('TerrNo')+"']").attr("data-boomerno"+$('#ambushBoomer').val(),"OK");
                            });
                            $(".warheadOption[data-boomerno"+$('#ambushBoomer').val()+"='OK']").show();
                            $('#ambushBoomer option:selected').attr('data-warhead','Calced');
                            $('.targetTerr').removeAttr('readonly');
                        },
                        error: function(data,status) {console.log("ERROR");console.log(data);console.log(status);} /*onError*/
                    });

                }
                recalc();
            });

            // Launch boomer page actions
            $('#launchBoomer').change(function () {
                $('.warheadOption').hide();
                $('#target1').val("-- None --").change();
                var Action = $('#Action').val();
                $('#launchNukes').text($('#launchBoomer option:selected').attr('data-nukes'));
                $('#launchNeutron').text($('#launchBoomer option:selected').attr('data-neutron'));
                $('.nuke').val('0');
                $('.neutron').val('0');
                if ($("#launchBoomer option:selected").attr('data-nukes') == '0') {
                    $('.nuke').attr('readonly','readonly');
                } else {
                    $('.nuke').attr('max',$("#launchBoomer option:selected").attr('data-nukes'));
                    $('.nuke').removeAttr('readonly');
                }
                if ($("#launchBoomer option:selected").attr('data-neutron') == '0') {
                    $('.neutron').attr('readonly','readonly');
                } else {
                    $('.neutron').attr('max',$("#launchBoomer option:selected").attr('data-neutron'));
                    $('.neutron').removeAttr('readonly');
                }
                // $('.neutron').attr('max',$("#launchBoomer option:selected").attr('data-neutron'));
                if (Action=='Ambush') {
                    // Info for ambush
                    $('#powername').text($('#launchBoomer option:selected').attr('data-powername'));
                    $('#major').text($('#launchBoomer option:selected').attr('data-major'));
                    $('#minor').text($('#launchBoomer option:selected').attr('data-minor'));
                } else if ($('#launchBoomer option:selected').attr('data-warhead')=='Calced') {
                    $(".warheadOption[data-boomerno"+$('#launchBoomer').val()+"='OK']").show();
                } else {
                    // Check what warhead targets are available
                    var postData = $('#Action').serialize() + "&terrname=" + $('#launchBoomer option:selected').text().replace(' ', '+');
                    // Submit AJAX
                    $('.targetTerr').attr('readonly','readonly');
                    $.ajax({
                        type: "POST",
                        url: "m/ajax/distance_xml.php",
                        cache: false,
                        data: postData,
                        dataType: "xml",
                        success: function (xml) {
                            $(xml).find('option').each(function() {
                                $(".warheadOption[terrno='"+$(this).attr('TerrNo')+"']").attr("data-boomerno"+$('#launchBoomer').val(),"OK");
                            });
                            $(".warheadOption[data-boomerno"+$('#launchBoomer').val()+"='OK']").show();
                            $('#launchBoomer option:selected').attr('data-warhead','Calced');
                            $('.targetTerr').removeAttr('readonly');
                        },
                        error: function(data,status) {console.log("ERROR");console.log(data);console.log(status);} /*onError*/
                    });

                }
                recalc();
            });

            // Warhead page actions
            $('.targetTerr').change(function () {
                $(this).closest('.targetRow').find('.target_powername').text($(this).find('option:selected').attr('powername'));
                // Add new row
                var targets = $(this).closest('form').find('.targetTerr').length;
                var nones = $(this).closest('form').find('.targetTerr option:selected[value="-- None --"]');
                if (nones.length == 0) {
                    targets++;
                    $('.targetRow:eq(0)').clone(true).hide().appendTo($('.warheadRow:eq(0)'));
                    $('.targetRow:last').find('.targetTerr').attr('name', 'target' + targets).attr('id', 'target' + targets).val('-- None --');
                    $('.targetRow:last').find('.nuke').attr('name', 'target' + targets + '_nukes').val(0);
                    $('.targetRow:last').find('.neutron').attr('name', 'target' + targets + '_neutron').val(0);
                    $('.targetRow:last').find('.target_powername').text('');
                    $('.targetRow:last').slideDown();
                }
                // Remove all rows after the first None
                else if (nones.length > 1) for (n = parseInt(nones.first().parent().attr('id').substring(6)) + 1; n <= targets; n++) $('#target' + n).closest('.targetRow').slideUp(function () {
                    $(this).remove();
                });
                // Look for matching territories
                $('.targetTerr').closest('.control-group').removeClass('error');
                var i = 2;
                while (i <= targets) {
                    var j = 1;
                    while (j < i) {
                        if ($('#target' + i).val() == $('#target' + j).val() && $('#target' + i).val() != '-- None --') {
                            $('#target' + i).closest('.control-group').addClass('error');
                            $('#target' + j).closest('.control-group').addClass('error');
                        }
                        j++;
                    }
                    i++;
                };
                recalc();
            });
            $('.nuke').change(function () {
                var t = 0;
                $('.nuke').each(function () {
                    t = t + parseInt($(this).val())
                });
                if (t > $(this).attr('max')) $('.nuke').closest('.control-group').addClass('error');
                else $('.nuke').closest('.control-group').removeClass('error');
                recalc();
            });
            $('.neutron').change(function () {
                var t = 0;
                $('.neutron').each(function () {
                    t = t + parseInt($(this).val())
                });
                if (t > $(this).attr('max')) $('.neutron').closest('.control-group').addClass('error');
                else $('.neutron').closest('.control-group').removeClass('error');
                recalc();
            });

            // Satellite offensive functions
            $('#def_power').change(function () {
                if ($(this).val() == '-- Select --') $('#battleAttack').attr('disabled', 'disabled');
                else if ($(this).val() == '-- None --') $('#battleAttack').attr('disabled', 'disabled');
                else $('#battleAttack').removeAttr('disabled');
            });
            $('#battleAttack').click(function () {
                // Disable buttons
                $('#battleAttack').attr('disabled', 'disabled');
                $('#battleStop').attr('disabled', 'disabled');
                // Remove select options that are no longer valid
                $('#Action option').each(function () {
                    if ($(this).text() != $('#Action option:selected').text()) $(this).remove();
                });
                $('#def_power option').each(function () {
                    if ($(this).text() != $('#def_power option:selected').text()) $(this).remove();
                });
                // Submit attack
                var formData = $('#orderForm').serialize();
                $.ajax({
                    url: "m/ajax/proc_4_satoff.php",
                    type: "POST",
                    data: formData,
                    dataType: "text",
                    success: procSatXML,
                    error: function (jqXHR, textStatus, errorThrown) {
                        alert("STOP ERROR:" + $(jqXHR).text() + ':' + textStatus + ':' + errorThrown);
                    }
                });
            });
            $('#battleStop').click(function () {
                // Disable buttons
                $('#battleAttack').attr('disabled', true);
                $('#battleStop').attr('disabled', true);
                // Send request
                $.ajax({
                    url: "m/ajax/proc_4_satoff.php",
                    type: "POST",
                    dataType: "text",
                    data: "lstarStop=Yes&randgen=" + $('#randgen').val(),
                    success: procSatXML,
                    error: function (jqXHR, textStatus, errorThrown) {
                        alert("ERROR:" + $(jqXHR).text() + ':' + textStatus + ':' + errorThrown);
                    }
                });
            });
            // Space Blast functions
            $('#space_nuke').change(recalc());

            function procSatXML(xml) {
                var xmlDoc = $.parseXML(xml),
                    $xml = $(xmlDoc);
                if ($xml.find("FAIL").text() != '') {
                    alert("PROCESSING ERROR:" + $xml.text());
                } else if ($xml.find('STOP').text() != '') {
                    $('#finished').show();
                    $('#battleAttack').hide();
                    $('#battleStop').hide();
                } else {
                    $('#currentBattleTable>#battleBody').empty();
                    // Construct row from XML response
                    var rows = $xml.find("R").get().reverse();
                    $(rows).each(function (index) {
                        $('#currentBattleTable>#battleBody').append("<tr>" + "<td>" + $(this).attr("Id").substring(1) + "</td>" + "<td>" + $(this).find('att_lstars').text() + "</td>" + "<td>" + $(this).find('att_ksats').text() + "</td>" + "<td>" + $(this).find('att_hits').text() + "</td>" + "<td>" + $(this).find('def_lstars').text() + "</td>" + "<td>" + $(this).find('def_ksats').text() + "</td>" + "<td>" + $(this).find('def_hits').text() + "</td>" + "</tr>");
                    })
                    var lrow = "<tr>" + "<td>Current</td>" + "<td>" + $xml.find('LSTAR > RESULT > ala').text() + "</td>" + "<td>" + $xml.find('LSTAR > RESULT > aka').text() + "</td>" + "<td></td>" + "<td>" + $xml.find('LSTAR > RESULT > dla').text() + "</td>" + "<td>" + $xml.find('LSTAR > RESULT > dka').text() + "</td>" + "<td></td>" + "</tr>";

                    // Add row to table
                    $('#currentBattleTable>#battleBody').append(lrow);
                    // Animate penultimate row
                    $('#currentBattleTable>#battleBody > tr:last').prev().find('td').wrapInner('<div style="display: none;" />').parent().find('td > div').slideDown(500, function () {
                        $(this).replaceWith($(this).contents());
                    });

                    // Change initial defender values
                    $('#lstarAttackingPowername').text($xml.find('LSTAR > AttPowername').text());
                    $('#lstarDefendingPowername').text($xml.find('LSTAR > DefPowername').text());
                    $('#battleStop').show();

                    // Change buttons if necessary
                    if ($xml.find('status').text() == 'Over') {
                        $('#finished').show();
                        $('#battleAttack').hide();
                        $('#battleStop').hide();
                    } else {
                        $('#battleAttack').attr('disabled', false);
                        $('#battleStop').attr('disabled', false);
                    }
                }
            };

            // Check for pre-existing orders - only Action is Satellite and def_power at the moment, phew
            if ($('#input-Action').length > 0) {
                $('#Action').val($('#input-Action').val());
                $('#Action').change();
            };
            if ($('#input-def_power').length > 0) {
                $('#def_power').val($('#input-def_power').val());
                $('#def_power').change();
                // Get current XML table
                $.ajax({
                    url: "m/ajax/proc_4_satoff.php",
                    type: "POST",
                    data: "getCurrent=Yes&randgen=" + $('#randgen').val(),
                    dataType: "text",
                    success: procSatXML,
                    error: function (jqXHR, textStatus, errorThrown) {
                        alert("GET ERROR:" + $(jqXHR).text() + ':' + textStatus + ':' + errorThrown);
                    }
                });
            };


            // Initial display
            recalc();
        };

        -->
</script>
