<?php
// Forum panel
// $Id: forum_panel.php 219 2014-04-14 11:57:34Z paul $
?>
<h2>Forum...<div class="pull-right"><small>* not for support issues!</small></h2>
<form id="forumForm" class="form-inline">
    <div class="controls" align="center">
        <input type='text' id="forumMessage" name="forumMessage" class="input-large" value=''/>
        <input id="forumPost" type='button' name='forumPost' value='Post' class="btn"/>
    </div>
</form>
<ul class="pager">
    <li class="previous"><a href="#" id="forumOlder">&larr; Older</a></li>
    <li class="next"><a href="#" id="forumNewer">Newer &rarr;</a></li>
</ul>
<ul id="forumList" class="commanderList"></ul>
