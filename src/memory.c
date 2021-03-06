/*
 *  ircd-hybrid: an advanced Internet Relay Chat Daemon(ircd).
 *  memory.c: Memory utilities.
 *
 *  Copyright (C) 2002 by the past and present ircd coders, and others.
 *
 *  This program is free software; you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License as published by
 *  the Free Software Foundation; either version 2 of the License, or
 *  (at your option) any later version.
 *
 *  This program is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU General Public License for more details.
 *
 *  You should have received a copy of the GNU General Public License
 *  along with this program; if not, write to the Free Software
 *  Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307
 *  USA
 *
 *  $Id: memory.c,v 1.1.1.1 2002/12/31 04:07:27 demond Exp $
 */


#define WE_ARE_MEMORY_C

#include "stdinc.h"
#include "ircd_defs.h"
#include "ircd.h"
#include "irc_string.h"
#include "memory.h"
#include "list.h"
#include "client.h"
#include "send.h"
#include "tools.h"
#include "s_log.h"
#include "restart.h"


/*
 * MyMalloc - allocate memory, call outofmemory on failure
 */
void *MyMalloc(size_t size)
{
    void *ret = calloc(1, size);
    if (ret == NULL)
	outofmemory();
    return ret;
}

/*
 * MyRealloc - reallocate memory, call outofmemory on failure
 */
void *MyRealloc(void *x, size_t y)
{
    void *ret = realloc(x, y);

    if (ret == NULL)
	outofmemory();
    return ret;
}

void MyFree(void *x)
{
     if(x)
     	free((x));
}

void _DupString(char **x, const char *y)
{
    (*x) = malloc(strlen(y) + 1);
    strcpy((*x), y);
}


/*
 * outofmemory()
 *
 * input        - NONE
 * output       - NONE
 * side effects - simply try to report there is a problem. Abort if it was called more than once
 */
void outofmemory()
{
    static int was_here = 0;

    if (was_here)
	abort();

    was_here = 1;

    ilog(L_CRIT, "Out of memory: restarting server...");
    restart("Out of Memory");
}
