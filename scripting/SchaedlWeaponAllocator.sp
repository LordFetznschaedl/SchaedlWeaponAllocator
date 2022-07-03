#include <sdkhooks>
#include <sdktools>
#include <sourcemod>
#include <clientprefs>

#include <retakes.inc>

#pragma newdecls required
#pragma semicolon 1
#pragma tabsize 0

#define MENU_TIME_LENGTH 15

Handle CTRifleCookie;
Handle CTPistolCookie;
char CTRifle[MAXPLAYERS+1][WEAPON_STRING_LENGTH];
char CTPistol[MAXPLAYERS+1][WEAPON_STRING_LENGTH];

Handle TRifleCookie;
Handle TPistolCookie;
char TRifle[MAXPLAYERS+1][WEAPON_STRING_LENGTH];
char TPistol[MAXPLAYERS+1][WEAPON_STRING_LENGTH];

Handle CTAwpChanceCookie;
Handle TAwpChanceCookie;
int CTAwpChance[MAXPLAYERS+1];
int TAwpChance[MAXPLAYERS+1];




public Plugin myinfo =
{
	name = "SchaedlWeaponAllocator",
	author = "LordFetznschaedl",
	description = "Weapon allocator for Splewis Retake Plugin",
	version = "1.0.0",
	url = "https://github.com/LordFetznschaedl/SchaedlWeaponAllocator"
};


public void OnPluginStart()
{	
	RegisterClientCookies();

	RegConsoleCmd("sm_weaponinfo", WeaponInfo, "Prints to chat the selected weapons.");
	RegConsoleCmd("sm_weaponinfocookies", WeaponInfoCookies, "Prints to chat the selected weapons saved in the cookies.");
}

public void OnClientConnected(int client)
{
	CTRifle[client] = "m4a1";
	TRifle[client] = "ak47";
	CTPistol[client] = "hkp2000";
	TPistol[client] = "glock";
	CTAwpChance[client] = 0;
	TAwpChance[client] = 0;
}

public void OnClientCookiesCached(int client) 
{
    if (IsFakeClient(client))
	{
		return;
	}
        
    char ctRifle[WEAPON_STRING_LENGTH];
    char tRifle[WEAPON_STRING_LENGTH];
	char ctPistol[WEAPON_STRING_LENGTH];
    char tPistol[WEAPON_STRING_LENGTH];
	char ctAwpChance[8];
	char tAwpChance[8];

	GetClientCookie(client, CTRifleCookie, ctRifle, sizeof(ctRifle));
	GetClientCookie(client, TRifleCookie, tRifle, sizeof(tRifle));
	GetClientCookie(client, CTPistolCookie, ctPistol, sizeof(ctPistol));
	GetClientCookie(client, TPistolCookie, tPistol, sizeof(tPistol));
	GetClientCookie(client, CTAwpChanceCookie, ctAwpChance, sizeof(ctAwpChance));
	GetClientCookie(client, TAwpChanceCookie, tAwpChance, sizeof(tAwpChance));

	CTRifle[client] = ctRifle;
	TRifle[client] = tRifle;
	CTPistol[client] = ctPistol;
	TPistol[client] = tPistol;
	CTAwpChance[client] = StringToInt(ctAwpChance);
	TAwpChance[client] = StringToInt(tAwpChance);
}

public void Retakes_OnGunsCommand(int client)
{
	MainMenu(client);
}

public void RegisterClientCookies()
{
	CTPistolCookie = RegClientCookie("retake_pistol_ct", "", CookieAccess_Private);
	TPistolCookie = RegClientCookie("retake_pistol_t", "", CookieAccess_Private);
    
	CTRifleCookie = RegClientCookie("retake_rifle_ct", "", CookieAccess_Private);
	TRifleCookie = RegClientCookie("retake_rifle_t", "", CookieAccess_Private);

	CTAwpChanceCookie = RegClientCookie("retake_awp_chance_ct", "", CookieAccess_Private);
	TAwpChanceCookie = RegClientCookie("retake_awp_chance_t", "", CookieAccess_Private);
}

public Action WeaponInfo(int client, int args)
{
	ReplyToCommand(client, "WEAPON INFO:");
	ReplyToCommand(client, "CT-Rifle: %s", CTRifle[client]);
	ReplyToCommand(client, "T-Rifle: %s", TRifle[client]);
	ReplyToCommand(client, "CT-Pistol: %s", CTPistol[client]);
	ReplyToCommand(client, "T-Pistol: %s", TPistol[client]);
	ReplyToCommand(client, "CT-AWP-Chance: %d%", CTAwpChance[client]);
	ReplyToCommand(client, "T-AWP-Chance: %d%", TAwpChance[client]);
}

public Action WeaponInfoCookies(int client, int args)
{
	char ctRifle[WEAPON_STRING_LENGTH];
    char tRifle[WEAPON_STRING_LENGTH];
	char ctPistol[WEAPON_STRING_LENGTH];
    char tPistol[WEAPON_STRING_LENGTH];
	char ctAwpChance[8];
	char tAwpChance[8];

	GetClientCookie(client, CTRifleCookie, ctRifle, sizeof(ctRifle));
	GetClientCookie(client, TRifleCookie, tRifle, sizeof(tRifle));
	GetClientCookie(client, CTPistolCookie, ctPistol, sizeof(ctPistol));
	GetClientCookie(client, TPistolCookie, tPistol, sizeof(tPistol));
	GetClientCookie(client, CTAwpChanceCookie, ctAwpChance, sizeof(ctAwpChance));
	GetClientCookie(client, TAwpChanceCookie, tAwpChance, sizeof(tAwpChance));

	ReplyToCommand(client, "WEAPON INFO COOKIES:");
	ReplyToCommand(client, "CT-Rifle: %s", ctRifle);
	ReplyToCommand(client, "T-Rifle: %s", tRifle);
	ReplyToCommand(client, "CT-Pistol: %s", ctPistol);
	ReplyToCommand(client, "T-Pistol: %s", tPistol);
	ReplyToCommand(client, "CT-AWP-Chance: %s%", ctAwpChance);
	ReplyToCommand(client, "T-AWP-Chance: %s%", tAwpChance);
}

public void MainMenu(int client)
{
	Menu menu = new Menu(MainMenuHandler);
	menu.SetTitle("Weapon Menu:");
	menu.AddItem("ct", "CT - Side");
	menu.AddItem("t", "T - Side");
	menu.Display(client, MENU_TIME_LENGTH);
}

public int MainMenuHandler(Menu menu, MenuAction action, int param1, int param2) 
{
    if (action == MenuAction_Select) 
	{
        int client = param1;
        char choice[32];
        menu.GetItem(param2, choice, sizeof(choice));
        
		if(strcmp("ct", choice, false) == 0)
		{
			CTRifleWeaponMenu(client);
		}
		else if(strcmp("t", choice, false) == 0)
		{
			TRifleWeaponMenu(client);
		}
		else
		{
			delete menu;
		}

    } 
	else if (action == MenuAction_End) 
	{
        delete menu;
    }
}

public void CTRifleWeaponMenu(int client)
{
	Menu menu = new Menu(CTRifleMenuHandler);
	menu.SetTitle("CT Rifle Menu:");
	menu.AddItem("m4a1", "M4A4");
	menu.AddItem("m4a1_silencer", "M4A1-S");
	menu.Display(client, MENU_TIME_LENGTH);
}

public int CTRifleMenuHandler(Menu menu, MenuAction action, int param1, int param2) 
{
	if (action == MenuAction_Select) 
	{
        int client = param1;
        char choice[WEAPON_STRING_LENGTH];
        menu.GetItem(param2, choice, sizeof(choice));
        
		CTRifle[client] = choice;
        SetClientCookie(client, CTRifleCookie, choice);

        CTPistolWeaponMenu(client);
    } 
	else if (action == MenuAction_End) 
	{
        delete menu;
    }
}

public void CTPistolWeaponMenu(int client)
{
	Menu menu = new Menu(CTPistolMenuHandler);
	menu.SetTitle("CT Pistol Menu:");
	menu.AddItem("hkp2000", "USP-S");
	menu.AddItem("deagle", "Deagle");
	menu.Display(client, MENU_TIME_LENGTH);
}

public int CTPistolMenuHandler(Menu menu, MenuAction action, int param1, int param2) 
{
	if (action == MenuAction_Select) 
	{
        int client = param1;
        char choice[WEAPON_STRING_LENGTH];
        menu.GetItem(param2, choice, sizeof(choice));
        
		CTPistol[client] = choice;
        SetClientCookie(client, CTPistolCookie, choice);

        CTAwpChanceWeaponMenu(client);
    } 
	else if (action == MenuAction_End) 
	{
        delete menu;
    }
}

public void CTAwpChanceWeaponMenu(int client)
{
	Menu menu = new Menu(CTAWPChanceMenuHandler);
	menu.SetTitle("CT AWP Chance Menu:");
	menu.AddItem("0", "0%");
	menu.AddItem("25", "25%");
	menu.AddItem("50", "50%");
	menu.AddItem("75", "75%");
	menu.AddItem("100", "100%");
	menu.Display(client, MENU_TIME_LENGTH);
}

public int CTAWPChanceMenuHandler(Menu menu, MenuAction action, int param1, int param2) 
{
    if (action == MenuAction_Select) 
	{
        int client = param1;
        char choice[8];
        menu.GetItem(param2, choice, sizeof(choice));

		int chance = StringToInt(choice);
		CTAwpChance[client] = chance;
		SetClientCookie(client, CTAwpChanceCookie, choice);

		MainMenu(client);
    } 
	else if (action == MenuAction_End) 
	{
        delete menu;
    }
}

public void TRifleWeaponMenu(int client)
{

}

public int TRifleMenuHandler(Menu menu, MenuAction action, int param1, int param2) 
{

}

public void TPistolWeaponMenu(int client)
{

}

public int TPistolMenuHandler(Menu menu, MenuAction action, int param1, int param2) 
{

}

public void TAwpChanceWeaponMenu(int client)
{
	Menu menu = new Menu(TAWPChanceMenuHandler);
	menu.SetTitle("T AWP Chance Menu:");
	menu.AddItem("0", "0%");
	menu.AddItem("25", "25%");
	menu.AddItem("50", "50%");
	menu.AddItem("75", "75%");
	menu.AddItem("100", "100%");
	menu.Display(client, MENU_TIME_LENGTH);
}

public int TAWPChanceMenuHandler(Menu menu, MenuAction action, int param1, int param2) 
{
    if (action == MenuAction_Select) 
	{
        int client = param1;
        char choice[8];
        menu.GetItem(param2, choice, sizeof(choice));

        int chance = StringToInt(choice);
		TAwpChance[client] = chance;
		SetClientCookie(client, TAwpChanceCookie, choice);

		MainMenu(client);
    } 
	else if (action == MenuAction_End) 
	{
        delete menu;
    }
}