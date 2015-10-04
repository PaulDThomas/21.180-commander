// Defense Javascript Functions
// $Id: defense.js 92 2012-06-14 22:40:54Z paul $

function defenseInit() {
    $('.defDef').click( function () { $(this).closest('table').find('.def').val('Defend'); });
    $('.defRes').click( function () { $(this).closest('table').find('.def').val('Resist'); });
    $('.defSur').click( function () { $(this).closest('table').find('.def').val('Surrender'); });
    $('.amYes').click( function () { $(this).closest('table').find('.am').val('Yes'); });
    $('.amNo').click( function () { $(this).closest('table').find('.am').val('No'); });
};
