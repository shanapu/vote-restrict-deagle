/*
 * VIPVote for restric deagle.
 * by: shanapu
 * https://github.com/shanapu/
 *
 * This program is free software; you can redistribute it and/or modify it under
 * the terms of the GNU General Public License, version 3.0, as published by the
 * Free Software Foundation.
 * 
 * This program is distributed in the hope that it will be useful, but WITHOUT
 * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE. See the GNU General Public License for more
 * details.
 *
 * You should have received a copy of the GNU General Public License along with
 * this program. If not, see <http://www.gnu.org/licenses/>.
 */

/******************************************************************************
                   STARTUP
******************************************************************************/

// Includes
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <cstrike>
#include <colors>

// Compiler Options
#pragma semicolon 1
#pragma newdecls required

// Variables
bool g_bIsDeagleRestrict = false;
int g_iCoolDown;

// Info
public Plugin myinfo = {
	name = "VIPVote for restrict deagle",
	author = "shanapu",
	description = "VIPS can use !votedeagle to restrict deagle",
	version = "1.0",
	url = "https://github.com/shanapu/"
};

// Start
public void OnPluginStart()
{
	// Client Commands
	RegAdminCmd("sm_votedeagle", Command_VoteDeagle, ADMFLAG_CUSTOM6, "Allows VIP to start vote for restrict deagle");

	// Hooks
	HookEvent("round_start", Event_RoundStart);
}

/******************************************************************************
                   COMMANDS
******************************************************************************/


// Voting for Event
public Action Command_VoteDeagle(int client, int args)
{
	if (g_iCoolDown > 0)
	{
		CReplyToCommand(client, "{green}[WizardGaming]{default} The Deagle is still restriced for %i rounds", g_iCoolDown);
		return Plugin_Handled;
	}

	StartVote();

	return Plugin_Handled;
}

public Action StartVote()
{
	if (IsVoteInProgress())
	{
		return;
	}

	Menu menu = new Menu(Handle_VoteMenu);
	menu.SetTitle("Restrict Deagle?");
	menu.AddItem("yes", "Yes");
	menu.AddItem("no", "No");
	menu.ExitButton = false;
	menu.DisplayVoteToAll(25);
}

public int Handle_VoteMenu(Menu menu, MenuAction action, int param1,int param2)
{
	if (action == MenuAction_End)
	{
		/* This is called after VoteEnd */
		delete menu;
	}
	else if (action == MenuAction_VoteEnd)
	{
		/* 0=yes, 1=no */
		if (param1 == 0)
		{
			g_bIsDeagleRestrict = true;
			g_iCoolDown = 3;
			CPrintToChatAll("{green}[WizardGaming]{default} Deagle restricted for 3 rounds");

			for (int i = 1; i <= MaxClients; i++) if (IsClientInGame(i))
			{
				StripDeagle(i);
			}
		}
	}
}

void StripDeagle(int client)
{
	int weapon;
	if ((weapon = GetPlayerWeaponSlot(client, CS_SLOT_SECONDARY)) != -1)   // strip knife slot 2 times for taser
	{
		char sWeapon[32];
		GetEdictClassname(weapon, sWeapon, sizeof(sWeapon));

		if (StrEqual(sWeapon, "weapon_deagle"))
		{
			RemovePlayerItem(client, weapon);
			AcceptEntityInput(weapon, "Kill");
		}
	}
}

/******************************************************************************
                   EVENTS
******************************************************************************/

// Round start
public void Event_RoundStart(Event event, char[] name, bool dontBroadcast)
{
	if (g_iCoolDown > 0)
	{
		g_iCoolDown--;

		if (g_iCoolDown == 0)
		{
			g_bIsDeagleRestrict = false;
			CPrintToChatAll("{green}[WizardGaming]{default} Deagle is no more restricted");
		}
	}
}


/******************************************************************************
                   FORWARDS LISTEN
******************************************************************************/

// Initialize Event
public void OnMapStart()
{
	g_iCoolDown = 0;
	g_bIsDeagleRestrict = false;
}

// Set Client Hook
public void OnClientPutInServer(int client)
{
	SDKHook(client, SDKHook_WeaponCanUse, OnWeaponCanUse);
}

// Knife only
public Action OnWeaponCanUse(int client, int weapon)
{
	if (g_bIsDeagleRestrict)
	{
		char sWeapon[32];
		GetEdictClassname(weapon, sWeapon, sizeof(sWeapon));

		if (StrEqual(sWeapon, "weapon_deagle"))
		{
			if (IsClientInGame(client) && IsPlayerAlive(client))
			{
				return Plugin_Handled;
			}
		}

		return Plugin_Continue;
	}

	return Plugin_Continue;
}