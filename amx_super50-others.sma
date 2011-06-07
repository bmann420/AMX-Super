/*
* -) DEAD CHAT 
* -) LOADING SOUNDS 
* -) SPECTATOR BUG FIX 
* -) "SHOWNDEAD" SCOREBOARD FIX 
* -) AFK BOMB TRANSFER 
* -) C4 TIMER 
* -) STATS MARQUEE REMOVE
* -) SPAWN PROTECTION 
* -) AFK Manager
*/

#include <amxmodx>
#include <amxmisc>
#include <hamsandwich>
#include <csx>

#define DAMAGE_RECEIVED

new cEnterMsg
	, cLeaveMsg
	, cEnterMsgEnable
	, cLeaveMsgEnable
	, cHostname
	, cDamage
	, cLoadingSounds
;

// damage done
new g_iSyncHud;

#if defined DAMAGE_RECEIVED
new g_iSyncHud2;
#endif


// Loading Sounds
new soundlist[][] = 
{
	"Half-Life01",
	"Half-Life02",
	"Half-Life03",
	"Half-Life04",
	"Half-Life06",
	"Half-Life08",
	"Half-Life10",
	"Half-Life11",
	"Half-Life12",
	"Half-Life13",
	"Half-Life14",
	"Half-Life15",
	"Half-Life16",
	"Half-Life17"
}

// Misc
new g_MaxPlayers;

public plugin_init()
{
	cLeaveMsgEnable		= register_cvar("amx_leavemessage_enable", "1");
	cEnterMsgEnable 	= register_cvar("amx_join_leave", "1");
	cEnterMsg 			= register_cvar("amx_enter_message", "%name% has joined!\nEnjoy the Server!\nCurrent Ranking is %rankpos%");
	cLeaveMsg 			= register_cvar("amx_leave_message", "%name% has left!\nHope to see you back sometime."); 
	cDamage				= register_cvar("bullet_damage", "1");
	
	cHostname			= get_cvar_pointer("hostname");
	
	// Damage done
	//RegisterHam(Ham_TakeDamage, "player", "FwdPlayerTakeDamagePost", 1);
	register_event("Damage", "on_damage", "b", "2!0", "3=0", "4!0")	
	
	g_iSyncHud = CreateHudSyncObj();
	
	#if defined DAMAGE_RECEIVED
	g_iSyncHud2 = CreateHudSyncObj();
	#endif
	
	// Misc
	g_MaxPlayers = get_maxplayers();
}


/* Enter / Leave messages
 *-----------------------
*/
public client_putinserver(id)
{
	if(get_pcvar_num(cEnterMsgEnable))
		set_task(2.0, "TaskShowEnterMsg", id);
}

public client_disconnect(id)
{
	if(get_pcvar_num(cLeaveMsgEnable))
		set_task(2.0, "TaskShowLeaveMsg", id);
}

public TaskShowEnterMsg(id)
{	
	if(!is_user_connected(id) || is_user_bot(id))
		return PLUGIN_HANDLED;
	
	new szName[32]
		, szMessage[192]
		, szHostname[64]
	;
	
	get_pcvar_string(cEnterMsg, szMessage, charsmax(szMessage));
	get_pcvar_string(cHostname, szHostname, charsmax(szHostname));
	get_user_name(id, szName, charsmax(szName));
	
	if(contain(szMessage, "%rankpos%") != -1)
	{
		new Stats[8];
		new iRank = get_user_stats(id, Stats, Stats);
		
		num_to_str(iRank, Stats, charsmax(Stats));
		replace(szMessage, charsmax(szMessage), "%rankpos%", Stats);
	}

	replace(szMessage, charsmax(szMessage), "%name%", szName);
	
	replace_all(szMessage, charsmax(szMessage), "\n", "^n");
	
	if(get_user_flags(id) & ADMIN_RESERVATION)
	{
		set_hudmessage(255, 0, 0, 0.10, 0.55, 0, 6.0, 6.0, 0.5, 0.15);
		show_hudmessage(0, szMessage);
	}
	
	else
	{
		set_hudmessage(0, 255, 0, 0.10, 0.55, 0, 6.0, 6.0, 0.5, 0.15); 
		show_hudmessage(0, szMessage);
	}
	
	return PLUGIN_HANDLED;
}

public TaskShowLeaveMsg(id)
{
	if(!is_user_connected(id) || is_user_bot(id))
		return PLUGIN_HANDLED;
	
	new szMessage[192]
		, szName[32]
	;

	get_pcvar_string(cLeaveMsg, szMessage, charsmax(szMessage));
	get_user_name(id, szName, charsmax(szName));

	if(contain(szMessage, "%hostname%") != -1)
	{
		new szHostname[64];
		get_pcvar_string(cHostname, szHostname, charsmax(szHostname));
		
		replace(szMessage, charsmax(szMessage), "%hostname%", szHostname);
	}
	
	
	replace(szMessage, 191, "%name%", szName);
	replace_all(szMessage, 191, "\n", "^n");

	set_hudmessage(255, 0, 255, 0.10, 0.55, 0, 6.0, 6.0, 0.5, 0.15);
	show_hudmessage(0, szMessage);
	
	return PLUGIN_HANDLED;
}


/* Damage done
 *------------
*/
/*
public FwdPlayerTakeDamagePost(iVictim, iInflictor, iAttacker, Float: flDamage, iDmgBits)
{	
	if(!get_pcvar_num(cDamage))
		return HAM_IGNORED;
	
#if defined DAMAGE_RECEIVED
	set_hudmessage(255, 0, 0, 0.45, 0.50, 2, 0.1, 4.0, 0.1, 0.1);
	ShowSyncHudMsg(iVictim, g_iSyncHud2, "%.0f^n", flDamage);
#endif

	if(1 <= iAttacker <= g_MaxPlayers)
	{
		set_hudmessage(0, 100, 200, -1.0, 0.55, 2, 0.1, 4.0, 0.02, 0.02);
		ShowSyncHudMsg(iAttacker, g_iSyncHud, "%.0f^n", flDamage);
	}
	
	return HAM_IGNORED;
}*/

public on_damage(id)
{
	if(!get_pcvar_num(cDamage))
		return;
	
	static attacker; attacker = get_user_attacker(id)
	static damage; damage = read_data(2)	
		
#if defined DAMAGE_RECEIVED
		
	set_hudmessage(255, 0, 0, 0.45, 0.50, 2, 0.1, 4.0, 0.1, 0.1, -1)
	ShowSyncHudMsg(id, g_iSyncHud2, "%i^n", damage)		
#endif

	if(1 <= attacker <= g_MaxPlayers)
	{
		set_hudmessage(0, 100, 200, -1.0, 0.55, 2, 0.1, 4.0, 0.02, 0.02, -1)
		ShowSyncHudMsg(attacker, g_iSyncHud, "%i^n", damage)				
	}
}