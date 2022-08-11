#pragma semicolon 1
#pragma newdecls required //強制1.7以後的新語法

#include <sourcemod>
#include <sdkhooks>
#include <sdktools>
#include <colors>
#include <l4d2util>

#define CLASSNAME_LENGTH 64

ConVar
g_hEnable,
g_hFireDisable,
g_hPipeBombDisable;

public Plugin myinfo =
{
	name = "anti-friendly_fire",
	author = "HarryPotter",
	description = "shoot teammate = shoot yourself",
	version = "1.2",
	url = "https://steamcommunity.com/id/fbef0102/"
}

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	EngineVersion engine = GetEngineVersion();

	if( engine != Engine_Left4Dead2 && engine != Engine_Left4Dead)
	{
		strcopy(error, err_max, "Plugin only supports Left 4 Dead 1 & 2.");
		return APLRes_SilentFailure;
	}

	return APLRes_Success;
}

public void OnPluginStart()
{
	g_hEnable 			= CreateConVar("anti_friendly_fire_enable", "1","Enable anti-friendly_fire",FCVAR_NOTIFY, true, 0.0, true, 1.0 );
	g_hFireDisable 		= CreateConVar("anti_friendly_fire_immue_fire", "1","If 1, Disable Fire friendly fire.",FCVAR_NOTIFY, true, 0.0, true, 1.0 );
	g_hPipeBombDisable 	= CreateConVar("anti_friendly_fire_immue_pipebomb", "1","If 1, Disable Pipe Bomb Explosive friendly fire.",FCVAR_NOTIFY, true, 0.0, true, 1.0 );

	HookEvent("player_hurt", Event_PlayerHurt);

	AutoExecConfig(false, "anti-friendly_fire");
}

public Action Event_PlayerHurt(Event event, const char[] name, bool dontBroadcast)
{
	int victim 		= GetClientOfUserId(GetEventInt(event, "userid"));
	int attacker 	= GetClientOfUserId(GetEventInt(event, "attacker"));
	int damage 		= GetEventInt(event, "dmg_health");

	if(g_hEnable.BoolValue == false
		|| !IsValidClientIndex(attacker)
		|| !IsValidClientIndex(victim)
		|| !IsSurvivor(victim)
		|| attacker == victim
		|| damage <=0)
	{
		return Plugin_Continue;
	}

	char WeaponName[CLASSNAME_LENGTH];
	event.GetString("weapon", WeaponName, sizeof(WeaponName));

	bool bIsSpecialWeapon = false;
	if(IsPipeBombExplode(WeaponName))
	{
		bIsSpecialWeapon = true;
		if(g_hPipeBombDisable.BoolValue == false)
		{
			return Plugin_Continue;
		}

	}
	else if(IsFire(WeaponName) || IsFireworkcrate(WeaponName))
	{
		bIsSpecialWeapon = true;
		if(g_hFireDisable.BoolValue == false)
		{
			return Plugin_Continue;
		}
	}

	if(bIsSpecialWeapon)
	{
		int health 		= GetEventInt(event, "health");
		int sethealth 	= health + damage;
		SetEntityHealth(victim, sethealth);
	}
	else if(!bIsSpecialWeapon && IsSurvivor(attacker) && !IsIncapacitated(victim))
	{
		int health 		= GetEventInt(event, "health");
		int sethealth 	= health + damage;
		SetEntityHealth(victim, sethealth);
		SDKHooks_TakeDamage(attacker, attacker, 0, float(damage), DMG_BURN);
	}

	return Plugin_Changed;
}

bool IsFire(char[] classname)
{
	return StrEqual(classname, "inferno");
}

bool IsPipeBombExplode(char[] classname)
{
	return StrEqual(classname, "pipe_bomb");
}

bool IsFireworkcrate(char[] classname)
{
	return StrEqual(classname, "fire_cracker_blast");
}