#include <sourcemod>
#include <cstrike>
#include <clientprefs>
#include <sdktools_functions>

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

int CTRifleCount = 0;
char AvailableCTRiflesNames[100][WEAPON_STRING_LENGTH];
char AvailableCTRiflesEntity[100][WEAPON_STRING_LENGTH];

int TRifleCount = 0;
char AvailableTRiflesNames[100][WEAPON_STRING_LENGTH];
char AvailableTRiflesEntity[100][WEAPON_STRING_LENGTH];

int CTPistolCount = 0;
char AvailableCTPistolsNames[100][WEAPON_STRING_LENGTH];
char AvailableCTPistolsEntity[100][WEAPON_STRING_LENGTH];

int TPistolCount = 0;
char AvailableTPistolsNames[100][WEAPON_STRING_LENGTH];
char AvailableTPistolsEntity[100][WEAPON_STRING_LENGTH];

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

	ParseWeapons();

	RegConsoleCmd("sm_weaponinfo", WeaponInfo, "Prints to chat the selected weapons.");
	RegConsoleCmd("sm_weaponinfocookies", WeaponInfoCookies, "Prints to chat the selected weapons saved in the cookies.");
}

public void ParseWeapons()
{
	char path[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, path, sizeof(path), "configs/SchaedlWeaponAllocator_Weapons.cfg");

	if(!FileExists(path))
	{
		SetFailState("Config file %s was not found!", path);
		return;
	}

	KeyValues weaponsKeyValues = new KeyValues("Weapons");
	if(!weaponsKeyValues.ImportFromFile(path))
	{
		SetFailState("Unable to parse the KeyValue file %s!", path);
		return;
	}

	if(!weaponsKeyValues.JumpToKey("Rifles"))
	{
		SetFailState("Unable to find Rifles section in the KeyValue file %s!", path);
		return;
	}

	if(!weaponsKeyValues.GotoFirstSubKey())
	{
		SetFailState("Unable to find Rifles section in the KeyValue file %s!", path);
		return;
	}

	
	do
	{
		char entity[WEAPON_STRING_LENGTH];
		char name[WEAPON_STRING_LENGTH];
		char team[8];

		weaponsKeyValues.GetSectionName(entity, sizeof(entity));
		weaponsKeyValues.GetString("name", name, sizeof(name));
		weaponsKeyValues.GetString("team", team, sizeof(team));

		if(strcmp("ct", team, false) == 0)
		{
			AvailableCTRiflesNames[CTRifleCount] = name;
			AvailableCTRiflesEntity[CTRifleCount] = entity;
			CTRifleCount++;
		}
		else if (strcmp("t", team, false) == 0)
		{
			AvailableTRiflesNames[TRifleCount] = name;
			AvailableTRiflesEntity[TRifleCount] = entity;
			TRifleCount++;
		}
		else if (strcmp("any", team, false) == 0)
		{
			AvailableCTRiflesNames[CTRifleCount] = name;
			AvailableCTRiflesEntity[CTRifleCount] = entity;
			CTRifleCount++;

			AvailableTRiflesNames[TRifleCount] = name;
			AvailableTRiflesEntity[TRifleCount] = entity;
			TRifleCount++;
		}
	}
	while(weaponsKeyValues.GotoNextKey());

	weaponsKeyValues.Rewind();

	if(!weaponsKeyValues.JumpToKey("Pistols"))
	{
		SetFailState("Unable to find Pistols section in the KeyValue file %s!", path);
		return;
	}

	if(!weaponsKeyValues.GotoFirstSubKey())
	{
		SetFailState("Unable to find Pistols section in the KeyValue file %s!", path);
		return;
	}

	
	do
	{
		char entity[WEAPON_STRING_LENGTH];
		char name[WEAPON_STRING_LENGTH];
		char team[8];

		weaponsKeyValues.GetSectionName(entity, sizeof(entity));
		weaponsKeyValues.GetString("name", name, sizeof(name));
		weaponsKeyValues.GetString("team", team, sizeof(team));

		if(strcmp("ct", team, false) == 0)
		{
			AvailableCTPistolsNames[CTPistolCount] = name;
			AvailableCTPistolsEntity[CTPistolCount] = entity;
			CTPistolCount++;
		}
		else if (strcmp("t", team, false) == 0)
		{
			AvailableTPistolsNames[TPistolCount] = name;
			AvailableTPistolsEntity[TPistolCount] = entity;
			TPistolCount++;
		}
		else if (strcmp("any", team, false) == 0)
		{
			AvailableCTPistolsNames[CTPistolCount] = name;
			AvailableCTPistolsEntity[CTPistolCount] = entity;
			CTPistolCount++;

			AvailableTPistolsNames[TPistolCount] = name;
			AvailableTPistolsEntity[TPistolCount] = entity;
			TPistolCount++;
		}
	}
	while(weaponsKeyValues.GotoNextKey());
}

public void OnClientConnected(int client)
{
	CTRifle[client] = "weapon_m4a1";
	TRifle[client] = "weapon_ak47";
	CTPistol[client] = "weapon_hkp2000";
	TPistol[client] = "weapon_glock";
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

	PrintToServer("WEAPON INFO COOKIES:");
	PrintToServer("[%d] CT-Rifle: %s", client, ctRifle);
	PrintToServer("[%d] T-Rifle: %s", client, tRifle);
	PrintToServer("[%d] CT-Pistol: %s", client, ctPistol);
	PrintToServer("[%d] T-Pistol: %s", client, tPistol);
	PrintToServer("[%d] CT-AWP-Chance: %s%", client, ctAwpChance);
	PrintToServer("[%d] T-AWP-Chance: %s%", client, tAwpChance);

	if(strlen(ctRifle) > 0)
	{
		CTRifle[client] = ctRifle;
	}
	if(strlen(tRifle) > 0)
	{
		TRifle[client] = tRifle;
	}
	if(strlen(ctPistol) > 0)
	{
		CTPistol[client] = ctPistol;
	}
	if(strlen(tPistol) > 0)
	{
		TPistol[client] = tPistol;
	}
	CTAwpChance[client] = StringToInt(ctAwpChance);
	TAwpChance[client] = StringToInt(tAwpChance);

	PrintToServer("WEAPON INFO:");
	PrintToServer("[%d] CT-Rifle: %s", client, CTRifle[client]);
	PrintToServer("[%d] T-Rifle: %s", client, TRifle[client]);
	PrintToServer("[%d] CT-Pistol: %s", client, CTPistol[client]);
	PrintToServer("[%d] T-Pistol: %s", client, TPistol[client]);
	PrintToServer("[%d] CT-AWP-Chance: %d%", client, CTAwpChance[client]);
	PrintToServer("[%d] T-AWP-Chance: %d%", client, TAwpChance[client]);
}

public void Retakes_OnGunsCommand(int client)
{
	MainMenu(client);
}

public void RegisterClientCookies()
{
	CTPistolCookie = RegClientCookie("SWA_pistol_ct", "", CookieAccess_Private);
	TPistolCookie = RegClientCookie("SWA_pistol_t", "", CookieAccess_Private);
    
	CTRifleCookie = RegClientCookie("SWA_rifle_ct", "", CookieAccess_Private);
	TRifleCookie = RegClientCookie("SWA_rifle_t", "", CookieAccess_Private);

	CTAwpChanceCookie = RegClientCookie("SWA_awp_chance_ct", "", CookieAccess_Private);
	TAwpChanceCookie = RegClientCookie("SWA_awp_chance_t", "", CookieAccess_Private);
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

	for(int i= 0; i < CTRifleCount; i++)
	{
		menu.AddItem(AvailableCTRiflesEntity[i], AvailableCTRiflesNames[i]);
	}

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
	
	for(int i= 0; i < CTPistolCount; i++)
	{
		menu.AddItem(AvailableCTPistolsEntity[i], AvailableCTPistolsNames[i]);
	}

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
	Menu menu = new Menu(TRifleMenuHandler);
	menu.SetTitle("T Rifle Menu:");

	for(int i= 0; i < TRifleCount; i++)
	{
		menu.AddItem(AvailableTRiflesEntity[i], AvailableTRiflesNames[i]);
	}

	menu.Display(client, MENU_TIME_LENGTH);
}

public int TRifleMenuHandler(Menu menu, MenuAction action, int param1, int param2) 
{
	if (action == MenuAction_Select) 
	{
        int client = param1;
        char choice[WEAPON_STRING_LENGTH];
        menu.GetItem(param2, choice, sizeof(choice));
        
		TRifle[client] = choice;
        SetClientCookie(client, TRifleCookie, choice);

        TPistolWeaponMenu(client);
    } 
	else if (action == MenuAction_End) 
	{
        delete menu;
    }
}

public void TPistolWeaponMenu(int client)
{
	Menu menu = new Menu(TPistolMenuHandler);
	menu.SetTitle("T Pistol Menu:");
	
	for(int i= 0; i < TPistolCount; i++)
	{
		menu.AddItem(AvailableTPistolsEntity[i], AvailableTPistolsNames[i]);
	}

	menu.Display(client, MENU_TIME_LENGTH);
}

public int TPistolMenuHandler(Menu menu, MenuAction action, int param1, int param2) 
{
	if (action == MenuAction_Select) 
	{
        int client = param1;
        char choice[WEAPON_STRING_LENGTH];
        menu.GetItem(param2, choice, sizeof(choice));
        
		TPistol[client] = choice;
        SetClientCookie(client, TPistolCookie, choice);

        TAwpChanceWeaponMenu(client);
    } 
	else if (action == MenuAction_End) 
	{
        delete menu;
    }
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

public void Retakes_OnWeaponsAllocated(ArrayList tPlayers, ArrayList ctPlayers, Bombsite bombsite) {
    WeaponAllocator(tPlayers, ctPlayers, bombsite);
}

public void WeaponAllocator(ArrayList tPlayers, ArrayList ctPlayers, Bombsite bombsite) {
    int tCount = tPlayers.Length;
    int ctCount = ctPlayers.Length;

	RandomizeArrayList(tPlayers);
	RandomizeArrayList(ctPlayers);

	bool isAWPGivenToT = false;
	bool isAWPGivenToCT = false;

    for (int i = 0; i < tCount; i++) {
        int client = tPlayers.Get(i);

		int awpChance = TAwpChance[client];
		if(!isAWPGivenToT && awpChance > 0 && GetRandomInt(0, 100) <= awpChance)
		{
			GivePlayerItem(client, "weapon_awp");
			isAWPGivenToT = true;
		}
        else {
            GivePlayerItem(client, TRifle[client]);
        } 

        GivePlayerItem(client, TPistol[client]);

        GivePlayerArmor(client, 100, true);
    }

    for (int i = 0; i < ctCount; i++) {
        int client = ctPlayers.Get(i);

		int awpChance = CTAwpChance[client];
		if(!isAWPGivenToCT && awpChance > 0 && GetRandomInt(0, 100) <= awpChance)
		{
			GivePlayerItem(client, "weapon_awp");
			isAWPGivenToCT = true;
		}
        else {
            GivePlayerItem(client, CTRifle[client]);
        } 

       	GivePlayerItem(client, CTPistol[client]);

		GivePlayerArmor(client, 100, true);
		GivePlayerDefuseKit(client);
    }
}

public void RandomizeArrayList(ArrayList arrayList)
{
	for(int i = 0; i < arrayList.Length; i++)
	{
		SwapArrayItems(arrayList, i, GetRandomInt(0, arrayList.Length-1));
	}
	
}

public void GivePlayerArmor(int client, int armorAmount, bool helmet)
{
	SetEntProp(client, Prop_Send, "m_ArmorValue", armorAmount);
	SetEntProp(client, Prop_Send, "m_bHasHelmet", helmet);
}

public void GivePlayerDefuseKit(int client)
{
	SetEntProp(client, Prop_Send, "m_bHasDefuser", 1);
}

