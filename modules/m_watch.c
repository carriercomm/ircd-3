/************************************************************************
 *   IRC - Internet Relay Chat, modules/m_watch.c
 *   Copyright (C) 1990 Jarkko Oikarinen and
 *                      University of Oulu, Computing Center
 *
 *   See file AUTHORS in IRC package for additional names of
 *   the programmers. 
 *
 *   This program is free software; you can redistribute it and/or modify
 *   it under the terms of the GNU General Public License as published by
 *   the Free Software Foundation; either version 1, or (at your option)
 *   any later version.
 *
 *   This program is distributed in the hope that it will be useful,
 *   but WITHOUT ANY WARRANTY; without even the implied warranty of
 *   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *   GNU General Public License for more details.
 *
 *   You should have received a copy of the GNU General Public License
 *   along with this program; if not, write to the Free Software
 *   Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.
 *
 *   $Id: m_watch.c,v 1.3 2003/03/10 06:09:02 demond Exp $
 */
#include "stdinc.h"
#include "handlers.h"
#include "client.h"
#include "ircd.h"
#include "numeric.h"
#include "s_conf.h"
#include "s_serv.h"
#include "s_user.h"
#include "s_log.h"
#include "s_misc.h"
#include "send.h"
#include "msg.h"
#include "parse.h"
#include "modules.h"

static void m_watch(struct Client*, struct Client*, int, char**);
static void show_watch(aClient *cptr, char *name, int rpl1, int rpl2);

struct Message watch_msgtab = {
  "WATCH", 0, 0, 0, 0, MFLG_SLOW, 0,
  {m_unregistered, m_watch, m_ignore, m_watch}
};

#ifndef STATIC_MODULES
void
_modinit(void)
{
  mod_add_cmd(&watch_msgtab);
}

void
_moddeinit(void)
{
  mod_del_cmd(&watch_msgtab);
}

const char *_version = "$Revision: 1.3 $";
#endif

/*
 *	shamelessly stolen from bahamut				
 *						-demond
 */

static char buf[BUFSIZE];

/*
 * RPL_NOWON   - Online at the moment (Succesfully added to WATCH-list)
 * RPL_NOWOFF  - Offline at the moement (Succesfully added to WATCH-list)
 * RPL_WATCHOFF   - Succesfully removed from WATCH-list.
 * ERR_TOOMANYWATCH - Take a guess :>  Too many WATCH entries.
 */
static void show_watch(aClient *cptr, char *name, int rpl1, int rpl2) 
{
    aClient *acptr;	
    
    if ((acptr = find_person(name)))
	sendto_one(cptr, form_str(cptr,rpl1), me.name, cptr->name,
		   acptr->name, acptr->username,
		   acptr->host, acptr->lasttime);
    else
	sendto_one(cptr, form_str(cptr,rpl2), me.name, cptr->name,
		   name, "*", "*", 0);
}
	
/* m_watch */
static void m_watch(aClient *cptr, aClient *sptr, int parc, char *parv[]) 
{
    aClient  *acptr;
    char  *s, *p, *user;
    char def[2] = "l";
	int i;
	
    if (parc < 2) 
    {
	/* Default to 'l' - list who's currently online */
	parc = 2;
	parv[1] = def;
    }
    
    /*for (p = NULL, s = strtoken(&p, parv[1], ", "); s;
	 s = strtoken(&p, NULL, ", "))*/
	/*                                                */
	/* this works on bahamut only...                  */
	/*                                  -demond       */
	/*                                                */
	for (i = 1, s = parv[1]; i < parc; s = parv[++i])
    {
	if ((user = (char *)strchr(s, '!')))
	    *user++ = '\0'; /* Not used */
		
	/*
	 * Prefix of "+", they want to add a name to their WATCH
	 * list. 
	 */
	if (*s == '+') 
	{
	    if (*(s+1)) 
	    {
		if (sptr->watches >= MAXWATCH) 
		{
		    sendto_one(sptr, form_str(sptr,ERR_TOOMANYWATCH),
			       me.name, cptr->name, s+1);					
		    continue;
		}				
		add_to_watch_hash_table(s+1, sptr);
	    }
	    show_watch(sptr, s+1, RPL_NOWON, RPL_NOWOFF);
	    continue;
	}
	
	/*
	 * Prefix of "-", coward wants to remove somebody from their
	 * WATCH list.  So do it. :-)
	 */
	if (*s == '-') 
	{
	    del_from_watch_hash_table(s+1, sptr);
	    show_watch(sptr, s+1, RPL_WATCHOFF, RPL_WATCHOFF);
	    continue;
	}
					
	/*
	 * Fancy "C" or "c", they want to nuke their WATCH list and start
	 * over, so be it.
	 */
	if (*s == 'C' || *s == 'c') 
	{
	    hash_del_watch_list(sptr);
	    continue;
	}
		
	/*
	 * Now comes the fun stuff, "S" or "s" returns a status report of
	 * their WATCH list.  I imagine this could be CPU intensive if its
	 * done alot, perhaps an auto-lag on this?
	 */
	if (*s == 'S' || *s == 's') 
	{
	    Link *lp;
	    aWatch *anptr;
	    int  count = 0;
							
	    /*
	     * Send a list of how many users they have on their WATCH list
	     * and how many WATCH lists they are on.
	     */
	    anptr = hash_get_watch(sptr->name);
	    if (anptr)
		for (lp = anptr->watch, count = 1; (lp = lp->next); count++);
	    sendto_one(sptr, form_str(sptr,RPL_WATCHSTAT), me.name, parv[0],
		       sptr->watches, count);
			
	    /*
	     * Send a list of everybody in their WATCH list. Be careful
	     * not to buffer overflow.
	     */
	    if ((lp = sptr->watch) == NULL) 
	    {
		sendto_one(sptr, form_str(sptr,RPL_ENDOFWATCHLIST), me.name, parv[0],
			   *s);
		continue;
	    }
	    *buf = '\0';
	    strcpy(buf, lp->value.wptr->nick);
	    count = strlen(parv[0])+strlen(me.name)+10+strlen(buf);
	    while ((lp = lp->next)) 
	    {
		if (count+strlen(lp->value.wptr->nick)+1 > BUFSIZE - 2) 
		{
		    sendto_one(sptr, form_str(sptr,RPL_WATCHLIST), me.name,
			       parv[0], buf);
		    *buf = '\0';
		    count = strlen(parv[0])+strlen(me.name)+10;
		}
		strcat(buf, " ");
		strcat(buf, lp->value.wptr->nick);
		count += (strlen(lp->value.wptr->nick)+1);
	    }
	    sendto_one(sptr, form_str(sptr,RPL_WATCHLIST), me.name, parv[0], buf);
	    sendto_one(sptr, form_str(sptr,RPL_ENDOFWATCHLIST), me.name, parv[0],
		       *s);
	    continue;
	}
		
	/*
	 * Well that was fun, NOT.  Now they want a list of everybody in
	 * their WATCH list AND if they are online or offline? Sheesh,
	 * greedy arn't we?
	 */
	if (*s == 'L' || *s == 'l') 
	{
	    Link *lp = sptr->watch;
			
	    while (lp) 
	    {
		if ((acptr = find_person(lp->value.wptr->nick)))
		    sendto_one(sptr, form_str(sptr,RPL_NOWON), me.name, parv[0],
			       acptr->name, acptr->username,
			       acptr->host, acptr->tsinfo);
		/*
		 * But actually, only show them offline if its a capital
		 * 'L' (full list wanted).
		 */
		else if (isupper(*s))
		    sendto_one(sptr, form_str(sptr,RPL_NOWOFF), me.name, parv[0],
			       lp->value.wptr->nick, "*", "*",
			       lp->value.wptr->lasttime);
		lp = lp->next;
	    }
			
	    sendto_one(sptr, form_str(sptr,RPL_ENDOFWATCHLIST), me.name, parv[0],
		       *s);
	    continue;
	}
	/* Hmm.. unknown prefix character.. Ignore it. :-) */
    }
	
    /*return 0;*/
}
