// Serious commands

/*
 *	Nr 		COMMAND				CALLBACK FUNCTION			ADMIN LEVEL
 *			
 *	1)		amx_alltalk			CmdAllTalk					ADMIN_LEVEL_A
 *	2)		amx_extend			CmdExtend					ADMIN_LEVEL_A
 *	3)		amx_(un)gag			Cmd(Un)Gag					ADMIN_LEVEL_A
 *	4)		amx_pass			CmdPass						ADMIN_PASSWORD
 *	5)		amx_nopass			CmdNoPass					ADMIN_PASSWORD
 *	6)		admin voicecomm		Cmd_PlusAdminVoice			ADMIN_VOICE
 *								Cmd_MinAdminVoice			ADMIN_VOICE
 *	7)		amx_transfer		Cmd_Transfer				ADMIN_LEVEL_D
 * 	8)		amx_swap			Cmd_Swap					ADMIN_LEVEL_D
 *	9)		amx_teamswap		Cmd_TeamSwap				ADMIN_LEVEL_D
 *	10)		amx_lock			Cmd_Lock					ADMIN_LEVEL_D
 *	11)		amx_unlock			Cmd_Unlock					ADMIN_LEVEL_D
 *	12)		amx_badaim			Cmd_BadAim					ADMIN_LEVEL_D
 *	13)		amx_quit			CmdQuit						ADMIN_LEVEL_E
 *	14)		amx_exec			CmdExec						ADMIN_BAN
 *	15a)	amx_restart			CmdRestart					ADMIN_BAN
 *	15b)	amx_shutdown		CmdRestart					ADMIN_RCON
 *	16)		say /gravity		CmdGravity					/
 *	17)		say /alltalk		CmdAlltalk					/
 *	18)		say /spec			CmdSpec						/
 *	19)		say /unspec			CmdUnSpec					/
 *	20)		say /admin(s)		CmdAdmins					/
 *	21)		say /fixsound		CmdFixSound					/
*/


/*	New ML lines
[en]
AMX_SUPER_UBERSLAP_TEAM_CASE1 = [AMXX] ADMIN uberslapped %s players
AMX_SUPER_UBERSLAP_TEAM_CASE2 = [AMXX] ADMIN %s uberslapped %s players
AMX_SUPER_UBERSLAP_TEAM_LOG = [AMX_Super] UBERSLAP: ^"%s<%s^" uberslapped ^"%s^" players

[nl]
AMX_SUPER_UBERSLAP_TEAM_CASE1 = [AMXX] ADMIN ubersloeg %s spelers
AMX_SUPER_UBERSLAP_TEAM_CASE2 = [AMXX] ADMIN %s ubersloeg %s spelers
AMX_SUPER_UBERSLAP_TEAM_LOG = [AMX_Super] UBERSLAAN: ^"%s<%s^" ubersloeg ^"%s^" spelers
*/

/*

# Name global variables like they should, I mean, we have g_GlowColor for example but below we have 'smoke', just telling this to make the code easier to read (same as the #1) (goes for both plugins, serious and fun commands)

# amx_userorigin doesn't log, I don't know if this was made on purpose, just pointing it out...


# I suggest making a cvar for amx_ban on Bad Aim because I don't think it's necessary at all, it's just a fun command or a "punishment" command type but there's no need to ban the user if he kills someone lol...
*/

#include <amxmodx>
#include <amxmisc>
#include <cstrike>
#include <fakemeta>
#include <hamsandwich>
#include <fun>

#define SetPlayerBit(%1,%2)      (%1 |= (1<<(%2&31)))
#define ClearPlayerBit(%1,%2)    (%1 &= ~(1 <<(%2&31)))
#define CheckPlayerBit(%1,%2)    (%1 & (1<<(%2&31))) 

//		amx_extend 
// #define MAPCYCLE				
#define EXTENDMAX 	9			// Maximum number of times a map may be extended by anyone.
#define EXTENDTIME 	15			// Maximum amount of time any map can be extended at once.
#define MAX_MAPS 	32			// Change this if you have more than 32 maps in mapcycle.

#if defined MAPCYCLE
new gNum;
new bool: cyclerfile;
#endif


//		amx_gag
#define TASK_GAG 		5446		// Taskid for gag. Change this number if it interferes with any other plugins.
#define SPEAK_NORMAL	0		// Not to be changed.
#define SPEAK_MUTED		1		// Not to be changed.
#define SPEAK_ALL		2		// Not to be changed.
#define SPEAK_LISTENALL	4		// Not to be changed.

// admin voicecomm
#define ADMIN_VOICE		ADMIN_RESERVATION

// amx_badaim
#define TASKID_UNBADAIM		15542	// taskid. Change this number if it interfers with any other plugins
#define TERRO 	0
#define COUNTER 1
#define AUTO	4
#define SPEC	5

// admin check
#define ADMIN_CHECK ADMIN_KICK  // For Admin Check

// For show_activity / log_amx team messages.
enum CmdTeam
{
	ALL,
	T,
	CT
};

new const g_TeamNames[CmdTeam][] = 
{ 
	"all",
	"terrorist", 
	"counter-terrorist" 
};

// Cvar pointers:
new cAllTalk
	, cTimeLimit
	, cDefaultGagTime
	, cGagSound
	, cBlockNameChange
	, sv_password
	, autobantimed
	, autobanall
	, cGravity
	//, cAlltalk
	, cAllowSoundFix
	, cAllowSpec
	, cAllowPublicSpec
	, cAdminCheck
	, cSvContact	
	, cBadAimBan
;

// admin voicecomm
enum SPKSETTINGS
{
	SPEAK_MUTED2, 	// 0
	SPEAK_NORMAL2, 	// 1
	SPEAK_ALL2,		// 2
	NONE,			// 3	
	NONE,			// 4
	SPEAK_ADMIN		// 5
};


new SPKSETTINGS: g_PlayerSpk[33]
	, admin
	, g_voicemask[33]
;

// team locker
new const Teamnames[6][] = 
{
	"Terrorists",
	"Counter-Terrorists",
	"",
	"",
	"Auto",
	"Spectator"
};
new bool: g_BlockJoin[6];

// amx_badaim
new bool: g_HasBadAim[33]
	, bool: g_AutoBan[33]
;

// amx shutdown
enum ShutDownMode
{
	RESTART,
	SHUTDOWN,
};

new const g_ShutDownNames[ShutDownMode][] = 
{
	"restart",
	"shut down"
};

new ShutDownMode: g_ShutDownMode,
	bool: g_ShuttingDown = false
;

// say /admins chat color - green
static const COLOR[] = "^x04";
new g_MsgSayText;

// say /(un)spec
new CsTeams: g_OldTeam[33];

// misc
new g_MaxPlayers;

public plugin_init()
{
	register_plugin("Amx Super Serious", "5.0", "Supercentral.net Scripting Team");
	register_dictionary("amx_super.txt");
	
	register_concmd("amx_alltalk", 	"CmdAllTalk", 	ADMIN_LEVEL_A, "[1 = ON | 0 = OFF]");
	register_concmd("amx_extend", 	"CmdExtend", 	ADMIN_LEVEL_A, "<added time to extend> : ex. 5, if you want to extend it five more minutes.");
	register_concmd("amx_gag", 		"CmdGag", 		ADMIN_LEVEL_A, "<nick, #userid or authid> <a|b|c> <time> - Flags: a = Normal Chat | b = Team Chat | c = Voicecomm");
	register_concmd("amx_ungag", 	"CmdUngag", 	ADMIN_LEVEL_A, "<nick, #userid or authid>");
	register_concmd("amx_pass", 	"CmdPass", 		ADMIN_PASSWORD,"<password> - sets the server's password")
	register_concmd("amx_nopass", 	"CmdNoPass", 	ADMIN_PASSWORD,"Removes the server's password")
	register_concmd("amx_transfer", "Cmd_Transfer", ADMIN_LEVEL_D, "<name> <CT/T/Spec> Transfers that player to the specified team");
	register_concmd("amx_swap", 	"Cmd_Swap", 	ADMIN_LEVEL_D, "<name> <name2> Swaps 2 players with eachother");
	register_concmd("amx_teamswap", "Cmd_TeamSwap", ADMIN_LEVEL_D, "Swaps 2 teams with eachother");
	register_concmd("amx_lock", 	"Cmd_Lock", 	ADMIN_LEVEL_D, "<CT/T/Auto/Spec> - Locks selected team");
	register_concmd("amx_unlock",	"Cmd_Unlock",	ADMIN_LEVEL_D, "<CT/T/Auto/Spec> - Unlocks selected team");
	register_concmd("amx_badaim", 	"Cmd_BadAim", 	ADMIN_LEVEL_D, "<player> <On/off or length of time: 1|0|time> <Save?: 1|0>: Turn on/off bad aim on a player.");
	register_concmd("amx_quit", 	"CmdQuit", 		ADMIN_LEVEL_E, "<nick, #userid, authid or @team>");
	register_concmd("amx_exec", 	"CmdExec", 		ADMIN_BAN, 	   "<nick, #userid, authid or @team> <command>");
	register_concmd("amx_restart", 	"CmdRestart", 	ADMIN_BAN, 	   "<seconds (1-20)> - Restarts the server in seconds");
	register_concmd("amx_shutdown", "CmdRestart", 	ADMIN_RCON,    "<seconds (1-20)> - Shuts down the server in seconds");
	
	register_clcmd("say /gravity", "CmdGravity");
	register_clcmd("say /alltalk", "CmdAlltalk");
	
	// admin voicecomm
	register_clcmd("+adminvoice", 	"Cmd_PlusAdminVoice");		
	register_clcmd("-adminvoice", 	"Cmd_MinAdminVoice");		
	
	register_event("VoiceMask", "Event_VoiceMask", "b");
	
	// Register new cvars and get existing cvar pointers:
	cAllTalk 			= get_cvar_pointer("sv_alltalk");
	cTimeLimit 			= get_cvar_pointer("mp_timelimit");
	sv_password 		= get_cvar_pointer("sv_password")
	cGravity 			= get_cvar_pointer("sv_gravity");
	// repeated-=removed
	//cAlltalk 			= get_cvar_pointer("sv_alltalk");
	cAllowSpec 			= get_cvar_pointer("allow_spectators");
	cSvContact 			= get_cvar_pointer("sv_contact");
	
	cGagSound 			= register_cvar("amx_super_gagsound", "1");
	cBlockNameChange 	= register_cvar("amx_super_gag_block_namechange", "1");
	cDefaultGagTime 	= register_cvar("amx_super_gag_default_time", "600.0");
	autobantimed 		= register_cvar("amx_autobantimed", "1");
	autobanall 			= register_cvar("amx_autobanall", "1");
	cAllowSoundFix 		= register_cvar("amx_soundfix_pallow", "1");
	cAllowPublicSpec 	= register_cvar("allow_public_spec","1");
	cAdminCheck 		= register_cvar("amx_admin_check", "1");
	cBadAimBan			= register_cvar("amx_badaim_ban", "0");
	
	
	// amx_gag
	register_clcmd("say", "CmdSay");
	register_clcmd("say_team", "CmdSay");
	
	register_forward(FM_Voice_SetClientListening, "Fwd_SetClientListening");
	
	
	// amx_extend
	#if defined MAPCYCLE
	new MapName[35];
	get_mapname(MapName, charsmax(MapName));
	
	new f = fopen("mapcycle.txt", "rt");
	
	if(f)
	{
		new Data[50];
		
		cyclerfile = false;
		
		while(!feof(f) && gNum < MAX_MAPS)
		{
			fgets(f, Data, charsmax(Data));
			trim(Data);
			
			if(!Data[0] || Data[0] == ';' || (Data[0] == '/' && Data[1] == '/'))
				continue;
			
			if(equali(Data, MapName))
			{
				cyclerfile = true;
				
				break;
			}
			
			gNum++;
		}
		
		fclose(f);
	}
	#endif
	
	// team locker
	register_menucmd(register_menuid("Team_Select", 1), (1<<0)|(1<<1)|(1<<4)|(1<<5), "team_select");
	register_concmd("jointeam", "join_team");
	
	// amx_badaim
	register_event("DeathMsg", "Event_DeathMsg", "a", "1>0");
	register_forward(FM_PlayerPreThink, "FwdPlayerPrethink");

}


/* client disconnects
 *-------------------
*/
public client_disconnect(id)
{
	if(CheckPlayerBit(admin, id)) 
	{
		g_PlayerSpk[id] = SPEAK_NORMAL2;
		
		ClearPlayerBit(admin, id);
	}
	
	g_HasBadAim[id] = false;
	g_AutoBan[id] = false;
}

/* client_authorized
 *------------------
*/
public client_authorized(id) 
{ 
 	if(get_user_flags(id) & ADMIN_RESERVATION) 
		SetPlayerBit(admin, id);
		
	check_aimvault(id);
}


/*	1)	amx_alltalk
 *-----------------
*/
public CmdAllTalk(id, level, cid)
{
	if(!cmd_access(id, level, cid, 1))
		return PLUGIN_HANDLED;
		
	if(read_argc() < 2)
	{	
		console_print(id, "%L", id, "AMX_SUPER_ALLTALK_STATUS", get_pcvar_num(cAllTalk));
		
		return PLUGIN_HANDLED;
	}
	
	new Arg[5];
	read_argv(1, Arg, charsmax(Arg));
	// server_cmd("sv_alltalk %s", Arg);
	set_pcvar_num(cAllTalk, str_to_num(Arg));
	
	new AdminName[35], AdminAuth[35];
	get_user_name(id, AdminName, charsmax(AdminName));
	get_user_authid(id, AdminAuth, charsmax(AdminAuth));
	
	console_print(id, "%L", id, "AMX_SUPER_ALLTALK_MSG", Arg);
	
	new Num = str_to_num(Arg);
	
	show_activity_key("AMX_SUPER_ALLTALK_SET_CASE1", "AMX_SUPER_ALLTALK_SET_CASE2", AdminName, Num);
	log_amx("%L", LANG_SERVER, "AMX_SUPER_ALLTALK_LOG", AdminName, AdminAuth, Num);
	
	return PLUGIN_HANDLED;
}


/*	2)	amx_extend
 *----------------
*/
new g_ExtendLimit;

public CmdExtend(id, level, cid)
{	
	if(!cmd_access(id, level, cid, 2))
		return PLUGIN_HANDLED;
	
	new Arg[35];
	read_argv(1, Arg, charsmax(Arg));
	
	new AdminName[35];
	get_user_name(id, AdminName, charsmax(AdminName));
	
	#if defined MAPCYCLE
	if(!cyclerfile)
	{
		client_print(id, print_chat, "%L", id, "AMX_SUPER_EXTEND_NOMAPCYCLE");
		
		return PLUGIN_HANDLED;
	}
	#endif
	
	if(strlen(Arg))
	{
		if(containi(Arg, "-") != -1)
		{
			client_print(id,print_chat,"%L", LANG_PLAYER, "AMX_SUPER_EXTEND_BAD_NUMBER");
			
			return PLUGIN_HANDLED;
		}
		
		new tlimit = str_to_num(Arg);
		
		if(g_ExtendLimit >= EXTENDMAX)
		{
			client_print(id,print_chat,"%L", LANG_PLAYER, "AMX_SUPER_EXTEND_EXTENDMAX",EXTENDMAX);
			
			return PLUGIN_HANDLED;
		}
		
		if(tlimit > EXTENDTIME)
		{
			client_print(id,print_chat,"%L", LANG_PLAYER, "AMX_SUPER_EXTEND_EXTENDTIME",EXTENDTIME);
			
			tlimit = EXTENDTIME;
		}
		
		set_pcvar_float(cTimeLimit, get_pcvar_float(cTimeLimit) + tlimit);
		
		show_activity_key("AMX_SUPER_EXTEND_SUCCESS_CASE1", "AMX_SUPER_EXTEND_SUCCESS_CASE2", AdminName, tlimit);
		
		++g_ExtendLimit;
	}
	
	return PLUGIN_HANDLED;
}	


/*	3)	amx_gag	/ amx_ungag
 *-------------
*/
enum
{
	NONE,
	CHAT,
	TEAM_CHAT,
	VOICE,
};


new g_GagFlags[33];
new g_Speak[33];
new g_GagReason[33][50];

public CmdGag(id, level, cid)
{
	if(!cmd_access(id, level, cid, 1))
		return PLUGIN_HANDLED;
	
	new szTarget[35], szFlags[5], szTime[10];
	read_argv(1, szTarget, charsmax(szTarget));
	read_argv(2, szFlags, charsmax(szFlags));
	read_argv(3, szTime, charsmax(szTime));
	
	new iPlayer = cmd_target(id, szTarget, CMDTARGET_OBEY_IMMUNITY | CMDTARGET_ALLOW_SELF | CMDTARGET_NO_BOTS);
	
	if(iPlayer)
	{
		// don't know if I should do this (suggestion ¿?)
		// added by juann
		if (g_GagFlags[iPlayer] != NONE)
		{
			// player was already gagged
			// AMX_SUPER_ALREADY_GAGGED = [AMXX] %s is already gagged & cannot be gagged again.
			return PLUGIN_HANDLED
		}
		
		new Float: flGagTime;
		
		if(!strlen(szFlags))
		{
			copy(szFlags, charsmax(szFlags), "abc");
			
			flGagTime = get_pcvar_float(cDefaultGagTime);
		}
		
		else if(isdigit(szFlags[0])
		&& !strlen(szTime)) // he forgot the flags
		{
			flGagTime = str_to_float(szFlags) * 60;
			
			copy(szFlags, charsmax(szFlags), "abc");
		}
		
		else if(strlen(szFlags) 
		&& strlen(szTime) 
		&& isdigit(szTime[0])) {	// he entered all the args.
			flGagTime = floatstr(szTime) * 60;
		}
		
		new bool: bReasonFound;
		if(read_argc() == 4)
		{
			read_argv(4, g_GagReason[iPlayer], 49);
			
			if(!strlen(g_GagReason[iPlayer]))
				bReasonFound = false;
			
			else
				bReasonFound = true;
		}
		
		g_GagFlags[iPlayer] = read_flags(szFlags);
		
		if(g_GagFlags[iPlayer] & VOICE)
			g_Speak[iPlayer] = SPEAK_MUTED;
		
		set_task(flGagTime, "TaskUngagPlayer", iPlayer + TASK_GAG);
		
		new szShownFlags[50], FlagCount;
		if(g_GagFlags[iPlayer] & CHAT)
		{
			copy(szShownFlags, charsmax(szShownFlags), "say");
			
			FlagCount++;
		}
		
		if(g_GagFlags[iPlayer] & TEAM_CHAT)
		{
			if(FlagCount)
				add(szShownFlags, charsmax(szShownFlags), " / say_team");
			
			else
				copy(szShownFlags, charsmax(szShownFlags), "say_team");
		}
		
		if(g_GagFlags[iPlayer] & VOICE)
		{	
			if(FlagCount)
				add(szShownFlags, charsmax(szShownFlags), " / voicecomm");
			
			else
				copy(szShownFlags, charsmax(szShownFlags), "voicecomm");
		}
		
		new AdminName[35], AdminAuth[35];
		get_user_name(id, AdminName, charsmax(AdminName));
		get_user_authid(id, AdminAuth, charsmax(AdminAuth));
		
		new PlayerName[35], PlayerAuth[35];
		get_user_name(iPlayer, PlayerName, charsmax(PlayerName));
		get_user_authid(iPlayer, PlayerAuth, charsmax(PlayerAuth));
		
		if(bReasonFound)
			show_activity_key("AMX_SUPER_GAG_PLAYER_REASON_CASE1", "AMX_SUPER_GAG_PLAYER_REASON_CASE2", AdminName, PlayerName, g_GagReason[iPlayer], szShownFlags);
		
		else
			show_activity_key("AMX_SUPER_GAG_PLAYER_CASE1", "AMX_SUPER_GAG_PLAYER_CASE2", AdminName, PlayerName, szShownFlags);	
	}
	
	return PLUGIN_HANDLED;
}

public client_infochanged(id)
{
	if(g_GagFlags[id] != NONE
	&& get_pcvar_num(cBlockNameChange))
	{
		new OldName[35], NewName[35];
		get_user_name(id, OldName, charsmax(OldName));
		get_user_info(id, "name", NewName, charsmax(NewName));
		
		if(!equal(OldName, NewName))
		{
			set_user_info(id, "name", OldName);
			
			client_print(id, print_chat, "%L", id, "AMX_SUPER_PLAYER_NAMELOCK");
		}
	}
}

public CmdSay(id)
{
	if(g_GagFlags[id] == NONE)
		return PLUGIN_CONTINUE;
		
	new Cmd[5];
	read_argv(0, Cmd, charsmax(Cmd));
	
	if(((g_GagFlags[id] & TEAM_CHAT) && Cmd[3] == '_') || ((g_GagFlags[id] & CHAT) && Cmd[3] != '_'))
	{
		if(g_GagReason[id][0])
			client_print(id, print_chat, "%L", id, "AMX_SUPER_GAG_REASON", g_GagReason[id]);
		
		else
			client_print(id, print_chat, "%L", id, "AMX_SUPER_PLAYER_GAGGED");
		
		if(get_pcvar_num(cGagSound))
			client_cmd(id, "spk ^"barney/youtalkmuch^"");
		
		return PLUGIN_HANDLED;
	}
	
	return PLUGIN_CONTINUE;
}

public CmdUngag(id, level, cid)
{
	if(!cmd_access(id, level, cid, 1))	
		return PLUGIN_HANDLED;
		
	new Target[35];
	read_argv(1, Target, charsmax(Target));
	
	new iPlayer = cmd_target(id, Target, CMDTARGET_OBEY_IMMUNITY | CMDTARGET_ALLOW_SELF | CMDTARGET_NO_BOTS);
	
	if(iPlayer)
	{
		new PlayerName[35];
		
		if(g_GagFlags[iPlayer] == NONE)
		{
			console_print(id, "%L", id, "AMX_SUPER_NOT_GAGGED", PlayerName);
			
			return PLUGIN_HANDLED;
		}
		
		UngagPlayer(iPlayer);
		
		new AdminName[35];
		get_user_name(id, AdminName, charsmax(AdminName));
		
		new AdminAuth[35], PlayerAuth[35];
		get_user_authid(id, AdminName, charsmax(AdminName));
		get_user_authid(iPlayer, PlayerAuth, charsmax(PlayerAuth));
		
		show_activity_key("AMX_SUPER_UNGAG_PLAYER_CASE1", "AMX_SUPER_UNGAG_PLAYER_CASE2", AdminName, PlayerName);
		log_amx("%L", LANG_SERVER, "AMX_SUPER_UNGAG_PLAYER_LOG", AdminName, AdminAuth, PlayerName, PlayerAuth);
	}
	
	return PLUGIN_HANDLED;
}

public TaskUngagPlayer(id)
{
	id -= TASK_GAG;
	
	if(!is_user_connected(id))
		return PLUGIN_HANDLED;
		
	UngagPlayer(id);
	
	new Name[35];
	get_user_name(id, Name, charsmax(Name));
	
	client_print(0, print_chat, "%L", LANG_PLAYER, "AMX_SUPER_GAG_END", Name);

	return PLUGIN_HANDLED;
}

UngagPlayer(id)
{
	if(g_GagFlags[id] & VOICE)
	{
		if(get_pcvar_num(cAllTalk))
			g_Speak[id] = SPEAK_ALL;
		
		else
			g_Speak[id] = SPEAK_NORMAL;
	}
	
	if(task_exists(id + TASK_GAG))
		remove_task(id + TASK_GAG);
		
	g_GagFlags[id] = NONE;
}

/* 4)	amx_pass
 *--------------
*/
public CmdPass(id, level, cid)
{
	if(!cmd_access(id, level, cid, 2))
		return PLUGIN_HANDLED
		
	new password[64]
	
	read_argv(1, password, 63)
	
	new authid[34]
	get_user_authid(id, authid, 33)
	
	new name[32]
	get_user_name(id, name, 31)
	
	show_activity_key("AMX_SUPER_PASSWORD_SET_CASE1", "AMX_SUPER_PASSWORD_SET_CASE2", name)
	
	log_amx("%L", LANG_SERVER, "AMX_SUPER_PASSWORD_SET_LOG",name, authid, password)
	
	set_pcvar_string(sv_password, password)
	
	return PLUGIN_HANDLED
}

/* 5)	amx_nopass
 *----------------
*/
public CmdNoPass(id, level, cid)
{
	if(!cmd_access(id, level, cid, 1))
		return PLUGIN_HANDLED
	
	new authid[34]
	get_user_authid(id, authid, 33)
	
	new name[32]
	get_user_name(id, name, 31)
	
	show_activity_key("AMX_SUPER_PASSWORD_SET_CASE1", "AMX_SUPER_PASSWORD_SET_CASE2", name)
	
	log_amx("%L", LANG_SERVER, "AMX_SUPER_PASSWORD_SET_LOG",name, authid)
	
	set_pcvar_string(sv_password, "")
	
	return PLUGIN_HANDLED
}

/* 6)	admin voicecomm
 *---------------------
*/
public Cmd_PlusAdminVoice(id)
{
	if(!CheckPlayerBit(admin, id))
	{
		client_print(id, print_chat, "%L", id, "AMX_SUPER_VOCOM_NO_ACCESS");
		
		return PLUGIN_HANDLED;
	}

	client_cmd(id, "+voicerecord");
	g_PlayerSpk[id] = SPEAK_ADMIN;

	new AdminName[35];
	get_user_name(id, AdminName, charsmax(AdminName));

	new players[32], pnum, tempid;
	get_players(players, pnum, "ch");
 
	for(new i = 0; i < pnum; i++)
	{
		tempid = players[i];
		
		if(CheckPlayerBit(admin, tempid))
		{
			if(tempid != id)
				client_print(tempid, print_chat, "%L", tempid, "AMX_SUPER_VOCOM_SPEAKING1", AdminName);
		}	
	}
	
	client_print(id, print_chat, "%L", id, "AMX_SUPER_VOCOM_SPEAKING2", AdminName);
	
	return PLUGIN_HANDLED;
}

public Cmd_MinAdminVoice(id) 
{
	if(is_user_connected(id)) 
	{ 
		client_cmd(id,"-voicerecord");
		
		if(g_PlayerSpk[id] == SPEAK_ADMIN) 
			g_PlayerSpk[id] = SPEAK_NORMAL2;
	}
	
	return PLUGIN_HANDLED;
}
/* wow unnecessary
public Fwd_Voice_SetClientListening(receiver, sender, listen) 
{
	
	
	return FMRES_IGNORED;
}
*/
public Event_VoiceMask(id)
	g_voicemask[id] = read_data(2);
	
// Shared with amx gag.
public Fwd_SetClientListening(Reciever, Sender, listen)
{	
	if(Reciever == Sender)
		return FMRES_IGNORED;
		
	if(g_PlayerSpk[Sender] == SPEAK_ADMIN) 
	{
		if(CheckPlayerBit(admin, Reciever))
			engfunc(EngFunc_SetClientListening, Reciever, Sender, SPEAK_NORMAL2);
			
		else
			engfunc(EngFunc_SetClientListening, Reciever, Sender, SPEAK_MUTED2);

		return FMRES_SUPERCEDE;
	}
	
	else if(g_voicemask[Reciever] & 1 << (Sender - 1)) 
	{
		engfunc(EngFunc_SetClientListening, Reciever, Sender, SPEAK_MUTED);
		
		forward_return(FMV_CELL, false);
	}
	
	switch(g_Speak[Sender])
	{	
		case SPEAK_MUTED:
		{
			engfunc(EngFunc_SetClientListening, Reciever, Sender, 0);
			
			forward_return(FMV_CELL, 0);
			
			return FMRES_SUPERCEDE;
		}
		
		case SPEAK_ALL, SPEAK_LISTENALL:
		{
			engfunc(EngFunc_SetClientListening, Reciever, Sender, 1);
			
			forward_return(FMV_CELL, 1);
			
			return FMRES_SUPERCEDE;
		}
		
		default: return FMRES_IGNORED;
	}
	
	return FMRES_IGNORED;
}
	
/* 7)	amx_transfer
 *------------------
*/
public Cmd_Transfer(id, level, cid)
{
	if(!cmd_access(id, level, cid, 3))
		return PLUGIN_HANDLED;
	
	new target[35], team[5];
	read_argv(1, target, charsmax(target));
	read_argv(2, team, charsmax(team));
	strtoupper(team);
	
	new tempid = cmd_target(id, target, 2);
	new teamname[35];
	
	if(!tempid)
		return PLUGIN_HANDLED;
	
	// added
	new CsTeams:pTeam = cs_get_user_team(tempid)
	
	if(!strlen(team))
	{	
		cs_set_user_team(tempid, /*cs_get_user_team(tempid)*/ pTeam == CS_TEAM_T ? CS_TEAM_CT : CS_TEAM_T);
		formatex(teamname, charsmax(teamname), "%s", /*replaced with*/ Teamnames[_:pTeam - 1] /*cs_get_user_team(tempid) == CS_TEAM_CT ? "Counter-Terrorists" : "Terrorists"*/);
	}
	else
	{
		// added by juann (check if player it's already on team)
		// don't know if this is the right way to do this,
		new CsTeams:cTeam
		
		if (team[0] == 'C')
			cTeam = CS_TEAM_CT
		else if (team[0] == 'T')
			cTeam = CS_TEAM_T
		else if (team[0] == 'S')
			cTeam = CS_TEAM_SPECTATOR
		else
		{
			// default case moved here
			client_print(id, print_console, "%L", LANG_PLAYER, "AMX_SUPER_TEAM_INVALID");
			return PLUGIN_HANDLED;
		}
		
		if (cTeam == pTeam)
		{
			// AMX_SUPER_TRANSFER_PLAYER_ALREADY = [AMXX] This player already belongs to that team!
			return PLUGIN_HANDLED
		}
		else
		{
			// added -juann-
			if (cTeam == CS_TEAM_SPECTATOR)
				user_silentkill(tempid)
				
			cs_set_user_team(tempid, cTeam)
			
			if (cTeam != CS_TEAM_SPECTATOR)
				ExecuteHamB(Ham_CS_RoundRespawn, tempid)

			// using teamnames variable if team != spec
			formatex(teamname, charsmax(teamname)-1, "%s", cTeam == CS_TEAM_SPECTATOR ? "Spectator" : Teamnames[_:cTeam - 1])
			
			/*switch(team[0])
			{
				case 'T':
				{
					cs_set_user_team(tempid, CS_TEAM_T);
					ExecuteHamB(Ham_CS_RoundRespawn, tempid);
					
					formatex(teamname, charsmax(teamname), "Terrorists");
				}
				
				case 'C':
				{
					cs_set_user_team(tempid, CS_TEAM_CT);
					ExecuteHamB(Ham_CS_RoundRespawn, tempid);
					
					formatex(teamname, charsmax(teamname), "Counter-Terrorists");
				}
				
				case 'S':
				{
					user_silentkill(tempid);
					cs_set_user_team(tempid, CS_TEAM_SPECTATOR);
					
					formatex(teamname, charsmax(teamname), "Spectator");
				}
				
				default:
				{
					client_print(id, print_console, "%L", LANG_PLAYER, "AMX_SUPER_TEAM_INVALID");
					return PLUGIN_HANDLED;
				}
			}*/
		}
	}
	
	new idname[35], tempidname[35];
	get_user_name(id, idname, charsmax(idname));
	get_user_name(tempid, tempidname, charsmax(tempidname));
	
	new authid[35];
	get_user_authid(id, authid, charsmax(authid));
	
	show_activity_key("AMX_SUPER_TRANSFER_PLAYER_CASE1", "AMX_SUPER_TRANSFER_PLAYER_CASE2", idname, tempidname, teamname);

	client_print(tempid, print_chat, "%L", LANG_PLAYER, "AMX_SUPER_TRANSFER_PLAYER_TEAM", teamname);

	console_print(id, "%L", LANG_PLAYER, "AMX_SUPER_TRANSFER_PLAYER_CONSOLE", idname, teamname);
	log_amx("%L", LANG_SERVER, "AMX_SUPER_TRANSFER_PLAYER_LOG", idname, authid, tempidname, teamname);
	
	return PLUGIN_HANDLED;
}
	
/* 8)	amx_swap
 *--------------
*/
public Cmd_Swap(id, level, cid)
{
	if(!cmd_access(id, level, cid, 3))
		return PLUGIN_HANDLED;
		
	new target1[35], target2[35];
	read_argv(1, target1, charsmax(target1));
	read_argv(2, target2, charsmax(target2));
	
	new tempid1 = cmd_target(id, target1, 2);
	new tempid2 = cmd_target(id, target2, 2);
	
	if(!tempid1 || !tempid2)
		return PLUGIN_HANDLED;
		
	new CsTeams: team1 = cs_get_user_team(tempid1);
	new CsTeams: team2 = cs_get_user_team(tempid2);
	
	if(team1 == team2)
	{
		client_print(id, print_console, "%L", LANG_PLAYER, "AMX_SUPER_TRANSFER_PLAYER_ERROR_CASE1");
		
		return PLUGIN_HANDLED;
	}
	
	if(team1 == CS_TEAM_UNASSIGNED || team2 == CS_TEAM_UNASSIGNED)
	{
		client_print(id, print_console, "%L", LANG_PLAYER, "AMX_SUPER_TRANSFER_PLAYER_ERROR_CASE2");
		
		return PLUGIN_HANDLED;
	}
	
	cs_set_user_team(tempid1, team2);
	ExecuteHamB(Ham_CS_RoundRespawn, tempid1);
	
	cs_set_user_team(tempid2, team1);
	ExecuteHamB(Ham_CS_RoundRespawn, tempid2);
	
	if(team1 == CS_TEAM_SPECTATOR)
		user_silentkill(tempid2);
	
	if(team2 == CS_TEAM_SPECTATOR)
		user_silentkill(tempid1);
	
	new name1[35], name2[35], idname[35], authid[35];
	get_user_name(tempid1, name1, charsmax(name1));
	get_user_name(tempid2, name2, charsmax(name2));
	get_user_name(id, idname, charsmax(idname));
	get_user_authid(id, authid, charsmax(authid));
	
	show_activity_key("AMX_SUPER_TRANSFER_SWAP_PLAYERS_SUCCESS_CASE1", "AMX_SUPER_TRANSFER_SWAP_PLAYERS_SUCCESS_CASE2", idname, name1, name2);

	client_print(tempid1, print_chat, "%L", LANG_PLAYER, "AMX_SUPER_TRANSFER_SWAP_PLAYERS_MESSAGE1", name2);
	client_print(tempid2, print_chat, "%L", LANG_PLAYER, "AMX_SUPER_TRANSFER_SWAP_PLAYERS_MESSAGE2", name1);

	client_print(id, print_console, "%L", LANG_PLAYER, "AMX_SUPER_TRANSFER_SWAP_PLAYERS_CONSOLE", name1, name2);
	
	log_amx("%L", LANG_PLAYER, "AMX_SUPER_TRANSFER_SWAP_PLAYERS_LOG", idname, authid, name1, name2);
	
	return PLUGIN_HANDLED;
}

/* 9)	amx_teamswap
 *------------------
*/
public Cmd_TeamSwap(id, level, cid)
{
	if(!cmd_access(id, level, cid, 1))
		return PLUGIN_HANDLED;
		
	new players[32], pnum, tempid;
	get_players(players, pnum);
	
	for(new i = 0; i < pnum; i++)
	{
		tempid = players[i];
		
		cs_set_user_team(tempid, cs_get_user_team(tempid) == CS_TEAM_T ? CS_TEAM_CT : CS_TEAM_T);
		ExecuteHamB(Ham_CS_RoundRespawn, tempid);
	}
	
	new name[35], authid[35];
	get_user_name(id, name, charsmax(name));
	get_user_authid(id, authid, charsmax(authid));

	show_activity_key("AMX_SUPER_TRANSFER_SWAP_TEAM_SUCCESS_CASE1", "AMX_SUPER_TRANSFER_SWAP_TEAM_SUCCESS_CASE2", name);

	console_print(id,"%L", LANG_PLAYER, "AMX_SUPER_TRANSFER_SWAP_TEAM_MESSAGE");
	
	log_amx("%L", LANG_SERVER, "AMX_SUPER_TRANSFER_SWAP_TEAM_LOG", name,authid);
	
	return PLUGIN_HANDLED;
}

/* 10)	amx_lock
 *--------------
*/
public Cmd_Lock(id, level, cid)
{
	if(!cmd_access(id, level, cid, 2))
		return PLUGIN_HANDLED;
	
	new arg[7];
	read_argv(1, arg, charsmax(arg));
	strtoupper(arg);
	
	new team;
	
	// comments set by juann, since we use strtoupper we don't need to check for lower case chars
	switch(arg[0])
	{
		case 'T'/*, 't'*/: 
			team = TERRO;
		
		case 'C'/*, 'c'*/:
			team = COUNTER;
			
		case 'A'/*, 'a'*/: 
			team = AUTO;
		
		case 'S'/*, 's'*/:
			team = SPEC;
		
		default:
		{	
			client_print(id, print_console, "%L", LANG_PLAYER, "AMX_SUPER_TEAM_INVALID");
			
			return PLUGIN_HANDLED;
		}	
	}
	
	g_BlockJoin[team] = true;
	
	new name[35], authid[35];
	get_user_name(id, name, charsmax(name));
	get_user_authid(id, authid, charsmax(authid));
	
	show_activity_key("AMX_SUPER_TEAM_LOCK_CASE1", "AMX_SUPER_TEAM_LOCK_CASE2", name, Teamnames[team]);

	console_print(id, "%L", LANG_PLAYER, "AMX_SUPER_TEAM_LOCK_CONSOLE", Teamnames[team]);
	log_amx("%L", LANG_SERVER, "AMX_SUPER_LOCK_TEAMS_LOG", name, authid, Teamnames[team]);

	return PLUGIN_HANDLED;
}

/* 11)	amx_unlock
 *----------------
*/
public Cmd_Unlock(id, level, cid)
{
	if(!cmd_access(id, level, cid, 2))
		return PLUGIN_HANDLED;
	
	new arg[7];
	read_argv(1, arg, charsmax(arg));
	strtoupper(arg);
	
	new team;
	
	// comments set by juann, since we use strtoupper we don't need to check for lower case chars
	switch(arg[0])
	{
		case 'T'/*, 't'*/: 
			team = TERRO;
		
		case 'C'/*, 'c'*/:
			team = COUNTER;
			
		case 'A'/*, 'a'*/: 
			team = AUTO;
		
		case 'S'/*, 's'*/:
			team = SPEC;
		
		default:
		{	
			client_print(id, print_console, "%L", LANG_PLAYER, "AMX_SUPER_TEAM_INVALID");
			
			return PLUGIN_HANDLED;
		}	
	}
	
	g_BlockJoin[team] = false;
	
	new name[32], authid[35];
	get_user_name(id, name, charsmax(name));
	get_user_authid(id, authid, charsmax(authid));
	
	show_activity_key("AMX_SUPER_TEAM_UNLOCK_CASE1", "AMX_SUPER_TEAM_UNLOCK_CASE2", name, Teamnames[team]);
	
	console_print(id, "%L", LANG_PLAYER, "AMX_SUPER_TEAM_UNLOCK_CONSOLE", Teamnames[team]);
	log_amx("%L", LANG_SERVER, "AMX_SUPER_UNLOCK_TEAMS_LOG", name, authid, Teamnames[team]);

	return PLUGIN_HANDLED;
}

/* team locker
 *------------
*/
public team_select(id, key) 
{ 
	if(g_BlockJoin[key])
	{
		engclient_cmd(id, "chooseteam");
		
		return PLUGIN_HANDLED;
	} 		
	
	return PLUGIN_CONTINUE;
} 

public join_team(id) 
{		
	new arg[3];
	read_argv(1, arg, charsmax(arg));
	
	if(g_BlockJoin[str_to_num(arg) - 1])
	{
		engclient_cmd(id, "chooseteam");
		
		return PLUGIN_HANDLED;
	} 

	return PLUGIN_CONTINUE; 
}

/* 12)	amx_badaim
 *----------------
*/
public Event_DeathMsg()
{
	new killer = read_data(1);
	new victim = read_data(2);
	
	if(g_HasBadAim[killer] && g_AutoBan[killer] && killer != victim)
	{
		new userid = get_user_userid(killer);
		
		new name[35];
		get_user_name(killer, name, charsmax(name));
		
		if(get_pcvar_num(cBadAimBan))
			server_cmd("amx_ban #%i Got a kill with bad aim.", userid);
		
		client_print(0, print_chat, "%L", LANG_PLAYER, "AMX_SUPER_BADAIM_KILLED", name);
	}
}

public Cmd_BadAim(id, level, cid)
{
	if(!cmd_access(id, level, cid, 3))
		return PLUGIN_HANDLED;
		
	new target[35], Time[10], save[2];
	
	read_argv(1, target, charsmax(target));
	read_argv(2, Time, charsmax(Time));
	read_argv(3, save, charsmax(save));
	
	if(!strlen(Time))
	{
		console_print(id, "%L", LANG_PLAYER, "AMX_SUPER_BADAIM_CONSOLE");
		
		return PLUGIN_HANDLED;
	}
	
	new timenum = str_to_num(Time);

	if(timenum < 0)
	{
		console_print(id, "%L", LANG_PLAYER, "AMX_SUPER_BADAIM_BADTIME");
		
		return PLUGIN_HANDLED;
	}
	
	new tempid = cmd_target(id, target, 2);

		
	if(!tempid)
		return PLUGIN_HANDLED;
			
	new name[35];
	get_user_name(tempid, name, charsmax(name));
	
	switch(timenum)
	{
		case 0:
		{
			if(!g_HasBadAim[tempid])
			{
				console_print(id, "%L", LANG_PLAYER, "AMX_SUPER_BADAIM_NO_BADAIM", name);
				
				return PLUGIN_HANDLED;
			}
			
			g_HasBadAim[tempid] = false;
			
			console_print(id, "%L", LANG_PLAYER, "AMX_SUPER_BADAIM_UNDO",name);

			set_aimvault(tempid, 0);
		}
		
		case 1:
		{
			if(g_HasBadAim[tempid])
			{
				console_print(id, "%L", LANG_PLAYER, "AMX_SUPER_BADAIM_CURRENT", name);
				
				return PLUGIN_HANDLED;
			}
			
			if(get_pcvar_num(autobanall))
				g_AutoBan[tempid] = true;
				
			g_HasBadAim[tempid] = true;
			
			console_print(id, "%L", LANG_PLAYER, "AMX_SUPER_BADAIM_WORSE", name);
		}
		
		default: // Timed
		{
			if(g_HasBadAim[tempid])
				console_print(id, "%L", LANG_PLAYER, "AMX_SUPER_BADAIM_MESSAGE1",name, timenum);
				
			else
				console_print(id, "%L", LANG_PLAYER, "AMX_SUPER_BADAIM_MESSAGE2",name, timenum);
		
			if(get_pcvar_num(autobantimed))
				g_AutoBan[tempid] = true;
				
			g_HasBadAim[tempid] = true;
			
			new taskdata[3];
			taskdata[0] = id;
			taskdata[1] = tempid;
			
			set_task(float(timenum), "Task_UnBadAim", tempid + TASKID_UNBADAIM, taskdata, 2);
		}
	}
	
	new savenum = str_to_num(save);
	
	if(savenum)
	{
		if(timenum > 1)
			console_print(id, "%L", LANG_PLAYER, "AMX_SUPER_BADAIM_BAN");

		else
			set_aimvault(tempid, 1);
	}
	
	new aname[32], authid[32];
	get_user_name(id, aname, 31);
	get_user_authid(id, authid, 31);

	log_amx( "%L", LANG_PLAYER, "AMX_SUPER_BADAIM_LOG", aname, authid, g_HasBadAim[tempid] == true? "set" : "removed", name);
	
	return PLUGIN_HANDLED;
}

public Task_UnBadAim(data[])
{
	new id = data[0];
	new tempid = data[1];
	
	new name[35];
	get_user_name(tempid, name, charsmax(name));

	client_print(id, print_chat, "%L", LANG_PLAYER, "AMX_SUPER_BADAIM_NO_BADAIM_MESSAGE", name);
	
	console_print(id, "%L", LANG_PLAYER, "AMX_SUPER_BADAIM_NO_BADAIM_MESSAGE_CONSOLE", name);

	g_HasBadAim[tempid] = false;
	g_AutoBan[tempid] = false;
}

public set_aimvault(id, value)
{
	new authid[35];
	get_user_authid(id, authid, charsmax(authid));
	
	new vaultkey[51];
	formatex(vaultkey, charsmax(vaultkey), "BADAIM_%s", authid);

	if(vaultdata_exists(vaultkey))
		remove_vaultdata(vaultkey);
	
	if(value == 1)
		set_vaultdata(vaultkey, "1");
}

public check_aimvault(id)
{
	new authid[35];
	get_user_authid(id, authid, charsmax(authid));
	
	new vaultkey[51];
	format(vaultkey,50,"BADAIM_%s",authid);

	if(vaultdata_exists(vaultkey))
	{	
		if(get_pcvar_num(autobanall))
			g_AutoBan[id] = true;
			
		g_HasBadAim[id] = true;
	}			
}

public FwdPlayerPrethink(id)
{
	if(g_HasBadAim[id])
	{
		static Float: BadAimVec[3] = {100.0, 100.0, 100.0};
		
		// entity_set_vector(id, EV_VEC_punchangle, BadAimVec);
		// entity_set_vector(id, EV_VEC_punchangle, BadAimVec);
		// entity_set_vector(id, EV_VEC_punchangle, BadAimVec);
		set_pev(id, pev_punchangle, BadAimVec);
	}
}

/* 13)	amx_quit
 *--------------
*/
public CmdQuit(id, level, cid)
{
	if(!cmd_access(id, level, cid, 2))
		return PLUGIN_HANDLED;
		
	new Arg[35];
	read_argv(1, Arg, charsmax(Arg));
	
	new AdminName[35], AdminAuth[35];
	get_user_name(id, AdminName, charsmax(AdminName));
	get_user_authid(id, AdminAuth, charsmax(AdminAuth));
	
	new iPlayer, TargetName[35];
	
	
	if(Arg[0] == '@')
	{
		new players[32], pnum, CmdTeam: Team;
		
		switch(Arg[1])
		{
			case 'c', 'C':
			{
				get_players(players, pnum, "e", "CT");
				
				Team = CT;
			}
			
			case 't', 'T':
			{
				get_players(players, pnum, "e", "TERRORIST");
				
				Team = T;
			}
			
			case 'a', 'A':
			{
				get_players(players, pnum);
			
				Team = ALL;
			}
		}
		
		if(!pnum)
		{
			console_print(id, "%L", id, "AMX_SUPER_NO_PLAYERS");
			
			return PLUGIN_HANDLED;
		}
		
		for(new i = 0; i < pnum; i++)
		{
			iPlayer = players[i];
			
			if(get_user_flags(iPlayer) & ADMIN_IMMUNITY && iPlayer != id)
			{
				get_user_name(iPlayer, TargetName, charsmax(TargetName));
				console_print(id, "%L", id, "AMX_SUPER_TEAM_IMMUNITY", TargetName);
				
				continue;
			}
			
			client_cmd(0, "spk ^"ambience/thunder_clap.wav^"");
			// client_cmd(iPlayer, "quit");
			console_print(iPlayer, "You quited");
		}
		
		show_activity_key("AMX_SUPER_QUIT_TEAM_CASE1", "AMX_SUPER_QUIT_TEAM_CASE2", AdminName, g_TeamNames[Team]);
		log_amx("%L", LANG_SERVER, "AMX_SUPER_QUIT_TEAM_LOG", AdminName, AdminAuth, g_TeamNames[Team]);
	}
	
	else
	{
		iPlayer = cmd_target(id, Arg, CMDTARGET_OBEY_IMMUNITY | CMDTARGET_ALLOW_SELF | CMDTARGET_NO_BOTS);
		
		if(iPlayer)
		{
			new PlayerAuth[35];
			get_user_name(iPlayer, TargetName, charsmax(TargetName));
			get_user_authid(iPlayer, PlayerAuth, charsmax(PlayerAuth));
			
			client_cmd(0, "spk ^"ambience/thunder_clap.wav^"");
			// client_cmd(iPlayer, "quit");
			console_print(iPlayer, "You quited");
			
			show_activity_key("AMX_SUPER_QUIT_PLAYER_CASE1", "AMX_SUPER_QUIT_PLAYER_CASE2", AdminName, TargetName);
			log_amx("%L", LANG_SERVER, "AMX_SUPER_QUIT_PLAYER_LOG", AdminName, AdminAuth, TargetName, PlayerAuth);
		}
	}
	
	return PLUGIN_HANDLED;
}

/* 14)	amx_exec
 *--------------
*/
public CmdExec(id, level, cid)
{
	if(!cmd_access(id, level, cid, 3))
		return PLUGIN_HANDLED;

	new Target[35], TargetName[35], Command[64];
	read_argv(1, Target, charsmax(Target));
	read_argv(2, Command, charsmax(Command));
	
	new AdminName[35], AdminAuth[35];
	get_user_name(id, AdminName, charsmax(AdminName));
	get_user_authid(id, AdminAuth, charsmax(AdminAuth));
	
	new iPlayer;
	
	if(Target[0] == '@')
	{
		new players[32], pnum, CmdTeam: Team;
		
		switch(Target[1])
		{
			case 'T', 't':
			{
				get_players(players, pnum, "e", "TERRORIST");
				
				Team = T;
			}
			
			case 'C', 'c':
			{
				get_players(players, pnum, "e", "CT");
				
				Team = CT;
			}
			
			case 'A', 'a':
			{
				get_players(players, pnum);
				
				Team = ALL;
			}
		}
		
		if(!pnum)
		{
			console_print(id, "%L", id, "AMX_SUPER_NO_PLAYERS");
			
			return PLUGIN_HANDLED;
		}
		
		for(new i = 0; i < pnum; i++)
		{
			iPlayer = players[i];
			
			if((get_user_flags(iPlayer) & ADMIN_IMMUNITY) && iPlayer != id)
			{
				get_user_name(iPlayer, TargetName, charsmax(TargetName));
				console_print(id, "%L", id, "AMX_SUPER_TEAM_IMMUNITY", TargetName);
				
				continue;
			}
			
			client_cmd(iPlayer, Command);
		}
		
		show_activity_key("AMX_SUPER_EXEC_TEAM_CASE1", "AMX_SUPER_EXEC_TEAM_CASE2", AdminName, Command, g_TeamNames[Team]);
		log_amx("%L", LANG_SERVER, "AMX_SUPER_EXEC_TEAM_LOG", AdminName, AdminAuth, Command, g_TeamNames[Team]);
	}
	
	else
	{
		iPlayer = cmd_target(id, Target, CMDTARGET_OBEY_IMMUNITY | CMDTARGET_ALLOW_SELF);
		
		if(iPlayer)
		{
			new TargetAuth[35];
			get_user_name(iPlayer, TargetName, charsmax(TargetName));
			get_user_authid(iPlayer, TargetAuth, charsmax(TargetAuth));
			
			client_cmd(iPlayer, Command);
			
			show_activity_key("AMX_SUPER_EXEC_PLAYER_CASE1", "AMX_SUPER_EXEC_PLAYER_CASE2", AdminName, Command, TargetName);
			log_amx("%L", LANG_SERVER, "AMX_SUPER_EXEC_PLAYER_LOG", AdminName, AdminAuth, Command, TargetName, TargetAuth);
		}
	}
	
	return PLUGIN_HANDLED;
}

/* 15)	amx_restart / shutdown
 *----------------------------
*/
public CmdRestart(id, level, cid)
{
	if(!cmd_access(id, level, cid, 2) || g_ShuttingDown)	
		return PLUGIN_HANDLED;
	
	new Cmd[14];
	read_argv(0, Cmd, charsmax(Cmd));
	
	console_print(id, Cmd);
	if(equali(Cmd, "amx_restart"))
		g_ShutDownMode = RESTART;
	
	else
		g_ShutDownMode = SHUTDOWN;
		
	new szTime[4];
	read_argv(1, szTime, charsmax(szTime));
	
	new iTime = str_to_num(szTime);
	
	if(!(1 <= iTime <= 20))
	{
		console_print(id, "%L", id, "AMX_SUPER_SHUTDOWN_CONSOLE");
		
		return PLUGIN_HANDLED;
	}
	
	StartShutDown(iTime);
	
	new AdminName[35], AdminAuth[35];
	get_user_name(id, AdminName, charsmax(AdminName));
	get_user_authid(id, AdminAuth, charsmax(AdminAuth));
	
	show_activity_key("AMX_SUPER_SHUTDOWN_CASE1", "AMX_SUPER_SHUTDOWN_CASE2", AdminName, g_ShutDownNames[g_ShutDownMode], iTime);
	log_amx("%L", LANG_SERVER, "AMX_SUPER_SHUTDOWN_MESSAGE_LOG", AdminName, id, AdminAuth, g_ShutDownNames[g_ShutDownMode]);
	
	return PLUGIN_HANDLED;
}

StartShutDown(iTime)
{
	g_ShuttingDown = true;
	
	new iCount;
	for(iCount = iTime; iCount != 0; iCount--)
		set_task(float(abs(iCount - iTime)), "TaskShutDown", iCount);
	
	set_task(float(iTime), "TaskShutDown");
}

public TaskShutDown(Number)
{
	if(!Number)
	{
		if(g_ShutDownMode == RESTART)
			server_cmd("restart");
		
		else
			server_cmd("quit");
	}
	
	new szNum[32];
	num_to_word(Number, szNum, charsmax(szNum));
	
	client_cmd(0, "spk ^"fvox/%s^"", szNum);
}

/* 16)	say /gravity
 *------------------
*/
public CmdGravity(id)
{
	client_print(id, print_chat, "%L", id, "AMX_SUPER_GRAVITY_CHECK", get_pcvar_num(cGravity));
	
	return PLUGIN_HANDLED;
}

/* 17)	say /alltalk
 *------------------
*/
public CmdAlltalk(id)
{
	client_print(id, print_chat, "%L", id, "AMX_SUPER_ALLTALK_CHECK", get_pcvar_num(cAllTalk));
	
	return PLUGIN_HANDLED;
}

/* 18)	say /spec
 *---------------
*/
public CmdSpec(id)
{
	new CsTeams: Team = cs_get_user_team(id);
	
	if((CS_TEAM_UNASSIGNED <= Team <= CS_TEAM_SPECTATOR) 
	&& get_pcvar_num(cAllowSpec) 
	|| get_pcvar_num(cAllowPublicSpec)) 
	{
		if(is_user_alive(id))
		{
			user_kill(id);
			
			cs_set_user_deaths( id, cs_get_user_deaths(id) - 1);
			set_user_frags( id, get_user_frags(id) + 1);
		}
		
		g_OldTeam[id] = Team;
		
		cs_set_user_team(id, CS_TEAM_SPECTATOR);
	}

	return PLUGIN_HANDLED;
}

/* 19)	say /unspec
 *-----------------
*/
public CmdUnSpec(id)
{
	if(g_OldTeam[id])
	{
		cs_set_user_team(id, g_OldTeam[id]);
		g_OldTeam[id] = CS_TEAM_UNASSIGNED;
	}
	
	return PLUGIN_HANDLED;
}

/* 20)	say /admin(s)
 *-------------------
*/
public CmdAdmins(id) 
{
	new message[256];
	
	if(get_pcvar_num(cAdminCheck))
	{
		new adminnames[33][32];
		new contactinfo[256], contact[112];
		new i, count, x, len;
		
		for(i = 1 ;i <= g_MaxPlayers; i++)
		{
			if(is_user_connected(i) && (get_user_flags(i) & ADMIN_CHECK))
				get_user_name(i, adminnames[count++], 31);
		}
		
		len = format(message, 255, "%s ADMINS ONLINE: ",COLOR);
		
		if(count > 0) 
		{
			for(x = 0 ; x < count ; x++) 
			{
				len += format(message[len], 255-len, "%s%s ", adminnames[x], x < (count-1) ? ", ":"");
				
				if(len > 96 ) 
				{
					print_message(id, message);
					len = format(message, 255, "%s ",COLOR);
				}
			}
			
			print_message(id, message);
		}
		
		else 
		{
			len += format(message[len], 255-len, "No admins online.");
			print_message(id, message);
		}
		
		get_pcvar_string(cSvContact, contact, 63);
		
		if(contact[0])  
		{
			format(contactinfo, 111, "%s Contact Server Admin -- %s", COLOR, contact);
			print_message(id, contactinfo);
		}
	}
	else
	{
		formatex(message, 255, "^x04 Admin Check is currently DISABLED.");
		print_message(id, message);
	}
}

print_message(id, msg[]) 
{
	message_begin(MSG_ONE, g_MsgSayText, {0,0,0}, id)
	write_byte(id)
	write_string(msg)
	message_end()
}

/* 21)	say /fixsound
 *-------------------
*/
public CmdFixSound(id)
{
	if(get_pcvar_num(cAllowSoundFix))
	{
		client_cmd(id, "stopsound; room_type 00");
		client_cmd(id, "stopsound");
		
		client_print(id, print_chat, "%L", id, "AMX_SUPER_SOUNDFIX");
	}
	
	else
		client_print(id, print_chat, "%L", id, "AMX_SUPER_SOUNDFIX_DISABLED");
	
	return PLUGIN_HANDLED;
} 
/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ deff0{\\ fonttbl{\\ f0\\ fnil Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ lang3082\\ f0\\ fs16 \n\\ par }
*/
