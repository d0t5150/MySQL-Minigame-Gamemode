#include <a_samp>

	#include <a_mysql>
	#include <MapAndreas>

	main() return 1;
	native gpci(playerid, serial[], len);
	#define isnull(%1) ((!(%1[0])) || (((%1[0]) == '\1') && (!(%1[1]))))

	enum weathers {
		EXTRASUNNY_LA = (0),
		SUNNY_LA,
		EXTRASUNNY_SMOG_LA,
		SUNNY_SMOG_LA,
		CLOUDY_LA,
		SUNNY_SF,
		EXTRASUNNY_SF,
		CLOUDY_SF,
		RAINY_SF,
		FOGGY_SF,
		SUNNY_VEGAS,
		EXTRASUNNY_VEGAS,
		CLOUDY_VEGAS,
		EXTRASUNNY_COUNTRYSIDE,
		SUNNY_COUNTRYSIDE,
		CLOUDY_COUNTRYSIDE,
		RAINY_COUNTRYSIDE,
		EXTRASUNNY_DESERT,
		SUNNY_DESERT,
		SANDSTORM_DESERT,
		UNDERWATER,
	}

	enum dialogs {
		DIALOG_UNKNOWN = 1,
		DIALOG_LOGIN,
		DIALOG_REGISTER
	}

	enum colors {
		COLOR_NOTICE = (0xE8DFB7FF),
		COLOR_MISSION = (0xCDDB86FF)
	}

	enum modes {
		GAMEMODE_RACE,
	}

	enum variables {
		GMmode,
		GMmodeEx,
		GMmodeRace,
		GMvehicle
	}

	enum grCP {
		Float:cpX,
		Float:cpY,
		Float:cpZ,
	}
	new GameRaceCP[31][grCP];

	new GameMode[variables];

	#define MAX_RACES 			(1)
	#define MAX_CHAT_LINES 		(20)
	#define SERVER_VAR_HASH		"-104*"

new MySQL:database;

	public OnGameModeInit() {
		printf(" Game > Booting the server up..");

		database = mysql_connect("localhost", "user", "test", "aioLG"),
			printf(" Game > Accessing the database securely.");
		if(mysql_errno(database)) {
			printf(" Game > Failed to access the database, shutting down the server."),
				SendRconCommand("exit");
			return 1; 
		}

		SetWeather(SANDSTORM_DESERT),
			printf(" Game > Setting the weather to %i", SANDSTORM_DESERT);

		SetWorldTime(21),
			printf(" Game > Setting the world time to %i:00", 21);

		DisableInteriorEnterExits(),
			printf(" Game > Disabling default interiors");

		ManualVehicleEngineAndLights(),
			printf(" Game > Disabling default vehicle handlings");

		MapAndreas_Init(MAP_ANDREAS_MODE_NONE),
			printf(" Game > Enabling Map Andreas under /SMALL/ mode");

		CallRemoteFunction("OnGameModeChange", "i", GAMEMODE_RACE);
		return 1;
	}

	public OnIncomingConnection(playerid, ip_address[], port) {
		printf(" Player > Receiving connection from (%s:%i)", ip_address, port);
		return 1;
	}

	public OnPlayerConnect(playerid) {
		new name[MAX_PLAYER_NAME], ip_port[22];
		GetPlayerName(playerid, name, MAX_PLAYER_NAME),
		NetStats_GetIpPort(playerid, ip_port, 22),
			printf(" Player > Estabilished connection with %s (%s)", name, ip_port);

		for(new id = 0; id <= MAX_CHAT_LINES; id++)
			SendClientMessage(playerid, 0xFFFFFF00, " ");
		printf(" Player > Clearing chat for %s(%i)", name, playerid),
		SendClientMessage(playerid, COLOR_NOTICE, " > The server is now trying to estabilish a connection, please wait.");

		TogglePlayerSpectating(playerid, true),
			printf(" Player > Setting player's login camera for %s(%i)", name, playerid);
		SetTimerEx("OnPlayerEstabilishConnection", 1, false, "i", playerid);
		return 1;
	}

	forward public OnPlayerEstabilishConnection(playerid);
	public OnPlayerEstabilishConnection(playerid) {
		new name[MAX_PLAYER_NAME], ip_port[22];
		GetPlayerName(playerid, name, MAX_PLAYER_NAME),
		NetStats_GetIpPort(playerid, ip_port, 22),
			printf(" Player > Server is now communicating with %s ((%i)%s)", name, playerid, ip_port);

		InterpolateCameraPos(playerid, -2637.9307, -2827.2493, 18.8876, -2637.9307, -2827.2493, 18.8876, 2000, CAMERA_CUT);
		InterpolateCameraLookAt(playerid, -2638.8201, -2827.7161, 18.8723, -2638.8201, -2827.7161, 18.8723, 2000, CAMERA_CUT);

		for(new id = 0; id <= MAX_CHAT_LINES; id++)
			SendClientMessage(playerid, 0xFFFFFF00, " ");
		printf(" Player > Clearing chat for %s(%i)", name, playerid),
		SendClientMessage(playerid, COLOR_NOTICE, " > The server has now estabilished a connection with you."),
		SendClientMessage(playerid, COLOR_NOTICE, " > Please wait for the server to check for banned IP's..");

		new query[524], gpciAD[41], ip[32];
		gpci(playerid, gpciAD, 41);
		GetPlayerIp(playerid, ip, 32);
		mysql_format(database, query, 524, "SELECT * FROM bans WHERE type = 1 AND gpci = '%e' OR type = 2 AND ip = '%e' OR type = 3 AND username = '%e'", gpciAD, ip, name);
		mysql_tquery(database, query, "OnPlayerRequestBanRecords", "isss", playerid, gpciAD, ip, name);
	}

	forward public OnPlayerRequestBanRecords(playerid, GPCI[], ip[], name[]);
	public OnPlayerRequestBanRecords(playerid, GPCI[], ip[], name[]) {
		if(cache_num_rows()) {
			new type;
			cache_get_value_name_int(0, "type", type);
			switch(type) {
				case 1: { // SAMP GPCI (not unique, rare ban)
					printf(" Player > GPCI banned computer (%s) is being kicked.", GPCI);

					new dialog[1024];
					format(dialog, 1024, "{6B9C6F}Error! {C4C4C4}Banned GPCI address.\n \n\
						{D6D6D6}Your computer's GPCI address %s:(%s) is registered being banned.\n\
						{D6D6D6}This type of ban is extremely rare, and if you should /NOT/ be banned, please contact a staff member.\n \n\
						{E8DFB7} > In order to contact a staff member, visit:\n\
						  {F1F1F1}http://lexus-gaming.pro", ip, GPCI);
					ShowPlayerDialog(playerid, DIALOG_UNKNOWN, DIALOG_STYLE_MSGBOX, "{D1E0D2}Something went wrong..", dialog, "Close", "");
					KickPlayer(playerid);
				}
				case 2: { // IP-Address perm. ban
					printf(" Player > IP banned user %s(%s) is being kicked.", name, ip);

					new dialog[1024];
					format(dialog, 1024, "{6B9C6F}Error! {C4C4C4}Banned IP-address.\n \n\
						{D6D6D6}Your router's IP address (%s) is registered being banned.\n\
						{D6D6D6}This type of ban is permanently and can be appealed.\n \n\
						{E8DFB7} > In order to appeal this ban, visit:\n\
						  {F1F1F1}http://lexus-gaming.pro", ip);
					ShowPlayerDialog(playerid, DIALOG_UNKNOWN, DIALOG_STYLE_MSGBOX, "{D1E0D2}Something went wrong..", dialog, "Close", "");
					KickPlayer(playerid);
				}
				case 3: { // Masteraccount ban
					printf(" Player > Masteraccount banned user %s(%i) is being kicked.", name, playerid);

					new dialog[1024];
					format(dialog, 1024, "{6B9C6F}Error! {C4C4C4}Banned account.\n \n\
						{D6D6D6}This account (%s) has been registered being banned.\n\
						{D6D6D6}This type of ban is only appealable at our website, by filling a form.\n \n\
						{E8DFB7} > In order to appeal this ban, visit:\n\
						  {F1F1F1}http://lexus-gaming.pro", name);
					ShowPlayerDialog(playerid, DIALOG_UNKNOWN, DIALOG_STYLE_MSGBOX, "{D1E0D2}Something went wrong..", dialog, "Close", "");
					KickPlayer(playerid);
				}
			}
		}
		else {
			printf(" Player > Player %s(%i) is not banned and is being looked up for a registration.");

			SendClientMessage(playerid, COLOR_NOTICE, " > The server has run through the active bans and have /NOT/ found you on the list.");
			SendClientMessage(playerid, COLOR_NOTICE, " > Please hold on for the server to check if you're a registered player or not..");

			new query[524];
			mysql_format(database, query, 524, "SELECT * FROM accounts WHERE username = '%e'", name);
			mysql_tquery(database, query, "OnPlayerRequestAccountRecords", "i", playerid);
		}
	}

	forward public OnPlayerRequestAccountRecords(playerid);
	public OnPlayerRequestAccountRecords(playerid) {
		new name[MAX_PLAYER_NAME];
		GetPlayerName(playerid, name, MAX_PLAYER_NAME);
		if(cache_num_rows()) {
			printf(" Player > Player %s(%i) is registered in the database, requesting the client to log in.", name, playerid);
		
			SendClientMessage(playerid, COLOR_NOTICE, " > This account has been registered at us, please enter the password to log in.");

			for(new id = 0; id < cache_num_fields(); id++) {
				switch(cache_get_field_type(id)) {
					case MYSQL_TYPE_VARCHAR: {
						new string[256], fieldname[256];
						cache_get_field_name(id, fieldname, 256);
						cache_get_value_index(0, id, string, 256);
						SetPVarString(playerid, fieldname, string);
						printf("DEBUGGGGG: Field %s is: (%s), VARCHAR", fieldname, string);
					}
					case MYSQL_TYPE_INT24: {
						new int, fieldname[256];
						cache_get_field_name(id, fieldname, 256);
						cache_get_value_index_int(0, id, int);
						SetPVarInt(playerid, fieldname, int);
						printf("DEBUGGGGG: Field %s is: (%i), INTENGER24", fieldname, int);
					}
				}
			}

			ShowPlayerDialog(playerid, DIALOG_LOGIN, DIALOG_STYLE_PASSWORD, "{D1E0D2}Account login pop-up", "{6B9C6F}This account is registered in our database.\n \n\
								{D6D6D6}If you're the owner of this account, please enter its password.\n\
								{D6D6D6}If you are /NOT/ the owner of the account, please register another name.\n", "Submit", "Cancel");
		}
		else {
			printf(" Player > Player %s(%i) is not registered, requesting a password for registration.", name, playerid);
			SendClientMessage(playerid, COLOR_NOTICE, " > This account is not registered at us, please enter a password to register.");
			ShowPlayerDialog(playerid, DIALOG_REGISTER, DIALOG_STYLE_PASSWORD, "{D1E0D2}Account registration pop-up", "{6B9C6F}This account is /NOT/ registered in our database.\n \n\
								{D6D6D6}If you're new to the server, please enter a password to register yourself.\n\
								{D6D6D6}But if you already have got an account registered, please use that one.\n", "Submit", "Cancel");
		}
	}

	KickPlayer(playerid) return SetTimerEx("OnServerKickPlayer", GetPlayerPing(playerid), false, "i", playerid);
	forward public OnServerKickPlayer(playerid);
	public OnServerKickPlayer(playerid) Kick(playerid);

	public OnDialogResponse(playerid, dialogid, response, listitem, inputtext[]) {
		switch(dialogid) {
			case DIALOG_LOGIN: {
				if(response) {
					if(!isnull(inputtext)) {
						new password[256], input[256];
						GetPVarString(playerid, "password", password, 256);
						SHA256_PassHash(inputtext, SERVER_VAR_HASH, input, 256);
						if(!strcmp(inputtext, input)) {
							new name[MAX_PLAYER_NAME];
							GetPlayerName(playerid, name, MAX_PLAYER_NAME);
							SetPlayerColor(playerid, 0xF1F1F1FF),
								printf(" Player > %s(%i) has logged in, registered.", name, playerid);
							new query[524], gpciAD[22], ip[32];
							GetPlayerIp(playerid, ip, 32);
							gpci(playerid, gpciAD, 22);
							mysql_format(database, query, 524, "INSERT INTO connections SET username = '%e', ip = '%e', gpci = '%e', timestamp = %i", name, ip, gpciAD, gettime());
							mysql_tquery(database, query, "OnPlayerLogin", "i", playerid);
						}
						else
							ShowPlayerDialog(playerid, DIALOG_LOGIN, DIALOG_STYLE_PASSWORD, "{D1E0D2}Account login pop-up", "{6B9C6F}This account is registered in our database.\n \n\
									{D6D6D6}If you're the owner of this account, please enter its password.\n\
									{D6D6D6}If you are /NOT/ the owner of the account, please register another name.\n \n\
									{BA686E}Error! {F1F1F1}The password don't match up.", "Submit", "Cancel");
					}
					else
						ShowPlayerDialog(playerid, DIALOG_LOGIN, DIALOG_STYLE_PASSWORD, "{D1E0D2}Account login pop-up", "{6B9C6F}This account is registered in our database.\n \n\
								{D6D6D6}If you're the owner of this account, please enter its password.\n\
								{D6D6D6}If you are /NOT/ the owner of the account, please register another name.\n \n\
								{BA686E}Error! {F1F1F1}You must insert a valid password.", "Submit", "Cancel");
				}
				else {
					SendClientMessage(playerid, COLOR_NOTICE, " < You decided to quit the login panel and was kicked.");
					KickPlayer(playerid);
				}
				return 1;
			}

			case DIALOG_REGISTER: {
				if(response) {
					if(!isnull(inputtext)) {
						new input[256];
						SHA256_PassHash(inputtext, SERVER_VAR_HASH, input, 256);
						SendClientMessage(playerid, COLOR_NOTICE, " > You have now registered your account, processing the information..");
						new query[524], name[MAX_PLAYER_NAME];
						GetPlayerName(playerid, name, MAX_PLAYER_NAME);
						mysql_format(database, query, 524, "INSERT INTO accounts SET username = '%e', password = '%e'", name, input);
						mysql_tquery(database, query, "OnPlayerRegister", "i", playerid),
						printf(" Player > Registering user (%s) - %i", name, playerid);
					} 
					else
						ShowPlayerDialog(playerid, DIALOG_REGISTER, DIALOG_STYLE_PASSWORD, "{D1E0D2}Account registration pop-up", "{6B9C6F}This account is /NOT/ registered in our database.\n \n\
								{D6D6D6}If you're new to the server, please enter a password to register yourself.\n\
								{D6D6D6}But if you already have got an account registered, please use that one.\n \n\
								{BA686E}Error! {F1F1F1}You must insert a valid password.", "Submit", "Cancel");
				}
				else {
					SendClientMessage(playerid, COLOR_NOTICE, " < You decided to quit the registration panel and was kicked.");
					KickPlayer(playerid);
				}
				return 1;
			}
		}
		return 0;
	}

	forward public OnPlayerRegister(playerid);
	public OnPlayerRegister(playerid) {
		new query[524], name[MAX_PLAYER_NAME], gpciAD[22], ip[32];
		GetPlayerName(playerid, name, MAX_PLAYER_NAME);
		GetPlayerIp(playerid, ip, 32);
		gpci(playerid, gpciAD, 22);
		mysql_format(database, query, 524, "INSERT INTO connections SET username = '%e', ip = '%e', gpci = '%e', timestamp = %i", name, ip, gpciAD, gettime());
		mysql_tquery(database, query, "OnPlayerLogin", "i", playerid);
		printf(" Player > Registered player to the database, %s(%i)", name, playerid);
	}

	forward public OnPlayerLogin(playerid);
	public OnPlayerLogin(playerid) {
		printf(" Player > Playerid (%i) has logged in, loading gamemode for player.", playerid);
		SendClientMessage(playerid, COLOR_NOTICE, " <> You've now logged in, requesting the server to spawn you..");


	}

	public OnPlayerEnterRaceCheckpoint(playerid) {
		if(GameMode[GMmode] != _:GAMEMODE_RACE)
			return 0;
		switch(GameMode[GMmodeEx]) {
			case 1: {
				if(GetPVarInt(playerid, "race CP") == 2) {
					SendClientMessage(playerid, -1, "finished");
				}
				else if(GetPVarInt(playerid, "race CP") < 1) {
					SetPlayerRaceCheckpoint(playerid, 0, GameRaceCP[GetPVarInt(playerid, "race CP")][cpX], GameRaceCP[GetPVarInt(playerid, "race CP")][cpY], GameRaceCP[GetPVarInt(playerid, "race CP")][cpZ], GameRaceCP[GetPVarInt(playerid, "race CP")+1][cpX], GameRaceCP[GetPVarInt(playerid, "race CP")+1][cpY], GameRaceCP[GetPVarInt(playerid, "race CP")+1][cpZ], 3.0);
				}
				else
					SetPlayerRaceCheckpoint(playerid, 1, GameRaceCP[GetPVarInt(playerid, "race CP")][cpX], GameRaceCP[GetPVarInt(playerid, "race CP")][cpY], GameRaceCP[GetPVarInt(playerid, "race CP")][cpZ], GameRaceCP[GetPVarInt(playerid, "race CP")+1][cpX], GameRaceCP[GetPVarInt(playerid, "race CP")+1][cpY], GameRaceCP[GetPVarInt(playerid, "race CP")+1][cpZ], 3.0);
			}
			default: {
				if(GetPVarInt(playerid, "race CP") == 30) {
					SendClientMessage(playerid, -1, "finished");
				}
				else if(GetPVarInt(playerid, "race CP") < 29) {
					SetPlayerRaceCheckpoint(playerid, 0, GameRaceCP[GetPVarInt(playerid, "race CP")][cpX], GameRaceCP[GetPVarInt(playerid, "race CP")][cpY], GameRaceCP[GetPVarInt(playerid, "race CP")][cpZ], GameRaceCP[GetPVarInt(playerid, "race CP")+1][cpX], GameRaceCP[GetPVarInt(playerid, "race CP")+1][cpY], GameRaceCP[GetPVarInt(playerid, "race CP")+1][cpZ], 3.0);
				}
				else
					SetPlayerRaceCheckpoint(playerid, 1, GameRaceCP[GetPVarInt(playerid, "race CP")][cpX], GameRaceCP[GetPVarInt(playerid, "race CP")][cpY], GameRaceCP[GetPVarInt(playerid, "race CP")][cpZ], GameRaceCP[GetPVarInt(playerid, "race CP")+1][cpX], GameRaceCP[GetPVarInt(playerid, "race CP")+1][cpY], GameRaceCP[GetPVarInt(playerid, "race CP")+1][cpZ], 3.0);
			}
		}
		return 1;
	}

	forward public OnGameModeChange(mode);
	public OnGameModeChange(mode) {
		switch(mode) {
			case GAMEMODE_RACE: {
				GameMode[GMmode] = mode;
				GameMode[GMmodeEx] = random(MAX_RACES);
				switch(GameMode[GMmodeEx]) {
					case 1: {
						GameMode[GMmodeRace] = 2;
						GameMode[GMvehicle] = 411;

						MapAndreas_FindZ_For2DCoord(250, -116, GameRaceCP[1][cpZ]);
						GameRaceCP[1][cpX] = 250;
						GameRaceCP[1][cpY] = -116;

						MapAndreas_FindZ_For2DCoord(257, 41, GameRaceCP[2][cpZ]);
						GameRaceCP[2][cpX] = 257;
						GameRaceCP[2][cpY] = 41;
					}

					default: {	
						GameMode[GMmodeRace] = 30;
						GameMode[GMvehicle] = 560;

						MapAndreas_FindZ_For2DCoord(64, 785, GameRaceCP[1][cpZ]);
						GameRaceCP[1][cpX] = 64;
						GameRaceCP[1][cpY] = 785;

						MapAndreas_FindZ_For2DCoord(156, 852, GameRaceCP[2][cpZ]);
						GameRaceCP[2][cpX] = 156;
						GameRaceCP[2][cpY] = 852;

						MapAndreas_FindZ_For2DCoord(238, 855, GameRaceCP[3][cpZ]);
						GameRaceCP[3][cpX] = 238;
						GameRaceCP[3][cpY] = 855;

						MapAndreas_FindZ_For2DCoord(360, 882, GameRaceCP[4][cpZ]);
						GameRaceCP[4][cpX] = 360;
						GameRaceCP[4][cpY] = 882;

						MapAndreas_FindZ_For2DCoord(447, 887, GameRaceCP[5][cpZ]);
						GameRaceCP[5][cpX] = 447;
						GameRaceCP[5][cpY] = 887;

						MapAndreas_FindZ_For2DCoord(514, 928, GameRaceCP[6][cpZ]);
						GameRaceCP[6][cpX] = 514;
						GameRaceCP[6][cpY] = 928;

						MapAndreas_FindZ_For2DCoord(516, 975, GameRaceCP[7][cpZ]);
						GameRaceCP[7][cpX] = 516;
						GameRaceCP[7][cpY] = 975;

						MapAndreas_FindZ_For2DCoord(510, 1019, GameRaceCP[8][cpZ]);
						GameRaceCP[8][cpX] = 510;
						GameRaceCP[8][cpY] = 1019;

						MapAndreas_FindZ_For2DCoord(510, 1131, GameRaceCP[9][cpZ]);
						GameRaceCP[9][cpX] = 510;
						GameRaceCP[9][cpY] = 1131;

						MapAndreas_FindZ_For2DCoord(593, 1215, GameRaceCP[10][cpZ]);
						GameRaceCP[10][cpX] = 593;
						GameRaceCP[10][cpY] = 1215;

						MapAndreas_FindZ_For2DCoord(656, 1276, GameRaceCP[11][cpZ]);
						GameRaceCP[11][cpX] = 656;
						GameRaceCP[11][cpY] = 1276;

						MapAndreas_FindZ_For2DCoord(669, 1314, GameRaceCP[12][cpZ]);
						GameRaceCP[12][cpX] = 669;
						GameRaceCP[12][cpY] = 1314;

						MapAndreas_FindZ_For2DCoord(724, 1337, GameRaceCP[13][cpZ]);
						GameRaceCP[13][cpX] = 724;
						GameRaceCP[13][cpY] = 1337;

						MapAndreas_FindZ_For2DCoord(1006, 1336, GameRaceCP[14][cpZ]);
						GameRaceCP[14][cpX] = 1006;
						GameRaceCP[14][cpY] = 1336;

						MapAndreas_FindZ_For2DCoord(1063, 1320, GameRaceCP[15][cpZ]);
						GameRaceCP[15][cpX] = 1063;
						GameRaceCP[15][cpY] = 1320;

						MapAndreas_FindZ_For2DCoord(1078, 1257, GameRaceCP[16][cpZ]);
						GameRaceCP[16][cpX] = 1078;
						GameRaceCP[16][cpY] = 1257;

						MapAndreas_FindZ_For2DCoord(1101, 1173, GameRaceCP[17][cpZ]);
						GameRaceCP[17][cpX] = 1101;
						GameRaceCP[17][cpY] = 1173;

						MapAndreas_FindZ_For2DCoord(1160, 1112, GameRaceCP[18][cpZ]);
						GameRaceCP[18][cpX] = 1160;
						GameRaceCP[18][cpY] = 1112;

						MapAndreas_FindZ_For2DCoord(1308, 1079, GameRaceCP[19][cpZ]);
						GameRaceCP[19][cpX] = 1308;
						GameRaceCP[19][cpY] = 1079;

						MapAndreas_FindZ_For2DCoord(1412, 967, GameRaceCP[20][cpZ]);
						GameRaceCP[20][cpX] = 1412;
						GameRaceCP[20][cpY] = 967;

						MapAndreas_FindZ_For2DCoord(1431, 833, GameRaceCP[21][cpZ]);
						GameRaceCP[21][cpX] = 1431;
						GameRaceCP[21][cpY] = 833;

						MapAndreas_FindZ_For2DCoord(1446, 639, GameRaceCP[22][cpZ]);
						GameRaceCP[22][cpX] = 1446;
						GameRaceCP[22][cpY] = 639;

						MapAndreas_FindZ_For2DCoord(1438, 487, GameRaceCP[23][cpZ]);
						GameRaceCP[23][cpX] = 1438;
						GameRaceCP[23][cpY] = 487;

						MapAndreas_FindZ_For2DCoord(1440, 308, GameRaceCP[24][cpZ]);
						GameRaceCP[24][cpX] = 1440;
						GameRaceCP[24][cpY] = 308;

						MapAndreas_FindZ_For2DCoord(1381, 197, GameRaceCP[25][cpZ]);
						GameRaceCP[25][cpX] = 1381;
						GameRaceCP[25][cpY] = 197;

						MapAndreas_FindZ_For2DCoord(1375, 33, GameRaceCP[26][cpZ]);
						GameRaceCP[26][cpX] = 1375;
						GameRaceCP[26][cpY] = 33;

						MapAndreas_FindZ_For2DCoord(1366, -137, GameRaceCP[27][cpZ]);
						GameRaceCP[27][cpX] = 1366;
						GameRaceCP[27][cpY] = -137;

						MapAndreas_FindZ_For2DCoord(1198, -177, GameRaceCP[28][cpZ]);
						GameRaceCP[28][cpX] = 1198;
						GameRaceCP[28][cpY] = -177;

						MapAndreas_FindZ_For2DCoord(1038, -174, GameRaceCP[29][cpZ]);
						GameRaceCP[29][cpX] = 1038;
						GameRaceCP[29][cpY] = -174;

						MapAndreas_FindZ_For2DCoord(870, -151, GameRaceCP[30][cpZ]);
						GameRaceCP[30][cpX] = 870;
						GameRaceCP[30][cpY] = -151;
					}
				}
				
				SendClientMessageToAll(COLOR_MISSION, "The gamemode was randomly selected for.. vehicle racing!");
				SendClientMessageToAll(COLOR_MISSION, "The race will start in 10 seconds, get ready!");

				for(new playerid = 0; playerid < MAX_PLAYERS; playerid++) {
					if(IsPlayerConnected(playerid) && GetPlayerColor(playerid) == 0xF1F1F1FF) {
						DisableRemoteVehicleCollisions(playerid, 1);
						SetPVarInt(playerid, "race vehicle", CreateVehicle(GameMode[GMvehicle], GameRaceCP[1][cpX], GameRaceCP[1][cpY], GameRaceCP[1][cpZ], random(360), random(140), random(140), -1, 0));
						PutPlayerInVehicle(playerid, GetPVarInt(playerid, "race vehicle"), 0);
						TogglePlayerControllable(playerid, false);
					}
				}

				SetTimerEx("OnGameLaunchRace", 7*1000, false, "i", 0);
			}
		}
	}

	forward public OnGameLaunchRace(stage);
	public OnGameLaunchRace(stage) {
		for(new playerid = 0; playerid < MAX_PLAYERS; playerid++) {
			if(IsPlayerConnected(playerid) && GetPlayerColor(playerid) == 0xF1F1F1FF && GetPlayerVehicleID(playerid) == 0) {
				DisableRemoteVehicleCollisions(playerid, 1);
				SetPVarInt(playerid, "race vehicle", CreateVehicle(GameMode[GMvehicle], GameRaceCP[1][cpX], GameRaceCP[1][cpY], GameRaceCP[1][cpZ], random(360), random(140), random(140), -1, 0));
				PutPlayerInVehicle(playerid, GetPVarInt(playerid, "race vehicle"), 0);
				TogglePlayerControllable(playerid, false);
			}
		}

		switch(stage) {
			case 0: {
				GameTextForAll("Ready..", 999, 3);
				SetTimerEx("OnGameLaunchRace", 1000, false, "i", 1);

			}
			case 1: {
				GameTextForAll("Set..", 999, 3);
				SetTimerEx("OnGameLaunchRace", 1000, false, "i", 2);
			}
			case 2: {
				GameTextForAll("~w~GO!", 999, 3);
				for(new playerid = 0; playerid < MAX_PLAYERS; playerid++) {
					if(IsPlayerConnected(playerid) && GetPlayerColor(playerid) == 0xF1F1F1FF && GetPlayerVehicleID(playerid) != 0) {
						TogglePlayerControllable(playerid, true);
					}
				}
			}
		}
	}
