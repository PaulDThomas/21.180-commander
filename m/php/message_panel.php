<!-- $Id: message_panel.php 207 2014-03-27 18:53:02Z paul $ -->
<h2>Messages...</h2>
<ul class="pager">
    <li class="previous"><a href="#" id="messageOlder">&larr;<span class='visible-desktop'> Older</span></a></li>
    <a href='#' id='messageFewer' title='Fewer messages'>&darr;</a>
    <span class='visible-desktop'><a id='messageN' class="disabled" title='Messages shown'>...</a></span>
    <a href='#' id='messageMore' title='More messages'>&uarr;</a>
    <li class="next"><a href="#" id="messageNewer"><span class='visible-desktop'>Newer </span>&rarr;</a></li>
</ul>
<form class="form-search">
    <div class="row-fluid">
        <div class="span9 control-group" align="center">
            <input type="text" class="input-medium search-query" id="messageSearch">
            <button type="submit" class="btn" id="messageRefresh">Search</button>
        </div>
        <div class="span3 dropdown">
            <input type="hidden" value="" id="messageDropValue"/>
            <a href='#' class="btn dropdown-toggle" data-toggle="dropdown" id='messageDrop'>Filter <b class="caret"></b></a>
            <ul class="dropdown-menu">
                <li><a class='messageDropItem'>All</a></li>
                <li><a class='messageDropItem'>Communication</a></li>
                <li><a class='messageDropItem'>Battle reports</a></li>
                <li><a class='messageDropItem'>Build reports</a></li>
                <li><a class='messageDropItem'>UN reports</a></li>
                <li><a class='messageDropItem'>Salvage reports</a></li>
                <?php
                // Get Superpowers messages that can be viewed
                $result = $mysqli -> query("Select powername From sp_resource Where gameno=$gameno and espionage_tech <= " . (isset($RESOURCE['espionage_tech'])?$RESOURCE['espionage_tech']:"0") . "-9");
                if ($result -> num_rows > 0) while ($row = $result -> fetch_assoc()) {
                    echo "<li><a class='messageDropItem'>${row['powername']}</a></li>";
                }
                $result -> close();
                ?>
            </ul>
            <?php if (isset($RESOURCE['userno'])) {?><button type="submit" class="btn" id="messageRead" title='Mark all messages read'>Mark Read</button><?php } ?>
        </div>
    </div>
</form>
<ul id="messageList" class="commanderList"></ul>
