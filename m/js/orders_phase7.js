<script type="text/javascript"><!--
// $Id: orders_phase7.js 100 2012-07-02 06:49:16Z paul $
function ordersInit () {
    // Set up buttons
    $('.cardBtn').click(function() {
        $('#CardNo').val($(this).attr('data-card'));
        $('#orderForm').submit();
    });
};
--></script>
