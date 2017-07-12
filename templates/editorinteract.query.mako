<!doctype html>
<%!
    import arrow, time
    def pretty_date(t):
        return arrow.Arrow.strptime(str(t), "%Y%m%d%H%M%S").strftime("%d %B %Y")
%>
<html>
<head>
    <%include file="header.mako" args="title='Editor Interaction Analyser'" />
    <script type=text/javascript src=/sigma/static/tablesorter.min.js></script>
    <script type=text/javascript>
window.__$_$______$_$_$$_$_i = 3;

function addEntry(i) {
    i = i.toString();
    var label = $("<label for=user" + i + "/>").html("User " + i + ":");
    var input = $("<input type=text></input>");
    input.attr("name", "user" + i).attr("id", "user" + i);
    var users = $("#userlist").children();
    var _i = users.length - 1;
    $(users[_i]).parent().append(label).append(input);
}

$(document).ready(function() { $("#maintable").tablesorter(); });
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
            Click on the "<a href=timeline.py>timeline</a>" link to
            see the edits that both users have made to the page in
            chronological order.
        </p>
    </div>
    <hr style="text-align:left;width:875px;margin-left:0" />
% for user, edits in store.query.rawresults.user_edits.items():
    <p>
        <a href="${store.domain}/wiki/User:${user|h}">${user|h}</a>
        (<a href="${store.domain}/wiki/User_talk:${user|h}">talk</a>)
        edit count: ${store.query.rawresults.editcounts[user]}
    </p>
% endfor
% if store.startdate and not store.enddate:
    <p>Only analysing edits from ${pretty_date(store.startdate)} and later.</p>
% elif store.enddate and not store.startdate:
    <p>Only analysing edits from ${pretty_date(store.enddate)} and earlier.</p>
% elif store.startdate and store.enddate:
    <p>Only analysing edits from ${pretty_date(store.startdate)} to ${pretty_date(store.enddate)}.</p>
% endif
    <p>Numbers in <span style="color: blue">blue</span> indicate which editor first edited the page.</p>
    <table border=1 id=maintable class=tablesorter>
        <thead>
        <tr>
            <th>Page</th>
            <th>Min time between edits</th>
            % for user in store.users:
                <th><small>${user|h}<br/>edits</small></th>
            % endfor
        </tr>
        </thead>
        <tbody>
    % for p, row in store.table.items():
        <tr>
            <td><a href="${store.domain}/wiki/${row[0]|h}">${row[0].replace("_", ' ')}</a></td>
            <td>${row[1][0][0]|h} ${row[1][0][1]|h} &mdash; <a href="${row[1][1]|h}" style="font-size: 0.8em">(timeline)</a></td>
            % for blue, ec in row[2:]:
                % if blue:
                    <td style="color:blue">${ec}</td>
                % else:
                    <td>${ec}</td>
                % endif
            % endfor
        </tr>
    % endfor
        </tbody>
    </table>
    <br />
    <small>
        Elapsed time: ${round(time.time() - store.starttime, 3)} seconds.
        <br />
        ${arrow.now().strftime("%H:%M:%S, %d %b %Y")}
    </small>
    <br />
    <br />
    <a href="editorinteract.py"><small>&larr;New search</small></a>
    <%include file="footer.mako" />
</body>
</html>
