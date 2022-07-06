#include <sourcemod>
#include <cstrike>
#include <clientprefs>
#include <retakes.inc>
#include <autoexecconfig>

#pragma newdecls required
#pragma semicolon 1
#pragma tabsize 0

#define MENU_TIME_LENGTH 15

bool IsLateLoad = false;

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

int CTNadesCount = 0;
int TNadesCount = 0;
char AvailableCTNades[100][NADE_STRING_LENGTH];
char AvailableTNades[100][NADE_STRING_LENGTH];

ConVar gcv_NadeMode;

ConVar gcv_CTMaxAWPChance;
ConVar gcv_TMaxAWPChance;

ConVar gcv_CTIncGrenadeChance;
ConVar gcv_TMolotovChance;
ConVar gcv_CTHEGrenadeChance;
ConVar gcv_THEGrenadeChance;
ConVar gcv_CTSmokeGrenadeChance;
ConVar gcv_TSmokeGrenadeChance;
ConVar gcv_CTFlashbangChance;
ConVar gcv_TFlashbangChance;
ConVar gcv_CTDecoyChance;
ConVar gcv_TDecoyChance;

public Plugin myinfo =
{
	name = "SchaedlWeaponAllocator",
	author = "LordFetznschaedl",
	description = "Weapon allocator for Splewis Retake Plugin",
	version = "1.0.0",
	url = "https://github.com/LordFetznschaedl/SchaedlWeaponAllocator"
};

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err)
{
	IsLateLoad = late;
	return APLRes_Success;
}

public void OnPluginStart()
{	
	RegisterClientCookies();
	CreateConVars();

	ParseWeapons();
	ParseNades();

	if(IsLateLoad)
	{
		LateLoad();
	}

	RegConsoleCmd("sm_weaponinfo", WeaponInfo, "Prints to chat the selected weapons.");
	RegConsoleCmd("sm_weaponinfocookies", WeaponInfoCookies, "Prints to chat the selected weapons saved in the cookies.");

	RegConsoleCmd("sm_availableweapons", AvailableWeapons, "Prints to chat all available weapons.");
	RegConsoleCmd("sm_availablenades", AvailableNades, "Prints to chat all available nades.");
}

public void CreateConVars()
{
	AutoExecConfig_SetFile("SchaedlWeaponAllocator", "sourcemod");
	AutoExecConfig_SetCreateFile(true);

	gcv_NadeMode = AutoExecConfig_CreateConVar("sm_swa_nade_mode", "2", "How Nades are given out. 0 - NoNades, 1 - RandomChanceNades, 2 - NadePresetConfig", _, true, 0.0, true, 2.0);

	gcv_CTMaxAWPChance = AutoExecConfig_CreateConVar("sm_swa_max_awp_chance", "50", "Max Chance available to get an awp as a CT. AWP Chance is available as 0%, 25%, 50%, 75%, 100%", _, true, 0.0, true, 100.0);
	gcv_TMaxAWPChance = AutoExecConfig_CreateConVar("sm_swa_max_awp_chance", "50", "Max Chance available to get an awp as a T. AWP Chance is available as 0%, 25%, 50%, 75%, 100%", _, true, 0.0, true, 100.0);

	gcv_CTIncGrenadeChance = AutoExecConfig_CreateConVar("sm_swa_ct_inc_grenade_chance", "50", "Percent Chance to get a Inc-Grenade as a CT", _, true, 0.0, true, 100.0);
	gcv_TMolotovChance = AutoExecConfig_CreateConVar("sm_swa_t_molotov_chance", "50", "Percent Chance to get a Molotov as a T", _, true, 0.0, true, 100.0);
	gcv_CTHEGrenadeChance = AutoExecConfig_CreateConVar("sm_swa_ct_he_grenade_chance", "50", "Percent Chance to get a HE-Grenade as a CT", _, true, 0.0, true, 100.0);
	gcv_THEGrenadeChance = AutoExecConfig_CreateConVar("sm_swa_t_he_grenade_chance", "50", "Percent Chance to get a HE-Grenade as a T", _, true, 0.0, true, 100.0);
	gcv_CTSmokeGrenadeChance = AutoExecConfig_CreateConVar("sm_swa_ct_smoke_grenade_chance", "50", "Percent Chance to get a Smoke-Grenade as a CT", _, true, 0.0, true, 100.0);
	gcv_TSmokeGrenadeChance = AutoExecConfig_CreateConVar("sm_swa_t_smoke_grenade_chance", "50", "Percent Chance to get a Smoke-Grenade as a T", _, true, 0.0, true, 100.0);
	gcv_CTFlashbangChance = AutoExecConfig_CreateConVar("sm_swa_ct_flashbang_chance", "50", "Percent Chance to get a Flashbang as a CT", _, true, 0.0, true, 100.0);
	gcv_TFlashbangChance = AutoExecConfig_CreateConVar("sm_swa_t_flashbang_chance", "50", "Percent Chance to get a Flashbang as a T", _, true, 0.0, true, 100.0);
	gcv_CTDecoyChance = AutoExecConfig_CreateConVar("sm_swa_ct_decoy_chance", "0", "Percent Chance to get a Decoy as a CT", _, true, 0.0, true, 100.0);
	gcv_TDecoyChance = AutoExecConfig_CreateConVar("sm_swa_t_decoy_chance", "0", "Percent Chance to get a Decoy as a T", _, true, 0.0, true, 100.0);

	AutoExecConfig_ExecuteFile();
	AutoExecConfig_CleanFile();
}

public void LateLoad()
{
	for (int i = 1; i <= MaxClients; i++)
		{
			if (!IsClientInGame(i))
				continue;

			OnClientConnected(i);

			if (!AreClientCookiesCached(i))
				continue;

			OnClientCookiesCached(i);
		}

		IsLateLoad = false;
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

public void ParseNades()
{
	char path[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, path, sizeof(path), "configs/SchaedlWeaponAllocator_Nades.cfg");

	if(!FileExists(path))
	{
		SetFailState("Config file %s was not found!", path);
		return;
	}

	KeyValues nadesKeyValues = new KeyValues("Nades");
	if(!nadesKeyValues.ImportFromFile(path))
	{
		SetFailState("Unable to parse the KeyValue file %s!", path);
		return;
	}

	if(!nadesKeyValues.GotoFirstSubKey())
	{
		SetFailState("Unable to find Nades section in the KeyValue file %s!", path);
		return;
	}
	
	do
	{
		char nades[NADE_STRING_LENGTH];
		char team[8];

		nadesKeyValues.GetString("nades", nades, sizeof(nades));
		nadesKeyValues.GetString("team", team, sizeof(team));

		if(strcmp("ct", team, false) == 0)
		{
			AvailableCTNades[CTNadesCount] = nades;
			CTNadesCount++;
		}
		else if (strcmp("t", team, false) == 0)
		{
			AvailableTNades[TNadesCount] = nades;
			TNadesCount++;
		}
		else if (strcmp("any", team, false) == 0)
		{
			AvailableCTNades[CTNadesCount] = nades;
			CTNadesCount++;

			AvailableTNades[TNadesCount] = nades;
			TNadesCount++;
		}
	}
	while(nadesKeyValues.GotoNextKey());
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

	int ctAwpChanceInt = StringToInt(ctAwpChance);
	int tAwpChanceInt = StringToInt(tAwpChance);

	if(ctAwpChanceInt > gcv_CTMaxAWPChance.IntValue)
	{
		ctAwpChanceInt = 25;
		ctAwpChance = "25";

		CTAwpChance[client] = ctAwpChanceInt;
		SetClientCookie(client, CTAwpChanceCookie, ctAwpChance);
	}
	if(tAwpChanceInt > gcv_TMaxAWPChance.IntValue)
	{
		ctAwpChanceInt = 25;
		ctAwpChance = "25";

		TAwpChance[client] = tAwpChanceInt;
		SetClientCookie(client, TAwpChanceCookie, tAwpChance);
	}

	CTAwpChance[client] = ctAwpChanceInt;
	TAwpChance[client] = tAwpChanceInt;
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
	ReplyToCommand(client, "--------------------------------------------------------");
	ReplyToCommand(client, "WEAPON INFO:");
	ReplyToCommand(client, "CT-Rifle: %s", CTRifle[client]);
	ReplyToCommand(client, "T-Rifle: %s", TRifle[client]);
	ReplyToCommand(client, "CT-Pistol: %s", CTPistol[client]);
	ReplyToCommand(client, "T-Pistol: %s", TPistol[client]);
	ReplyToCommand(client, "CT-AWP-Chance: %d%", CTAwpChance[client]);
	ReplyToCommand(client, "T-AWP-Chance: %d%", TAwpChance[client]);
	ReplyToCommand(client, "--------------------------------------------------------");
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

	ReplyToCommand(client, "--------------------------------------------------------");
	ReplyToCommand(client, "WEAPON INFO COOKIES:");
	ReplyToCommand(client, "CT-Rifle: %s", ctRifle);
	ReplyToCommand(client, "T-Rifle: %s", tRifle);
	ReplyToCommand(client, "CT-Pistol: %s", ctPistol);
	ReplyToCommand(client, "T-Pistol: %s", tPistol);
	ReplyToCommand(client, "CT-AWP-Chance: %s%", ctAwpChance);
	ReplyToCommand(client, "T-AWP-Chance: %s%", tAwpChance);
	ReplyToCommand(client, "--------------------------------------------------------");
}

public Action AvailableWeapons(int client, int args)
{
	ReplyToCommand(client, "--------------------------------------------------------");
	ReplyToCommand(client, "Rifles CT:");
	for(int i = 0; i < CTRifleCount; i++)
	{
		ReplyToCommand(client, "%s - %s", AvailableCTRiflesNames[i], AvailableCTRiflesEntity[i]);
	}
	ReplyToCommand(client, "--------------------------------------------------------");
	ReplyToCommand(client, "Pistols CT:");
	for(int i = 0; i < CTPistolCount; i++)
	{
		ReplyToCommand(client, "%s - %s", AvailableCTPistolsNames[i], AvailableCTPistolsEntity[i]);
	}
	ReplyToCommand(client, "--------------------------------------------------------");
	ReplyToCommand(client, "Rifles T:");
	for(int i = 0; i < TRifleCount; i++)
	{
		ReplyToCommand(client, "%s - %s", AvailableTRiflesNames[i], AvailableTRiflesEntity[i]);
	}
	ReplyToCommand(client, "--------------------------------------------------------");
	ReplyToCommand(client, "Pistols T:");
	for(int i = 0; i < TPistolCount; i++)
	{
		ReplyToCommand(client, "%s - %s", AvailableTPistolsNames[i], AvailableTPistolsEntity[i]);
	}
	ReplyToCommand(client, "--------------------------------------------------------");

} 

public Action AvailableNades(int client, int args)
{
	ReplyToCommand(client, "--------------------------------------------------------");
	ReplyToCommand(client, "Nades CT:");
	for(int i = 0; i < CTNadesCount; i++)
	{
		ReplyToCommand(client, "%s", AvailableCTNades[i]);
	}
	ReplyToCommand(client, "--------------------------------------------------------");
	ReplyToCommand(client, "Nades T:");
	for(int i = 0; i < TNadesCount; i++)
	{
		ReplyToCommand(client, "%s", AvailableTNades[i]);
	}
	ReplyToCommand(client, "--------------------------------------------------------");
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
	menu.AddItem("0", "0%", 0 <= gcv_CTMaxAWPChance.IntValue?ITEMDRAW_DEFAULT:ITEMDRAW_DISABLED);
	menu.AddItem("25", "25%", 25 <= gcv_CTMaxAWPChance.IntValue?ITEMDRAW_DEFAULT:ITEMDRAW_DISABLED);
	menu.AddItem("50", "50%", 50 <= gcv_CTMaxAWPChance.IntValue?ITEMDRAW_DEFAULT:ITEMDRAW_DISABLED);
	menu.AddItem("75", "75%", 75 <= gcv_CTMaxAWPChance.IntValue?ITEMDRAW_DEFAULT:ITEMDRAW_DISABLED);
	menu.AddItem("100", "100%", 100 <= gcv_CTMaxAWPChance.IntValue?ITEMDRAW_DEFAULT:ITEMDRAW_DISABLED);
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
	menu.AddItem("0", "0%", 0 <= gcv_TMaxAWPChance.IntValue?ITEMDRAW_DEFAULT:ITEMDRAW_DISABLED);
	menu.AddItem("25", "25%", 25 <= gcv_TMaxAWPChance.IntValue?ITEMDRAW_DEFAULT:ITEMDRAW_DISABLED);
	menu.AddItem("50", "50%", 50 <= gcv_TMaxAWPChance.IntValue?ITEMDRAW_DEFAULT:ITEMDRAW_DISABLED);
	menu.AddItem("75", "75%", 75 <= gcv_TMaxAWPChance.IntValue?ITEMDRAW_DEFAULT:ITEMDRAW_DISABLED);
	menu.AddItem("100", "100%", 100 <= gcv_TMaxAWPChance.IntValue?ITEMDRAW_DEFAULT:ITEMDRAW_DISABLED);
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

	char primary[WEAPON_STRING_LENGTH];
    char secondary[WEAPON_STRING_LENGTH];
    
    bool helmet = true;
    bool kit = true;
	int healthAmount;
	int armorAmount;
	
	RandomizeArrayList(tPlayers);
	RandomizeArrayList(ctPlayers);

	bool isAWPGivenToT = false;
	bool isAWPGivenToCT = false;

    for (int i = 0; i < tCount; i++) {
        int client = tPlayers.Get(i);
		char nades[NADE_STRING_LENGTH];

		int awpChance = TAwpChance[client];
		if(!isAWPGivenToT && awpChance > 0 && GetRandomInt(0, 100) <= awpChance)
		{
			primary = "weapon_awp";
			isAWPGivenToT = true;
		}
        else {
            primary = TRifle[client];
        } 

        secondary = TPistol[client];

        helmet = true;
        kit = false;
		healthAmount = 100;
		armorAmount = 100;

        SetNades(false, nades);
        Retakes_SetPlayerInfo(client, primary, secondary, nades, healthAmount, armorAmount, helmet, kit);
    }

    for (int i = 0; i < ctCount; i++) {
        int client = ctPlayers.Get(i);
		char nades[NADE_STRING_LENGTH];

		int awpChance = CTAwpChance[client];
		if(!isAWPGivenToCT && awpChance > 0 && GetRandomInt(0, 100) <= awpChance)
		{
			primary = "weapon_awp";
			isAWPGivenToCT = true;
		}
        else {
            primary = CTRifle[client];
        } 

        secondary = CTPistol[client];

        kit = true;
        helmet = true;
		healthAmount = 100;
		armorAmount = 100;

        SetNades(true, nades);
        Retakes_SetPlayerInfo(client, primary, secondary, nades, healthAmount, armorAmount, helmet, kit);
    }
}

public void RandomizeArrayList(ArrayList arrayList)
{
	for(int i = 0; i < arrayList.Length; i++)
	{
		SwapArrayItems(arrayList, i, GetRandomInt(0, arrayList.Length-1));
	}
	
}

public void SetNades(bool isClientCT, char nades[NADE_STRING_LENGTH])
{
	switch(gcv_NadeMode.IntValue)
	{
		case 0:
		{
			return;
		}
		case 1:
		{
			SetRandomizedNades(isClientCT, nades);
			return;
		}
		case 2:
		{
			SetNadePresets(isClientCT, nades);
			return;
		}
	}
}

public void SetRandomizedNades(bool isClientCT, char nades[NADE_STRING_LENGTH]) 
{
	char molotov = 'm';
	char incGrenade = 'i';
	char heGrenade = 'h';
	char flashbang = 'f';
	char smokeGrenade = 's';
	char decoy = 'd';
 
	if(isClientCT)
	{
		if(GetRandomInt(0, 100) <= gcv_CTIncGrenadeChance.IntValue)
		{
			nades[0] = incGrenade;
		}
		if(GetRandomInt(0, 100) <= gcv_CTSmokeGrenadeChance.IntValue)
		{
			nades[1] = smokeGrenade;
		}
		if(GetRandomInt(0, 100) <= gcv_CTHEGrenadeChance.IntValue)
		{
			nades[2] = heGrenade;
		}
		if(GetRandomInt(0, 100) <= gcv_CTFlashbangChance.IntValue)
		{
			nades[3] = flashbang;
		}
		if(GetRandomInt(0, 100) <= gcv_CTDecoyChance.IntValue)
		{
			nades[4] = decoy;
		}

	}
	else if(!isClientCT)
	{
		if(GetRandomInt(0, 100) <= gcv_TMolotovChance.IntValue)
		{
			nades[0] = molotov;
		}
		if(GetRandomInt(0, 100) <= gcv_TSmokeGrenadeChance.IntValue)
		{
			nades[1] = smokeGrenade;
		}
		if(GetRandomInt(0, 100) <= gcv_THEGrenadeChance.IntValue)
		{
			nades[2] = heGrenade;
		}
		if(GetRandomInt(0, 100) <= gcv_TFlashbangChance.IntValue)
		{
			nades[3] = flashbang;
		}
		if(GetRandomInt(0, 100) <= gcv_TDecoyChance.IntValue)
		{
			nades[4] = decoy;
		}
	}
}

public void SetNadePresets(bool isClientCT, char nades[NADE_STRING_LENGTH])
{
	if(isClientCT)
	{
		nades = AvailableCTNades[GetRandomInt(0, CTNadesCount)];
	}
	else if(!isClientCT)
	{
		nades = AvailableTNades[GetRandomInt(0, TNadesCount)];
	}
}