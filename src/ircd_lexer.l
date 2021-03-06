/*
 *  ircd-hybrid: an advanced Internet Relay Chat Daemon(ircd).
 *  ircd_lexer.l: Scans the ircd configuration file for tokens.
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
 *  $Id: ircd_lexer.l,v 1.4 2003/05/24 00:07:46 demond Exp $
 */

%option case-insensitive
%option noyywrap
%option nounput

%{
/* XXX - No we aren't but lex calls malloc :(. It is even worse that it
   doesn't call free! */
#define WE_ARE_MEMORY_C
#include "stdinc.h"
#include "tools.h"
#include "irc_string.h"
#include "common.h"
#include "s_conf.h"
#ifdef VMS
# include "ircd_parser_tab.h"
#else
# include "y.tab.h"
#endif
#include "memory.h"
#include "hostmask.h"
#include "setup.h"
#include "config.h"
#include "s_log.h"

#undef YY_INPUT
#define YY_FATAL_ERROR(msg) conf_yy_fatal_error(msg)
#define YY_INPUT(buf,result,max_size) \
  if (!(result = conf_fbgets(buf, max_size, conf_fbfile_in))) \
    YY_FATAL_ERROR("input in flex scanner failed"); 
#define MAX_INCLUDE_DEPTH 10


int lineno=1;
char linebuf[IRCD_BUFSIZE];
char conffilebuf[IRCD_BUFSIZE];
int include_stack_ptr=0;
YY_BUFFER_STATE include_stack[MAX_INCLUDE_DEPTH];
int lineno_stack[MAX_INCLUDE_DEPTH];
FBFILE* inc_fbfile_in[MAX_INCLUDE_DEPTH];
char conffile_stack[MAX_INCLUDE_DEPTH][IRCD_BUFSIZE];
void ccomment(void);
void hashcomment(void);
void cinclude(void);
int ieof(void);
%}

ws        [ \t]*
digit     [0-9]
comment   #.*
qstring   \"[^\"\n]*[\"\n]
include   \.include{ws}(\<.*\>|\".*\")

%%
{include}       { cinclude(); }
"/*"	        { ccomment(); }

\n.*	        { strcpy(linebuf, yytext+1); lineno++; yyless(1); }

{ws}            ;
{comment}       { hashcomment(); }

{digit}+        { yylval.number = atoi(yytext); return NUMBER; }

{qstring}	{ if(yytext[yyleng-2] == '\\')
		    {
		      yyless(yyleng-1); /* return last quote */
		      yymore();		/* append next string */
		    }
		  else
		    {
		      yylval.string = yytext+1;
		      if(yylval.string[yyleng-2] != '"')
			ilog(L_ERROR, "Unterminated character string");
		      else
			{
			  int i,j;

			  yylval.string[yyleng-2] = '\0'; /* remove close
							   *  quote 
							   */
			  
			  for (j=i=0 ;yylval.string[i] != '\0'; i++,j++)
			    {
			      if (yylval.string[i] != '\\')
				{
				  yylval.string[j] = yylval.string[i];
				}
			      else
				{
				  i++;
				  if (yylval.string[i] == '\0') /* XXX 
								 * should not
								 * happen
								 */
				    {
				      ilog(L_ERROR,
					   "Unterminated character string");
				      break;
				    }
				  yylval.string[j] = yylval.string[i];
				}
			    }
			  yylval.string[j] = '\0';
			  return QSTRING;
			}
		    }
		}

accept_password { return ACCEPT_PASSWORD; }
action		{ return ACTION; }
admin		{ return ADMIN; }
administrator	{ return ADMIN; }
aftype		{ return AFTYPE; }
auth		{ return AUTH; }
autoconn	{ return AUTOCONN; }
can_flood	{ return CAN_FLOOD; }
caller_id_wait	{ return CALLER_ID_WAIT; }
channel		{ return CHANNEL; }
cipher_preference { return CIPHER_PREFERENCE; }
class		{ return CLASS; }
client_exit     { return CLIENT_EXIT; }
client_flood	{ return T_CLIENT_FLOOD; }
compressed	{ return COMPRESSED; }
compression_level { return COMPRESSION_LEVEL; }
connect		{ return CONNECT; }
connectfreq     { return CONNECTFREQ; }
cyrillic        { return CYRILLIC; }
totaltrans      { return TOTALTRANS; }
cryptlink	{ return CRYPTLINK; }
default_cipher_preference { return DEFAULT_CIPHER_PREFERENCE; }
default_floodcount  { return DEFAULT_FLOODCOUNT; }
default_split_server_count { return DEFAULT_SPLIT_SERVER_COUNT; }
default_split_user_count   { return DEFAULT_SPLIT_USER_COUNT; }
deny		{ return DENY; }
description	{ return DESCRIPTION; }
die		{ return DIE; }
disable_hidden	{ return DISABLE_HIDDEN; }
disable_local_channels { return DISABLE_LOCAL_CHANNELS; }
disable_remote_commands	{ return DISABLE_REMOTE_COMMANDS; }
dot_in_ip6_addr { return DOT_IN_IP6_ADDR; }
dots_in_ident   { return DOTS_IN_IDENT; }
egdpool_path        { return EGDPOOL_PATH; }
email		{ return EMAIL; }
encrypted       { return ENCRYPTED; }
exceed_limit    { return EXCEED_LIMIT; }
exempt		{ return EXEMPT; }
fakename	{ return FAKENAME; }
fallback_to_ip6_int { return FALLBACK_IP6_INT; }
flatten_links	{ return FLATTEN_LINKS; }
fname_foperlog  { return FNAME_FOPERLOG; }
fname_operlog   { return FNAME_OPERLOG; }
fname_userlog   { return FNAME_USERLOG; }
netid		{ return NETID; }
gecos		{ return GECOS; }
general		{ return GENERAL; }
gline		{ return GLINE; }
gline_exempt    { return GLINE_EXEMPT; }
gline_log       { return GLINE_LOG; }
gline_time      { return GLINE_TIME; }
global_kill	{ return GLOBAL_KILL; }
have_ident	{ return HAVE_IDENT; }
havent_read_conf { return HAVENT_READ_CONF; }
hidden		{ return HIDDEN; }
hide_servers	{ return HIDE_SERVERS; }
host		{ return HOST; }
maskhost	{ return MASKHOST; }
hub		{ return HUB; }
hub_mask	{ return HUB_MASK; }
idletime        { return IDLETIME; }
ip		{ return IP; }
ipv4            { return T_IPV4; }
ipv6            { return T_IPV6; }
kill		{ return KILL; }
kline		{ return KLINE; }
kline_exempt	{ return KLINE_EXEMPT; }
l_crit		{ return T_L_CRIT; }
l_debug		{ return T_L_DEBUG; }
l_error		{ return T_L_ERROR; }
l_info		{ return T_L_INFO; }
l_notice 	{ return T_L_NOTICE; }
l_trace		{ return T_L_TRACE; }
l_warn		{ return T_L_WARN; }
lazylink	{ return LAZYLINK; }
leaf_mask	{ return LEAF_MASK; }
listen		{ return LISTEN; }
log_level	{ return LOG_LEVEL; }
logging         { return LOGGING; }
logpath         { return T_LOGPATH; }
masked		{ return TMASKED; }
max_buffer	{ return T_MAX_BUFFER; }
max_clients     { return T_MAX_CLIENTS; }
max_number	{ return MAX_NUMBER; }
maximum_links   { return MAXIMUM_LINKS; }
message_locale	{ return MESSAGE_LOCALE; }
min_nonwildcard { return MIN_NONWILDCARD; }
name		{ return NAME; }
network_desc    { return NETWORK_DESC; }
network_name    { return NETWORK_NAME; }
nick		{ return NICK; }
nick_changes	{ return NICK_CHANGES; }
no		{ return TNO; }
no_create_on_split { return NO_CREATE_ON_SPLIT; }
no_join_on_split   { return NO_JOIN_ON_SPLIT; }
no_oper_flood   { return NO_OPER_FLOOD; }
no_tilde	{ return NO_TILDE; }
number_per_ip	{ return NUMBER_PER_IP; }
oper		{ return OPERATOR; }
oper_log        { return OPER_LOG; }
oper_pass_resv	{ return OPER_PASS_RESV; }
operator	{ return OPERATOR; }
passwd		{ return PASSWORD; }
password	{ return PASSWORD; }
ping_cookie	{ return PING_COOKIE; }
ping_time	{ return PING_TIME; }
port		{ return PORT; }
sslport		{ return SSLPORT; }
quiet_on_ban    { return QUIET_ON_BAN; }
reason		{ return REASON; }
redirport       { return REDIRPORT; }
redirserv       { return REDIRSERV; }
rehash		{ return REHASH; }
reject		{ return TREJECT; }
remote		{ return REMOTE; }
restricted      { return RESTRICTED; }
resv		{ return RESV; }
rsa_private_key_file		{ return RSA_PRIVATE_KEY_FILE; }
rsa_public_key_file		{ return RSA_PUBLIC_KEY_FILE; }
ssl_certificate_file	{ return SSL_CERTIFICATE_FILE; }
send_password	{ return SEND_PASSWORD; }
sendq		{ return SENDQ; }
serverhide	{ return SERVERHIDE; }
serverinfo	{ return SERVERINFO; }
services        { return SERVICES; }
servlink_path   { return SERVLINK_PATH; }
shared          { return T_SHARED; }
short_motd      { return SHORT_MOTD; }
skip_on_fail    { return SKIP_ON_FAIL; }
silent          { return SILENT; }
spoof		{ return SPOOF; }
spoof_notice	{ return SPOOF_NOTICE; }
true_no_oper_flood { return TRUE_NO_OPER_FLOOD; }
unkline		{ return UNKLINE; }
use_anonops	{ return USE_ANONOPS; }
use_egd 	{ return USE_EGD; }
use_except	{ return USE_EXCEPT; }
use_halfops     { return USE_HALFOPS; }
use_help        { return USE_HELP; }
use_invex	{ return USE_INVEX; }
use_subst	{ return USE_SUBST; }
use_denies	{ return USE_DENIES; }
use_knock	{ return USE_KNOCK; }
use_vchans      { return USE_VCHANS; }
throttle_time { return THROTTLE_TIME; }
user		{ return USER;} 
vchans_oper_only { return VCHANS_OPER_ONLY; }
vhost	{ return VHOST; }
vhost6	{ return VHOST6; }
warn		{ return WARN; }
yes		{ return TYES; }
equivalent      { return EQUIVALENT; }
nicks           { return NICKS; }
relays          { return RELAYS; }
userpar			{ return USERPAR; }
param			{ return PARAM; }
dummy           { return DUMMY; }

drone_rate_max		{ return DRONE_RATE_MAX; }
drone_rate_period	{ return DRONE_RATE_PERIOD; }
drone_kline			{ return DRONE_KLINE; }
drone_batch			{ return DRONE_BATCH; }
drone_kline_time	{ return DRONE_KLINE_TIME; }
drone_reason		{ return DREASON; }
spam_wait			{ return SPAM_WAIT; }
repeat_grace		{ return REPEAT_GRACE; }
spawn_pass			{ return SPAWN_PASS; }
gateway				{ return GATEWAY; }
clusters			{ return CLUSTERS; }
bridge				{ return BRIDGE; }

failed_oper_notice      { return FAILED_OPER_NOTICE; }
max_accept              { return MAX_ACCEPT; }
max_nick_changes        { return MAX_NICK_CHANGES; }
max_chans_per_user      { return MAX_CHANS_PER_USER; }
max_nick_time           { return MAX_NICK_TIME; }
anti_nick_flood         { return ANTI_NICK_FLOOD; }
anti_spam_exit_message_time { return ANTI_SPAM_EXIT_MESSAGE_TIME; }
ts_max_delta            { return TS_MAX_DELTA; }
ts_warn_delta           { return TS_WARN_DELTA; }
links_delay           { return LINKS_DELAY; }
grace_time				{ return GRACE_TIME; }
kline_with_connection_closed { return KLINE_WITH_CONNECTION_CLOSED; }
kline_with_reason       { return KLINE_WITH_REASON; }
warn_no_nline           { return WARN_NO_NLINE; }
non_redundant_klines    { return NON_REDUNDANT_KLINES; }

stats_o_oper_only       { return STATS_O_OPER_ONLY; }
stats_k_oper_only	{ return STATS_K_OPER_ONLY; }
stats_i_oper_only	{ return STATS_I_OPER_ONLY; }
stats_P_oper_only	{ return STATS_P_OPER_ONLY; }
pace_wait               { return PACE_WAIT; }
pace_wait_simple	{ return PACE_WAIT_SIMPLE; }
knock_delay             { return KNOCK_DELAY; }
knock_delay_channel	{ return KNOCK_DELAY_CHANNEL; }
iauth_server            { return IAUTH_SERVER; }
iauth_port		{ return IAUTH_PORT; }
glines                  { return GLINES; }
max_bans                { return MAX_BANS; }
modules                 { return MODULES; }
module                  { return MODULE; }
path                    { return PATH; }
max_targets             { return MAX_TARGETS; }

oper_only_umodes        { return OPER_ONLY_UMODES; }
oper_umodes             { return OPER_UMODES; }
bots                    { return T_BOTS; }
cconn                   { return T_CCONN; }
debug                   { return T_DEBUG; }
full                    { return T_FULL; }
skill                   { return T_SKILL; }
nchange                 { return T_NCHANGE; }
rconn					{ return T_REMOTE; }
rej                     { return T_REJ; }
unauth                  { return T_UNAUTH; }
spy                     { return T_SPY; }
external                { return T_EXTERNAL; }
operwall                { return T_OPERWALL; }
servnotice              { return T_SERVNOTICE; }
invisible               { return T_INVISIBLE; }
wallop                  { return T_WALLOP; }
callerid                { return T_CALLERID; }
drone                   { return T_DRONE; }
locops                  { return T_LOCOPS; }

millennia		{ return MILLENNIA; }
millennium		{ return MILLENNIA; }
centuries		{ return CENTURIES; }
century			{ return CENTURIES; }
decades			{ return DECADES; }
decade			{ return DECADES; }
years			{ return YEARS; }
year			{ return YEARS; }
months			{ return MONTHS; }
month			{ return MONTHS; }
weeks			{ return WEEKS; }
week			{ return WEEKS; }
days			{ return DAYS; }
day			{ return DAYS; }
hours			{ return HOURS; }
hour			{ return HOURS; }
minutes			{ return MINUTES; }
minute			{ return MINUTES; }
seconds			{ return SECONDS; }
second			{ return SECONDS; }

bytes			{ return BYTES; }
byte			{ return BYTES; }
kilobytes		{ return KBYTES; }
kilobyte		{ return KBYTES; }
kbytes			{ return KBYTES; }
kbyte			{ return KBYTES; }
kb			{ return KBYTES; }
megabytes		{ return MBYTES; }
megabyte		{ return MBYTES; }
mbytes			{ return MBYTES; }
mbyte			{ return MBYTES; }
mb			{ return MBYTES; }
gigabytes		{ return GBYTES; }
gigabyte		{ return GBYTES; }
gbytes			{ return GBYTES; }
gbyte			{ return GBYTES; }
gb			{ return GBYTES; }
terabytes		{ return TBYTES; }
terabyte		{ return TBYTES; }
tbytes			{ return TBYTES; }
tbyte			{ return TBYTES; }
tb			{ return TBYTES; }
\.\.                    { return TWODOTS; }

.		        { return yytext[0]; }
<<EOF>>     { if (ieof()) yyterminate(); }

%%

/* C-comment ignoring routine -kre*/
void ccomment(void)
{
  int c;

  /* log(L_NOTICE, "got comment"); */
  while (1)
  {
    while ((c = input()) != '*' && c != EOF)
      if (c == '\n') ++lineno;
    if (c == '*')
    {
      while ((c = input()) == '*');
      if (c == '/') break;
    }
    if (c == EOF)
    {
      YY_FATAL_ERROR("EOF in comment");
      /* XXX hack alert this disables
       * the stupid unused function warning
       * gcc generates 
       */
      if(1 == 0)
		yy_fatal_error("EOF in comment");
      break;
    }
  }
}

/* #-comment style, look for #include */
#define INCLUDE "#include"
void hashcomment(void) 
{
  if (strlen(yytext) < strlen(INCLUDE))
    return;

  if ( !strncasecmp(yytext, INCLUDE, strlen(INCLUDE)) ) 
      yyerror("You probably meant '.include', skipping");
}

/* C-style .includes. This function will properly swap input conf buffers,
 * and lineno -kre */
void cinclude(void)
{
  char *c;
  if ((c = strchr(yytext, '<')) == NULL)
    *strchr(c = strchr(yytext, '"') + 1, '"') = 0;
  else
    *strchr(++c, '>') = 0;

  /* log(L_NOTICE, "got include %s!", c); */

  /* do stacking and co. */ 
  if (include_stack_ptr >= MAX_INCLUDE_DEPTH)
    ilog(L_ERROR, "Includes nested too deep in %s", c);
  else
  {
    FBFILE *tmp_fbfile_in;
    char filenamebuf[IRCD_BUFSIZE];
    
#ifdef HAVE_SNPRINTF
    snprintf(filenamebuf, IRCD_BUFSIZE, "%s/%s", ETCPATH, c);
#else
    sprintf(filenamebuf, "%s/%s", ETCPATH, c);
#endif
    tmp_fbfile_in = fbopen(filenamebuf, "r");
    
    if (tmp_fbfile_in == NULL)
    {
      ilog(L_ERROR, "Cannot include %s", filenamebuf);
      return;
    }
    lineno_stack[include_stack_ptr] = lineno;
    lineno = 1;
    inc_fbfile_in[include_stack_ptr] = conf_fbfile_in;
    strlcpy(conffile_stack[include_stack_ptr], conffilebuf, IRCD_BUFSIZE);
    include_stack[include_stack_ptr++] = YY_CURRENT_BUFFER;
    conf_fbfile_in = tmp_fbfile_in;
    sprintf(conffilebuf, "%s", c);
    yy_switch_to_buffer(yy_create_buffer(yyin, YY_BUF_SIZE));
  }
}

/* This is function that will be called on EOF in conf file. It will
 * apropriately close conf if it not main conf and swap input buffers -kre
 * */
int ieof(void)
{
  /* log(L_NOTICE, "return from include stack!"); */
  if (include_stack_ptr)
    fbclose(conf_fbfile_in);
  if (--include_stack_ptr < 0)
  {
    /* log(L_NOTICE, "terminating lexer"); */
    /* We will now exit the lexer - restore init values if we get /rehash
     * later and reenter lexer -kre */
    include_stack_ptr = 0;
    lineno = 1;
    return 1;
  }
  /* switch buffer */
  /* log(L_NOTICE, "deleting include_stack_ptr=%d", include_stack_ptr); */
  yy_delete_buffer(YY_CURRENT_BUFFER);
  lineno = lineno_stack[include_stack_ptr];
  conf_fbfile_in = inc_fbfile_in[include_stack_ptr];
  strlcpy(conffilebuf, conffile_stack[include_stack_ptr], IRCD_BUFSIZE); 
  yy_switch_to_buffer(include_stack[include_stack_ptr]);
  return 0;
}
