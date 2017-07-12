#!/home/sigma/.local/bin/python3
# -*- coding: utf-8 -*-
# Copyright (c) 2017 User:Σ, GPLv3

import re

import cymysql as sql

from tool import Tool
from utils import Databank, connect_info, ucfirst


class Timeline(Tool):

    def __call__(self):
        store = self.store
        if store.name is None and store.page is None:
            return "timeline.index.mako", store
        self.set_constants()
        self.prepare_query(store)
        with sql.connect(**connect_info(store.server)) as cursor:
            self.do_query(store.query, cursor)
        store.query.results = self.fix_results(store.query.rawresults)
        return "timeline.query.mako", store

    def set_constants(self):
        super().set_constants()
        store = self.store
        store.page = ucfirst(store.page)
        store.titleparts = self.titleparts(store.page)

        try:
            store.startdate = int(store.startdate) * 1000000
        except:
            store.startdate = 0

        try:
            store.enddate = int(store.enddate) * 1000000 
        except:
            store.enddate = 0

        if isinstance(store.users, list):
            store.users = set(store.users)
        elif isinstance(store.users, str):
            store.users = {store.users}
        else:
            store.users = set()
        self.organise_users(store)


    def organise_users(self, store):
        expr = re.compile("user([0-9]+)$")
        for param in store.kw:
            match = expr.match(param)
            if match and int(match.group(1)) < 21:
                store.users.add(store.kw[param].strip())
        store.users = {ucfirst(u.strip()) for u in store.users}
        store.users = {u for u in store.users if u}
        store.users = tuple(store.users)


    @staticmethod
    def prepare_query(store: Databank):
        l = []
        s = []
        s.append(
            "SELECT r.rev_id,r.rev_timestamp,page_namespace,page_title,r.rev_user_text,r.rev_minor_edit,rr.rev_len,r.rev_len,r.rev_comment"
        )
        s.append("FROM revision_userindex r JOIN page ON rev_page=page_id")
        s.append("LEFT JOIN revision_userindex rr ON r.rev_parent_id=rr.rev_id")
        #s.append("SELECT rev_user_text, rev_timestamp, rev_minor_edit, rev_id, rev_comment")
        #s.append("FROM revision_userindex")
        #s.append("JOIN page ON rev_page=page_id")
        s.append("WHERE r.rev_deleted=0")
        s.append("AND page_title=%s")
        l.append(store.titleparts[2])
        s.append("AND page_namespace=%s")
        l.append(store.titleparts[0])
        s.append("AND r.rev_user_text IN")
        s.append(','.join(["%s"] * len(store.users)).join("()"))
        l.extend(store.users)
        if store.startdate:
            s.append("AND r.rev_timestamp > %s")
            l.append(store.startdate)
        if store.enddate:
            s.append("AND r.rev_timestamp < %s")
            l.append(store.enddate + 235959)
        s.append("ORDER BY r.rev_timestamp DESC LIMIT 1000")

        store.query.str = '\n'.join(s)
        store.query.args = tuple(l)

    @staticmethod
    def do_query(query, cur):
        cur.execute(query.str, query.args)
        query.rawresults = cur.fetchall()

    def fix_results(self, res):
        for line in res:
            new_line = []
            for obj in line:
                if isinstance(obj, bytes):
                    obj = obj.decode("utf8")
                new_line.append(obj)
            # this next part is the worst part ever
            # rev_user_text, rev_timestamp, rev_minor_edit, rev_id, rev_comment
            # revid, ts, namespace, title, user, isminor, oldsize, newsize, summ = row
            #revid, ts, namespace, title, user, isminor, oldsize, newsize, summ = new_line
            #del new_line
            yield self.history_line(new_line)
