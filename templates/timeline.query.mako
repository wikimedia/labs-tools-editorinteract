<!doctype html>
<%!
    import time, arrow
    from datetime import timedelta

    from utils import format_seconds
%>
<html>
<head>
    <%include file="header.mako" args="title='Editor Interaction Analyser - Timeline'" />
</head>
<body>
    <h1>Editor Interaction Analyser - Timeline</h1>
    <ul>
        <% lasteditor = lastedittime = None %>
        % for urls, ts, stamp, diffword, histword, user, sizesize, sizetag, minor, page, summ in store.query.results:
            % if lasteditor != user:
                % if lastedittime and lasteditor:
                    <li style="list-style:none;color: #f43;">
                        <% f = format_seconds(lastedittime - ts) %>
                        <small>... ${f[0]} ${f[1]} ...</small>
                    </li>
                % endif
                % if 0:
                <li style="list-style:none">
                    Edits by 
                    <a href="${urls['u']|h}">${user|h}</a>
                    (<a href="${urls['ut']|h}">talk</a>)
                </li>
                % endif
            %endif
<%
                lasteditor = user
                lastedittime = ts
%>
            <li>
                <a href="${urls['rv']|h}">${stamp}</a>
                (<a href="${urls['diff']|h}">${diffword}</a> | <a href="${urls['hist']}">${histword}</a>)
                <a href="${urls['u']|h}">${user}</a>
                (<a href="${urls['ut']|h}">talk</a> | <a href="${urls['uc']|h}">contribs</a>)
                ${minor}
                . . ${sizesize} ${sizetag} . .
                <i>(${summ})</i>
            </li>
        %endfor
    </ul>
    <br/>
    <small>
        Elapsed time: ${round(time.time() - store.starttime, 3)} seconds.
        <br/>
        ${arrow.now().strftime("%H:%M:%S, %d %b %Y")}
    </small>
    <br />
    <br />
    <%include file="footer.mako" />
</body>
</html>
