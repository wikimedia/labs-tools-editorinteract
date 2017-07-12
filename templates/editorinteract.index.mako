<!doctype html>
<%!
    import arrow, time
%>
<html>
<head>
    <%include file="header.mako" args="title='Editor Interaction Analyser'" />
    <script type="text/javascript">
window.__$_$______$_$_$$_$_i = 3;

function addEntry(i) {
    i = i.toString();
    var label = $("<label for=user" + i + "/>").html("User " + i + ":");
    var input = $("<input type=text></input>");
    input.attr("name", "users").attr("id", "user" + i);
    var users = $("#userlist").children();
    var _i = users.length - 1;
    $(users[_i]).parent().append(label).append(input);
}
    </script>
</head>
<body>
    <div style="width:875px;">
        <h1>Editor Interaction Analyser</h1>
        <p>
            This tool shows the common pages that two or more editors have
            both edited, sorted by minimum time between edits by the
            users. In other words, if the editors made an edit to the same
            page within a short time, that page will show up towards the top
            of the table. In general, when two users edit a page within a
            short time, chances are high that they have interacted directly
            with one another on that page.
        </p>
        <p>
            Click on the "<a href="/sigma/timeline.py">timeline</a>" link to
            see the edits that both users have made to the page in
            chronological order.
        </p>
    </div>
    <div id='indexform'>
    <form action="/sigma/editorinteract.py" method="GET">
        <!--
        <a id="moarusers" onclick="addEntry(++__$_$______$_$_$$_$_i);
                                   if(__$_$______$_$_$$_$_i>19)
                                       this.parentNode.removeChild(this);">Add users</a>
                                       -->
        <div style="clear: both"></div>
        <div id="userlist">
            <label for='user1'>User 1:</label>
            <input type='text' id='user1' name='users' />
            <label for='user2'>User 2:</label>
            <input type='text' id='user2' name='users' />
            <label for='user3'>User 3:</label>
            <input type='text' id='user3' name='users' />
            <div>
                <label id=moarusers onclick="addEntry(++__$_$______$_$_$$_$_i);if(__$_$______$_$_$$_$_i>19)this.parentNode.parentNode.removeChild(this.parentNode);"><a><b>Add user</b></a></label>
                <div style="width: 200px;float: left;padding: 2px 2px;margin: 2px 0px 16px 10px;"><hr/></div/>
            </div>
        </div>
        <label for='startdate'>
            Start date:<br/>
            <span class='gray'>YYYYMMDD format</span>
        </label>
        <input type='text' id='startdate' name='startdate' />
        <label for='enddate'>End date:</label>
        <input type='text' id='enddate' name='enddate' />
        <label for='ns'>Restrict to namespaces:<br/>
            <span class='gray'><samp>,,</samp> for mainspace</span>
        </label>
        <input type='text' id='ns' name='ns' placeholder='Talk,Book talk,,' />
        <label for=server>Database:<br/>
            <span class=gray>lang + project (<a href="//meta.wikimedia.org/w/api.php?action=sitematrix&format=jsonfm">list</a>)</span>
        </label>
        <input type=text id=server name=server value=enwiki />
        <div>
            <label for='allusers'>Pages edited by all users</label>
            <input type='checkbox' id='allusers' name='allusers' />
        </div>
        <button>Submit</button>
        <div style='clear: all;'></div>
    </form>
    </div>
    <br />
    <small>
        Elapsed time: ${round(time.time() - store.starttime, 3)} seconds.
        <br />
        ${arrow.now().strftime("%H:%M:%S, %d %b %Y")}
    </small>
    <br />
    <br />
    <a href="/sigma/"><small>&larr;Home</small></a>
    <%include file="footer.mako" />
</body>
</html>
