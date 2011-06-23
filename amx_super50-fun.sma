// Fun commands

/*
 *	Nr 		COMMAND				CALLBACK FUNCTION			ADMIN LEVEL
 *			
 *	1)		amx_heal			CmdHeal						ADMIN_LEVEL_A		
 *	2)		amx_armor			CmdArmor					ADMIN_LEVEL_A
 *	3)		amx_teleport		CmdTeleport					ADMIN_LEVEL_A
 *	4)		amx_userorigin		CmdUserOrigin				ADMIN_LEVEL_A
 *	5)		amx_stack			CmdStack					ADMIN_LEVEL_A
 *	6)		amx_gravity			CmdGravity					ADMIN_LEVEL_A
 *	7)		amx_unammo			CmdUnAmmo					ADMIN_LEVEL_A
 *	8)		amx_weapon(menu)	CmdWeapon(Menu)				ADMIN_LEVEL_C
 *	9)		amx_drug			CmdDrug						ADMIN_LEVEL_C
 *	10)		amx_godmode			CmdGodmode					ADMIN_LEVEL_C
 *	11)		amx_givemoney		CmdGiveMoney				ADMIN_LEVEL_C
 *	12)		amx_takemoney		CmdTakeMoney				ADMIN_LEVEL_C
 *	13)		amx_noclip			CmdNoclip					ADMIN_LEVEL_C
 *	14)		amx_speed			CmdSpeed					ADMIN_LEVEL_C
 *	15)		amx_revive			CmdRevive					ADMIN_LEVEL_C
 *	16)		amx_bury			Cmd_Bury					ADMIN_LEVEL_B 	
 *	17)		amx_unbury			Cmd_Unbury					ADMIN_LEVEL_B
 *	18)		amx_disarm			Cmd_Disarm					ADMIN_LEVEL_B
 *	19)		amx_slay2			Cmd_Slay2					ADMIN_LEVEL_B
 *	20)		amx_rocket			Cmd_Rocket					ADMIN_LEVEL_B
 *	21)		amx_fire			Cmd_Fire					ADMIN_LEVEL_B
 *	22)		amx_flash			Cmd_Flash					ADMIN_LEVEL_B
 *	23)		amx_uberslap		Cmd_UberSlap				ADMIN_LEVEL_B
 *	24)		amx_glow(2)			Cmd_Glow					ADMIN_LEVEL_D
 *	25)		amx_glowcolors		Cmd_GlowColors				ADMIN_LEVEL_D
*/ 


/*
	Fixed bugs:
	
	- amx_revive didn't work with @ params.
	- amx_godmode & amx_noclip didn't work with ADMIN_IMMUNITY flag.
	- amx_heal set health instead of adding it to current health.
	- amx_userorigin didn't work on dead / immune players.
	
	Drekes		06/10/2010:
	- Updated amx_glow(2) with bitsums.		tnx Juann
	- Changed godmode / noclip settings 	tnx Juann
	
	Drekes		06/23/2010
	- Fixed ADMIN_IMMUNITY issues.
*/

 

#include <amxmodx>
#include <amxmisc>
#include <fun>
#include <cstrike>
#include <fakemeta>
#include <hamsandwich>

#define SetPlayerBit(%1,%2)      (%1 |= (1<<(%2&31)))
#define ClearPlayerBit(%1,%2)    (%1 &= ~(1 <<(%2&31)))
#define CheckPlayerBit(%1,%2)    (%1 & (1<<(%2&31))) 

// amx_disarm
#define OFFSET_PRIMARYWEAPON        116 

// amx_glow & amx_glow2
#define MAX_COLORS 	30


// 	Used for the show_activity() / log_amx messages.
enum CmdTeam
{
	ALL,
	T,
	CT
};

new const g_TeamNames[CmdTeam][] = 
{ 
	"All",
	"Terrorist", 
	"Counter-Terrorist" 
};


// cvar pointers
new cGravity
	, sv_maxspeed
	, allowcatchfire
	, flashsound
;

// perm checks
enum (<<=1) 
{
	PERMGOD = 1,
	PERMSPEED,
	PERMDRUGS,
	PERMNOCLIP,
	HASSPEED,
	HASGLOW
};

new g_iFlags[33];


// amx_weaponmenu
new gTeamMenu
	, gPlayerMenu
	, gWeaponMenu
;

// amx_drug
new gSetFOVMsg
	// , bool: gPermDrugs[33]
;

// amx_godmode
// new bool: gPermGod[33]
// ;

// amx_noclip
// new bool: gPermNoclip[33]
// ;

// amx_speed
new bool:gFreezeTime
	// , bool:gPermSpeed[33]
	// , bool:gHasSpeed[33]
;

// amx_fire
new onfire
;

// amx_glow, amx_glow2, amx_glowcolors
new const g_Colors[MAX_COLORS][3] = 
{
	{255, 0, 0},
	{255, 190, 190},
	{165, 0, 0},
	{255, 100, 100},
	{0, 0, 255},
	{0, 0, 136},
	{95, 200, 255},
	{0, 150, 255},
	{0, 255, 0},
	{180, 255, 175},
	{0, 155, 0},
	{150, 63, 0},
	{205, 123, 64},
	{255, 255, 255},
	{255, 255, 0},
	{189, 182, 0},
	{255, 255, 109},
	{255, 150, 0},
	{255, 190, 90},
	{222, 110, 0},
	{243, 138, 255},
	{255, 0, 255},
	{150, 0, 150},
	{100, 0, 100},
	{200, 0, 0},
	{220, 220, 0},
	{192, 192, 192},
	{190, 100, 10},
	{114, 114, 114},
	{0, 0, 0}
};

new const g_ColorNames[MAX_COLORS][] = 
{
	"red",
	"pink",
	"darkred",
	"lightred",
	"blue",
	"darkblue",
	"lightblue",
	"aqua",
	"green",
	"lightgreen",
	"darkgreen",
	"brown",
	"lightbrown",
	"white",
	"yellow",
	"darkyellow",
	"lightyellow",
	"orange",
	"lightorange",
	"darkorange",
	"lightpurple",
	"purple",
	"darkpurple",
	"violet",
	"maroon",
	"gold",
	"silver",
	"bronze",
	"grey",
	"off"
};

new g_GlowColor[33][4]
	// , bool: g_HasGlow[33]
	// , g_HasGlow
;

// sprites for effects
new smoke
	, white
	, light
	, blueflare2
	, mflash
;

// message ids
new g_Msg_Damage
	, g_Msg_ScreenFade
;

public plugin_init()
{
	register_plugin("Amx Super Fun", "5.0", "Supercentral.net Scripting Team");
	register_dictionary("amx_super.txt");
	
	register_concmd("amx_heal", 		"CmdHeal", 			ADMIN_LEVEL_A, "<nick, #userid, authid or @team> <HP to give>");
	register_concmd("amx_armor", 		"CmdArmor", 		ADMIN_LEVEL_A, "<nick, #userid, authid or @team> <armor to give>");
	register_concmd("amx_teleport", 	"CmdTeleport", 		ADMIN_LEVEL_A, "<nick, #userid or authid> [x] [y] [z]");
	register_concmd("amx_userorigin", 	"CmdUserOrigin", 	ADMIN_LEVEL_A, "<nick, #userid or authid");
	register_concmd("amx_stack", 		"CmdStack", 		ADMIN_LEVEL_A, "<nick, #userid or authid> [0|1|2]");
	register_concmd("amx_gravity", 		"CmdGravity", 		ADMIN_LEVEL_A, "<gravity #>");
	register_concmd("amx_unammo", 		"CmdUnAmmo", 		ADMIN_LEVEL_A, "<nick, #userid or @team> [0|1] - 0=OFF 1=ON");
	register_concmd("amx_weaponmenu", 	"CmdWeaponMenu", 	ADMIN_LEVEL_C, "shows the weapon menu");
	register_concmd("amx_drug", 		"CmdDrug", 			ADMIN_LEVEL_C, "<@all, @team, nick, #userid, authid> [0|1|2] - 0=OFF 1=ON 2=ON + ON EACH ROUND")
	register_concmd("amx_godmode", 		"CmdGodmode", 		ADMIN_LEVEL_C, "<nick, #userid, authid or @team> [0|1|2] - 0=OFF 1=ON 2=ON + ON EACH ROUND")
	register_concmd("amx_givemoney",	"CmdGiveMoney",		ADMIN_LEVEL_C, "<nick, #userid, authid or @team> <amount> - gives specified player money")
	register_concmd("amx_takemoney",	"CmdTakeMoney",		ADMIN_LEVEL_C, "<nick, #userid or authid> <amount> - takes specified player money")
	register_concmd("amx_noclip", 		"CmdNoclip", 		ADMIN_LEVEL_C, "<nick, #userid, authid or @team> [0|1|2] - 0=OFF 1=ON 2=ON + ON EACH ROUND")
	register_concmd("amx_speed", 		"CmdSpeed", 		ADMIN_LEVEL_C, "<nick, #userid, authid or @team> [0|1|2] - 0=OFF 1=ON 2=ON + ON EACH ROUND")
	register_concmd("amx_revive", 		"CmdRevive", 		ADMIN_LEVEL_C, "<nick, #userid, authid or @team>")
	register_concmd("amx_bury", 		"Cmd_Bury", 		ADMIN_LEVEL_B, "<nick, #userid, authid or @team>");
	register_concmd("amx_unbury", 		"Cmd_Unbury",		ADMIN_LEVEL_B, "<nick, #userid, authid or @team>");
	register_concmd("amx_disarm",		"Cmd_Disarm", 		ADMIN_LEVEL_B, "<nick, #userid, authid or @team>");
	register_concmd("amx_slay2", 		"Cmd_Slay2",		ADMIN_LEVEL_B, "<nick, #userid, authid or @team> [1-Lightning|2-Blood|3-Explode]");
	register_concmd("amx_rocket", 		"Cmd_Rocket", 		ADMIN_LEVEL_B, "<nick, #userid, authid or @team>");
	register_concmd("amx_fire", 		"Cmd_Fire", 		ADMIN_LEVEL_B, "<nick, #userid, authid or @team>");
	register_concmd("amx_flash", 		"Cmd_Flash", 		ADMIN_LEVEL_B, "<nick, #userid, authid or @team");
	register_concmd("amx_uberslap", 	"Cmd_UberSlap", 	ADMIN_LEVEL_B, "<nick, #userid or authid");
	register_concmd("amx_glow", 		"Cmd_Glow", 		ADMIN_LEVEL_D, "<nick, #userid, authid, or @team/@all> <color> (or) <rrr> <ggg> <bbb> <aaa> -- lasts 1 round");
	register_concmd("amx_glow2", 		"Cmd_Glow", 		ADMIN_LEVEL_D, "<nick, #userid, authid, or @team/@all> <color> (or) <rrr> <ggg> <bbb> <aaa> -- lasts forever");
	register_concmd("amx_glowcolors", 	"Cmd_GlowColors", 	ADMIN_LEVEL_D, "shows a list of colors for amx_glow and amx_glow2");
	
	// Register new cvars and get existing cvar pointers:
	cGravity 		= get_cvar_pointer("sv_gravity");
	sv_maxspeed 	= get_cvar_pointer("sv_maxspeed")
	
	allowcatchfire 	= register_cvar("allow_catchfire", "1");
	flashsound 		= register_cvar("amx_flashsound","1");
	
	
	// amx_unammo
	register_event("CurWeapon", "Event_CurWeapon", "be", "1=1");
		
	// amx_weaponmenu
	gTeamMenu = menu_create("\rTeam?", "TeamHandler")
	menu_additem(gTeamMenu, "All", "1")
	menu_additem(gTeamMenu, "Counter-Terrorist", "2")
	menu_additem(gTeamMenu, "Terrorist", "3")
	menu_additem(gTeamMenu, "Player", "4")
	gPlayerMenu = menu_create("\rPlayers:", "PlayerHandler")
	
	// amx_drug
	gSetFOVMsg = get_user_msgid("SetFOV")
	
	// amx_speed
	RegisterHam(Ham_Item_PreFrame, "player", "FwdPlayerSpeedPost", 1)
	register_logevent("LogEventRoundStart", 2, "1=Round_Start")
	register_event("HLTV", "EventFreezeTime", "a")
	set_pcvar_num(sv_maxspeed, 9999999)
	
	// message ids
	g_Msg_Damage = get_user_msgid("Damage");
	g_Msg_ScreenFade = get_user_msgid("ScreenFade");
	// Used by several commands
	RegisterHam(Ham_Spawn, "player", "FwdPlayerSpawnPost", 1)
}

/* Precache
 *---------
*/
public plugin_precache()
{
	// amx_slay2 & amx_rocket sprites
	smoke 		= precache_model("sprites/steam1.spr");
	white		= precache_model("sprites/white.spr");
	light 		= precache_model("sprites/lgtning.spr");
	blueflare2 	= precache_model( "sprites/blueflare2.spr");
	mflash 		= precache_model("sprites/muzzleflash.spr");
	
	// amx_rocket sounds
	precache_sound("ambience/thunder_clap.wav");
	precache_sound("weapons/headshot2.wav");
	precache_sound("weapons/rocketfire1.wav");
	precache_sound("weapons/rocket1.wav");
	
	// amx_fire sounds
	precache_sound("ambience/flameburst1.wav");
	precache_sound("scientist/scream21.wav");
	precache_sound("scientist/scream07.wav");
}

/* Player Spawn
 *-------------
*/
public FwdPlayerSpawnPost(id)
{
	if(!is_user_alive(id))
		return HAM_IGNORED;
		
	// if(gPermDrugs[id])
	if(g_iFlags[id] & PERMDRUGS)
		set_user_drugs(id, 1)
		
	// if(gPermGod[id])
	if(g_iFlags[id] & PERMGOD)
		set_user_godmode(id, 1)
	
	// if(gPermNoclip[id])
	if(g_iFlags[id] & PERMNOCLIP)
		set_user_noclip(id, 1)
	
	// if(gHasSpeed[id])
	if(g_iFlags[id] & HASSPEED)
	{
		// gHasSpeed[id] = false
		g_iFlags[id] &= ~HASSPEED;
		
		SetSpeed(id, 0)
	}
	
	// if(g_HasGlow[id])
	if(g_iFlags[id] & HASGLOW)
		set_user_rendering(id, kRenderFxGlowShell, g_GlowColor[id][0], g_GlowColor[id][1], g_GlowColor[id][2], kRenderTransAlpha, g_GlowColor[id][3]);	
	else
		set_user_rendering(id, kRenderFxNone, 0, 0, 0, kRenderNormal, 0);
		//set_user_rendering(id);
		
	return HAM_IGNORED;
}


/* Player Disconnects
 *-------------------
*/
public client_disconnect(id)
{
	if(CheckPlayerBit(onfire, id))
		ClearPlayerBit(onfire, id);
		
	// gPermDrugs[id] 	= false
	// gPermGod[id] 	= false
	// gPermNoclip[id] = false
	// gHasSpeed[id] 	= false
	// gPermSpeed[id] 	= false
	// g_HasGlow[id] 	= false;
	g_iFlags[id] = 0;
}


/*	1)	amx_heal
 *--------------
*/
public CmdHeal(id, level, cid)
{
	if(!cmd_access(id, level, cid, 3))
		return PLUGIN_HANDLED;
	
	new Arg[35], szHealth[10];
	read_argv(1, Arg, charsmax(Arg));
	read_argv(2, szHealth, charsmax(szHealth));
	
	new iHealth = str_to_num(szHealth);
	
	new AdminName[35], AdminAuth[35];
	get_user_name(id, AdminName, charsmax(AdminName));
	get_user_authid(id, AdminAuth, charsmax(AdminAuth));
	
	new Tempid, TargetName[35];
	
	if(iHealth <= 0)	
	{
		console_print(id, "%L", id, "AMX_SUPER_AMOUNT_GREATER");
		
		return PLUGIN_HANDLED;
	}
	
	if(Arg[0] == '@')
	{
		new Players[32], Pnum, CmdTeam: Team;
		
		switch(Arg[1])
		{
			case 'T', 't':
			{	
				get_players(Players, Pnum, "ae", "TERRORIST");
				
				Team = T;
			}
			
			case 'C', 'c':
			{
				get_players(Players, Pnum, "ae", "CT");
				
				Team = CT;
			}
			
			case 'A', 'a':
			{
				get_players(Players, Pnum, "a");
				
				Team = ALL;
			}
		}
		
		if(!Pnum)
		{
			console_print(id, "%L", id, "AMX_SUPER_NO_PLAYERS");
			
			return PLUGIN_HANDLED;
		}

		for(new i = 0; i < Pnum; i++)
		{
			Tempid = Players[i];
			
			if((get_user_flags(Tempid)) && Tempid != id)
			{
				get_user_name(Tempid, TargetName, charsmax(TargetName));
				console_print(id, "%L", id, "AMX_SUPER_TEAM_IMMUNITY", TargetName);
				
				continue;
			}
			
			set_user_health(Tempid, get_user_health(Tempid) + iHealth);
		}
		
		show_activity_key("AMX_SUPER_HEAL_TEAM_CASE1", "AMX_SUPER_HEAL_TEAM_CASE2", AdminName, iHealth, g_TeamNames[Team]);
		log_amx("%L", LANG_SERVER, "AMX_SUPER_HEAL_TEAM_LOG", AdminName, AdminAuth, iHealth, g_TeamNames[Team]);
	}
	
	else
	{	
		Tempid = cmd_target(id, Arg, CMDTARGET_ALLOW_SELF | CMDTARGET_ONLY_ALIVE);
		
		if(Tempid)
		{
			set_user_health(Tempid, get_user_health(Tempid) + iHealth);
			
			new PlayerAuth[35];
			get_user_authid(Tempid, PlayerAuth, charsmax(PlayerAuth));
			get_user_name(Tempid, TargetName, charsmax(TargetName));
			
			show_activity_key("AMX_SUPER_HEAL_PLAYER_CASE1", "AMX_SUPER_HEAL_PLAYER_CASE2", AdminName, iHealth, TargetName);
			log_amx("%L", LANG_SERVER, "AMX_SUPER_HEAL_PLAYER_LOG", AdminName, AdminAuth, iHealth, TargetName, PlayerAuth);
		}
	}

	return PLUGIN_HANDLED;
}


/* 2)	amx_armor
 *---------------
*/
public CmdArmor(id, level, cid)
{
	if(!cmd_access(id, level, cid, 3))
		return PLUGIN_HANDLED;
	
	new Arg[35], szArmor[10];
	read_argv(1, Arg, charsmax(Arg));
	read_argv(2, szArmor, charsmax(szArmor));
	
	new iArmor = str_to_num(szArmor);
	
	new AdminName[35], AdminAuth[35];
	get_user_name(id, AdminName, charsmax(AdminName));
	get_user_authid(id, AdminAuth, charsmax(AdminAuth));
	
	new Tempid, TargetName[35];
	
	if(iArmor <= 0)	
	{
		console_print(id, "%L", id, "AMX_SUPER_AMOUNT_GREATER");
		
		return PLUGIN_HANDLED;
	}
	
	if(Arg[0] == '@')
	{
		new Players[32], Pnum, CmdTeam: Team;
		
		switch(Arg[1])
		{
			case 'T', 't':
			{	
				get_players(Players, Pnum, "ae", "TERRORIST");
				
				Team = T;
			}
			
			case 'C', 'c':
			{
				get_players(Players, Pnum, "ae", "CT");
				
				Team = CT;
			}
			
			case 'A', 'a':
			{
				get_players(Players, Pnum, "a");
				
				Team = ALL;
			}
		}
		
		if(!Pnum)
		{
			console_print(id, "%L", id, "AMX_SUPER_NO_PLAYERS");
			
			return PLUGIN_HANDLED;
		}

		for(new i = 0; i < Pnum; i++)
		{
			Tempid = Players[i];
			
			if((get_user_flags(Tempid)) && Tempid != id)
			{
				get_user_name(Tempid, TargetName, charsmax(TargetName));
				console_print(id, "%L", id, "AMX_SUPER_TEAM_IMMUNITY", TargetName);
				
				continue;
			}
			
			cs_set_user_armor(Tempid, iArmor, CS_ARMOR_VESTHELM);
		}
		
		show_activity_key("AMX_SUPER_ARMOR_TEAM_CASE1", "AMX_SUPER_ARMOR_TEAM_CASE2", AdminName, iArmor, g_TeamNames[Team]);
		log_amx("%L", LANG_SERVER, "AMX_SUPER_ARMOR_TEAM_LOG", AdminName, AdminAuth, iArmor, g_TeamNames[Team]);
	}
	
	else
	{	
		Tempid = cmd_target(id, Arg, CMDTARGET_ALLOW_SELF | CMDTARGET_ONLY_ALIVE);
		
		if(Tempid)
		{
			cs_set_user_armor(Tempid, iArmor, CS_ARMOR_VESTHELM);
			
			new PlayerAuth[35];
			get_user_authid(Tempid, PlayerAuth, charsmax(PlayerAuth));
			get_user_name(Tempid, TargetName, charsmax(TargetName));
			
			show_activity_key("AMX_SUPER_ARMOR_PLAYER_CASE1", "AMX_SUPER_ARMOR_PLAYER_CASE2", AdminName, iArmor, TargetName);
			log_amx("%L", LANG_SERVER, "AMX_SUPER_ARMOR_PLAYER_LOG", AdminName, AdminAuth, iArmor, TargetName, PlayerAuth);
		}
	}

	return PLUGIN_HANDLED;
}


/* 3)	amx_teleport
 *------------------
*/
public CmdTeleport(id, level, cid)
{
	if(!cmd_access(id, level, cid, 5))
		return PLUGIN_HANDLED;
	
	new Target[35];
	read_argv(1, Target, charsmax(Target));
	
	new Tempid = cmd_target(id, Target, CMDTARGET_ALLOW_SELF | CMDTARGET_ONLY_ALIVE);
	
	if(Tempid)
	{
		new Ori1[5], Ori2[5], Ori3[5];
		read_argv(2, Ori1, charsmax(Ori1));
		read_argv(3, Ori2, charsmax(Ori2));
		read_argv(4, Ori3, charsmax(Ori3));
		
		new Float: Origin[3];
		Origin[0] = str_to_float(Ori1);
		Origin[1] = str_to_float(Ori2);
		Origin[2] = str_to_float(Ori3);
		
		// set_pev(Tempid, pev_origin, Origin);
		engfunc(EngFunc_SetOrigin, Tempid, Origin);
		
		new AdminName[35], AdminAuth[35];
		get_user_name(id, AdminName, charsmax(AdminName));
		get_user_authid(id, AdminAuth, charsmax(AdminAuth));
		
		new TargetName[35], TargetAuth[35];
		get_user_name(Tempid, TargetName, charsmax(TargetName));
		get_user_authid(Tempid, TargetAuth, charsmax(TargetAuth));
		
		show_activity_key("AMX_SUPER_TELEPORT_PLAYER_CASE1", "AMX_SUPER_TELEPORT_PLAYER_CASE2", AdminName, TargetName);
		log_amx("%L", LANG_SERVER, "AMX_SUPER_TELEPORT_PLAYER_LOG", AdminName, AdminAuth, TargetName, TargetAuth, floatround(Origin[0]), floatround(Origin[1]), floatround(Origin[2]));
	}
	
	return PLUGIN_HANDLED;
}

/* 4)	amx_userorigin
 *--------------------
*/
new g_UserOrigin[33][3];


public CmdUserOrigin(id, level, cid)
{
	if(!cmd_access(id, level, cid, 2)) 
		return PLUGIN_HANDLED

	new Target[35];
	read_argv(1, Target, charsmax(Target));

	new Tempid = cmd_target(id, Target, CMDTARGET_ALLOW_SELF);
	
	if(Tempid)
	{
		new Name[35];
		get_user_origin(Tempid, g_UserOrigin[id]);
		get_user_name(Tempid, Name, charsmax(Name));

		console_print(id, "%L", LANG_PLAYER, "AMX_SUPER_TELEPORT_ORIGIN_SAVED", g_UserOrigin[id][0], g_UserOrigin[id][1], g_UserOrigin[id][2], Name);
	}
	
	return PLUGIN_HANDLED;
}

/* 5)	amx_stack
 *---------------
*/
public CmdStack(id, level, cid)
{
	if(!cmd_access(id, level, cid, 2))
		return PLUGIN_HANDLED;

	new Target[35];
	read_argv(1, Target, charsmax(Target));

	new Tempid = cmd_target(id, Target, CMDTARGET_OBEY_IMMUNITY | CMDTARGET_ALLOW_SELF | CMDTARGET_ONLY_ALIVE);
	
	if(Tempid)
	{	
		new Type[5];
		read_argv(2, Type, charsmax(Type));
		
		new Float: Origin[3];
		pev(Tempid, pev_origin, Origin);

		new y = 36, z = 96;
		switch(str_to_num(Type))
		{
			case 0: y = 0;
			case 1: z = 0;
		}
	
		new players[32], pnum, iPlayer;
		get_players(players, pnum, "a");
		
		for(new i = 0; i < pnum ; i++)
		{
			iPlayer = players[i];
			
			if((iPlayer == id) || (get_user_flags(iPlayer) & ADMIN_IMMUNITY) && iPlayer != id) 
				continue
				
			Origin[1] += y;
			Origin[2] += z;
			set_pev(iPlayer, pev_origin, Origin);
		}

		new AdminName[35], AdminAuth[35];
		get_user_name(id, AdminName, charsmax(AdminName));
		get_user_authid(id, AdminAuth, charsmax(AdminAuth));
		
		new TempName[35], TempAuth[35];
		get_user_name(Tempid, TempName, charsmax(TempName));
		get_user_authid(Tempid, TempAuth, charsmax(TempAuth));

		console_print(id,"%L", LANG_PLAYER, "AMX_SUPER_STACK_PLAYER_MSG", TempName);
		
		show_activity_key("AMX_SUPER_STACK_PLAYER_CASE1", "AMX_SUPER_STACK_PLAYER_CASE2", AdminName, TempName);
		log_amx("%L", LANG_SERVER, "AMX_SUPER_STACK_PLAYER_LOG", AdminName, AdminAuth, TempName, TempAuth);
	}

	return PLUGIN_HANDLED;
}

/*	6)	amx_gravity
 *-----------------
*/
public CmdGravity(id, level, cid)
{
	if(!cmd_access(id, level, cid, 1))	
		return PLUGIN_HANDLED;
	
	if(read_argc() < 2)
	{
		console_print(id, "%L", id, "AMX_SUPER_GRAVITY_STATUS", get_pcvar_num(cGravity));
		
		return PLUGIN_HANDLED;
	}
	
	new Arg[5];
	read_argv(1, Arg, charsmax(Arg));
	// server_cmd("sv_gravity %s", Arg);
	set_pcvar_num(cGravity, str_to_num(Arg));
	
	new AdminName[35], AdminAuth[35];
	get_user_name(id, AdminName, charsmax(AdminName));
	get_user_authid(id, AdminAuth, charsmax(AdminAuth));
	
	console_print(id, "%L", id, "AMX_SUPER_GRAVITY_MSG", Arg);
	
	show_activity_key("AMX_SUPER_GRAVITY_SET_CASE1", "AMX_SUPER_GRAVITY_SET_CASE2", AdminName, Arg);
	log_amx("%L", LANG_SERVER, "AMX_SUPER_GRAVITY_LOG", AdminName, AdminAuth, Arg);
	
	return PLUGIN_HANDLED;
}

/* 7)	amx_unammo
 *----------------
*/
new bUnammo;
new Float: g_ReloadTime[33];

public CmdUnAmmo(id, level, cid)
{
	if(!cmd_access(id, level, cid, 2))
		return PLUGIN_HANDLED;
		
	new Target[35], Setting[5];
	read_argv(1, Target, charsmax(Target));
	read_argv(2, Setting, charsmax(Setting));
	
	new cmd = str_to_num(Setting);
	
	new AdminName[35], AdminAuth[35];
	new TargetName[35];
	
	get_user_name(id, AdminName, charsmax(AdminName));
	get_user_authid(id, AdminAuth, charsmax(AdminAuth));
	
	new Tempid;
	if(Target[0] == '@')
	{
		new CmdTeam: Team, players[32], pnum;
		
		switch(Target[1])
		{
			case 'T', 't':
			{
				get_players(players, pnum, "ae", "TERRORIST");
				
				Team = T;
			}
			
			case 'A', 'a':
			{
				get_players(players, pnum, "a");
				
				Team = ALL;
			}
			
			case 'C', 'c':
			{
				get_players(players, pnum, "ae", "CT");
				
				Team = CT;
			}
		}
		
		if(!pnum)
		{
			console_print(id, "%L", id, "AMX_SUPER_NO_PLAYERS");
			
			return PLUGIN_HANDLED;
		}
		
		for(new i = 0; i < pnum; i++)
		{
			Tempid = players[i];
			
			if((get_user_flags(Tempid) & ADMIN_IMMUNITY) && Tempid != id)
			{
				get_user_name(Tempid, TargetName, charsmax(TargetName));
				console_print(id, "%L", "AMX_SUPER_TEAM_IMMUNITY", TargetName);
				
				continue;
			}
			
			if(cmd)
				SetPlayerBit(bUnammo, Tempid);
			
			else
				ClearPlayerBit(bUnammo, Tempid);
		}
		
		console_print(id, "%L", id, "AMX_SUPER_AMMO_TEAM_MSG", g_TeamNames[Team], cmd);
		
		show_activity_key("AMX_SUPER_AMMO_CASE1", "AMX_SUPER_AMMO_CASE2", AdminName, g_TeamNames[Team], cmd);
		log_amx("%L", LANG_SERVER, "AMX_SUPER_AMMO_TEAM_LOG", AdminName, AdminAuth, g_TeamNames[Team], cmd);
	}
	
	else
	{
		Tempid = cmd_target(id, Target, CMDTARGET_OBEY_IMMUNITY | CMDTARGET_ALLOW_SELF | CMDTARGET_ONLY_ALIVE);
		
		if(Tempid)
		{	
			if(cmd)
				SetPlayerBit(bUnammo, Tempid);
			
			else
				ClearPlayerBit(bUnammo, Tempid);
				
			new TargetAuth[35];
			get_user_name(Tempid, TargetName, charsmax(TargetName));
			get_user_authid(Tempid, TargetAuth, charsmax(TargetAuth));
			
			console_print(id, "%L", id, "AMX_SUPER_AMMO_PLAYER_MSG", TargetName, cmd);
			
			show_activity_key("AMX_SUPER_AMMO_PLAYER_CASE1", "AMX_SUPER_AMMO_PLAYER_CASE2", AdminName, TargetName, cmd);
			log_amx("%L", LANG_SERVER, "AMX_SUPER_AMMO_PLAYER_LOG", AdminName, AdminAuth, TargetName, TargetAuth, cmd);
		}
	}
	
	return PLUGIN_HANDLED;
}

public Event_CurWeapon(id)
{
	if(CheckPlayerBit(bUnammo, id))
	{
		new wpnid = read_data(2);
		new clip = read_data(3);
	
		if(wpnid == CSW_C4 
		|| wpnid == CSW_KNIFE
		|| wpnid == CSW_HEGRENADE
		|| wpnid == CSW_SMOKEGRENADE
		|| wpnid == CSW_FLASHBANG) {
			return PLUGIN_CONTINUE;
		}
		
		if(!clip)
		{
			new SysTime = get_systime();
			
			if(g_ReloadTime[id] >= SysTime - 1)
				return PLUGIN_CONTINUE;
			
			new WeaponName[20];
			get_weaponname(wpnid, WeaponName, charsmax(WeaponName));
			
			new EntId = -1;
			while((EntId = engfunc(EngFunc_FindEntityByString, EntId, "classname", WeaponName)) != 0)
			{	
				if(pev_valid(EntId) && pev(EntId, pev_owner) == id)
				{
					cs_set_weapon_ammo(EntId, getMaxClipAmmo(wpnid));
					
					break;
				}
			}
		}
	}
	
	return PLUGIN_CONTINUE;
}

getMaxClipAmmo(wpnid)
{
	new clip = -1
	
	switch(wpnid)
	{
		case CSW_P228: clip = 13
		case CSW_SCOUT, CSW_AWP: clip = 10
		case CSW_HEGRENADE, CSW_C4, CSW_SMOKEGRENADE, CSW_FLASHBANG, CSW_KNIFE: clip = 0
		case CSW_XM1014, CSW_DEAGLE: clip = 7
		case CSW_MAC10, CSW_AUG, CSW_SG550, CSW_MP5NAVY, CSW_M4A1, CSW_SG552, CSW_AK47: clip = 30
		case CSW_ELITE: clip = 15
		case CSW_FIVESEVEN, CSW_GLOCK18, CSW_G3SG1: clip = 20
		case CSW_UMP45, CSW_FAMAS: clip = 25
		case CSW_GALI: clip = 35
		case CSW_USP: clip = 12
		case CSW_M249: clip = 100
		case CSW_M3: clip = 8
		case CSW_P90: clip = 50
		/*case CSW_P228 : return 13;
		case CSW_SCOUT : return 10;
		case CSW_HEGRENADE : return 0;
		case CSW_XM1014 : return 7;
		case CSW_C4 : return 0;
		case CSW_MAC10 : return 30;
		case CSW_AUG : return 30;
		case CSW_SMOKEGRENADE : return 0;
		case CSW_ELITE : return 15;
		case CSW_FIVESEVEN : return 20;
		case CSW_UMP45 : return 25;
		case CSW_SG550 : return 30;
		case CSW_GALI : return 35;
		case CSW_FAMAS : return 25;
		case CSW_USP : return 12;
		case CSW_GLOCK18 : return 20;
		case CSW_AWP : return 10;
		case CSW_MP5NAVY : return 30;
		case CSW_M249 : return 100;
		case CSW_M3 : return 8;
		case CSW_M4A1 : return 30;
		case CSW_TMP : return 30;
		case CSW_G3SG1 : return 20;
		case CSW_FLASHBANG : return 0;
		case CSW_DEAGLE : return 7;
		case CSW_SG552 : return 30;
		case CSW_AK47 : return 30;
		case CSW_KNIFE : return 0;
		case CSW_P90 : return 50;*/
	}
	//return -1;
	return clip;
}		

/* 8a)	amx_weapon
 *----------------
*/
enum
{
	WEAPON_USP,
	WEAPON_GLOCK18,
	WEAPON_DEAGLE,
	WEAPON_P228,
	WEAPON_ELITE,
	WEAPON_FIVESEVEN,
	WEAPON_M3,
	WEAPON_XM1014,
	WEAPON_TMP,
	WEAPON_MAC10,
	WEAPON_MP5NAVY,
	WEAPON_P90,
	WEAPON_UMP45,
	WEAPON_FAMAS,
	WEAPON_GALIL,
	WEAPON_AK47,
	WEAPON_M4A1,
	WEAPON_SG552,
	WEAPON_AUG,
	WEAPON_SCOUT,
	WEAPON_SG550,
	WEAPON_AWP,
	WEAPON_G3SG1,
	WEAPON_M249,
	WEAPON_HEGRENADE,
	WEAPON_SMOKEGRENADE,
	WEAPON_FLASHBANG,
	WEAPON_SHIELD,
	WEAPON_C4,
	WEAPON_KNIFE,
	ITEM_KEVLAR,
	ITEM_ASSAULTSUIT,
	ITEM_THIGHPACK
}

new bpammo[] =  // 0 denotes a blank weapon id
{
	0,
	52,
	0,
	90,
	1,
	32,
	1,
	100,
	90,
	1,
	120,
	100,
	100,
	90,
	90,
	90,
	100,
	120,
	30,
	120,
	200,
	32,
	90,
	120,
	90,
	2,
	35,
	90,
	90,
	0,
	100
}
	
	

new weapons[33][] =
{
	"weapon_usp",
	"weapon_glock18",
	"weapon_deagle",
	"weapon_p228",
	"weapon_elite",
	"weapon_fiveseven",
	"weapon_m3",
	"weapon_xm1014",
	"weapon_tmp",
	"weapon_mac10",
	"weapon_mp5navy",
	"weapon_p90",
	"weapon_ump45",
	"weapon_famas",
	"weapon_galil",
	"weapon_ak47",
	"weapon_m4a1",
	"weapon_sg552",
	"weapon_aug",
	"weapon_scout",
	"weapon_sg550",
	"weapon_awp",
	"weapon_g3sg1",
	"weapon_m249",
	"weapon_hegrenade",
	"weapon_smokegrenade",
	"weapon_flashbang",
	"weapon_shield",
	"weapon_c4",
	"weapon_knife",
	"item_kevlar",
	"item_assaultsuit",
	"item_thighpack"
}

new weapon_names[][] = 
{
	"All Weapons",
	"Knife",
	"",
	"",
	"",
	"",
	"",
	"",
	"",
	"",
	"",
	"Glock",
	"USP",
	"P228",
	"Deagle",
	"Fiveseven",
	"Dual Elites",
	"",
	"",
	"",
	"",
	"M3",
	"XM1014",
	"",
	"",
	"",
	"",
	"",
	"",
	"",
	"",
	"TMP",
	"MAC10",
	"MP5 Navy",
	"P90",
	"UMP45",
	"",
	"",
	"",
	"",
	"Famas",
	"Galil",
	"AK47",
	"M4A1",
	"SG552",
	"AUG",
	"Scout",
	"SG550",
	"Awp",
	"G3SG1",
	"",
	"M249",
	"Kevlar and Helmit", //82
	"HE Grenade",
	"Flashbang",
	"Smoke Grenade",
	"Defuse Kit",
	"Shield",
	"",
	"",
	"",
	"C4",
	"Night Vision"
}

public CmdWeapon(id, level, cid)
{
	if(!cmd_access(id, level, cid, 3))
		return PLUGIN_HANDLED
	
	new name[32]
	get_user_name(id, name, 31)
	
	new AuthId[36]
	get_user_authid(id, AuthId, 35)
	
	new arg1[32]
	read_argv(1, arg1, 31)
	
	new arg2[24]
	read_argv(2, arg2, 23)
	
	new weapon = str_to_num(arg2)
	
	if(arg1[0] == '@')
	{	
		new players[32], pnum, CmdTeam: Team;
		
		
		switch(arg1[1])
		{
			case 't', 'T':
			{
				get_players(players, pnum, "ae", "TERRORIST");
				Team = T;
			}
			
			case 'c', 'C':
			{
				get_players(players, pnum, "ae", "CT");
				Team = CT;
			}
			
			case 'a', 'A':
			{
				get_players(players, pnum, "a");
				Team = ALL;
			}
		}
		
		for(new i; i < pnum; i++)
			give_weapon(players[i], weapon)
					
		show_activity_key("AMX_SUPER_WEAPON_TEAM_CASE1", "AMX_SUPER_WEAPON_TEAM_CASE2", name, g_TeamNames[Team])

		console_print(id, "%L", LANG_PLAYER, "AMX_SUPER_WEAPON_TEAM_MSG", weapon, g_TeamNames[Team])
		log_amx("%L", LANG_SERVER, "AMX_SUPER_WEAPON_TEAM_LOG", name, AuthId, weapon, g_TeamNames[Team])
	}
	
	else
	{
		new player = cmd_target(id, arg1, 7)
		if(!player)
			return PLUGIN_HANDLED
			
		give_weapon(player, weapon)
		
		new name2[32]
		get_user_name(player, name2, 31)
		
		new AuthId2[36]
		get_user_authid(player, AuthId2, 35)
		
		show_activity_key("AMX_SUPER_WEAPON_PLAYER_CASE1", "AMXX_SUPER_WEAPON_PLAYER_CASE2", name, name2)

		console_print(id,"%L", LANG_PLAYER, "AMX_SUPER_WEAPON_PLAYER_MSG", weapon, name2)
		log_amx("%L", LANG_SERVER, "AMX_SUPER_WEAPON_PLAYER_LOG", name, AuthId, weapon, name2, AuthId2)
	}
	
	return PLUGIN_HANDLED
}

/* 8b)	amx_weaponmenu
 *--------------------
*/
enum 
{ 
	All,
	Ct,
	Terro,
	Player
};

new gTeamChoice[33]
	, gPlayerName[33][34]
	, gPlayerId[33]
;

public CmdWeaponMenu(id, level, cid)
{
	if(!cmd_access(id, level, cid, 1))
		return PLUGIN_HANDLED

	menu_display(id, gTeamMenu)
	return PLUGIN_HANDLED
}

public CmdCallbackMenu(id)
	menu_display(id, gTeamMenu)

public TeamHandler(id, menu, item)
{
	if(item == MENU_EXIT)
		return PLUGIN_HANDLED
	
	new name[32], info[6]
	new access, callback
	menu_item_getinfo(menu, item, access, info, 5, name, 31, callback)
	
	new key = str_to_num(info)
	switch(key)
	{
		case 1:
			gTeamChoice[id] = All
		
		case 2:
			gTeamChoice[id] = Ct
		
		case 3:
			gTeamChoice[id]  = Terro
		
		case 4:
			gTeamChoice[id] = Player
	}
	
	if(gTeamChoice[id] != Player)
		WeaponMenu(id);
		
	else
		PlayerMenu(id);
	
	return PLUGIN_HANDLED
}

public PlayerMenu(id)
{
	new name[34], szId[6]
	new players[32], pnum, tempid
	get_players(players, pnum, "a")
	for(new i; i < pnum; i++)
	{
		tempid = players[i]
		
		get_user_name(tempid, name, 33)
		num_to_str(tempid, szId, 5)
			
		menu_additem(gPlayerMenu, name, szId)
	}
	
	menu_display(id, gPlayerMenu)
}

public PlayerHandler(id, menu, item)
{
	if(item == MENU_EXIT)
	{
		CmdCallbackMenu(id)
		return PLUGIN_HANDLED
	}
	
	new info[6]
	new access, callback
	menu_item_getinfo(menu, item, access, info, 5, gPlayerName[id], 33, callback)
	
	gPlayerId[id] = str_to_num(info)
	
	WeaponMenu(id)
	return PLUGIN_HANDLED
}
	
public WeaponMenu(id)
{
	new szTitle[64];
	
	switch(gTeamChoice[id])
	{	
		case All: 
			formatex(szTitle, charsmax(szTitle), "\rTeam: All Weapon ?");
		
		case Ct:
			formatex(szTitle, charsmax(szTitle), "\rTeam: CT Weapon ?");
		
		case Terro:
			formatex(szTitle, charsmax(szTitle), "\rTeam: T Weapon ?");
			
		case Player:
			formatex(szTitle, charsmax(szTitle), "\rPlayer: %s Weapon?", gPlayerName[id])
	}
	
	gWeaponMenu = menu_create(szTitle, "WeaponHandler");
	
	new info[6]
	for(new i; i < sizeof(weapon_names); i++)
	{
		if(strlen(weapon_names[i]))
		{
			num_to_str(i, info, 5)
		
			menu_additem(gWeaponMenu, weapon_names[i], info)
		}
	}
	
	menu_display(id, gWeaponMenu)
}

public WeaponHandler(id, menu, item)
{
	if(item == MENU_EXIT)
	{
		CmdCallbackMenu(id)
		return PLUGIN_HANDLED
	}
	
	new name[32], info[6]
	new access, callback
	menu_item_getinfo(menu, item, access, info, 5, name, 31, callback)
	
	new choice = str_to_num(info)
	
	if(gTeamChoice[id] == Player)
	{
		switch(choice)
		{
			case 1..51:
				give_weapon(gPlayerId[id], choice)
			
			case 52..62:
				give_weapon(gPlayerId[id], (choice+30))
			
			default:
				give_weapon(gPlayerId[id], 200)
		}
	}
	
	else
	{
		new players[32], pnum
		// get_players(players, pnum, "a")
	
		switch(gTeamChoice[id])
		{
			case All:
				get_players(players, pnum, "a");
			
			case Terro:
				get_players(players, pnum, "ae", "TERRORIST");
			
			case Ct:
				get_players(players, pnum, "ae", "CT");
		}
		
		for(new i = 0; i < pnum; i++)
		{
			switch(choice)
			{
				case 1..51:
					give_weapon(players[i], choice);
				
				case 52..62:
					give_weapon(players[i], (choice + 30));
				
				default: 
					give_weapon(players[i], 200);
			}
		}
	}
	
	menu_destroy(gWeaponMenu)
	return PLUGIN_HANDLED
}

give_weapon(id,weapon)
{
	switch (weapon)
	{
		//Secondary weapons
		//Pistols
		case 1:
		{
			give_item(id,weapons[WEAPON_KNIFE])
		}
		
		case 11:
		{
			give_weapon_x(id, weapons[WEAPON_GLOCK18])
		}
		
		case 12:
		{
			give_weapon_x(id, weapons[WEAPON_USP])
		}
		
		case 13:
		{
			give_weapon_x(id, weapons[WEAPON_P228])
		}
		
		case 14:
		{
			give_weapon_x(id, weapons[WEAPON_DEAGLE])
		}
		
		case 15:
		{
			give_weapon_x(id, weapons[WEAPON_FIVESEVEN])
		}
		
		case 16:
		{
			give_weapon_x(id, weapons[WEAPON_ELITE])
		}
		
		case 17:
		{
			//all pistols
			give_weapon(id,11)
			give_weapon(id,12)
			give_weapon(id,13)
			give_weapon(id,14)
			give_weapon(id,15)
			give_weapon(id,16)
		}
		
		//Primary weapons
		//Shotguns
		case 21:
		{
			give_weapon_x(id, weapons[WEAPON_M3])
		}
		
		case 22:
		{
			give_weapon_x(id, weapons[WEAPON_XM1014])
		}
		
		//SMGs
		case 31:
		{
			give_weapon_x(id, weapons[WEAPON_TMP])
		}
		
		case 32:
		{
			give_weapon_x(id, weapons[WEAPON_MAC10])
		}
		
		case 33:
		{
			give_weapon_x(id, weapons[WEAPON_MP5NAVY])
		}
		
		case 34:
		{
			give_weapon_x(id, weapons[WEAPON_P90])
		}
		
		case 35:
		{ 
			give_weapon_x(id, weapons[WEAPON_UMP45])
		}
		
		//Rifles 
		case 40:
		{
			give_weapon_x(id, weapons[WEAPON_FAMAS])
		}
		
		case 41:
		{
			give_weapon_x(id, weapons[WEAPON_GALIL])
		}
		
		case 42:
		{
			give_weapon_x(id, weapons[WEAPON_AK47])
		}
		
		case 43:
		{
			give_weapon_x(id, weapons[WEAPON_M4A1])
		}
		
		case 44:
		{
			give_weapon_x(id, weapons[WEAPON_SG552])
		}
		
		case 45:
		{
			give_weapon_x(id,weapons[WEAPON_AUG])
		}
		
		case 46:
		{
			give_weapon_x(id, weapons[WEAPON_SCOUT])
		}
		
		case 47:
		{
			give_weapon_x(id, weapons[WEAPON_SG550])
		}
		
		case 48:
		{
			give_weapon_x(id, weapons[WEAPON_AWP])
		}
		
		case 49:
		{
			give_weapon_x(id, weapons[WEAPON_G3SG1])
		}
		
		//Machine gun (M249 Para)
		case 51:
		{
			give_weapon_x(id, weapons[WEAPON_M249]) 
		}
		
		//Shield combos
		case 60:
		{
			give_item(id, weapons[WEAPON_SHIELD])
			give_weapon_x(id, weapons[WEAPON_GLOCK18])
			give_weapon_x(id, weapons[WEAPON_HEGRENADE])
			give_weapon_x(id, weapons[WEAPON_FLASHBANG])
			give_item(id, weapons[ITEM_ASSAULTSUIT])
		}
		
		case 61:
		{
			give_item(id, weapons[WEAPON_SHIELD])
			give_weapon_x(id, weapons[WEAPON_USP])
			give_weapon_x(id, weapons[WEAPON_HEGRENADE])
			give_weapon_x(id, weapons[WEAPON_FLASHBANG])
			give_item(id, weapons[ITEM_ASSAULTSUIT])
		}
		
		case 62:
		{
			give_item(id, weapons[WEAPON_SHIELD])
			give_weapon_x(id, weapons[WEAPON_P228])
			give_weapon_x(id, weapons[WEAPON_HEGRENADE])
			give_weapon_x(id, weapons[WEAPON_FLASHBANG])
			give_item(id, weapons[ITEM_ASSAULTSUIT])
		}
		
		case 63:
		{
			give_item(id, weapons[WEAPON_SHIELD])
			give_weapon_x(id, weapons[WEAPON_DEAGLE])
			give_weapon_x(id, weapons[WEAPON_HEGRENADE])
			give_weapon_x(id, weapons[WEAPON_FLASHBANG])
			give_item(id, weapons[ITEM_ASSAULTSUIT])
		}
		
		case 64:
		{
			give_item(id, weapons[WEAPON_SHIELD])
			give_weapon_x(id, weapons[WEAPON_FIVESEVEN])
			give_weapon_x(id, weapons[WEAPON_HEGRENADE])
			give_weapon_x(id, weapons[WEAPON_FLASHBANG])
			give_item(id, weapons[ITEM_ASSAULTSUIT])
		}
		
		//Equipment 
		case 81:
		{
			give_item(id, weapons[ITEM_KEVLAR])
		}
		
		case 82:
		{
			give_item(id, weapons[ITEM_ASSAULTSUIT])
		}
		
		case 83:
		{
			give_weapon_x(id, weapons[WEAPON_HEGRENADE])
		}
		
		case 84:
		{
			give_weapon_x(id, weapons[WEAPON_FLASHBANG])
		}
		
		case 85:
		{
			give_weapon_x(id, weapons[WEAPON_SMOKEGRENADE])
		}
		
		case 86:
		{
			give_item(id, weapons[ITEM_THIGHPACK])
		}
		
		case 87:
		{
			give_item(id, weapons[WEAPON_SHIELD])
		}
		
		//All ammo
		case 88:
		{
			new iWeapons[32], WeaponNum

			get_user_weapons(id, iWeapons, WeaponNum) 
			for(new i; i < WeaponNum; i++) 
				cs_set_user_bpammo(id, iWeapons[i], bpammo[iWeapons[i]])

		}
		
		//All grenades
		case 89:
		{
			give_weapon_x(id, weapons[WEAPON_HEGRENADE])
			give_weapon_x(id, weapons[WEAPON_SMOKEGRENADE])
			give_weapon_x(id, weapons[WEAPON_FLASHBANG])
		}
		
		//C4
		case 91:
		{
			give_item(id, weapons[WEAPON_C4])
			cs_set_user_plant(id, 1, 1)
		}
		
		case 92:
		{
			cs_set_user_nvg(id, 1)
		}
		
		//AWP Combo.
		case 100:
		{
			give_weapon_x(id, weapons[WEAPON_AWP])
			give_weapon_x(id, weapons[WEAPON_DEAGLE])
			give_weapon_x(id, weapons[WEAPON_HEGRENADE])
			give_weapon_x(id, weapons[WEAPON_FLASHBANG])
			give_weapon_x(id, weapons[WEAPON_SMOKEGRENADE])
			give_item(id, weapons[ITEM_ASSAULTSUIT])
		}
		
		//Money case.
 		case 160:
		{
			cs_set_user_money(id, 16000, 1)
		}
		
		//AllWeapons
		case 200:
		{
			//all up to wpnindex 51 are given.. replace w loop
			give_weapon_x(id, weapons[WEAPON_USP])
			give_weapon_x(id, weapons[WEAPON_GLOCK18])
			give_weapon_x(id, weapons[WEAPON_DEAGLE])
			give_weapon_x(id, weapons[WEAPON_P228])
			give_weapon_x(id, weapons[WEAPON_ELITE])
			give_weapon_x(id, weapons[WEAPON_FIVESEVEN])
			give_weapon_x(id, weapons[WEAPON_M3])
			give_weapon_x(id, weapons[WEAPON_XM1014])
			give_weapon_x(id, weapons[WEAPON_TMP])
			give_weapon_x(id, weapons[WEAPON_MAC10])
			give_weapon_x(id, weapons[WEAPON_MP5NAVY])
			give_weapon_x(id, weapons[WEAPON_P90])
			give_weapon_x(id, weapons[WEAPON_UMP45])
			give_weapon_x(id, weapons[WEAPON_FAMAS])
			give_weapon_x(id, weapons[WEAPON_GALIL])
			give_weapon_x(id, weapons[WEAPON_AK47])
			give_weapon_x(id, weapons[WEAPON_M4A1])
			give_weapon_x(id, weapons[WEAPON_SG552])
			give_weapon_x(id, weapons[WEAPON_AUG])
			give_weapon_x(id, weapons[WEAPON_SCOUT])
			give_weapon_x(id, weapons[WEAPON_SG550])
			give_weapon_x(id, weapons[WEAPON_AWP])
 			give_weapon_x(id, weapons[WEAPON_G3SG1])
			give_weapon_x(id, weapons[WEAPON_M249])
			give_weapon_x(id, weapons[WEAPON_HEGRENADE])
			give_weapon_x(id, weapons[WEAPON_SMOKEGRENADE])
			give_weapon_x(id, weapons[WEAPON_FLASHBANG])
		}
		
		default: return false
	}
	
	return true
}

stock give_weapon_x(id, const weapon[])
{
	give_item(id, weapon)
	
	new weaponid = get_weaponid(weapon)
	
	if(weaponid)
		cs_set_user_bpammo(id, weaponid, bpammo[weaponid])
}


/* 9)	amx_drug
 *--------------
*/
public CmdDrug(id, level, cid)
{
	if(!cmd_access(id, level, cid, 2))
		return PLUGIN_HANDLED
	
	new cmd[24]
	read_argv(1, cmd, 23)
	
	new length[6]
	read_argv(2, length, 2)
	
	if(cmd[0] == '@')
	{
		new players[32], pnum, iPlayer, CmdTeam: Team;

		switch(cmd[1])
		{
			case 't', 'T':	
			{
				get_players(players, pnum, "ae", "TERRORIST");
				Team = T;
			}
			
			case 'c', 'C':
			{
				get_players(players, pnum, "ae", "CT");
				Team = CT;
			}
			
			case 'a', 'A':
			{
				get_players(players, pnum, "a");
				Team = ALL;
			}
		}
		
		for(new i = 0; i < pnum; i++)
		{
			iPlayer = players[i];
			
			if((get_user_flags(iPlayer) & ADMIN_IMMUNITY) && iPlayer != id)
			{
				get_user_name(iPlayer, cmd, charsmax(cmd));
				console_print(id, "%L", "AMX_SUPER_TEAM_IMMUNITY", cmd);
				
				continue;
			}
			
			set_user_drugs(players[i], str_to_num(length));
		}
		
		new name[32], authid[32]

		get_user_name( id, name, 31 )
		get_user_authid( id, authid, 31 )

		show_activity_key("AMX_SUPER_DRUG_TEAM_CASE1", "AMX_SUPER_DRUG_TEAM_CASE2", name, g_TeamNames[Team])

		console_print( id, "%L", id, "AMX_SUPER_DRUG_TEAM_MSG", g_TeamNames[Team])
		log_amx( "%L", LANG_SERVER, "AMX_SUPER_DRUG_TEAM_LOG", name, authid, g_TeamNames[Team])
	}
	else
	{
		new player = cmd_target(id, cmd, CMDTARGET_OBEY_IMMUNITY | CMDTARGET_ALLOW_SELF | CMDTARGET_ONLY_ALIVE);
		
		if(!player)
			return PLUGIN_HANDLED

		set_user_drugs(player, str_to_num(length))
		
		new name[32], authid[32]
		new name2[32], authid2[32]

		get_user_name( id, name, 31 )
		get_user_authid( id, authid, 31 )

		get_user_name( player, name2, 31 )
		get_user_authid( player, authid2, 31 )

		show_activity_key("AMX_SUPER_DRUG_PLAYER_CASE1", "AMX_SUPER_DRUG_PLAYER_CASE2", name, name2)

		console_print( id, "%L", id, "AMX_SUPER_DRUG_PLAYER_MSG", name2 )
		log_amx( "%L", LANG_SERVER, "AMX_SUPER_DRUG_PLAYER_LOG", name, authid, name2, authid2 )
	}
	
	return PLUGIN_HANDLED
}

set_user_drugs(id, x)
{
	switch(x)
	{
		case 1,2:
		{
			message_begin(MSG_ONE, gSetFOVMsg, _, id)
			write_byte(180)
			message_end()
			
			if (x == 2)
				g_iFlags[id] |= PERMDRUGS;
		}
		/*.
		case 1:
		{
			message_begin(MSG_ONE, gSetFOVMsg, _, id)
			write_byte(180)
			message_end()
		}
		
		case 2:
		{
			message_begin(MSG_ONE, gSetFOVMsg, _, id)
			write_byte(180)
			message_end()
			
			// gPermDrugs[id] = true
			g_iFlags[id] |= PERMDRUGS;
		}*/
		
		default:
		{
			message_begin(MSG_ONE, gSetFOVMsg, _, id)
			write_byte(90)
			message_end()
			
			// gPermDrugs[id] = false
			g_iFlags[id] &= ~PERMDRUGS;
		}
	}
}

/*	10)		amx_godmode
 *---------------------
*/
public CmdGodmode(id, level, cid)
{
	if(!cmd_access(id, level, cid, 2))
		return PLUGIN_HANDLED
	
	new name[32]
	get_user_name(id, name, 31)
	
	new AuthId[36]
	get_user_authid(id, AuthId, 35)
	
	new cmd[24]
	read_argv(1, cmd, 23)
	
	new length[6]
	read_argv(2, length, 2)
	
	new godmodesetting = str_to_num(length)
	
	if(cmd[0] == '@')
	{
		new players[32], pnum, tempid, CmdTeam: Team
		
		switch(cmd[1])
		{
			case 't', 'T':	
			{
				get_players(players, pnum, "ae", "TERRORIST");
				Team = T;
			}
			
			case 'c', 'C':
			{
				get_players(players, pnum, "ae", "CT");
				Team = CT;
			}
			
			case 'a', 'A':
			{
				get_players(players, pnum, "a");
				Team = ALL;
			}
		}
		
		for(new i = 0; i < pnum; i++)
		{
			tempid = players[i];
			
			// set_user_godmode(tempid, godmodesetting)
			set_user_godmode(tempid, !!godmodesetting);
			
			if (godmodesetting == 2)
				g_iFlags[tempid] |= PERMGOD
		}
		
		/* removed from *for* loop
			switch(length[0])
			{
				case '0':
				{
					set_user_godmode(tempid, 0);
					// gPermGod[tempid] = false;
					g_iFlags[id] &= ~PERMGOD;
				}
				
				case '1':
					set_user_godmode(tempid, 1);
				
				case '2':
				{
					set_user_godmode(tempid, 1);
					// gPermGod[tempid] = true;
					g_iFlags[id] |= PERMGOD;
				}
			}
		}*/
		
		//godmodesetting = str_to_num(length)
		
		show_activity_key("AMX_SUPER_GODMODE_TEAM_CASE1", "AMX_SUPER_GODMODE_TEAM_CASE2", name, godmodesetting, g_TeamNames[Team])

		console_print(id, "%L", LANG_PLAYER, "AMX_SUPER_GODMODE_TEAM_MSG", godmodesetting, g_TeamNames[Team])
		log_amx("%L", LANG_SERVER, "AMX_SUPER_GODMODE_TEAM_LOG", name, AuthId, godmodesetting, g_TeamNames[Team])
	}
	
	else
	{
		new player = cmd_target(id, cmd, CMDTARGET_ALLOW_SELF | CMDTARGET_ONLY_ALIVE)
		
		if(!player)
			return PLUGIN_HANDLED

		new name2[32]
		get_user_name(player, name2, 31)
		
		// set_user_godmode(player, godmodesetting)
		set_user_godmode(player, !!godmodesetting)
		
		if (godmodesetting == 2)
			g_iFlags[player] |= PERMGOD
			
		/*switch(length[0])
		{
			case '0':
			{
				set_user_godmode(player, 0)
				// gPermGod[player] = false
				g_iFlags[player] &= ~PERMGOD;
			}
			
			case '1':
				set_user_godmode(player, 1)
			
			case '2':
			{
				set_user_godmode(player, 1)
				// gPermGod[id] = true
				g_iFlags[player] |= PERMGOD;
			}
		}*/
		
		//godmodesetting = str_to_num(length)
				
		show_activity_key("AMX_SUPER_GODMODE_PLAYER_CASE1", "AMX_SUPER_GODMODE_PLAYER_CASE2", name, godmodesetting, name2)

		console_print(id, "%L", LANG_PLAYER, "AMX_SUPER_GODMODE_PLAYER_MSG", godmodesetting, name2)
		log_amx("%L", LANG_SERVER, "AMX_SUPER_GODMODE_PLAYER_LOG", name, AuthId, godmodesetting, name2)
	}
	
	return PLUGIN_HANDLED
}

/* 11)	amx_givemoney
 *-------------------
*/
public CmdGiveMoney(id, level, cid)
{
	if(!cmd_access(id, level, cid, 3))
		return PLUGIN_HANDLED
	
	new AuthId[36]
	get_user_authid(id, AuthId, 35)
	
	new name[32]
	get_user_name(id, name, 31)
	
	new arg1[32]
	read_argv(1, arg1, 31)
	
	new arg2[32]
	read_argv(2, arg2, 31)
	
	new money = str_to_num(arg2)
	
	if(arg1[0] == '@')
	{
		new players[32], pnum, tempid, CmdTeam: Team
		
		switch(arg1[1])
		{
			case 't', 'T':	
			{
				get_players(players, pnum, "ae", "TERRORIST");
				Team = T;
			}
			
			case 'c', 'C':
			{
				get_players(players, pnum, "ae", "CT");
				Team = CT;
			}
			
			case 'a', 'A':
			{
				get_players(players, pnum, "a");
				Team = ALL;
			}
		}
		
		new addmoney
		for(new i = 0; i < pnum; i++)	
		{
			tempid = players[i];
			
			addmoney = cs_get_user_money(tempid) + money;
			
			if(addmoney > 16000)
				addmoney = 16000;
			
			cs_set_user_money(tempid, addmoney);
		}
			
			
		
		show_activity_key("AMX_SUPER_GIVEMONEY_TEAM_CASE1", "AMX_SUPER_GIVEMONEY_TEAM_CASE2", name, money, g_TeamNames[Team])
		
		console_print(id, "%L", LANG_PLAYER, "AMX_SUPER_GIVEMONEY_TEAM_MSG", name, money, g_TeamNames[Team])
		log_amx("%L", LANG_SERVER, "AMX_SUPER_GIVEMONEY_TEAM_LOG", name, AuthId, money, g_TeamNames[Team])
	}
	else
	{
		new player = cmd_target(id, arg1, CMDTARGET_ALLOW_SELF)
		if(!player)
			return PLUGIN_HANDLED
		
		new startmoney = cs_get_user_money(player)
		new addmoney = startmoney + money
		
		if( addmoney > 16000 )
			addmoney = 16000
		
		cs_set_user_money(player, addmoney)
		
		new name2[32]
		get_user_name(player, name2, 31)
		
		new AuthId2[36]
		get_user_authid(player, AuthId2, 35)
		
		show_activity_key("AMX_SUPER_GIVEMONEY_PLAYER_CASE1", "AMX_SUPER_GIVEMONEY_PLAYER_CASE2", name, money, name2)
		
		console_print(id, "%L", LANG_PLAYER, "AMX_SUPER_GIVEMONEY_PLAYER_MSG", name, money, name2)
		log_amx("%L", LANG_SERVER, "AMX_SUPER_GIVEMONEY_PLAYER_LOG", name, AuthId, money, name2, AuthId2)
	}
	
	return PLUGIN_HANDLED
}

/* 12)	amx_takemoney
 *-------------------
*/
public CmdTakeMoney(id, level, cid)
{
	if(!cmd_access(id, level, cid, 3))
		return PLUGIN_HANDLED
	
	new name[32]
	get_user_name(id, name, 31)
	
	new AuthId[36]
	get_user_authid(id, AuthId, 35)
	
	new arg1[32]
	read_argv(1, arg1, 31)
	
	new arg2[32]
	read_argv(2, arg2, 31)
	
	new money = str_to_num(arg2)
	
	if(arg1[0] == '@')
	{
		new players[32], pnum, tempid, CmdTeam: Team

		switch(arg1[1])
		{
			case 't', 'T':	
			{
				get_players(players, pnum, "ae", "TERRORIST");
				Team = T;
			}
			
			case 'c', 'C':
			{
				get_players(players, pnum, "ae", "CT");
				Team = CT;
			}
			
			case 'a', 'A':
			{
				get_players(players, pnum, "a");
				Team = ALL;
			}
		}
		
		new takemoney;
		for(new i = 0; i < pnum; i++)
		{
			tempid = players[i];
			
			if((get_user_flags(tempid) & ADMIN_IMMUNITY) && tempid != id)
			{
				get_user_name(tempid, arg2, charsmax(arg2));
				console_print(id, "%L", "AMX_SUPER_TEAM_IMMUNITY", arg2);
				
				continue;
			}
			
			takemoney = cs_get_user_money(tempid) - money;
			
			if(takemoney < 0)
				takemoney = 0;
				
			cs_set_user_money(tempid, takemoney);
		}
			
					
		show_activity_key("AMX_SUPER_TAKEMONEY_TEAM_CASE1", "AMX_SUPER_TAKEMONEY_TEAM_CASE2", name, money, g_TeamNames[Team])
		
		console_print(id, "%L", LANG_PLAYER, "AMX_SUPER_TAKEMONEY_TEAM_MSG", name, money, g_TeamNames[Team])
		log_amx("%L", LANG_SERVER, "AMX_SUPER_TAKEMONEY_TEAM_LOG", name, AuthId, money, g_TeamNames[Team])
	}
	else
	{
		new player = cmd_target(id, arg1, CMDTARGET_OBEY_IMMUNITY | CMDTARGET_ALLOW_SELF)
		if(!player)
			return PLUGIN_HANDLED
		
		new startmoney = cs_get_user_money(player)
		new submoney = startmoney - money
		
		if(submoney < 0)
			submoney = 0
		
		cs_set_user_money(player, submoney)
		
		new name2[32]
		get_user_name(player, name2, 31)
		
		new AuthId2[36]
		get_user_authid(player, AuthId2, 35)
		
		show_activity_key("AMX_SUPER_TAKEMONEY_TEAM_CASE1", "AMX_SUPER_TAKEMONEY_TEAM_CASE2", name, money, name2)
		
		console_print(id, "%L", LANG_PLAYER, "AMX_SUPER_TAKEMONEY_TEAM_MSG", name, money, name2)
		log_amx("%L", LANG_SERVER, "AMX_SUPER_TAKEMONEY_TEAM_LOG", name, AuthId, money, name2, AuthId2)
	}
	
	return PLUGIN_HANDLED
}

/* 13)	amx_noclip
 *----------------
*/
public CmdNoclip(id, level, cid)
{
	if(!cmd_access(id, level, cid, 2))
		return PLUGIN_HANDLED
	
	//new noclipsetting
	
	new name[32]
	get_user_name(id, name, 31)
	
	new AuthId[36]
	get_user_authid(id, AuthId, 35)
	
	new cmd[24]
	read_argv(1, cmd, 23)
	
	new length[6]
	read_argv(2, length, 2)
	
	//added
	new noclipsetting = str_to_num(length)
	
	if(cmd[0] == '@')
	{
		new players[32], pnum, tempid, CmdTeam: Team
	
		switch(cmd[1])
		{
			case 't', 'T':	
			{
				get_players(players, pnum, "ae", "TERRORIST");
				Team = T;
			}
			
			case 'c', 'C':
			{
				get_players(players, pnum, "ae", "CT");
				Team = CT;
			}
			
			case 'a', 'A':
			{
				get_players(players, pnum, "a");
				Team = ALL;
			}
		}
		
		for(new i = 0; i < pnum; i++)
		{
			tempid = players[i];
			
			//added
			// set_user_noclip(tempid, noclipsetting)
			set_user_noclip(tempid, !!noclipsetting);
			
			if (noclipsetting == 2)
				g_iFlags[tempid] |= PERMNOCLIP
		}
		
		// removed from for loop
		/*	switch(length[0])
			{
				case '0':
				{
					set_user_noclip(tempid, 0)
					// gPermNoclip[tempid] = false
					g_iFlags[tempid] &= ~PERMNOCLIP;
				}
				
				case '1':
					set_user_noclip(tempid, 1)
				
				case '2':
				{
					set_user_noclip(tempid, 1)
					// gPermNoclip[tempid] = true
					g_iFlags[tempid] |= PERMNOCLIP;
				}
			}
		}*/
		
		//noclipsetting = str_to_num(length)
		
		show_activity_key("AMX_SUPER_NOCLIP_TEAM_CASE1", "AMX_SUPER_NOCLIP_TEAM_CASE2", name, noclipsetting, g_TeamNames[Team])
		
		console_print(id,"%L", LANG_PLAYER, "AMX_SUPER_NOCLIP_TEAM_MSG", noclipsetting, g_TeamNames[Team])
		log_amx("%L", LANG_SERVER, "AMX_SUPER_NOCLIP_TEAM_LOG", name, AuthId, noclipsetting, g_TeamNames[Team])
	}
	else
	{
		new player = cmd_target(id, cmd, CMDTARGET_ALLOW_SELF | CMDTARGET_ONLY_ALIVE)
		if(!player)
			return PLUGIN_HANDLED

		new name2[32]
		get_user_name(player, name2, 31)
		
		new AuthId2[36]
		get_user_authid(player, AuthId2, 35)
		
		// added
		// set_user_noclip(player, noclipsetting)
		set_user_noclip(player, !!noclipsetting);
		
		if (noclipsetting == 2)
			g_iFlags[player] |= PERMNOCLIP;
	
		/*switch(length[0])
		{
			case '0':
			{
				set_user_noclip(player, 0)
				// gPermNoclip[id] = false
				g_iFlags[player] &= ~PERMNOCLIP;
			}
			
			case '1':
				set_user_noclip(player, 1)
			
			case '2':
			{
				set_user_noclip(player, 1)
				// gPermNoclip[id] = true
				g_iFlags[player] |= PERMNOCLIP;
			}
		}*/
		
		//noclipsetting = str_to_num(length)
		
		show_activity_key("AMX_SUPER_NOCLIP_PLAYER_CASE1", "AMX_SUPER_NOCLIP_PLAYER_CASE2", name, noclipsetting, name2)

		console_print(id,"%L", LANG_PLAYER, "AMX_SUPER_NOCLIP_PLAYER_MSG",noclipsetting, name2)
		log_amx("%L", LANG_SERVER, "AMX_SUPER_NOCLIP_PLAYER_LOG", name, AuthId, noclipsetting, name2, AuthId2)
	}
	
	return PLUGIN_HANDLED
}

/* 14)	amx_speed
 *---------------
*/
public LogEventRoundStart()
	gFreezeTime = false

public EventFreezeTime()
	gFreezeTime = true 
	
public FwdPlayerSpeedPost(id)
{
	// if((gHasSpeed[id] || gPermSpeed[id]) && !gFreezeTime)
	if(!gFreezeTime && (g_iFlags[id] & HASSPEED) || (g_iFlags[id] & PERMSPEED))
		SetSpeed(id, 1)
}
		
public CmdSpeed(id, level, cid)
{
	if(!cmd_access(id, level, cid, 2))
		return PLUGIN_HANDLED
	
	new name[32]
	get_user_name(id, name, 31)
	
	new AuthId[36]
	get_user_authid(id, AuthId, 35)
	
	new cmd[24]
	read_argv(1, cmd, 23)
	
	new length[6]
	read_argv(2, length, 2)
	
	// added
	new speedsetting = str_to_num(length)
	
	if(cmd[0] == '@')
	{
		new players[32], pnum, tempid, CmdTeam: Team
		
		switch(cmd[1])
		{
			case 't', 'T':	
			{
				get_players(players, pnum, "ae", "TERRORIST");
				Team = T;
			}
			
			case 'c', 'C':
			{
				get_players(players, pnum, "ae", "CT");
				Team = CT;
			}
			
			case 'a', 'A':
			{
				get_players(players, pnum, "a");
				Team = ALL;
			}
		}
		
		for(new i = 0; i < pnum; i++)
		{
			tempid = players[i];
			
			// [HERE] -> Modified SetSpeed function to set perm variables
			SetSpeed(tempid, speedsetting)
		}
			/*switch(length[0])
			{
				case '0':
				{
					SetSpeed(tempid, 0);
					
					// gHasSpeed[tempid] = false;
					// gPermSpeed[tempid] = false;
					g_iFlags[tempid] &= ~HASSPEED;
					g_iFlags[tempid] &= ~PERMSPEED;
				}
				
				case '1':
				{
					SetSpeed(tempid, 1);
					
					// gHasSpeed[tempid] = true;
					g_iFlags[tempid] |= HASSPEED;
				}
				
				
				case '2':
				{
					SetSpeed(tempid, 1);
					
					g_iFlags[tempid] |= PERMSPEED;
				}
			}
		}*/
		
		//speedsetting = str_to_num(length)
		
		show_activity_key("AMX_SUPER_SPEED_TEAM_CASE1", "AMX_SUPER_SPEED_TEAM_CASE2", name, speedsetting, g_TeamNames[Team])

		console_print(id, "%L", LANG_PLAYER, "AMX_SUPER_SPEED_TEAM_MSG", speedsetting, g_TeamNames[Team])
		log_amx("%L", LANG_SERVER, "AMX_SUPER_SPEED_TEAM_LOG", name, AuthId, speedsetting, g_TeamNames[Team])
	}
	else
	{
		new player = cmd_target(id, cmd, CMDTARGET_ALLOW_SELF | CMDTARGET_ONLY_ALIVE)
		if(!player)
			return PLUGIN_HANDLED

		new name2[32]
		get_user_name(player, name2, 31)
		
		// [HERE] -> Modified SetSpeed function to set perm variables
		SetSpeed(player, speedsetting)
		
		/*switch(length[0])
		{
			case '0':
			{
				SetSpeed(player, 0)
				
				// gHasSpeed[id] = false
				// gPermSpeed[id] = false
				g_iFlags[player] &= ~HASSPEED;
				g_iFlags[player] &= ~PERMSPEED;
			}
				
			case '1':
			{
				SetSpeed(player, 1)
				// gHasSpeed[id] = true
				g_iFlags[player] |= HASSPEED;
			}
				
			case '2':
			{
				SetSpeed(player, 1)
				// gPermSpeed[id] = true
				g_iFlags[player] |= PERMSPEED;
			}
		}*/
		
		//speedsetting = str_to_num(length)
				
		show_activity_key("AMX_SUPER_SPEED_PLAYER_CASE1", "AMX_SUPER_SPEED_PLAYER_CASE2", name, speedsetting, name2)

		console_print(id, "%L", LANG_PLAYER, "AMX_SUPER_SPEED_PLAYER_MSG", speedsetting, name2)
		log_amx("%L", LANG_SERVER, "AMX_SUPER_SPEED_PLAYER_LOG", name, AuthId, speedsetting, name2)
	}
	
	return PLUGIN_HANDLED
}

SetSpeed(id, setting)
{
	if(!setting)
	{
		// Provided by ConnorMcLeod from cs_reset_user_maxspeed function in some of his plugns
		new Float:flMaxSpeed;
		
		switch ( get_user_weapon(id) )
		{
			case CSW_SG550, CSW_AWP, CSW_G3SG1 : flMaxSpeed = 210.0;
			case CSW_M249 : flMaxSpeed = 220.0;
			case CSW_AK47 : flMaxSpeed = 221.0;
			case CSW_M3, CSW_M4A1 : flMaxSpeed = 230.0;
			case CSW_SG552 : flMaxSpeed = 235.0;
			case CSW_XM1014, CSW_AUG, CSW_GALIL, CSW_FAMAS : flMaxSpeed = 240.0;
			case CSW_P90 : flMaxSpeed = 245.0;
			case CSW_SCOUT : flMaxSpeed = 260.0;
			default : flMaxSpeed = 250.0;
		}
		set_user_maxspeed(id, flMaxSpeed);
		
		// ADDED
		g_iFlags[id] &= ~HASSPEED;
		g_iFlags[id] &= ~PERMSPEED;
	}
	
	else
	{
		// ADDED - untested
		new Flag = setting == 2 ? PERMSPEED : HASSPEED
		g_iFlags[id] |= Flag
		
		new Float:speed = get_user_maxspeed(id)
		
		set_user_maxspeed(id, (speed * 2.0))
	}
}

/* 15)	amx_revive
 *----------------
*/
public CmdRevive(id, level, cid)
{
	if(!cmd_access(id, level, cid, 2))
		return PLUGIN_HANDLED
	
	new cmd[24]
	read_argv(1, cmd, 23)
	
	new name[34]
	get_user_name(id, name, 33)
	
	new AuthId[36]
	get_user_authid(id, AuthId, 35)
	
	if(cmd[0] == '@')
	{
		new players[32], pnum, iPlayer, CmdTeam: Team
		get_players(players, pnum);
		
		/*
			| Fixed bug:
			| get_players() used a (alive only) flag to get the players.
			| and because the e flag is bugged without the a flag, we have to check the team in the loop.
		*/
		switch(cmd[1])
		{
			case 't', 'T':	
			{
				// get_players(players, pnum, "ae", "TERRORIST");
				Team = T;
			}
			
			case 'c', 'C':
			{
				// get_players(players, pnum, "ae", "CT");
				Team = CT;
			}
			
			case 'a', 'A':
			{
				// get_players(players, pnum);
				Team = ALL;
			}
		}		
		
		
		for(new i = 0; i < pnum; i++)
		{
			iPlayer = players[i];
			
			switch(Team)
			{
				case T:
				{
					if(cs_get_user_team(iPlayer) == CS_TEAM_T)
						ExecuteHamB(Ham_Spawn, iPlayer);
				}
				
				case CT:
				{
					if(cs_get_user_team(iPlayer) == CS_TEAM_CT)
						ExecuteHamB(Ham_Spawn, iPlayer);
				}
				
				case ALL:
				{
					if(CS_TEAM_UNASSIGNED < cs_get_user_team(iPlayer) < CS_TEAM_SPECTATOR)
						ExecuteHamB(Ham_Spawn, iPlayer);
				}
			}
			
			//ExecuteHam(Ham_Spawn, players[i]);
			// should we use Ham_CS_RoundRespawn ¿? Don't know, but modified to ExecuteHamB
			// ExecuteHamB(Ham_Spawn, players[i])
		}
		show_activity_key("AMX_SUPER_REVIVE_TEAM_CASE1", "AMX_SUPER_REVIVE_TEAM_CASE2", name, g_TeamNames[Team])
	
		console_print(id,"%L", LANG_PLAYER, "AMX_SUPER_REVIVE_TEAM_MSG", g_TeamNames[Team])
		log_amx("%L", LANG_SERVER, "AMX_SUPER_REVIVE_TEAM_LOG", name, AuthId, g_TeamNames[Team])
	}
	else
	{
		new player = cmd_target(id, cmd, CMDTARGET_ALLOW_SELF)
		if(!player)
			return PLUGIN_HANDLED

		// should we use Ham_CS_RoundRespawn ¿? Don't know, but modified to ExecuteHamB
		//ExecuteHam(Ham_Spawn, player)
		ExecuteHamB(Ham_Spawn, player)
		
		new name2[34]
		get_user_name(player, name2, 33)
		
		new AuthId2[36]
		get_user_authid(player, AuthId2, 35)
		
		show_activity_key("AMX_SUPER_REVIVE_PLAYER_CASE1", "AMX_SUPER_REVIVE_PLAYER_CASE2", name, name2)
		
		console_print(id,"%L", LANG_PLAYER, "AMX_SUPER_REVIVE_PLAYER_MSG", name2)
		log_amx("%L", LANG_SERVER, "AMX_SUPER_REVIVE_PLAYER_LOG",name, AuthId2, name2, AuthId2)
	}
	
	return PLUGIN_HANDLED
}

/* 16)	amx_bury
 *--------------
*/
public Cmd_Bury(id, level, cid)
{
	if(!cmd_access(id, level, cid, 2))
		return PLUGIN_HANDLED;
	
	new target[32];
	read_argv(1, target, charsmax(target));
	
	new TargetName[32];
	
	new AdminName[32];
	get_user_name(id, AdminName, charsmax(AdminName));
	
	new AuthID[25];
	get_user_authid(id, AuthID, charsmax(AuthID));
		
	new tempid;
	
	if(target[0] == '@')
	{
		new players[32], pnum, CmdTeam: team;
		
		switch(target[1])
		{
			case 'A', 'a':
			{
				get_players(players, pnum, "a");
				
				team = ALL;
			}
			
			case 'T', 't':
			{
				get_players(players, pnum, "ae", "TERRORIST");
				
				team = T;
			}
			
			case 'C', 'c':
			{
				get_players(players, pnum, "ae", "CT");
				
				team = CT;
			}
		}
		
		if(!pnum)
		{
			console_print(id, "%L", id, "AMX_SUPER_NO_PLAYERS");
			
			return PLUGIN_HANDLED;
		}
		
		for(new i = 0; i < pnum; i++)
		{
			tempid = players[i];
			
			if((get_user_flags(tempid) & ADMIN_IMMUNITY) && tempid != id)
			{
				get_user_name(tempid, TargetName, charsmax(TargetName));
				console_print(id, "%L", id, "AMX_SUPER_TEAM_IMMUNITY", TargetName);
				
				continue;
			}
				
			BuryPlayer(tempid);
		}
		
		show_activity_key("AMX_SUPER_BURY_TEAM_CASE1", "AMX_SUPER_BURY_TEAM_CASE2", AdminName, g_TeamNames[team]);
		
		log_amx("%L", LANG_SERVER, "AMX_SUPER_BURY_TEAM_LOG", AdminName, AuthID, g_TeamNames[team]);
	}
	
	else
	{
		tempid = cmd_target(id, target, CMDTARGET_OBEY_IMMUNITY | CMDTARGET_ALLOW_SELF | CMDTARGET_ONLY_ALIVE);
		
		if(tempid)
		{
			BuryPlayer(tempid);
			
			get_user_name(tempid, TargetName, charsmax(TargetName));
			
			
			new TempAuthID[25];
			get_user_authid(tempid, TempAuthID, charsmax(TempAuthID));
			
			log_amx("%L", LANG_SERVER, "AMX_SUPER_BURY_PLAYER_LOG", AdminName, AuthID, TargetName, TempAuthID);
			show_activity_key("AMX_SUPER_BURY_PLAYER_CASE1", "AMX_SUPER_BURY_PLAYER_CASE2", AdminName, TargetName);

			console_print(id, "%L", id, "AMX_SUPER_BURY_MSG", TargetName);
		}
	}
	
	return PLUGIN_HANDLED;
}

BuryPlayer(tempid)
{
	new VicName[32];
	get_user_name(tempid, VicName, charsmax(VicName));
	
	new Weapons[32], Weapon;
	get_user_weapons(tempid, Weapons, Weapon);
	
	new WeaponName[32];
	for(new i = 0; i < Weapon; i++)
	{
		get_weaponname(Weapons[i], WeaponName, charsmax(WeaponName));
		engclient_cmd(tempid, "drop", WeaponName);
	}
	
	engclient_cmd(tempid, "weapon_knife");
	
	new Float: Origin[3];
	pev(tempid, pev_origin, Origin);
	
	Origin[2] -= 30.0;
	// set_pev(tempid, pev_origin, Origin);
	engfunc(EngFunc_SetOrigin, tempid, Origin);
}

/*	17)		amx_unbury
 *--------------------
*/
public Cmd_Unbury(id, level, cid)
{
	if(!cmd_access(id, level, cid, 2))
		return PLUGIN_HANDLED;
		
	new target[32];
	read_argv(1, target, charsmax(target));
	
	new TargetName[32];
	
	new AdminName[32];
	get_user_name(id, AdminName, charsmax(AdminName));
	
	new AuthID[25];
	get_user_authid(id, AuthID, charsmax(AuthID));
		
	new tempid;
	
	if(target[0] == '@')
	{	
		new players[32], pnum, CmdTeam: team;
	
		switch(target[1])
		{
			case 'A', 'a':
			{
				get_players(players, pnum, "a");
				
				team = ALL;
			}
			
			case 'T', 't':
			{
				get_players(players, pnum, "ae", "TERRORIST");
				
				team = T;
			}
			
			case 'C', 'c':
			{
				get_players(players, pnum, "ae", "CT");
				
				team = CT;
			}
		}
		
		if(!pnum)
		{
			console_print(id, "%L", id, "AMX_SUPER_NO_PLAYERS");
			
			return PLUGIN_HANDLED;
		}
		
		for(new i = 0; i < pnum; i++)
		{			
			tempid = players[i];
			
			if((get_user_flags(tempid) & ADMIN_IMMUNITY) && tempid != id)
			{
				get_user_name(tempid, TargetName, charsmax(TargetName));
				console_print(id, "%L", id, "AMX_SUPER_TEAM_IMMUNITY", TargetName);
				
				continue;
			}
			
			UnburyPlayer(tempid);
		}
			
		show_activity_key("AMX_SUPER_UNBURY_TEAM_CASE1", "AMX_SUPER_UNBURY_TEAM_CASE2", AdminName, g_TeamNames[team]);
		log_amx("%L", LANG_SERVER, "AMX_SUPER_UNBURY_TEAM_LOG", AdminName, AuthID, g_TeamNames[team]);
	}
	
	else
	{
		tempid = cmd_target(id, target, CMDTARGET_OBEY_IMMUNITY | CMDTARGET_ALLOW_SELF | CMDTARGET_ONLY_ALIVE);
		
		if(tempid)
		{
			UnburyPlayer(tempid);
			
			get_user_name(tempid, TargetName, charsmax(TargetName));
			
			
			
			new TempAuthID[25];
			get_user_authid(tempid, TempAuthID, charsmax(TempAuthID));

			log_amx("%L", LANG_SERVER, "AMX_SUPER_UNBURY_PLAYER_LOG", AdminName, AuthID, TargetName, TempAuthID);
			show_activity_key("AMX_SUPER_UNBURY_PLAYER_CASE1", "AMX_SUPER_UNBURY_PLAYER_CASE2", AdminName, TargetName);
			
			console_print(id, "%L", id, "AMX_SUPER_UNBURY_MSG", TargetName);
			
		}
	}

	return PLUGIN_HANDLED;
}

UnburyPlayer(tempid)
{
	new VicName[32];
	get_user_name(tempid, VicName, charsmax(VicName));
	
	new Float: Origin[3];
	pev(tempid, pev_origin, Origin);
	
	Origin[2] += 35.0;
	// set_pev(tempid, pev_origin, Origin);
	engfunc(EngFunc_SetOrigin, tempid, Origin);
}

/* 18)	amx_disarm
 *----------------
*/
public Cmd_Disarm(id, level, cid)
{
	if(!cmd_access(id, level, cid, 1))
		return PLUGIN_HANDLED;
	
	new target[35];
	read_argv(1, target, charsmax(target));
	
	new AdminName[35], TargetName[35];
	get_user_name(id, AdminName, charsmax(AdminName));
	
	new AuthID[35];
	get_user_authid(id, AuthID, charsmax(AuthID));
	
	new tempid;
	
	if(target[0] == '@')
	{
		new players[32], pnum, CmdTeam: team;
		
		switch(target[1])
		{
			case 'A', 'a':
			{
				get_players(players, pnum, "a");
				
				team = ALL;
			}
			
			case 'T', 't':
			{
				get_players(players, pnum, "ae", "TERRORIST");
				
				team = T;
			}
			
			case 'C', 'c':
			{
				get_players(players, pnum, "ae", "CT");
				
				team = CT;
			}
		}
		
		if(!pnum)
		{
			console_print(id, "%L", id, "AMX_SUPER_NO_PLAYERS");
			
			return PLUGIN_HANDLED;
		}
		
		for(new i = 0; i < pnum; i++)
		{
			tempid = players[i];
			
			if((get_user_flags(tempid) & ADMIN_IMMUNITY) && tempid != id)
			{
				get_user_name(tempid, TargetName, charsmax(TargetName));
				console_print(id, "%L", id, "AMX_SUPER_TEAM_IMMUNITY", TargetName);
				
				continue;
			}
			
			strip_user_weapons(tempid);
			set_pdata_int(tempid, OFFSET_PRIMARYWEAPON, 0);		// Bugfix.
			give_item(tempid, "weapon_knife");
		}
			
		show_activity_key("AMX_SUPER_DISARM_TEAM_CASE1", "AMX_SUPER_DISARM_TEAM_CASE2", AdminName, g_TeamNames[team]);
		log_amx("%L", LANG_SERVER, "AMX_SUPER_DISARM_TEAM_LOG", AdminName, AuthID, g_TeamNames[team]);
	}
	
	else
	{
		tempid = cmd_target(id, target, CMDTARGET_OBEY_IMMUNITY | CMDTARGET_ALLOW_SELF | CMDTARGET_ONLY_ALIVE);
		
		if(tempid)
		{
			strip_user_weapons(id);
			set_pdata_int(id, OFFSET_PRIMARYWEAPON, 0);
			give_item(id, "weapon_knife");
			
			get_user_name(tempid, TargetName, charsmax(TargetName));
					
			new TempAuthID[25];
			get_user_authid(tempid, TempAuthID, charsmax(TempAuthID));
			
			log_amx("%L", LANG_SERVER, "AMX_SUPER_DISARM_PLAYER_LOG", AdminName, AuthID, TargetName, TempAuthID);
			show_activity_key("AMX_SUPER_DISARM_PLAYER_CASE1", "AMX_SUPER_DISARM_PLAYER_CASE2", AdminName, TargetName);

			console_print(id, "%L", id, "AMX_SUPER_DISARM_MSG", TargetName);
		}
	}
	
	return PLUGIN_HANDLED;
}

/* 19)	amx_slay2
 *---------------
*/
public Cmd_Slay2(id, level, cid)
{
	if(!cmd_access(id, level, cid, 2))
		return PLUGIN_HANDLED;
		
	new target[35], method[2];
	
	new AdminName[35], TargetName[35];
	get_user_name(id, AdminName, charsmax(AdminName));
	
	new AuthID[35];
	get_user_authid(id, AuthID, charsmax(AuthID));
	
	new tempid, CmdTeam: team;
	
	read_argv(1, target, charsmax(target));
	read_argv(2, method, charsmax(method));
	
	if(target[0] == '@')
	{
		new players[32], pnum;
		
		switch(target[1])
		{
			case 'A', 'a':
			{
				get_players(players, pnum, "a");
				
				team = ALL;
			}
			
			case 'T', 't':
			{
				get_players(players, pnum, "ae", "TERRORIST");
				
				team = T;
			}
			
			case 'C', 'c':
			{
				get_players(players, pnum, "ae", "CT");
				
				team = CT;
			}
		}
		
		if(!pnum)
		{
			console_print(id, "%L", id, "AMX_SUPER_NO_PLAYERS");
			
			return PLUGIN_HANDLED;
		}
		
		for(new i = 0; i < pnum; i++)
		{
			tempid = players[i];
			
			if((get_user_flags(tempid) & ADMIN_IMMUNITY) && tempid != id)
			{
				get_user_name(tempid, TargetName, charsmax(TargetName));
				console_print(id, "%L", id, "AMX_SUPER_TEAM_IMMUNITY", TargetName);
				
				continue;
			}
			
			slay_player(tempid, str_to_num(method));
		}
			
		show_activity_key("AMX_SUPER_SLAY2_TEAM_CASE1", "AMX_SUPER_SLAY2_TEAM_CASE2", AdminName, g_TeamNames[team]);
		log_amx("%L", LANG_SERVER, "AMX_SUPER_SLAY2_TEAM_LOG", AdminName, AuthID, g_TeamNames[team]);
	}
	
	else
	{
		tempid = cmd_target(id, target, CMDTARGET_OBEY_IMMUNITY | CMDTARGET_ALLOW_SELF | CMDTARGET_ONLY_ALIVE);
		
		if(tempid)
		{
			slay_player(tempid, str_to_num(method));
			
			get_user_name(tempid, TargetName, charsmax(TargetName));
			
			
			new TempAuthID[25];
			get_user_authid(tempid, TempAuthID, charsmax(TempAuthID));
			
			log_amx("%L", LANG_SERVER, "AMX_SUPER_SLAY2_PLAYER_LOG", AdminName, AuthID, TargetName, TempAuthID);
			show_activity_key("AMX_SUPER_SLAY2_PLAYER_CASE1", "AMX_SUPER_SLAY2_PLAYER_CASE2", AdminName, TargetName);
			
			console_print(id, "%L", id, "AMX_SUPER_SLAY2_MSG", TargetName);
		}
	}
	
	return PLUGIN_HANDLED;
}

slay_player(victim,type)
{
	new origin[3], srco[3];
	get_user_origin(victim, origin);

	origin[2] -= 26;
	srco[0] = origin[0] + 150;
	srco[1] = origin[1] + 150;
	srco[2] = origin[2] + 400;

	switch(type)
	{
		case 1:
		{
			lightning(srco,origin);
			emit_sound(victim,CHAN_ITEM, "ambience/thunder_clap.wav", 1.0, ATTN_NORM, 0, PITCH_NORM);
		}
		
		case 2:
		{
			blood(origin);
			emit_sound(victim,CHAN_ITEM, "weapons/headshot2.wav", 1.0, ATTN_NORM, 0, PITCH_NORM);
		}
		case 3: 
			explode(origin);
	}
	
	user_kill(victim, 1);
}

explode(vec1[3]) 
{
	//Blast Circles
	message_begin(MSG_BROADCAST, SVC_TEMPENTITY, vec1);
	write_byte(21);
	write_coord(vec1[0]);
	write_coord(vec1[1]);
	write_coord(vec1[2] + 16);
	write_coord(vec1[0]);
	write_coord(vec1[1]);
	write_coord(vec1[2] + 1936);
	write_short(white);
	write_byte(0); // startframe
	write_byte(0); // framerate
	write_byte(2); // life
	write_byte(16); // width
	write_byte(0); // noise
	write_byte(188); // r
	write_byte(220); // g
	write_byte(255); // b
	write_byte(255); //brightness
	write_byte(0); // speed
	message_end();

	//Explosion2
	message_begin(MSG_BROADCAST, SVC_TEMPENTITY);
	write_byte(12);
	write_coord(vec1[0]);
	write_coord(vec1[1]);
	write_coord(vec1[2]);
	write_byte(188); // byte (scale in 0.1's)
	write_byte(10); // byte (framerate)
	message_end();

	//Smoke
	message_begin(MSG_BROADCAST, SVC_TEMPENTITY, vec1);
	write_byte(5);
	write_coord(vec1[0]);
	write_coord(vec1[1]);
	write_coord(vec1[2]);
	write_short(smoke);
	write_byte(2);
	write_byte(10);
	message_end();
}

blood(vec1[3]) 
{
	//LAVASPLASH
	message_begin(MSG_BROADCAST, SVC_TEMPENTITY);
	write_byte(10);
	write_coord(vec1[0]);
	write_coord(vec1[1]);
	write_coord(vec1[2]);
	message_end();
}

lightning (vec1[3],vec2[3]) 
{
	//Lightning
	message_begin(MSG_BROADCAST, SVC_TEMPENTITY);
	write_byte(0);
	write_coord(vec1[0]);
	write_coord(vec1[1]);
	write_coord(vec1[2]);
	write_coord(vec2[0]);
	write_coord(vec2[1]);
	write_coord(vec2[2]);
	write_short(light);
	write_byte(1); // framestart
	write_byte(5); // framerate
	write_byte(2); // life
	write_byte(20); // width
	write_byte(30); // noise
	write_byte(200); // r, g, b
	write_byte(200); // r, g, b
	write_byte(200); // r, g, b
	write_byte(200); // brightness
	write_byte(200); // speed
	message_end();

	//Sparks
	message_begin(MSG_PVS, SVC_TEMPENTITY, vec2);
	write_byte(9);
	write_coord(vec2[0]);
	write_coord(vec2[1]);
	write_coord(vec2[2]);
	message_end();

	//Smoke
	message_begin(MSG_BROADCAST, SVC_TEMPENTITY, vec2);
	write_byte(5);
	write_coord(vec2[0]);
	write_coord(vec2[1]);
	write_coord(vec2[2]);
	write_short(smoke);
	write_byte(10);
	write_byte(10);
	message_end();
}

/* 20)	amx_rocket
 *----------------
*/
new rocket_z[33];

public Cmd_Rocket(id, level, cid)
{
	if(!cmd_access(id, level, cid, 1))
		return PLUGIN_HANDLED;
		
	new target[35];
	read_argv(1, target, charsmax(target));
	
	new AdminName[35], TargetName[35], Authid[35];
	get_user_name(id, AdminName, charsmax(AdminName));
	get_user_authid(id, Authid, charsmax(Authid));
	
	new tempid;
	
	if(target[0] == '@')
	{
		new players[32], pnum, CmdTeam: team;
		
		switch(target[1])
		{
			case 'A', 'a':
			{
				get_players(players, pnum, "a");
				
				team = ALL;
			}
			
			case 'T', 't':
			{
				get_players(players, pnum, "ae", "TERRORIST");
				
				team = T;
			}
			
			case 'C', 'c':
			{
				get_players(players, pnum, "ae", "CT");
				
				team = CT;
			}
		}
		
		if(!pnum)
		{
			console_print(id, "%L", id, "AMX_SUPER_NO_PLAYERS");
			
			return PLUGIN_HANDLED;
		}
		
		for(new i = 0; i < pnum; i++)
		{
			tempid = players[i];
			
			if((get_user_flags(tempid) & ADMIN_IMMUNITY) && id != tempid)
			{	
				get_user_name(tempid, TargetName, charsmax(TargetName));
				
				console_print(id, "%L", id, "AMX_SUPER_TEAM_IMMUNITY", TargetName);
				
				continue;
			}
			
			emit_sound(tempid, CHAN_WEAPON , "weapons/rocketfire1.wav", 1.0, ATTN_NORM, 0, PITCH_NORM);
			set_user_maxspeed(tempid,0.01);
			
			set_task(1.2, "Task_Rocket_LiftOff" , tempid);
		}
		
		console_print(id, "%L", id, "AMX_SUPER_ROCKET_TEAM_MSG", g_TeamNames[team]);
		
		show_activity_key("AMX_SUPER_ROCKET_CASE1", "AMX_SUPER_ROCKET_CASE2", AdminName, g_TeamNames[team]);
		log_amx("%L", LANG_SERVER, "AMX_SUPER_ROCKET_TEAM_LOG", AdminName, Authid, g_TeamNames[team]);
	}
	
	else
	{
		tempid = cmd_target(id, target, CMDTARGET_OBEY_IMMUNITY | CMDTARGET_ALLOW_SELF | CMDTARGET_ONLY_ALIVE);
		
		if(tempid)
		{
			emit_sound(tempid, CHAN_WEAPON, "weapons/rocketfire1.wav", 1.0, ATTN_NORM, 0, PITCH_NORM);
			set_user_maxspeed(tempid, 0.01);
			
			set_task(1.2, "Task_Rocket_LiftOff", tempid);
			
			new TempAuthid[35];
			get_user_authid(tempid, TempAuthid, charsmax(TempAuthid));
			get_user_name(tempid, TargetName, charsmax(TargetName));
						
			show_activity_key("AMX_SUPER_ROCKET_PLAYER_CASE1", "AMX_SUPER_ROCKET_PLAYER_CASE2", AdminName, TargetName);
			log_amx("%L", LANG_SERVER, "AMX_SUPER_ROCKET_PLAYER_LOG", AdminName, Authid, TargetName, TempAuthid);
			
			console_print(id, "%L", id, "AMX_SUPER_ROCKET_PLAYER_MSG", TargetName);
		}
	}
	
	return PLUGIN_HANDLED;
}
		
public Task_Rocket_LiftOff(victim)
{
	if(!is_user_alive(victim))
		return;
		
	set_user_gravity(victim, -0.50);
	client_cmd(victim, "+jump;wait;wait;-jump");
	emit_sound(victim, CHAN_VOICE, "weapons/rocket1.wav", 1.0, 0.5, 0, PITCH_NORM);
	
	rocket_effects(victim);
}

public rocket_effects(victim)
{
	if(!is_user_alive(victim)) 
		return;

	new vorigin[3];
	get_user_origin(victim,vorigin);

	message_begin(MSG_ONE, g_Msg_Damage, {0,0,0}, victim);
	write_byte(30); // dmg_save
	write_byte(30); // dmg_take
	write_long(1<<16); // visibleDamageBits
	write_coord(vorigin[0]); // damageOrigin.x
	write_coord(vorigin[1]); // damageOrigin.y
	write_coord(vorigin[2]); // damageOrigin.z
	message_end();

	if(rocket_z[victim] == vorigin[2]) 
		rocket_explode(victim);

	rocket_z[victim] = vorigin[2];

	//Draw Trail and effects

	//TE_SPRITETRAIL - line of moving glow sprites with gravity, fadeout, and collisions
	message_begin(MSG_BROADCAST, SVC_TEMPENTITY);
	write_byte(15);
	write_coord(vorigin[0]); // coord, coord, coord (start)
	write_coord(vorigin[1]);
	write_coord(vorigin[2]);
	write_coord(vorigin[0]); // coord, coord, coord (end)
	write_coord(vorigin[1]);
	write_coord(vorigin[2] - 30);
	write_short(blueflare2); // short (sprite index)
	write_byte(5); // byte (count)
	write_byte(1); // byte (life in 0.1's)
	write_byte(1);  // byte (scale in 0.1's)
	write_byte(10); // byte (velocity along vector in 10's)
	write_byte(5);  // byte (randomness of velocity in 10's)
	message_end();

	//TE_SPRITE - additive sprite, plays 1 cycle
	message_begin(MSG_BROADCAST,SVC_TEMPENTITY);
	write_byte(17);
	write_coord(vorigin[0]);  // coord, coord, coord (position)
	write_coord(vorigin[1]);
	write_coord(vorigin[2] - 30);
	write_short(mflash); // short (sprite index)
	write_byte(15); // byte (scale in 0.1's)
	write_byte(255); // byte (brightness)
	message_end();

	set_task(0.2, "rocket_effects", victim);
}

public rocket_explode(victim)
{
	if(is_user_alive(victim)) 
	{
		new vec1[3];
		get_user_origin(victim,vec1);

		// blast circles
		message_begin(MSG_BROADCAST, SVC_TEMPENTITY, vec1);
		write_byte(21);
		write_coord(vec1[0]);
		write_coord(vec1[1]);
		write_coord(vec1[2] - 10);
		write_coord(vec1[0]);
		write_coord(vec1[1]);
		write_coord(vec1[2] + 1910);
		write_short(white);
		write_byte(0); // startframe
		write_byte(0); // framerate
		write_byte(2); // life
		write_byte(16); // width
		write_byte(0); // noise
		write_byte(188); // r
		write_byte(220); // g
		write_byte(255); // b
		write_byte(255); //brightness
		write_byte(0); // speed
		message_end();

		//Explosion2
		message_begin(MSG_BROADCAST, SVC_TEMPENTITY);
		write_byte(12);
		write_coord(vec1[0]);
		write_coord(vec1[1]);
		write_coord(vec1[2]);
		write_byte(188); // byte (scale in 0.1's)
		write_byte(10); // byte (framerate)
		message_end();

		//smoke
		message_begin(MSG_BROADCAST, SVC_TEMPENTITY, vec1);
		write_byte(5);
		write_coord(vec1[0]);
		write_coord(vec1[1]);
		write_coord(vec1[2]);
		write_short(smoke);
		write_byte(2);
		write_byte(10);
		message_end();

		user_kill(victim, 1);
	}

	//stop_sound
	emit_sound(victim, CHAN_VOICE, "weapons/rocket1.wav", 0.0, 0.0, (1<<5), PITCH_NORM);

	set_user_maxspeed(victim, 1.0);
	set_user_gravity(victim, 1.00);
}

/* 21)	amx_fire
 *--------------
*/
public Cmd_Fire(id, level, cid)
{
	if(!cmd_access(id, level, cid, 1))
		return PLUGIN_HANDLED;
		
	new AdminName[35], AuthID[35], TargetName[35];
	get_user_name(id, AdminName, charsmax(AdminName));
	get_user_authid(id, AuthID, charsmax(AuthID));
	
	new target[35];
	read_argv(1, target, charsmax(target));
	
	new tempid;
	
	if(target[0] == '@')
	{
		new players[32], pnum;
		new CmdTeam: team;
		
		switch(target[1])
		{
			case 'A', 'a':
			{
				get_players(players, pnum, "a");
				
				team = ALL;
			}
			
			case 'T', 't':
			{
				get_players(players, pnum, "ae", "TERRORIST");
				
				team = T;
			}
			
			case 'C', 'c':
			{
				get_players(players, pnum, "ae", "CT");
				
				team = CT;
			}
		}
		
		if(!pnum)
		{
			console_print(id, "%L", id, "AMX_SUPER_NO_PLAYERS");
			
			return PLUGIN_HANDLED;
		}
		
		for(new i = 0; i < pnum; i++)
		{
			tempid = players[i];
			
			if((get_user_flags(tempid) & ADMIN_IMMUNITY) && id != tempid)
			{
				get_user_name(tempid, TargetName, charsmax(TargetName));
				
				console_print(id, "%L", id, "AMX_SUPER_TEAM_IMMUNITY", TargetName);
				
				continue;
			}
		
			SetPlayerBit(onfire, tempid);
			
			ignite_effects(tempid);
			ignite_player(tempid);
		}
		
		show_activity_key("AMX_SUPER_FIRE_TEAM_CASE1", "AMX_SUPER_FIRE_TEAM_CASE2", AdminName, g_TeamNames[team]);
		log_amx("%L", LANG_SERVER, "AMX_SUPER_FIRE_TEAM_LOG", AdminName, AuthID, g_TeamNames[team]);
	}
	
	else
	{
		tempid = cmd_target(id, target, CMDTARGET_OBEY_IMMUNITY | CMDTARGET_ALLOW_SELF | CMDTARGET_ONLY_ALIVE);
		
		if(tempid)
		{
			new TempAuthID[35];
			get_user_authid(tempid, TempAuthID, charsmax(TempAuthID));
			get_user_name(tempid, TargetName, charsmax(TargetName));
			
			SetPlayerBit(onfire, tempid);
			
			ignite_effects(tempid);
			ignite_player(tempid);
		
			show_activity_key("AMX_SUPER_FIRE_PLAYER_CASE1", "AMX_SUPER_FIRE_PLAYER_CASE2", AdminName, TargetName);
			log_amx("%L", LANG_SERVER, "AMX_SUPER_FIRE_PLAYER_LOG", AdminName, AuthID, TargetName, TempAuthID);
			
			console_print(id, "%L", id, "AMX_SUPER_FIRE_PLAYER_MSG", TargetName);
		}
	}
	
	return PLUGIN_HANDLED;
}
	
public ignite_effects(id)  
{
	if(is_user_alive(id) && CheckPlayerBit(onfire, id))
    {
		new origin[3];
		get_user_origin(id, origin);
		
		//TE_SPRITE - additive sprite, plays 1 cycle
		message_begin(MSG_BROADCAST, SVC_TEMPENTITY);
		write_byte(17);
		write_coord(origin[0]);  // coord, coord, coord (position)
		write_coord(origin[1]);
		write_coord(origin[2]);
		write_short(mflash); // short (sprite index)
		write_byte(20); // byte (scale in 0.1's)
		write_byte(200); // byte (brightness)
		message_end();
		
		//Smoke
		message_begin(MSG_BROADCAST,SVC_TEMPENTITY, origin);
		write_byte(5);
		write_coord(origin[0]);// coord coord coord (position)
		write_coord(origin[1]);
		write_coord(origin[2]);
		write_short(smoke);// short (sprite index)
		write_byte(20); // byte (scale in 0.1's)
		write_byte(15); // byte (framerate)
		message_end();
		
		set_task(0.2, "ignite_effects", id);
	}
	
	else    
	{
		if(CheckPlayerBit(onfire, id))
		{
			emit_sound(id, CHAN_AUTO, "scientist/scream21.wav", 0.6, ATTN_NORM, 0, PITCH_HIGH);
			ClearPlayerBit(onfire, id);
		}
	}
}

public ignite_player(id)   
{
	if(is_user_alive(id) && CheckPlayerBit(onfire, id)) 
	{
		new origin[3];
				
		new Health = get_user_health(id);
		get_user_origin(id, origin);
		
		//create some damage
		set_user_health(id, Health - 10);
		
		message_begin(MSG_ONE, g_Msg_Damage, _, id);
		write_byte(30); // dmg_save
		write_byte(30); // dmg_take
		write_long(1<<21); // visibleDamageBits
		write_coord(origin[0]); // damageOrigin.x
		write_coord(origin[1]); // damageOrigin.y
		write_coord(origin[2]); // damageOrigin.z
		message_end();
		
		//create some sound
		emit_sound(id, CHAN_ITEM, "ambience/flameburst1.wav", 0.6, ATTN_NORM, 0, PITCH_NORM);
		
		//Ignite Others 
		if(get_pcvar_num(allowcatchfire)) 
		{       
			new pOrigin[3];
			
			new players[32], pnum, tempid;
			get_players(players, pnum, "a");
			
			new pName[32], kName[32]; 
			
			for(new i = 0; i < pnum; ++i) 
			{                   
				tempid = players[i];
				
				get_user_origin(tempid, pOrigin);
				
				if(get_distance(origin, pOrigin) < 100)
				{ 
					if(!CheckPlayerBit(onfire, tempid)) 
					{ 
						               
						get_user_name(tempid, pName, charsmax(pName));
						get_user_name(id, kName, charsmax(kName)); 
						
						emit_sound(tempid, CHAN_WEAPON, "scientist/scream07.wav", 1.0, ATTN_NORM, 0, PITCH_HIGH); 
						client_print(0, print_chat, "* [AMX] OH! NO! %s has caught %s on fire!", kName, pName);
						
						SetPlayerBit(onfire, tempid);
						
						ignite_player(tempid);
						ignite_effects(tempid);
					}                
				} 
			}           
		} 
		
		//Call Again in 2 seconds       
		set_task(2.0, "ignite_player", id);       
	}    
} 

/* 22)	amx_flash
 *---------------
*/
public Cmd_Flash(id, level, cid)
{
	if(!cmd_access(id, level, cid, 2))
		return PLUGIN_HANDLED;
		
	new target[35], TargetName[35];
	read_argv(1, target, charsmax(target));
	
	new AdminName[35], AuthID[35];
	get_user_name(id, AdminName, charsmax(AdminName));
	get_user_authid(id, AuthID, charsmax(AuthID));
	
	new tempid;
	
	if(target[0] == '@')
	{
		new players[32], pnum;
		new CmdTeam: team;
		
		switch(target[1])
		{
			case 'A', 'a':
			{
				get_players(players, pnum, "a");
				
				team = ALL;
			}
			
			case 'T', 't':
			{
				get_players(players, pnum, "ae", "TERRORIST");
				
				team = T;
			}
			
			case 'C', 'c':
			{
				get_players(players, pnum, "ae", "CT");
				
				team = CT;
			}
		}
		
		if(!pnum)
		{
			console_print(id, "%L", id, "AMX_SUPER_NO_PLAYERS");
			
			return PLUGIN_HANDLED;
		}
		
		for(new i = 0; i < pnum; i++)
		{
			tempid = players[i];
			
			if((get_user_flags(tempid) & ADMIN_IMMUNITY) && id != tempid)
			{
				get_user_name(tempid, TargetName, charsmax(TargetName));
				
				console_print(id, "%L", id, "AMX_SUPER_TEAM_IMMUNITY", TargetName);
				
				continue;
			}
			
			Flash_Player(tempid);
		}
		
		console_print(id, "%L", id, "AMX_SUPER_FLASH_TEAM_MSG", g_TeamNames[team]);
		
		show_activity_key("AMX_SUPER_FLASH_TEAM_CASE1", "AMX_FLASH_TEAM_CASE2", AdminName, g_TeamNames[team]);
		log_amx("%L", LANG_SERVER, "AMX_SUPER_FLASH_TEAM_LOG", AdminName, AuthID, g_TeamNames[team]);
	}
	
	else
	{
		tempid = cmd_target(id, target, CMDTARGET_OBEY_IMMUNITY | CMDTARGET_ALLOW_SELF | CMDTARGET_ONLY_ALIVE);
		
		if(tempid)
		{
			Flash_Player(tempid);
			
			new TempAuthId[35];
			get_user_authid(tempid, TempAuthId, charsmax(TempAuthId));
			get_user_name(tempid, TargetName, charsmax(TargetName));
			
			console_print(id, "%L", id, "AMX_SUPER_FLASH_PLAYER_MSG", TargetName);
			
			show_activity_key("AMX_SUPER_FLASH_PLAYER_CASE1", "AMX_SUPER_FLASH_PLAYER_CASE2", AdminName, TargetName);
			
			log_amx("%L", LANG_SERVER, "AMX_SUPER_FLASH_PLAYER_LOG", AdminName, AuthID, TargetName, TempAuthId);
		}
	}
	
	return PLUGIN_HANDLED;
}

Flash_Player(id)
{
	message_begin(MSG_ONE, g_Msg_ScreenFade, {0,0,0}, id);
	write_short(1<<15);
	write_short(1<<10);
	write_short(1<<12);
	write_byte(255);
	write_byte(255);
	write_byte(255);
	write_byte(255);
	message_end();

	if(get_pcvar_num(flashsound))
		emit_sound(id, CHAN_BODY, "weapons/flashbang-2.wav", 1.0, ATTN_NORM, 0, PITCH_HIGH);
}

/* 23)	amx_uberslap
 *------------------
*/
public Cmd_UberSlap(id, level, cid)
{
	if(!cmd_access(id, level, cid, 2))
		return PLUGIN_HANDLED;
		
	new target[35];
	read_argv(1, target, charsmax(target));
	
	new TargetName[35], AdminName[35];
	get_user_name(id, AdminName, charsmax(AdminName));
			
	new AuthID[35];
	get_user_authid(id, AuthID, charsmax(AuthID));
	new tempid;
	
	if(target[0] == '@')
	{
		new players[32], pnum;
		new CmdTeam: team;
		
		switch(target[1])
		{
			case 'A', 'a':
			{
				get_players(players, pnum, "a");
				
				team = ALL;
			}
			
			case 'T', 't':
			{
				get_players(players, pnum, "ae", "TERRORIST");
				
				team = T;
			}
			
			case 'C', 'c':
			{
				get_players(players, pnum, "ae", "CT");
				
				team = CT;
			}
		}
		
		if(!pnum)
		{
			console_print(id, "%L", id, "AMX_SUPER_NO_PLAYERS");
			
			return PLUGIN_HANDLED;
		}
		
		for(new i = 0; i < pnum; i++)
		{
			tempid = players[i];
			
			if((get_user_flags(tempid) & ADMIN_IMMUNITY) && id != tempid)
			{	
				get_user_name(tempid, TargetName, charsmax(TargetName));
				
				console_print(id, "%L", id, "AMX_SUPER_TEAM_IMMUNITY", TargetName);
				
				continue;
			}
			
			set_task(0.1, "Slap_Player", tempid, _, _, "a", 100);
		}
		
		show_activity_key("AMX_SUPER_UBERSLAP_TEAM_CASE1", "AMX_SUPER_UBERSLAP_TEAM_CASE2", AdminName, g_TeamNames[team]);
		log_amx("%L", LANG_SERVER, "AMX_SUPER_UBERSLAP_TEAM_LOG", AdminName, AuthID, g_TeamNames[team]);
	}
	
	else
	{
		tempid = cmd_target(id, target, CMDTARGET_OBEY_IMMUNITY | CMDTARGET_ALLOW_SELF | CMDTARGET_ONLY_ALIVE);
		
		if(tempid)
		{
			get_user_name(tempid, TargetName, charsmax(TargetName));
			
			new TempAuthID[35];
			get_user_authid(tempid, TempAuthID, charsmax(TempAuthID));
					
			set_task(0.1, "Slap_Player", tempid, _, _, "a", 100);
			
			show_activity_key("AMX_SUPER_UBERSLAP_PLAYER_CASE1", "AMX_SUPER_UBERSLAP_PLAYER_CASE2", AdminName, TargetName);
			log_amx("%L", LANG_SERVER, "AMX_SUPER_UBERSLAP_PLAYER_LOG", AdminName, AuthID, TargetName, TempAuthID);
			
			console_print(id, "%L", id, "AMX_SUPER_UBERSLAP_PLAYER_MSG", TargetName);
		}
	}

	return PLUGIN_HANDLED;
}

public Slap_Player(id)
{
	if(get_user_health(id) > 1)
		user_slap(id, 1);
	
	else
		user_slap(id, 0);
}

/* 24)	amx_glow(2)
 *-----------------
*/
public Cmd_Glow(id, level, cid)
{
	if(!cmd_access(id, level, cid, 3))
		return PLUGIN_HANDLED;
		
	new cmd[20], target[35], color[20], green[3], blue[3], alpha[3];
	read_argv(0, cmd, charsmax(cmd)); 			
	read_argv(1, target, charsmax(target));		
	read_argv(2, color, charsmax(color));		
	read_argv(3, green, charsmax(green));
	read_argv(4, blue, charsmax(blue));
	read_argv(5, alpha, charsmax(alpha));
	
	new rednum, greennum, bluenum, alphanum;
	
	new bool: Off;
	new bool: Glow2;
	
	if(cmd[8] == '2')
		Glow2 = true;
		
	else 
		Glow2 = false;
		
	if(!strlen(green))
	{
		new bool: Valid_Color = false;
		
		for(new i = 0; i < MAX_COLORS; i++)
		{
			if(equali(color, g_ColorNames[i]))
			{	
				rednum = g_Colors[i][0];
				greennum = g_Colors[i][1];
				bluenum = g_Colors[i][2];
				alphanum = 255;
				
				if(equali(color, "off"))
					Off = true;
				
				else 
					Off = false;
					
				Valid_Color = true;
				
				break;
			}
		}
		
		if(!Valid_Color)
		{ 
			console_print(id, "%L", LANG_PLAYER, "AMX_SUPER_GLOW_INVALID_COLOR");
			
			return PLUGIN_HANDLED;
		}
	}
	
	else
	{
		rednum = str_to_num(color);
		greennum = str_to_num(green);
		bluenum = str_to_num(blue);
		alphanum = str_to_num(alpha);
		
		clamp(rednum, 0, 255);
		clamp(greennum, 0, 255);
		clamp(bluenum, 0, 255);
		clamp(alphanum, 0, 255);
	}
	
	new tempid;
	new name[34], authid[35];
	get_user_name(id, name, charsmax(name));
	get_user_authid(id, authid, charsmax(authid));

	if(target[0] == '@')
	{
		new players[32], pnum;
		
		if(equali(target[1], "T"))
			copy(target[1], charsmax(target), "TERRORIST");
		
		if(equali(target[1], "ALL"))
			get_players(players, pnum, "a");
		
		else
			get_players(players, pnum, "ae", target[1]);
			
		for(new i = 0; i < pnum; i++)
		{
			tempid = players[i];
			
			if(Glow2)
			{
				g_GlowColor[tempid][0] = rednum;
				g_GlowColor[tempid][1] = greennum;
				g_GlowColor[tempid][2] = bluenum;
				g_GlowColor[tempid][3] = alphanum;
				
				// g_HasGlow[tempid] = true;
				g_iFlags[tempid] |= HASGLOW;
				
			}
			
			else
			{
				arrayset(g_GlowColor[tempid], 0, 4);
				// g_HasGlow[tempid] = false;
				g_iFlags[tempid] &= ~HASGLOW;
			}
			
			set_user_rendering(tempid, kRenderFxGlowShell, rednum, greennum, bluenum, kRenderTransAlpha, alphanum);
		}
		
		if(Off)
			show_activity_key("AMX_SUPER_GLOW_TEAM_OFF_CASE1", "AMX_SUPER_GLOW_TEAM_OFF_CASE2", name, target[1]);
		
		else
			show_activity_key("AMX_SUPER_GLOW_TEAM_CASE1", "AMX_SUPER_GLOW_TEAM_CASE2", name, target[1]);
		
		console_print(id, "%L", id, "AMX_SUPER_GLOW_TEAM_MSG", target[1]);
		log_amx("%L", LANG_SERVER, "AMX_SUPER_GLOW_TEAM_LOG", name, authid, target[1]);
	}

	else
	{
		tempid = cmd_target(id, target, 2);
		
		if(!tempid)
			return PLUGIN_HANDLED;
			
		if(Glow2)
		{
			g_GlowColor[tempid][0] = rednum;
			g_GlowColor[tempid][1] = greennum;
			g_GlowColor[tempid][2] = bluenum;
			g_GlowColor[tempid][3] = alphanum;
			
			// g_HasGlow[tempid] = true;
			g_iFlags[tempid] |= HASGLOW;
		}
		
		else
		{
			arrayset(g_GlowColor[tempid], 0, sizeof(g_GlowColor[]));
			// g_HasGlow[tempid] = false;
			g_iFlags[tempid] &= ~HASGLOW;
		}
		
		set_user_rendering(tempid, kRenderFxGlowShell, rednum, greennum, bluenum, kRenderTransAlpha, alphanum);
		
		new tempidname[35];
		get_user_name(tempid, tempidname, charsmax(tempidname));
		
		if(Off)
			show_activity_key("AMX_SUPER_GLOW_PLAYER_OFF_CASE1", "AMX_SUPER_GLOW_PLAYER_OFF_CASE2", name, tempidname);
			
		else
			show_activity_key("AMX_SUPER_GLOW_PLAYER_CASE1", "AMX_SUPER_GLOW_PLAYER_CASE2", name, tempidname);

		console_print(id, "%L", id, "AMX_SUPER_GLOW_TEAM_MSG", tempidname);
		log_amx("%L", LANG_SERVER, "AMX_SUPER_GLOW_TEAM_LOG", name, authid, tempidname);
	}
	return PLUGIN_HANDLED;
}

/* 25)	amx_glowcolors
 *--------------------
*/
public Cmd_GlowColors(id, level, cid)
{
	if(!cmd_access(id, level, cid, 1))
		return PLUGIN_HANDLED;
	
	console_print(id, "Colors:");
	
	for(new i = 0; i < MAX_COLORS; i++)
		console_print(id, "%i %s", i + 1, g_ColorNames[i]);
	
	console_print(id, "Example: ^"amx_glow superman yellow^"");
	
	return PLUGIN_HANDLED;
}
/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ deff0{\\ fonttbl{\\ f0\\ fnil Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ lang3082\\ f0\\ fs16 \n\\ par }
*/
