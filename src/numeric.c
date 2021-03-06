/*
 *  ircd-hybrid: an advanced Internet Relay Chat Daemon(ircd).
 *  numeric.c: Numeric handling functions.
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
 *  $Id: numeric.c,v 1.2 2003/03/10 06:09:05 demond Exp $
 */

#include "stdinc.h"
#include "setup.h"
#include "config.h"
#include "client.h"
#include "numeric.h"
#include "irc_string.h"
#include "common.h"     /* NULL cripes */
#include "memory.h"

#include "messages.tab"

/*
 * form_str
 *
 * inputs	- numeric
 * output	- corresponding string
 * side effects	- NONE
 */
char* form_str(struct Client *who, int numeric)
{
  char *num_ptr;

  assert(-1 < numeric);
  assert(numeric < ERR_LAST_ERR_MSG);
  assert(0 != replies[numeric]);

  if (numeric > ERR_LAST_ERR_MSG)
    numeric = ERR_LAST_ERR_MSG;
  if (numeric < 0)
    numeric = ERR_LAST_ERR_MSG;

  num_ptr = replies[numeric];
  if (num_ptr == NULL)
    num_ptr = replies[ERR_LAST_ERR_MSG];

  if (!who) return (_(num_ptr));
  	else
  return (IsSetAltLocale(who)? __("alt-language", num_ptr) : _(num_ptr));
}


