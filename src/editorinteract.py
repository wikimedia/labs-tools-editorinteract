#!/home/sigma/.local/bin/python3
# -*- coding: utf-8 -*-
# Copyright (c) 2017 User:Σ, GPLv3


import re
from collections import OrderedDict, defaultdict
from urllib.parse import urlencode
from datetime import timedelta

import arrow
import cymysql as sql

from tool import Tool
from utils import Databank, connect_info, ucfirst, format_seconds

class EditorInteract(Tool):

    def __call__(self):
        store = self.store
        self.set_constants()
        if not store.users:
            return "editorinteract.index.mako", store
        self.prepare_query(store)
        with sql.connect(**connect_info(store.server)) as cursor:
            self.do_query(store.query, cursor)
        self.process_results(store)
        return "editorinteract.query.mako", store

    @staticmethod
    def ucfirst(s: str):
        """Now with better namespace checks"""
        if ":" in s:
            if s.count(":") != 1:
                return s
            return ":".join(map(ucfirst, s.split(":")))
        return s[0].upper() + s[1:] if len(s) else s

    @staticmethod
    def snip_between(l, key=lambda x: x):
        """Not a very good function name, but screw it"""
        l = list(tuple(l))
        i = 0
        while True:
            prev_u = key(l[i - 1]) if i != 0 else None
            u = key(l[i])
            next_u = key(l[i + 1]) if i + 1 < len(l) else None
            if prev_u == u == next_u:
                del l[i]
            else:
                i += 1
            if i >= len(l):
                return l

    @staticmethod
    def diff(arr):
        arr = list(arr)
        yield from ((arr[i+1] - arr[i]) for i in range(len(arr) - 1))

    @staticmethod
    def format_date(i):
        return arrow.Arrow.strptime(i, "%Y%m%d%H%M%S")

    def organise_users(self, store):
        expr = re.compile("user([0-9]+)$")
        for param in store.kw:
            match = expr.match(param)
            if match and int(match.group(1)) < 21:
                store.users.add(store.kw[param].strip())
        store.users = {self.ucfirst(u.strip()) for u in store.users}
        store.users = {u for u in store.users if u}

    def set_constants(self):
        super().set_constants()
        store = self.store
        try:
            store.startdate = int(store.startdate)
        except:
            store.startdate = 0

        try:
            store.enddate = int(store.enddate)
        except:
            store.enddate = 0

        rvns = store.rvnamespaces
        if store.ns:
            ns_ = {rvns[x.lower()] for x in store.ns.split(",") if x.lower() in rvns}
            if ns_:
                # Only do it if there were valid namespaces
                store.ns_ = ", ".join("%s" % e for e in ns_)

        if isinstance(store.users, list):
            store.users = set(store.users)
        elif isinstance(store.users, str):
            store.users = {store.users}
        else:
            store.users = set()
        self.organise_users(store)

    @staticmethod
    def prepare_query(store: Databank):
        l = []
        s = [
            "SELECT page_namespace, page_title, rev_timestamp",
            "FROM revision_userindex JOIN page ON rev_page=page_id",
            "WHERE rev_deleted=0 AND rev_user_text=%s"
        ]
        l.extend([])  # partial stub, will fill in later
        if store.ns_:
            s.append("AND page_namespace IN (%s)" % store.ns_)

        s.append("AND rev_timestamp > %s")
        if store.startdate:
            store.startdate *= 1000000
            l.append(store.startdate)
        else:
            now = arrow.get() - timedelta(days=365.25 * 100)
            l.append(now.strftime("%Y%m%d%H%M%S"))

        if store.enddate:
            s.append("AND rev_timestamp < %s")
            store.enddate *= 1000000
            store.enddate += 235959
            l.append(store.enddate)

        s.append("ORDER BY rev_timestamp DESC")
        s.append("LIMIT %s")
        l.append(int(round(100 / len(store.users), 0) * 1000))
        store.query.str = '\n'.join(s)
        store.query.args = tuple(l)
        store.query.users = tuple(store.users)  # :(

    @staticmethod
    def do_query(query, cur):
        query.rawresults = Databank()
        q = "SELECT user_name, user_editcount FROM user WHERE user_name IN\n"
        q += ','.join(["%s"] * len(query.users)).join("()")
        cur.execute(q, query.users)
        editcounts = {str(k, 'utf8'): v for k, v in cur}
        query.rawresults.editcounts = defaultdict(int, editcounts)

        # {Username:[("Namespace:pagetitle",rev_timestamp),(page,timestamp)...], Username2:[(page,timestamp)...]}
        query.rawresults.user_edits = {}
        for user in query.users:
            cur.execute(query.str, (user,) + query.args)
            query.rawresults.user_edits[user] = cur.fetchall()

    def process_results(self, store):
        for user, edits in store.query.rawresults.user_edits.items():
            newedits = []
            for edit in edits:
                edit = [s.decode("utf8") if isinstance(s, bytes) else s for s in edit]
                t = ''
                if store.namespaces[edit[0]]:
                    t = store.namespaces[edit[0]] + ":"
                newedits.append((t + edit[1], self.format_date(edit[2])))
            newedits.sort(key=lambda x: x[1].timestamp)
            store.query.rawresults.user_edits[user] = newedits
        common_pages = set()
        if store.allusers:
            allpages = []
            for user in store.users:
                allpages.append({p[0] for p in store.query.rawresults.user_edits[user]})
            common_pages = set.intersection(*allpages)
        else:
            for user in store.users:
                unionset = set()
                for user2 in store.users:
                    if user == user2:
                        continue
                    unionset.update(edit[0] for edit in store.query.rawresults.user_edits[user2])
                    common_pages.update({edit[0] for edit in store.query.rawresults.user_edits[user]} & unionset)
        # Find minimum time between edits by different users on the same page
        # make dict {page: [edit, edit, edit...]} and get the smallest
        # diff between 2 timestamps by different users
        page_scores = {}
        page_hist = {}
        for page in common_pages:
            page_edits = []
            diffs = []
            for user, edits in store.query.rawresults.user_edits.items():
                page_edits.extend((user, e[1]) for e in edits if e[0] == page)
            page_edits.sort(key=lambda x: x[1])
            page_hist[page] = page_edits
            page_edits = self.snip_between(page_edits, key=lambda ed: ed[0])
            for i in range(len(page_edits) - 1, 0, -1):
                if page_edits[i][0] != page_edits[i - 1][0]:
                    # I wish I could use the diff function I wrote :(
                    diffs.append(page_edits[i][1] - page_edits[i - 1][1])
            if diffs:
                smallest = min(diffs)
                fuzziness = timedelta(days=365)
                if smallest < fuzziness or 1 == 1:  # TODO: GET param this shit
                    page_scores[page] = smallest
        table = OrderedDict()
        for page in sorted(page_scores, key=page_scores.get):
            table[page] = []
            table[page].append(page)  # title stuff - index 0
            duration = format_seconds(page_scores[page])
            timeline_url = '/sigma/timeline.py'
            fragment = {"page": page, "users": tuple(store.users), "server": store.server}
            if store.startdate:
                fragment['startdate'] = store.startdate
            if store.enddate:
                fragment['enddate'] = store.enddate
            timeline_url += "?" + urlencode(fragment, doseq=True)
            table[page].append([duration, timeline_url])  # min time between edits - index 1
            for user in store.users:
                p_hist = page_hist[page]
                user_is_first = p_hist[0][0] == user
                editcount = len([e for e in p_hist if e[0] == user])
                table[page].append((user_is_first, editcount))  # edit count and blue-ness for the user
        store.table = table

#Improvements:
#Cap list at certain number or time between edits
#Display edit count per page per editor
#Display average time between edits?
#Display overall edit count of each editor?  and first edit date?
#Make timeline easier to read: color-code different editors, display time between edits when editor changes in timeline

