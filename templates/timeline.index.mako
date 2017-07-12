<!doctype html>
<%!
    import arrow, time
%>
<html>
<head>
    <%include file="header.mako" args="title='Editor Interaction Analyser - Timeline'" />
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
    <div style="width:875px">
        <h1>Editor Interaction Analyser - Timeline</h1>
        <p>
            This tool, often used in conjunction with the
            <a href="editorinteract.py">Editor Interaction Analyser</a>,
            shows the edits that the specified users have made to a page in
                chronological order.
        </p>
    </div>
    <div id='indexform'>
    <form action="/sigma/timeline.py" method=GET>
        <a id="moarusers" onclick="addEntry(++__$_$______$_$_$$_$_i);
                                   if(__$_$______$_$_$$_$_i>19)
                                       this.parentNode.removeChild(this);">Add users</a>
        <div style="clear: all"></div>
        <div id="userlist">
            <label for='user1'>User 1:</label>
            <input type='text' id='user1' name='users' />
            <label for='user2'>User 2:</label>
            <input type='text' id='user2' name='users' />
            <label for='user3'>User 3:</label>
            <input type='text' id='user3' name='users' />
        </div>
        <label for=page>Page:</label>
        <input type=text id=page name=page />
        <label for='startdate'>
            Start date:<br/>
            <span class='gray'>YYYYMMDD format</span>
        </label>
        <input type='text' id='startdate' name='startdate' />
        <label for='enddate'>End date:</label>
        <input type='text' id='enddate' name='enddate' />
        <label for=server>Database:<br/>
            <span class=gray>lang + project (<a href="//meta.wikimedia.org/w/api.php?action=sitematrix&format=jsonfm">list</a>)</span>
        </label>
        <input type=text id=server name=server value=enwiki />
        <button>Submit</button>
        <div style='clear: both'></div>
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
    <a href="/sigma"><small>&larr;Home</small></a>
    <%include file="footer.mako" />
</body>
</html>
