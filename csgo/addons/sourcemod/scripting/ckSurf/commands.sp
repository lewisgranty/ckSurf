
/*public Action Command_rTimes(int client, int args)
{
	for (int i = 0; i < MAXZONEGROUPS; i++)
		PrintToChatAll("%i. %f",i, g_fReplayTimes[i]);

	return Plugin_Handled;
}*/

public Action Command_Vip(int client, int args)
{
	if (!IsValidClient(client))
		return Plugin_Handled;

	if (!g_bflagTitles[client][0] && g_hFreeVipAtRank.IntValue < g_PlayerRank[client])
	{
		PrintToChat(client, "[%cSurf Timer%c] This command requires the VIP title.", MOSSGREEN, WHITE);
		return Plugin_Handled;
	}

	Menu vipEffects = CreateMenu(h_vipEffects);
	char szMenuItem[128];

	SetMenuTitle(vipEffects, "Exclusive VIP effects: ");

	if (!g_bTrailOn[client])
		Format(szMenuItem, 128, "[OFF] Player Trail");
	else
		Format(szMenuItem, 128, "[ON] Player Trail");
	AddMenuItem(vipEffects, "", szMenuItem);

	Format(szMenuItem, 128, "Trail Color: %s", RGB_COLOR_NAMES[g_iTrailColor[client]]);
	AddMenuItem(vipEffects, "", szMenuItem);
	AddMenuItem(vipEffects, "", "Vote to extend map (!ve)");

	if (GetConVarBool(g_hAllowVipMute))
		AddMenuItem(vipEffects, "", "Mute a player (!vmute)");
	else
		AddMenuItem(vipEffects, "", "Mute a player (!vmute)", ITEMDRAW_DISABLED);

	AddMenuItem(vipEffects, "", "More to come...", ITEMDRAW_DISABLED);

	SetMenuExitButton(vipEffects, true);
	DisplayMenu(vipEffects, client, MENU_TIME_FOREVER);
	return Plugin_Handled;
}

public int h_vipEffects(Menu tMenu, MenuAction action, int client, int item)
{
	switch (action)
	{
		case MenuAction_Select:
		{
			switch (item)
			{
				case 0:
				{
					toggleTrail(client);
					CreateTimer(0.1, RefreshVIPMenu, client, TIMER_FLAG_NO_MAPCHANGE);
				}
				case 1:
				{
					CreateTimer(0.1, RefreshVIPMenu, client, TIMER_FLAG_NO_MAPCHANGE);
					changeTrailColor(client);
				}
				case 2:
				{
					Command_VoteExtend(client, 0);
				}
				case 3:
				{
					Command_MutePlayer(client, 0);
				}
			}
		}
		case MenuAction_End:
		{
			CloseHandle(tMenu);
		}
	}
}

public Action Command_MutePlayer (int client, int args)
{
	if (!IsValidClient(client))
		return Plugin_Handled;

	if (!GetConVarBool(g_hAllowVipMute))
	{
		ReplyToCommand(client, "[%cSurf Timer%c] VIP muting has been disabled on this server.", MOSSGREEN, WHITE);
		return Plugin_Handled;
	}


	if (!g_bflagTitles[client][0] && g_hFreeVipAtRank.IntValue < g_PlayerRank[client])
	{
		ReplyToCommand(client, "[%cSurf Timer%c] This command requires the VIP title.", MOSSGREEN, WHITE);
		return Plugin_Handled;
	}

	if (args > 0)
	{
		char szName[MAX_NAME_LENGTH], szBuffer[MAX_NAME_LENGTH];
		GetCmdArg(1, szName, MAX_NAME_LENGTH);

		int target = Client_FindByName(szName, true, false);

		if (target != -1)
		{
			if (BaseComm_IsClientMuted(target))
			{
				if (BaseComm_SetClientMute(target, false))
					PrintToChatAll("[%cSurf Timer%c] %s was unmuted by a VIP.", MOSSGREEN, WHITE, szBuffer);
			}
			else
			{
				if (BaseComm_SetClientMute(target, true))
					PrintToChatAll("[%cSurf Timer%c] %s was muted by a VIP.", MOSSGREEN, WHITE, szBuffer);
			}
			return Plugin_Handled;
		}
		else
		{
			PrintToChat(client, "[%cSurf Timer%c] Could not find a player with the name of %s.", MOSSGREEN, WHITE, szName);
			return Plugin_Handled;
		}
	}

	Menu mMutePlayers = CreateMenu(h_MutePlayers);
	SetMenuTitle(mMutePlayers, "Select player to mute or unmute");
	char szMenuItem[48], id[8], count;
	for (int i = 0; i < MAXPLAYERS+1; i++)
	{
		if (IsValidClient(i) && !IsFakeClient(i) && client != i)
		{
			count++;
			IntToString(i, id, 8);
			if (BaseComm_IsClientMuted(i))
			{
				GetClientName(i, szMenuItem, 48);
				Format(szMenuItem, 48, "[ON] %s", szMenuItem);
			}
			else
			{
				GetClientName(i, szMenuItem, 48);
				Format(szMenuItem, 48, "[OFF] %s", szMenuItem);
			}
			AddMenuItem(mMutePlayers, id, szMenuItem);
		}
	}
	if (count == 0)
	{
		ReplyToCommand(client, "[%cSurf Timer%c] No valid players found.", MOSSGREEN, WHITE);
		CloseHandle(mMutePlayers);
		return Plugin_Handled;
	}
	SetMenuExitButton(mMutePlayers, true);
	DisplayMenu(mMutePlayers, client, MENU_TIME_FOREVER);
	return Plugin_Handled;
}

public int h_MutePlayers(Menu tMenu, MenuAction action, int client, int item)
{
	switch (action)
	{
		case MenuAction_Select:
		{
			char aID[8];
			GetMenuItem(tMenu, item, aID, sizeof(aID));
			int clientID = StringToInt(aID);
			if (IsValidClient(clientID))
			{
				char szName[MAX_NAME_LENGTH];
				GetClientName(clientID, szName, MAX_NAME_LENGTH);
				if (BaseComm_IsClientMuted(clientID))
				{
					if (BaseComm_SetClientMute(clientID, false))
						PrintToChatAll("[%cSurf Timer%c] %s was unmuted by a VIP.", MOSSGREEN, WHITE, szName);
				}
				else
				{
					if (BaseComm_SetClientMute(clientID, true))
						PrintToChatAll("[%cSurf Timer%c] %s was muted by a VIP.", MOSSGREEN, WHITE, szName);

				}
			}
		}
		case MenuAction_End:
		{
			CloseHandle(tMenu);
		}
	}
}

public Action Command_SetTitle(int client, int args)
{
	if (!IsValidClient(client))
		return Plugin_Handled;

	if (!g_bHasTitle[client])
	{
		PrintToChat(client, "[%cSurf Timer%c] You don't have access to any custom titles.", MOSSGREEN, WHITE);
		return Plugin_Handled;
	}
	Menu playersTitles = CreateMenu(H_PlayersTitles);
	SetMenuTitle(playersTitles, "Your available titles: ");

	char id[8], szMenuItem[54];
	for (int i = 0; i < TITLE_COUNT; i++)
	{
		if (g_bflagTitles[client][i] && !StrEqual(g_szflagTitle[i], ""))
		{

			IntToString(i, id, 8);
			if (g_iTitleInUse[client] == i)
				Format(szMenuItem, 54, "[ON] %s", g_szflagTitle[i]);
			else
				Format(szMenuItem, 54, "[OFF] %s", g_szflagTitle[i]);

			AddMenuItem(playersTitles, id, szMenuItem);
		}
	}

	SetMenuExitButton(playersTitles, true);
	DisplayMenu(playersTitles, client, MENU_TIME_FOREVER);
	return Plugin_Handled;
}
public int H_PlayersTitles(Menu tMenu, MenuAction action, int client, int item)
{
	switch (action)
	{
		case MenuAction_Select:
		{
			if (!IsValidClient(client))
				return;
			char aID[8], szSteamID[32];
			GetMenuItem(tMenu, item, aID, sizeof(aID));
			int titleID = StringToInt(aID);

			if (g_iTitleInUse[client] == titleID)
				g_iTitleInUse[client] = -1;
			else
				g_iTitleInUse[client] = titleID;

			SetPlayerRank(client);
			CreateTimer(0.5, SetClanTag, client, TIMER_FLAG_NO_MAPCHANGE);

			//GetClientAuthString(client, szSteamID, 32, true);
			GetClientAuthId(client, AuthId_Steam2, szSteamID, MAX_NAME_LENGTH, true);

			db_updatePlayerTitleInUse(g_iTitleInUse[client], szSteamID);
		}
		case MenuAction_End:
		{
			CloseHandle(tMenu);
		}
	}
}

public Action Command_VoteExtend(int client, int args)
{
	if(!IsValidClient(client))
		return Plugin_Handled;

	if (!g_bflagTitles[client][0] && g_hFreeVipAtRank.IntValue < g_PlayerRank[client])
	{
		ReplyToCommand(client, "[Surf Timer] This command requires the VIP title.");
		return Plugin_Handled;
	}

	if (IsVoteInProgress())
	{
		ReplyToCommand(client, "[Surf Timer] Please wait until the current vote has finished.");
		return Plugin_Handled;
	}

	if (g_VoteExtends >= GetConVarInt(g_hMaxVoteExtends))
	{
		ReplyToCommand(client, "[Surf Timer] There have been too many extends this map.");
		return Plugin_Handled;
	}

	// Here we go through and make sure this user has not already voted. This persists throughout map.
	for (int i = 0; i < g_VoteExtends; i++)
	{
		if (StrEqual(g_szUsedVoteExtend[i], g_szSteamID[client], false))
		{
			ReplyToCommand(client, "[Surf Timer] You have already used your vote to extend this map.");
			return Plugin_Handled;
		}
	}

	StartVoteExtend(client);
	return Plugin_Handled;
}

public void StartVoteExtend(int client)
{
	char szPlayerName[MAX_NAME_LENGTH];
	GetClientName(client, szPlayerName, MAX_NAME_LENGTH);
	CPrintToChatAll("[{olive}CK{default}] Vote to Extend started by {green}%s{default}", szPlayerName);

	g_szUsedVoteExtend[g_VoteExtends] = g_szSteamID[client];	// Add the user's steam ID to the list
	g_VoteExtends++;	// Increment the total number of vote extends so far

	Menu voteExtend = CreateMenu(H_VoteExtend);
	SetVoteResultCallback(voteExtend, H_VoteExtendCallback);
	char szMenuTitle[128];

	char buffer[8];
	IntToString(RoundToFloor(GetConVarFloat(g_hVoteExtendTime)), buffer, sizeof(buffer));

	Format(szMenuTitle, sizeof(szMenuTitle), "Extend map for %s minutes?", buffer);
	SetMenuTitle(voteExtend, szMenuTitle);

	AddMenuItem(voteExtend, "", "Yes");
	AddMenuItem(voteExtend, "", "No");
	SetMenuExitButton(voteExtend, false);
	VoteMenuToAll(voteExtend, 20);
}

public int H_VoteExtend(Menu tMenu, MenuAction action, int client, int item)
{
	if (action == MenuAction_End)
	{
		CloseHandle(tMenu);
	}
}

public void H_VoteExtendCallback(Menu menu, int num_votes, int num_clients, const int[][] client_info, int num_items, const int[][] item_info)
{
	int votesYes = 0;
	int votesNo = 0;

	if (item_info[0][VOTEINFO_ITEM_INDEX] == 0)
	{	// If the winner is Yes
		votesYes = item_info[0][VOTEINFO_ITEM_VOTES];
		if (num_items > 1)
		{
			votesNo = item_info[1][VOTEINFO_ITEM_VOTES];
		}
	}
	else
	{	// If the winner is No
		votesNo = item_info[0][VOTEINFO_ITEM_VOTES];
		if (num_items > 1)
		{
			votesYes = item_info[1][VOTEINFO_ITEM_VOTES];
		}
	}

	if (votesYes > votesNo) // A tie is a failure
	{
		CPrintToChatAll("[{olive}CK{default}] Vote to Extend succeeded - Votes Yes: %i | Votes No: %i", votesYes, votesNo);
		ExtendMapTimeLimit(RoundToFloor(GetConVarFloat(g_hVoteExtendTime)*60));
	}
	else
	{
		CPrintToChatAll("[{olive}CK{default}] Vote to Extend failed - Votes Yes: %i | Votes No: %i", votesYes, votesNo);
	}
}

public Action Command_normalMode(int client, int args)
{
	if (!IsValidClient(client))
		return Plugin_Handled;

	Client_Stop(client, 1);
	g_bPracticeMode[client] = false;
	Command_Restart(client, 1);

	PrintToChat(client, "%t", "PracticeNormal", MOSSGREEN, WHITE, MOSSGREEN);
	return Plugin_Handled;
}

public Action Command_createPlayerCheckpoint(int client, int args)
{
	if (!IsValidClient(client))
		return Plugin_Handled;

	if (g_iClientInZone[client][0] == 1 || g_iClientInZone[client][0] == 5)
	{
		PrintToChat(client, "%t", "PracticeInStartZone", MOSSGREEN, WHITE);
		return Plugin_Handled;
	}

	float CheckpointTime = GetGameTime();

	// Move old checkpoint to the undo values, if the last checkpoint was made more than a second ago
	if (g_bCreatedTeleport[client] && (CheckpointTime - g_fLastPlayerCheckpoint[client]) > 1.0)
	{
		g_fLastPlayerCheckpoint[client] = CheckpointTime;
		Array_Copy(g_fCheckpointLocation[client], g_fCheckpointLocation_undo[client], 3);
		Array_Copy(g_fCheckpointVelocity[client], g_fCheckpointVelocity_undo[client], 3);
		Array_Copy(g_fCheckpointAngle[client], g_fCheckpointAngle_undo[client], 3);
	}

	g_bCreatedTeleport[client] = true;
	GetClientAbsOrigin(client, g_fCheckpointLocation[client]);
	GetEntPropVector(client, Prop_Data, "m_vecVelocity", g_fCheckpointVelocity[client]);
	GetClientEyeAngles(client, g_fCheckpointAngle[client]);


	PrintToChat(client, "%t", "PracticePointCreated", MOSSGREEN, WHITE, MOSSGREEN, WHITE);

	return Plugin_Handled;
}

public Action Command_goToPlayerCheckpoint(int client, int args)
{
	if (!IsValidClient(client))
		return Plugin_Handled;

	if (g_fCheckpointLocation[client][0] != 0.0 && g_fCheckpointLocation[client][1] != 0.0 && g_fCheckpointLocation[client][2] != 0.0)
	{
		if (g_bPracticeMode[client] == false)
		{
			PrintToChat(client, "%t", "PracticeStarted", MOSSGREEN, WHITE, MOSSGREEN, WHITE, MOSSGREEN, WHITE);
			PrintToChat(client, "%t", "PracticeStarted2", MOSSGREEN, WHITE, MOSSGREEN, WHITE, MOSSGREEN, WHITE);
			g_bPracticeMode[client] = true;
		}

		SetEntPropVector(client, Prop_Data, "m_vecVelocity", view_as<float>( { 0.0, 0.0, 0.0 } ));
		TeleportEntity(client, g_fCheckpointLocation[client], g_fCheckpointAngle[client], g_fCheckpointVelocity[client]);
	}
	else
		PrintToChat(client, "%t", "PracticeStartError", MOSSGREEN, WHITE, MOSSGREEN);

	return Plugin_Handled;
}

public Action Command_undoPlayerCheckpoint(int client, int args)
{
	if (!IsValidClient(client))
		return Plugin_Handled;

	if (g_fCheckpointLocation_undo[client][0] != 0.0 && g_fCheckpointLocation_undo[client][1] != 0.0 && g_fCheckpointLocation_undo[client][2] != 0.0)
	{
		float tempLocation[3], tempVelocity[3], tempAngle[3];

		// Location
		Array_Copy(g_fCheckpointLocation_undo[client], tempLocation, 3);
		Array_Copy(g_fCheckpointLocation[client], g_fCheckpointLocation_undo[client], 3);
		Array_Copy(tempLocation, g_fCheckpointLocation[client], 3);

		// Velocity
		Array_Copy(g_fCheckpointVelocity_undo[client], tempVelocity, 3);
		Array_Copy(g_fCheckpointVelocity[client], g_fCheckpointVelocity_undo[client], 3);
		Array_Copy(tempVelocity, g_fCheckpointVelocity[client], 3);

		// Angle
		Array_Copy(g_fCheckpointAngle_undo[client], tempAngle, 3);
		Array_Copy(g_fCheckpointAngle[client], g_fCheckpointAngle_undo[client], 3);
		Array_Copy(tempAngle, g_fCheckpointAngle[client], 3);

		PrintToChat(client, "%t", "PracticeUndo", MOSSGREEN, WHITE);
	}
	else
		PrintToChat(client, "%t", "PracticeUndoError", MOSSGREEN, WHITE, MOSSGREEN);

	return Plugin_Handled;
}

public Action Command_Teleport(int client, int args)
{
	// Throttle using !back to fix errors with replays
	if ((GetGameTime() - g_fLastCommandBack[client]) < 1.0)
		return Plugin_Handled;
	else
		g_fLastCommandBack[client] = GetGameTime();

	if (g_Stage[g_iClientInZone[client][2]][client] == 1)
	{
		teleportClient(client, g_iClientInZone[client][2], 1, false);
		return Plugin_Handled;
	}

	teleportClient(client, g_iClientInZone[client][2], g_Stage[g_iClientInZone[client][2]][client], false);
	return Plugin_Handled;
}

public Action Command_GoBack(int client, int args)
{
	// Throttle using !back to fix errors with replays
	if ((GetGameTime() - g_fLastCommandBack[client]) < 1.0)
		return Plugin_Handled;
	else
		g_fLastCommandBack[client] = GetGameTime();

	if (g_Stage[g_iClientInZone[client][2]][client] == 1)
	{
		teleportClient(client, g_iClientInZone[client][2], 1, false);
		return Plugin_Handled;
	}

	teleportClient(client, g_iClientInZone[client][2], g_Stage[g_iClientInZone[client][2]][client]-1, true);
	return Plugin_Handled;
}

public Action Command_HowTo(int client, int args)
{
	OpenMOTD(client, "https://www.youtube.com/embed/lYc52kwTNb8");
	return Plugin_Handled;
}

public Action Command_Zones(int client, int args)
{
	if (IsValidClient(client))
	{
		ZoneMenu(client);
		resetSelection(client);
	}
	return Plugin_Handled;
}

public Action Command_ListBonuses(int client, int args)
{
	if (IsValidClient(client))
	{
		ListBonuses(client, 1);
	}
	return Plugin_Handled;
}

public void ListBonuses(int client, int type)
{
	// Types: Start(1), End(2), Stage(3), Checkpoint(4), Speed(5), TeleToStart(6), Validator(7), Chekcer(8), Stop(0)
	char buffer[3];
	Menu listBonusesMenu;
	if (type == 1)
	{
		listBonusesMenu = new Menu(MenuHandler_SelectBonus);
	}
	else
	{
		listBonusesMenu = new Menu(MenuHandler_SelectBonusTop);
	}

	listBonusesMenu.SetTitle("Choose a bonus");

	if (g_mapZoneGroupCount > 1)
	{
		for (int i = 1; i < g_mapZoneGroupCount; i++)
		{
			IntToString(i, buffer, 3);
			listBonusesMenu.AddItem(buffer, g_szZoneGroupName[i]);
		}
	}
	else
	{
		PrintToChat(client, "[%cSurf Timer%c] There are no bonuses in this map.", MOSSGREEN, WHITE);
		return;
	}

	listBonusesMenu.ExitButton = true;
	listBonusesMenu.Display(client, 60);
}

public int MenuHandler_SelectBonusTop(Menu sMenu, MenuAction action, int client, int item)
{
	switch (action)
	{
		case MenuAction_Select:
		{
			char aID[3];
			GetMenuItem(sMenu, item, aID, sizeof(aID));
			int zoneGrp = StringToInt(aID);
			db_selectBonusTopSurfers(client, g_szMapName, zoneGrp);
		}
		case MenuAction_End:
		{
			delete sMenu;
		}
	}
}


public int MenuHandler_SelectBonus(Menu sMenu, MenuAction action, int client, int item)
{
	switch (action)
	{
		case MenuAction_Select:
		{
			char aID[3];
			GetMenuItem(sMenu, item, aID, sizeof(aID));
			int zoneGrp = StringToInt(aID);

			teleportClient(client, zoneGrp, 1, true);
		}
		case MenuAction_End:
		{
			delete sMenu;
		}
	}
}

public Action Command_ToBonus(int client, int args)
{
	if (!IsValidClient(client))
		return Plugin_Handled;

	// If not enough arguments, or there is more than one bonus
	if (args < 1 && g_mapZoneGroupCount > 2) // Tell player to select specific bonus
	{
		/*PrintToChat(client, "[%cSurf Timer%c] Usage: !b <bonus number>", MOSSGREEN, WHITE);
		if (g_mapZoneGroupCount > 1)
		{
			PrintToChat(client, "[%cSurf Timer%c] Available bonuses:", MOSSGREEN, WHITE);
			for (int i = 1; i < g_mapZoneGroupCount; i++)
			{
				PrintToChat(client, "[%c%i.%c] %s", YELLOW, i, WHITE, g_szZoneGroupName[i]);
			}
		}*/
		ListBonuses(client, 1);
		return Plugin_Handled;
	}

	int zoneGrp;
	if (g_mapZoneGroupCount > 2) // If there is more than one bonus in the map, get the zGrp from command
	{
		char arg1[3];
		GetCmdArg(1, arg1, sizeof(arg1));

		if (!arg1[0])
			zoneGrp = args;
		else
			zoneGrp = StringToInt(arg1);

		if (zoneGrp == 0)
		{
			Command_Restart(client, 1);
			return Plugin_Handled;
		}
	}
	else
		zoneGrp = 1;

	teleportClient(client, zoneGrp, 1, true);
	return Plugin_Handled;
}

public Action Command_SelectStage(int client, int args)
{
	if (IsValidClient(client))
		ListStages(client, g_iClientInZone[client][2]);
	return Plugin_Handled;
}


public void ListStages(int client, int zonegroup)
{
	// Types: Start(1), End(2), Stage(3), Checkpoint(4), Speed(5), TeleToStart(6), Validator(7), Chekcer(8), Stop(0)
	Menu sMenu = CreateMenu(MenuHandler_SelectStage);
	SetMenuTitle(sMenu, "Stage selector");
	int amount = 0;
	char StageName[64], ZoneInfo[6];

	int StageIds[MAXZONES] =  { -1, ... };

	if (g_mapZonesCount > 0)
	{
		for (int i = 0; i <= g_mapZonesCount; i++)
		{
			if (g_mapZones[i][zoneType] == 3 && g_mapZones[i][zoneGroup] == zonegroup)
			{
				StageIds[amount] = i;
				amount++;
			}
		}
		if (amount == 0)
		{
			AddMenuItem(sMenu, "", "The map is linear.", ITEMDRAW_DISABLED);
		}
		else
		{
			amount = 0;
			for (int t = 0; t < 128; t++)
			{
				if (StageIds[t] >= 0)
				{
					amount++;
					Format(StageName, sizeof(StageName), "Stage %i", (amount + 1));
					IntToString(amount + 1, ZoneInfo, 6);
					AddMenuItem(sMenu, ZoneInfo, StageName);
				}
			}
		}
	}
	else
	{
		AddMenuItem(sMenu, "", "No stages are available.", ITEMDRAW_DISABLED);
	}

	SetMenuExitButton(sMenu, true);
	DisplayMenu(sMenu, client, MENU_TIME_FOREVER);
}

public int MenuHandler_SelectStage(Menu tMenu, MenuAction action, int client, int item)
{
	switch (action)
	{
		case MenuAction_Select:
		{
			char aID[64];
			GetMenuItem(tMenu, item, aID, sizeof(aID));
			int id = StringToInt(aID);
			teleportClient(client, g_iClientInZone[client][2], id, true);
		}
		case MenuAction_End:
		{
			CloseHandle(tMenu);
		}
	}
}

public Action Command_ToStage(int client, int args)
{
	if (!IsValidClient(client))
		return Plugin_Handled;

	if (g_RepeatStage[client] != -1)
		Command_Repeat(client, 0);

	if (args < 1)
	{
		// Remove chat output to reduce chat spam
		//PrintToChat(client, "Teleport to stage 1 | Default usage: !s <stage number>");
		teleportClient(client, g_iClientInZone[client][2], 1, true);
	}
	else
	{
		char arg1[3];
		GetCmdArg(1, arg1, sizeof(arg1));
		int StageId = StringToInt(arg1);

		teleportClient(client, g_iClientInZone[client][2], StageId, true);
	}

	return Plugin_Handled;
}

public Action Command_ToEnd(int client, int args)
{
	if (!IsValidClient(client))
		return Plugin_Handled;

	if (!GetConVarBool(g_hCommandToEnd))
	{
		ReplyToCommand(client, "[%cSurf Timer%c] Teleportation to the end zone has been disabled on this server.", MOSSGREEN, WHITE);
		return Plugin_Handled;
	}
	teleportClient(client, g_iClientInZone[client][2], -1, true);
	return Plugin_Handled;
}

public Action Command_Restart(int client, int args)
{
	if (GetConVarBool(g_hDoubleRestartCommand) && args == 0)
	{
		if (GetGameTime() - g_fClientRestarting[client] > 5.0)
			g_bClientRestarting[client] = false;

		// Check that the client has a timer running, the zonegroup he is in has stages and that this is the first click
		if (IsValidClient(client) && g_bTimeractivated[client] && g_mapZonesTypeCount[g_iClientInZone[client][2]][3] > 0 && !g_bClientRestarting[client] && g_Stage[g_iClientInZone[client][2]][client] > 1)
		{
			g_fClientRestarting[client] = GetGameTime();
			g_bClientRestarting[client] = true;
			PrintToChat(client, "[%cSurf Timer%c] Are you sure you want to restart your run? Use %c!r%c again to restart.", MOSSGREEN, WHITE, GREEN, WHITE);
			ClientCommand(client, "play ambient/misc/clank4");
			return Plugin_Handled;
		}
	}

	g_bClientRestarting[client] = false;
	teleportClient(client, 0, 1, true);
	return Plugin_Handled;
}

public Action Client_HideChat(int client, int args)
{
	HideChat(client);
	if (g_bHideChat[client])
		PrintToChat(client, "%t", "HideChat1", MOSSGREEN, WHITE);
	else
		PrintToChat(client, "%t", "HideChat2", MOSSGREEN, WHITE);
	return Plugin_Handled;
}

public void HideChat(int client)
{
	if (!g_bHideChat[client])
	{
		// Hiding
		if (g_bViewModel[client])
			SetEntProp(client, Prop_Send, "m_iHideHUD", GetEntProp(client, Prop_Send, "m_iHideHUD") | HIDE_RADAR | HIDE_CHAT | HIDE_CROSSHAIR);
		else
			SetEntProp(client, Prop_Send, "m_iHideHUD", GetEntProp(client, Prop_Send, "m_iHideHUD") | HIDE_RADAR | HIDE_CHAT);
	}
	else
	{
		// Displaying
		if (g_bViewModel[client])
			SetEntProp(client, Prop_Send, "m_iHideHUD", HIDE_RADAR | HIDE_CROSSHAIR);
		else
			SetEntProp(client, Prop_Send, "m_iHideHUD", HIDE_RADAR);
	}

	g_bHideChat[client] = !g_bHideChat[client];
}

public Action ToggleCheckpoints(int client, int args)
{
	if (!IsValidClient(client))
		return Plugin_Handled;

	if (g_bCheckpointsEnabled[client])
	{
		g_bCheckpointsEnabled[client] = false;
		if (g_bActivateCheckpointsOnStart[client])
			g_bActivateCheckpointsOnStart[client] = false;
		PrintToChat(client, "%t", "ToogleCheckpoints1", MOSSGREEN, WHITE);
	}
	else
	{
		if (g_bTimeractivated[client])
		{
			PrintToChat(client, "%t", "ToggleCheckpoints3", MOSSGREEN, WHITE);
			g_bActivateCheckpointsOnStart[client] = true;
		}
		else
		{
			g_bCheckpointsEnabled[client] = true;
			PrintToChat(client, "%t", "ToggleCheckpoints2", MOSSGREEN, WHITE);
		}
	}
	return Plugin_Handled;
}

public Action Client_HideWeapon(int client, int args)
{
	HideViewModel(client);
	if (g_bViewModel[client])
		PrintToChat(client, "%t", "HideViewModel2", MOSSGREEN, WHITE);
	else
		PrintToChat(client, "%t", "HideViewModel1", MOSSGREEN, WHITE);
	return Plugin_Handled;
}

public void HideViewModel(int client)
{
	Client_SetDrawViewModel(client, !g_bViewModel[client]);
	if (!g_bViewModel[client])
	{
		// Display
		if (!g_bHideChat[client])
			SetEntProp(client, Prop_Send, "m_iHideHUD", HIDE_RADAR);
		else
			SetEntProp(client, Prop_Send, "m_iHideHUD", HIDE_RADAR | HIDE_CHAT);
	}
	else
	{
		// Hiding
		if (!g_bHideChat[client])
			SetEntProp(client, Prop_Send, "m_iHideHUD", GetEntProp(client, Prop_Send, "m_iHideHUD") | HIDE_RADAR | HIDE_CROSSHAIR);
		else
			SetEntProp(client, Prop_Send, "m_iHideHUD", GetEntProp(client, Prop_Send, "m_iHideHUD") | HIDE_RADAR | HIDE_CHAT | HIDE_CROSSHAIR);
	}


	g_bViewModel[client] = !g_bViewModel[client];
}

public Action Client_Wr(int client, int args)
{
	if (IsValidClient(client))
	{
		if (g_fRecordMapTime == 9999999.0)
			PrintToChat(client, "%t", "NoRecordTop", MOSSGREEN, WHITE);
		else
			PrintMapRecords(client);
	}
	return Plugin_Handled;
}

public Action Command_Tier(int client, int args)
{
	if (IsValidClient(client) && g_bTierFound[0]) //the second condition is only checked if the first passes
		PrintToChat(client, g_sTierString[0]);
}

public Action Command_bTier(int client, int args)
{
	if (IsValidClient(client))
	{
		if (g_mapZoneGroupCount == 1)
		{
			PrintToChat(client, "[%cSurf Timer%c] There are no bonuses in this map.", MOSSGREEN, WHITE);
			return;
		}

		int found = 0;
		for (int i = 1; i < MAXZONEGROUPS; i++)
		{
			if (g_bTierFound[i])
			{
				PrintToChat(client, g_sTierString[i]);
				found++;
			}
		}

		if (found == 0)
		{
			PrintToChat(client, "[%cSurf Timer%c] Bonus tiers have not been set on this map.", MOSSGREEN, WHITE);
		}
	}
}

public Action Client_Avg(int client, int args)
{
	if (!IsValidClient(client))
		return Plugin_Handled;

	char szProTime[32];
	FormatTimeFloat(client, g_favg_maptime, 3, szProTime, sizeof(szProTime));

	if (g_MapTimesCount == 0)
		Format(szProTime, 32, "N/A");

	PrintToChat(client, "%t", "AvgTime", MOSSGREEN, WHITE, GRAY, DARKBLUE, WHITE, szProTime, g_MapTimesCount);

	if (g_bhasBonus)
	{
		char szBonusTime[32];

		for (int i = 1; i < g_mapZoneGroupCount; i++)
		{
			FormatTimeFloat(client, g_fAvg_BonusTime[i], 3, szBonusTime, sizeof(szBonusTime));

			if (g_iBonusCount[i] == 0)
				Format(szBonusTime, 32, "N/A");
			PrintToChat(client, "%t", "AvgTimeBonus", MOSSGREEN, WHITE, GRAY, YELLOW, WHITE, szBonusTime, g_iBonusCount[i]);
		}
	}

	return Plugin_Handled;
}

public Action Client_Flashlight(int client, int args)
{
	if (IsValidClient(client) && IsPlayerAlive(client))
		SetEntProp(client, Prop_Send, "m_fEffects", GetEntProp(client, Prop_Send, "m_fEffects") ^ 4);
	return Plugin_Handled;
}

public Action Client_Challenge(int client, int args)
{
	if (!g_bChallenge[client] && !g_bChallenge_Request[client])
	{
		if (IsPlayerAlive(client))
		{
			if (GetConVarBool(g_hCvarNoBlock))
			{
				Menu menu2 = CreateMenu(ChallengeMenuHandler2);
				char tmp[64];
				if (GetConVarBool(g_hPointSystem))
					Format(tmp, 64, "ckSurf - Challenge: Player Bet?\nYour Points: %i", g_pr_points[client]);
				else
					Format(tmp, 64, "ckSurf - Challenge: Player Bet?\nPlayer point system disabled", g_pr_points[client]);
				SetMenuTitle(menu2, tmp);
				AddMenuItem(menu2, "0", "No bet");
				if (GetConVarBool(g_hPointSystem))
				{
					Format(tmp, 64, "%i", g_pr_PointUnit * 50);
					if (g_pr_PointUnit * 5 <= g_pr_points[client])
						AddMenuItem(menu2, tmp, tmp);
					Format(tmp, 64, "%i", (g_pr_PointUnit * 100));
					if ((g_pr_PointUnit * 10) <= g_pr_points[client])
						AddMenuItem(menu2, tmp, tmp);
					Format(tmp, 64, "%i", (g_pr_PointUnit * 250));
					if ((g_pr_PointUnit * 25) <= g_pr_points[client])
						AddMenuItem(menu2, tmp, tmp);
					Format(tmp, 64, "%i", (g_pr_PointUnit * 500));
					if ((g_pr_PointUnit * 50) <= g_pr_points[client])
						AddMenuItem(menu2, tmp, tmp);
				}
				SetMenuOptionFlags(menu2, MENUFLAG_BUTTON_EXIT);
				DisplayMenu(menu2, client, MENU_TIME_FOREVER);
			}
			else
				PrintToChat(client, "%t", "ChallengeFailed1", RED, WHITE);
		}
		else
			PrintToChat(client, "%t", "ChallengeFailed2", RED, WHITE);
	}
	else
		PrintToChat(client, "%t", "ChallengeFailed3", RED, WHITE);
	return Plugin_Handled;
}


public int ChallengeMenuHandler2(Menu menu, MenuAction action, int param1, int param2)
{
	if (action == MenuAction_Select)
	{
		char info[32];
		GetMenuItem(menu, param2, info, sizeof(info));
		int value = StringToInt(info);
		if (value == g_pr_PointUnit * 50)
			g_Challenge_Bet[param1] = 50;
		else
			if (value == (g_pr_PointUnit * 100))
				g_Challenge_Bet[param1] = 100;
			else
				if (value == (g_pr_PointUnit * 250))
					g_Challenge_Bet[param1] = 250;
				else
					if (value == (g_pr_PointUnit * 500))
						g_Challenge_Bet[param1] = 500;
					else
						g_Challenge_Bet[param1] = 0;
		char szPlayerName[MAX_NAME_LENGTH];
		Menu menu2 = CreateMenu(ChallengeMenuHandler3);
		SetMenuTitle(menu2, "ckSurf - Challenge: Select your Opponent");
		int playerCount = 0;
		for (int i = 1; i <= MaxClients; i++)
		{
			if (IsValidClient(i) && IsPlayerAlive(i) && i != param1 && !IsFakeClient(i))
			{
				GetClientName(i, szPlayerName, MAX_NAME_LENGTH);
				AddMenuItem(menu2, szPlayerName, szPlayerName);
				playerCount++;
			}
		}
		if (playerCount > 0)
		{
			SetMenuOptionFlags(menu2, MENUFLAG_BUTTON_EXIT);
			DisplayMenu(menu2, param1, MENU_TIME_FOREVER);
		}
		else
		{
			PrintToChat(param1, "%t", "ChallengeFailed4", MOSSGREEN, WHITE);
		}

	}
	else

	if (action == MenuAction_End)
	{
		CloseHandle(menu);
	}
}

public int ChallengeMenuHandler3(Menu menu, MenuAction action, int param1, int param2)
{
	if (action == MenuAction_Select)
	{
		char info[32];
		char szPlayerName[MAX_NAME_LENGTH];
		char szTargetName[MAX_NAME_LENGTH];
		GetClientName(param1, szPlayerName, MAX_NAME_LENGTH);
		GetMenuItem(menu, param2, info, sizeof(info));
		for (int i = 1; i <= MaxClients; i++)
		{
			if (IsValidClient(i) && IsPlayerAlive(i) && i != param1)
			{
				GetClientName(i, szTargetName, MAX_NAME_LENGTH);

				if (StrEqual(info, szTargetName))
				{
					if (!g_bChallenge[i])
					{
						if ((g_pr_PointUnit * g_Challenge_Bet[param1]) <= g_pr_points[i])
						{
							//id of challenger
							char szSteamId[32];
							//GetClientAuthString(i, szSteamId, 32);
							GetClientAuthId(i, AuthId_Steam2, szSteamId, MAX_NAME_LENGTH, true);
							Format(g_szChallenge_OpponentID[param1], 32, szSteamId);
							char cp[16];
							if (g_bChallenge_Checkpoints[param1])
								Format(cp, 16, " allowed");
							else
								Format(cp, 16, " forbidden");
							int value = g_pr_PointUnit * g_Challenge_Bet[param1];
							PrintToChat(param1, "%t", "Challenge1", RED, WHITE, YELLOW, szTargetName, value, cp);
							//target msg
							EmitSoundToClient(i, "buttons/button15.wav", i);
							PrintToChat(i, "%t", "Challenge2", RED, WHITE, YELLOW, szPlayerName, GREEN, WHITE, value, cp);
							g_fChallenge_RequestTime[param1] = GetGameTime();
							g_bChallenge_Request[param1] = true;
						}
						else
						{
							PrintToChat(param1, "%t", "ChallengeFailed5", RED, WHITE, szTargetName, g_pr_points[i]);
						}
					}
					else
						PrintToChat(param1, "%t", "ChallengeFailed6", RED, WHITE, szTargetName);
				}
			}
		}
	}
	else if (action == MenuAction_End)
	{
		CloseHandle(menu);
	}
}

public Action Client_Abort(int client, int args)
{
	if (g_bChallenge[client])
	{
		if (g_bChallenge_Abort[client])
		{
			g_bChallenge_Abort[client] = false;
			PrintToChat(client, "[%cSurf Timer%c] You have disagreed to abort the challenge.", RED, WHITE);
		}
		else
		{
			g_bChallenge_Abort[client] = true;
			PrintToChat(client, "[%cSurf Timer%c] You have agreed to abort the challenge. Waiting for your opponent..", RED, WHITE, GREEN);
		}
	}
	return Plugin_Handled;
}

public Action Client_Accept(int client, int args)
{
	char szSteamId[32];
	char szCP[32];
	//GetClientAuthString(client, szSteamId, 32);
	GetClientAuthId(client, AuthId_Steam2, szSteamId, MAX_NAME_LENGTH, true);

	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsValidClient(i) && IsPlayerAlive(i) && i != client && g_bChallenge_Request[i])
		{
			if (StrEqual(szSteamId, g_szChallenge_OpponentID[i]))
			{
				//GetClientAuthString(i, g_szChallenge_OpponentID[client], 32);
				GetClientAuthId(i, AuthId_Steam2, g_szChallenge_OpponentID[client], MAX_NAME_LENGTH, true);
				g_bChallenge_Request[i] = false;
				g_bChallenge[i] = true;
				g_bChallenge[client] = true;
				g_bChallenge_Abort[client] = false;
				g_bChallenge_Abort[i] = false;
				g_Challenge_Bet[client] = g_Challenge_Bet[i];
				g_bChallenge_Checkpoints[client] = g_bChallenge_Checkpoints[i];
				teleportClient(client, 0, 1, true);
				teleportClient(i, 0, 1, true);
				SetEntityMoveType(i, MOVETYPE_NONE);
				SetEntityMoveType(client, MOVETYPE_NONE);
				g_CountdownTime[i] = 10;
				g_CountdownTime[client] = 10;
				CreateTimer(1.0, Timer_Countdown, i, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
				CreateTimer(1.0, Timer_Countdown, client, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
				PrintToChat(client, "%t", "Challenge3", RED, WHITE, YELLOW);
				PrintToChat(i, "%t", "Challenge3", RED, WHITE, YELLOW);
				char szPlayer1[MAX_NAME_LENGTH];
				char szPlayer2[MAX_NAME_LENGTH];
				GetClientName(i, szPlayer1, MAX_NAME_LENGTH);
				GetClientName(client, szPlayer2, MAX_NAME_LENGTH);

				if (g_bChallenge_Checkpoints[i])
					Format(szCP, sizeof(szCP), "Allowed");
				else
					Format(szCP, sizeof(szCP), "Forbidden");
				int points = g_Challenge_Bet[i] * 2 * g_pr_PointUnit;
				PrintToChatAll("[%cSurf Timer%c] Challenge: %c%s%c vs. %c%s%c", RED, WHITE, MOSSGREEN, szPlayer1, WHITE, MOSSGREEN, szPlayer2, WHITE);
				PrintToChatAll("[%cSurf Timer%c] Checkpoints: %c%s%c, Pot: %c%ip", RED, WHITE, GRAY, szCP, WHITE, GRAY, points);

				int r1 = GetRandomInt(55, 255);
				int r2 = GetRandomInt(55, 255);
				int r3 = GetRandomInt(0, 55);
				int r4 = GetRandomInt(0, 255);
				SetEntityRenderColor(i, r1, r2, r3, r4);
				SetEntityRenderColor(client, r1, r2, r3, r4);
				Client_Stop(client, 1);
				Client_Stop(i, 1);
				CreateTimer(1.0, CheckChallenge, i, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
				CreateTimer(1.0, CheckChallenge, client, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
			}
		}
	}
	return Plugin_Handled;
}

public Action Client_Knife(int client, int args)
{
	if (!IsValidClient(client) || !IsPlayerAlive(client))
		return Plugin_Handled;

	// Can also be used for the knife delay
	if ((GetGameTime() - g_flastClientKnife[client]) < 10.0)
		return Plugin_Handled;

	g_flastClientKnife[client] = GetGameTime();

	if (Client_HasWeapon(client, "weapon_knife"))
	{
		int weapon = Client_GetWeapon(client, "weapon_knife");
		FakeClientCommand(client, "use %s", weapon);
		InstantSwitch(client, weapon);
	}
	else {
		GivePlayerItem(client, "weapon_knife");
	}

	return Plugin_Handled;
}

public Action Client_Usp(int client, int args)
{
	if (!IsValidClient(client) || !IsPlayerAlive(client))
		return Plugin_Handled;

	if ((GetGameTime() - g_flastClientUsp[client]) < 10.0)
		return Plugin_Handled;

	g_flastClientUsp[client] = GetGameTime();

	if (Client_HasWeapon(client, "weapon_hkp2000"))
	{
		int weapon = Client_GetWeapon(client, "weapon_hkp2000");
		FakeClientCommand(client, "use %s", weapon);
		InstantSwitch(client, weapon);
	}
	else
		GivePlayerItem(client, "weapon_usp_silencer");
	return Plugin_Handled;
}

public Action Client_Decoy(int client, int args)
{
	if (!IsValidClient(client) || !IsPlayerAlive(client))
		return Plugin_Handled;

	if ((GetGameTime() - g_flastClientDecoy[client]) < 10.0)
		return Plugin_Handled;

	g_flastClientDecoy[client] = GetGameTime();

	if(Client_HasWeapon(client, "weapon_decoy"))
	{
		int weapon = Client_GetWeapon(client, "weapon_decoy");
		FakeClientCommand(client, "use %s", weapon);
		InstantSwitch(client, weapon);
	}
	else
		GivePlayerItem(client, "weapon_decoy");

	return Plugin_Handled;
}

void InstantSwitch(int client, int weapon, int timer = 0)
{
	if (weapon == -1)
		return;

	float GameTime = GetGameTime();

	if (!timer)
	{
		SetEntPropEnt(client, Prop_Send, "m_hActiveWeapon", weapon);
		SetEntPropFloat(weapon, Prop_Send, "m_flNextPrimaryAttack", GameTime);
	}

	SetEntPropFloat(client, Prop_Send, "m_flNextAttack", GameTime);
	int ViewModel = GetEntPropEnt(client, Prop_Send, "m_hViewModel");
	SetEntProp(ViewModel, Prop_Send, "m_nSequence", 0);
}

public Action Client_Surrender(int client, int args)
{
	char szSteamIdOpponent[32];
	char szNameOpponent[MAX_NAME_LENGTH];
	char szName[MAX_NAME_LENGTH];
	if (g_bChallenge[client])
	{
		GetClientName(client, szName, MAX_NAME_LENGTH);
		for (int i = 1; i <= MaxClients; i++)
		{
			if (IsValidClient(i) && i != client)
			{
				//GetClientAuthString(i, szSteamIdOpponent, 32);
				GetClientAuthId(i, AuthId_Steam2, szSteamIdOpponent, MAX_NAME_LENGTH, true);
				if (StrEqual(szSteamIdOpponent, g_szChallenge_OpponentID[client]))
				{
					GetClientName(i, szNameOpponent, MAX_NAME_LENGTH);
					g_bChallenge[i] = false;
					g_bChallenge[client] = false;
					db_insertPlayerChallenge(i);
					SetEntityRenderColor(i, 255, 255, 255, 255);
					SetEntityRenderColor(client, 255, 255, 255, 255);

					//msg
					for (int j = 1; j <= MaxClients; j++)
					{
						if (IsValidClient(j) && IsValidEntity(j))
						{
							PrintToChat(j, "%t", "Challenge4", RED, WHITE, MOSSGREEN, szNameOpponent, WHITE, MOSSGREEN, szName, WHITE);
						}
					}
					//win ratio
					SetEntityMoveType(client, MOVETYPE_WALK);
					SetEntityMoveType(i, MOVETYPE_WALK);

					if (g_Challenge_Bet[client] > 0)
					{
						g_pr_showmsg[i] = true;
						PrintToChat(i, "%t", "Rc_PlayerRankStart", MOSSGREEN, WHITE, GRAY);
						PrintToChat(client, "%t", "Rc_PlayerRankStart", MOSSGREEN, WHITE, GRAY);
						int lostpoints = g_Challenge_Bet[client] * g_pr_PointUnit;
						for (int j = 1; j <= MaxClients; j++)
							if (IsValidClient(j) && IsValidEntity(j))
								PrintToChat(j, "[%cSurf Timer%c] %c%s%c has lost %c%i %cpoints!", MOSSGREEN, WHITE, PURPLE, szName, GRAY, RED, lostpoints, GRAY);
					}
					//db update
					CreateTimer(0.0, UpdatePlayerProfile, i, TIMER_FLAG_NO_MAPCHANGE);
					CreateTimer(0.5, UpdatePlayerProfile, client, TIMER_FLAG_NO_MAPCHANGE);
					i = MaxClients + 1;
				}
			}
		}
	}
	return Plugin_Handled;
}

public Action Command_ext_Menu(int client, const char[] command, int argc)
{
	return Plugin_Handled;
}

//https://forums.alliedmods.net/showthread.php?t=206308
public Action Command_JoinTeam(int client, const char[] command, int argc)
{
	if (!IsValidClient(client) || argc < 1)
		return Plugin_Handled;
	char arg[4];
	GetCmdArg(1, arg, sizeof(arg));
	int toteam = StringToInt(arg);

	TeamChangeActual(client, toteam);
	return Plugin_Handled;
}

public Action Client_OptionMenu(int client, int args)
{
	OptionMenu(client);
	return Plugin_Handled;
}

public Action NoClip(int client, int args)
{
	if (!IsValidClient(client))
		return Plugin_Handled;

	Action_NoClip(client);

	return Plugin_Handled;
}

public Action UnNoClip(int client, int args)
{
	if (g_bNoClip[client] == true)
		Action_UnNoClip(client);
	return Plugin_Handled;
}

public Action Command_ckNoClip(int client, int args)
{
	if(!IsValidClient(client))
		return Plugin_Handled;

	if(!IsPlayerAlive(client))
	{
		ReplyToCommand(client, "[%cSurf Timer%c] You cannot use NoClip while you are dead", MOSSGREEN, WHITE);
	}
	else
	{
		MoveType mt = GetEntityMoveType(client);

		if (mt != MOVETYPE_NOCLIP)
		{
			Action_NoClip(client);
		}
		else
		{
			Action_UnNoClip(client);
		}
	}

	return Plugin_Handled;
}


public Action Client_Top(int client, int args)
{
	ckTopMenu(client);
	return Plugin_Handled;
}

public Action Client_MapTop(int client, int args)
{
	char szArg[128];

	if (args == 0)
	{
		Format(szArg, 128, "%s", g_szMapName);
	}
	else
	{
		GetCmdArg(1, szArg, 128);
	}
	db_selectMapTopSurfers(client, szArg);
	return Plugin_Handled;
}

public Action Client_BonusTop(int client, int args)
{
	char szArg[128], zGrp;

	if (!IsValidClient(client))
		return Plugin_Handled;

	switch (args)
	{
		case 0:
		{  // !btop
			if (g_mapZoneGroupCount == 1)
			{
				PrintToChat(client, "[%cSurf Timer%c] No bonus found on this map.", MOSSGREEN, WHITE);
				PrintToChat(client, "[%cSurf Timer%c] Usage: !btop <bonus id> <mapname>", MOSSGREEN, WHITE);
				return Plugin_Handled;
			}
			if (g_mapZoneGroupCount == 2)
			{
				zGrp = 1;
				Format(szArg, 128, "%s", g_szMapName);
			}
			if (g_mapZoneGroupCount > 2)
			{
				ListBonuses(client, 2);
				return Plugin_Handled;
			}
		}
		case 1:
		{  //!btop <mapname> / <bonus id>
			// 1st check if bonus id or mapname
			GetCmdArg(1, szArg, 128);
			if (StringToInt(szArg) == 0 && szArg[0] != '0') // passes, if not a number (argument is mapname)
			{
				db_selectBonusesInMap(client, szArg);
				return Plugin_Handled;
			}
			else // argument is a bonus id (Use current map)
			{
				zGrp = StringToInt(szArg);
				if (0 < zGrp < MAXZONEGROUPS)
				{
					Format(szArg, 128, "%s", g_szMapName);
				}
				else
				{
					PrintToChat(client, "[%cSurf Timer%c] Invalid bonus ID %i.", MOSSGREEN, WHITE, zGrp);
					return Plugin_Handled;
				}
			}
		}
		case 2:
		{
			GetCmdArg(1, szArg, 128);
			if (StringToInt(szArg) == 0 && szArg[0] != '0') // passes, if not a number (argument is mapname)
			{
				char szZGrp[128];
				GetCmdArg(2, szZGrp, 128);
				zGrp = StringToInt(szZGrp);
			}
			else // argument is a bonus id
			{
				zGrp = StringToInt(szArg);
				GetCmdArg(2, szArg, 128);
			}

			if (0 > zGrp || zGrp > MAXZONEGROUPS)
			{
				PrintToChat(client, "[%cSurf Timer%c] Invalid bonus ID %i.", MOSSGREEN, WHITE, zGrp);
				return Plugin_Handled;
			}
		}
		default:
		{
			PrintToChat(client, "[%cSurf Timer%c] Usage: !btop <bonus id> <mapname>", MOSSGREEN, WHITE);
			return Plugin_Handled;
		}
	}

	db_selectBonusTopSurfers(client, szArg, zGrp);
	return Plugin_Handled;
}

public Action Client_StageTop(int client, int args)
{
	if (!g_bhasStages)
		return Plugin_Handled;

	StageTopMenu(client);
	return Plugin_Continue;
}

public Action Client_Spec(int client, int args)
{
	SpecPlayer(client, args);
	return Plugin_Handled;
}

public void SpecPlayer(int client, int args)
{
	char szPlayerName[MAX_NAME_LENGTH];
	char szPlayerName2[256];
	char szOrgTargetName[MAX_NAME_LENGTH];
	char szTargetName[MAX_NAME_LENGTH];
	char szArg[MAX_NAME_LENGTH];
	Format(szTargetName, MAX_NAME_LENGTH, "");
	Format(szOrgTargetName, MAX_NAME_LENGTH, "");

	if (args == 0)
	{
		Menu menu = CreateMenu(SpecMenuHandler);

		if (g_bSpectate[client])
			SetMenuTitle(menu, "ckSurf - Spec menu (press 'm' to rejoin a team!)");
		else
			SetMenuTitle(menu, "ckSurf - Spec menu");
		int playerCount = 0;

		//add replay bots
		if (g_RecordBot != -1)
		{
			if (g_RecordBot != -1 && IsValidClient(g_RecordBot) && IsPlayerAlive(g_RecordBot))
			{
				Format(szPlayerName2, 256, "Map record replay (%s)", g_szReplayTime);
				AddMenuItem(menu, "MAP RECORD REPLAY", szPlayerName2);
				playerCount++;
			}
		}


		int count = 0;
		//add players
		for (int i = 1; i <= MaxClients; i++)
		{
			if (IsValidClient(i) && IsPlayerAlive(i) && i != client && !IsFakeClient(i))
			{
				if (count == 0)
				{
					int bestrank = 99999999;
					for (int x = 1; x <= MaxClients; x++)
					{
						if (IsValidClient(x) && IsPlayerAlive(x) && x != client && !IsFakeClient(x) && g_PlayerRank[x] > 0)
							if (g_PlayerRank[x] <= bestrank)
							bestrank = g_PlayerRank[x];
					}
					char szMenu[128];
					Format(szMenu, 128, "Highest ranked player (#%i)", bestrank);
					AddMenuItem(menu, "brp123123xcxc", szMenu);
					AddMenuItem(menu, "", "", ITEMDRAW_SPACER);
				}
				GetClientName(i, szPlayerName, MAX_NAME_LENGTH);
				Format(szPlayerName2, 256, "%s (%s)", szPlayerName, g_pr_rankname[i]);
				AddMenuItem(menu, szPlayerName, szPlayerName2);
				playerCount++;
				count++;
			}
		}

		if (playerCount > 0 || g_RecordBot != -1)
		{
			SetMenuOptionFlags(menu, MENUFLAG_BUTTON_EXIT);
			DisplayMenu(menu, client, MENU_TIME_FOREVER);
		}
		else
			PrintToChat(client, "%t", "ChallengeFailed4", MOSSGREEN, WHITE);

	}
	else
	{
		for (int i = 1; i < 20; i++)
		{
			GetCmdArg(i, szArg, MAX_NAME_LENGTH);
			if (!StrEqual(szArg, "", false))
			{
				if (i == 1)
					Format(szTargetName, MAX_NAME_LENGTH, "%s", szArg);
				else
					Format(szTargetName, MAX_NAME_LENGTH, "%s %s", szTargetName, szArg);
			}
		}
		Format(szOrgTargetName, MAX_NAME_LENGTH, "%s", szTargetName);
		StringToUpper(szTargetName);
		for (int i = 1; i <= MaxClients; i++)
		{
			if (IsValidClient(i) && IsPlayerAlive(i) && i != client)
			{
				GetClientName(i, szPlayerName, MAX_NAME_LENGTH);
				StringToUpper(szPlayerName);
				if ((StrContains(szPlayerName, szTargetName) != -1))
				{
					ChangeClientTeam(client, 1);
					SetEntPropEnt(client, Prop_Send, "m_hObserverTarget", i);
					SetEntProp(client, Prop_Send, "m_iObserverMode", 4);
					return;
				}
			}
		}
		PrintToChat(client, "%t", "PlayerNotFound", MOSSGREEN, WHITE, szOrgTargetName);
	}
}

public int SpecMenuHandler(Menu menu, MenuAction action, int param1, int param2)
{
	if (action == MenuAction_Select)
	{
		char info[32];
		char szPlayerName[MAX_NAME_LENGTH];
		GetMenuItem(menu, param2, info, sizeof(info));

		if (StrEqual(info, "brp123123xcxc"))
		{
			int playerid;
			int count = 0;
			int bestrank = 99999999;
			for (int i = 1; i <= MaxClients; i++)
			{
				if (IsValidClient(i) && IsPlayerAlive(i) && i != param1 && !IsFakeClient(i))
				{
					if (g_PlayerRank[i] <= bestrank)
					{
						bestrank = g_PlayerRank[i];
						playerid = i;
						count++;
					}
				}
			}
			if (count == 0)
				PrintToChat(param1, "%t", "NoPlayerTop", MOSSGREEN, WHITE);
			else
			{
				ChangeClientTeam(param1, 1);
				SetEntPropEnt(param1, Prop_Send, "m_hObserverTarget", playerid);
				SetEntProp(param1, Prop_Send, "m_iObserverMode", 4);
			}
		}
		else
		{
			for (int i = 1; i <= MaxClients; i++)
			{
				if (IsValidClient(i) && IsPlayerAlive(i) && i != param1)
				{
					GetClientName(i, szPlayerName, MAX_NAME_LENGTH);
					if (i == g_RecordBot)
						Format(szPlayerName, MAX_NAME_LENGTH, "MAP RECORD REPLAY");
					if (StrEqual(info, szPlayerName))
					{
						ChangeClientTeam(param1, 1);
						SetEntPropEnt(param1, Prop_Send, "m_hObserverTarget", i);
						SetEntProp(param1, Prop_Send, "m_iObserverMode", 4);
					}
				}
			}
		}
	}
	else
		if (action == MenuAction_End)
		{
			CloseHandle(menu);
		}
}

public void CompareMenu(int client, int args)
{
	char szArg[MAX_NAME_LENGTH];
	char szPlayerName[MAX_NAME_LENGTH];
	if (args == 0)
	{
		Format(szPlayerName, MAX_NAME_LENGTH, "");
		Menu menu = CreateMenu(CompareSelectMenuHandler);
		SetMenuTitle(menu, "ckSurf - Compare menu");
		int playerCount = 0;
		for (int i = 1; i <= MaxClients; i++)
		{
			if (IsValidClient(i) && IsPlayerAlive(i) && i != client && !IsFakeClient(i))
			{
				GetClientName(i, szPlayerName, MAX_NAME_LENGTH);
				AddMenuItem(menu, szPlayerName, szPlayerName);
				playerCount++;
			}
		}
		if (playerCount > 0)
		{
			SetMenuOptionFlags(menu, MENUFLAG_BUTTON_EXIT);
			DisplayMenu(menu, client, MENU_TIME_FOREVER);
		}
		else
			PrintToChat(client, "[%cSurf Timer%c] No valid players found", MOSSGREEN, WHITE);
		return;
	}
	else
	{
		for (int i = 1; i < 20; i++)
		{
			GetCmdArg(i, szArg, MAX_NAME_LENGTH);
			if (!StrEqual(szArg, "", false))
			{
				if (i == 1)
					Format(szPlayerName, MAX_NAME_LENGTH, "%s", szArg);
				else
					Format(szPlayerName, MAX_NAME_LENGTH, "%s %s", szPlayerName, szArg);
			}
		}
		//player ingame? new name?
		if (!StrEqual(szPlayerName, "", false))
		{
			int id = -1;
			char szName[MAX_NAME_LENGTH];
			char szName2[MAX_NAME_LENGTH];
			for (int i = 1; i <= MaxClients; i++)
			{
				if (IsValidClient(i) && i != client)
				{
					GetClientName(i, szName, MAX_NAME_LENGTH);
					StringToUpper(szName);
					Format(szName2, MAX_NAME_LENGTH, "%s", szPlayerName);
					if ((StrContains(szName, szName2) != -1))
					{
						id = i;
						continue;
					}
				}
			}
			if (id != -1)
				db_viewPlayerRank2(client, g_szSteamID[id]);
			else
				db_viewPlayerAll2(client, szPlayerName);
		}
	}
}

public int CompareSelectMenuHandler(Menu menu, MenuAction action, int param1, int param2)
{
	if (action == MenuAction_Select)
	{
		char info[32];
		char szPlayerName[MAX_NAME_LENGTH];
		GetMenuItem(menu, param2, info, sizeof(info));

		for (int i = 1; i <= MaxClients; i++)
		{
			if (IsValidClient(i) && i != param1)
			{
				GetClientName(i, szPlayerName, MAX_NAME_LENGTH);
				if (StrEqual(info, szPlayerName))
				{
					db_viewPlayerRank2(param1, g_szSteamID[param1]);
				}
			}
		}
		CompareMenu(param1, 0);
	}
	else
		if (action == MenuAction_End)
	{
		if (IsValidClient(param1))
			g_bSelectProfile[param1] = false;
		CloseHandle(menu);
	}
}

public void ProfileMenu(int client, int args)
{
	//spam protection
	float diff = GetGameTime() - g_fProfileMenuLastQuery[client];
	if (diff < 0.5)
	{
		g_bSelectProfile[client] = false;
		return;
	}
	g_fProfileMenuLastQuery[client] = GetGameTime();

	char szArg[MAX_NAME_LENGTH];
	//no argument
	if (args == 0)
	{
		char szPlayerName[MAX_NAME_LENGTH];
		Menu menu = CreateMenu(ProfileSelectMenuHandler);
		SetMenuTitle(menu, "ckSurf - Profile menu");
		GetClientName(client, szPlayerName, MAX_NAME_LENGTH);
		AddMenuItem(menu, szPlayerName, szPlayerName);
		int playerCount = 1;
		for (int i = 1; i <= MaxClients; i++)
		{
			if (IsValidClient(i) && i != client && !IsFakeClient(i))
			{
				GetClientName(i, szPlayerName, MAX_NAME_LENGTH);
				AddMenuItem(menu, szPlayerName, szPlayerName);
				playerCount++;
			}
		}
		g_bSelectProfile[client] = true;
		SetMenuOptionFlags(menu, MENUFLAG_BUTTON_EXIT);
		DisplayMenu(menu, client, MENU_TIME_FOREVER);
		return;
	}
	else
	{
		if (args != -1)
		{
			g_bSelectProfile[client] = false;
			Format(g_szProfileName[client], MAX_NAME_LENGTH, "");
			for (int i = 1; i < 20; i++)
			{
				GetCmdArg(i, szArg, MAX_NAME_LENGTH);
				if (!StrEqual(szArg, "", false))
				{
					if (i == 1)
						Format(g_szProfileName[client], MAX_NAME_LENGTH, "%s", szArg);
					else
						Format(g_szProfileName[client], MAX_NAME_LENGTH, "%s %s", g_szProfileName[client], szArg);
				}
			}
		}
	}
	//player ingame? new name?
	if (args != 0 && !StrEqual(g_szProfileName[client], "", false))
	{
		bool bPlayerFound = false;
		char szSteamId2[32];
		char szName[MAX_NAME_LENGTH];
		char szName2[MAX_NAME_LENGTH];
		for (int i = 1; i <= MaxClients; i++)
		{
			if (IsValidClient(i))
			{
				GetClientName(i, szName, MAX_NAME_LENGTH);
				StringToUpper(szName);
				Format(szName2, MAX_NAME_LENGTH, "%s", g_szProfileName[client]);
				if ((StrContains(szName, szName2) != -1))
				{
					bPlayerFound = true;
					GetClientAuthId(i, AuthId_Steam2, szSteamId2, MAX_NAME_LENGTH, true);
					//GetClientAuthString(i, szSteamId2, 32);
					continue;
				}
			}
		}
		if (bPlayerFound)
			db_viewPlayerRank(client, szSteamId2);
		else
			db_viewPlayerProfile1(client, g_szProfileName[client]);
	}
}

public int ProfileSelectMenuHandler(Menu menu, MenuAction action, int param1, int param2)
{
	if (action == MenuAction_Select)
	{
		char info[32];
		char szPlayerName[MAX_NAME_LENGTH];
		GetMenuItem(menu, param2, info, sizeof(info));

		for (int i = 1; i <= MaxClients; i++)
		{
			if (IsValidClient(i))
			{
				GetClientName(i, szPlayerName, MAX_NAME_LENGTH);
				if (StrEqual(info, szPlayerName))
				{
					Format(g_szProfileName[param1], MAX_NAME_LENGTH, "%s", szPlayerName);
					char szSteamId[32];
					GetClientAuthId(i, AuthId_Steam2, szSteamId, MAX_NAME_LENGTH, true);
					//GetClientAuthString(i, szSteamId, 32);
					db_viewPlayerRank(param1, szSteamId);
				}
			}
		}
	}
	else
		if (action == MenuAction_End)
	{
		if (IsValidClient(param1))
			g_bSelectProfile[param1] = false;
		CloseHandle(menu);
	}
}


public Action Client_Hide(int client, int args)
{
	HideMethod(client);
	if (!g_bHide[client])
		PrintToChat(client, "%t", "Hide1", MOSSGREEN, WHITE);
	else
		PrintToChat(client, "%t", "Hide2", MOSSGREEN, WHITE);
	return Plugin_Handled;
}

public void HideMethod(int client)
{
	g_bHide[client] = !g_bHide[client];
}

public Action Client_Latest(int client, int args)
{
	db_ViewLatestRecords(client);
	return Plugin_Handled;
}

public Action Client_Showsettings(int client, int args)
{
	ShowSrvSettings(client);
	return Plugin_Handled;
}

public Action Client_Help(int client, int args)
{
	HelpPanel(client);
	return Plugin_Handled;
}

public Action Client_Ranks(int client, int args)
{
	if (IsValidClient(client))
	{
		char ChatLine[512];
		Format(ChatLine, 512, "[%cSurf Timer%c] ", MOSSGREEN, WHITE);
		int i, RankValue[SkillGroup];
		for (i = 0; i < GetArraySize(g_hSkillGroups); i++)
		{
			GetArrayArray(g_hSkillGroups, i, RankValue[0]);

			if (i != 0 && i % 3 == 0)
			{
				PrintToChat(client, ChatLine);
				Format(ChatLine, 512, " ");
			}
			Format(ChatLine, 512, "%s%s%c (%ip)   ", ChatLine, RankValue[RankNameColored], WHITE, RankValue[PointReq]);
		}
		PrintToChat(client, ChatLine);
	}
	return Plugin_Handled;
}

public Action Client_Profile(int client, int args)
{
	ProfileMenu(client, args);
	return Plugin_Handled;
}

public Action Client_Compare(int client, int args)
{
	CompareMenu(client, args);
	return Plugin_Handled;
}

public Action Client_RankingSystem(int client, int args)
{
	PrintToChat(client, "[%cSurf Timer%c]%c Loading html page.. (requires cl_disablehtmlmotd 0)", MOSSGREEN, WHITE, LIMEGREEN);
	ShowMOTDPanel(client, "ckSurf - Ranking System", "http://koti.kapsi.fi/~mukavajoni/ranking/index.html", MOTDPANEL_TYPE_URL);
	return Plugin_Handled;
}

public Action Client_Pause(int client, int args)
{
	if (GetClientTeam(client) == 1)return Plugin_Handled;
	PauseMethod(client);
	if (g_bPause[client] == false)
		PrintToChat(client, "%t", "Pause2", MOSSGREEN, WHITE, RED, WHITE);
	else
		PrintToChat(client, "%t", "Pause3", MOSSGREEN, WHITE);
	return Plugin_Handled;
}

public void PauseMethod(int client)
{
	if (GetClientTeam(client) == 1)return;

	g_fLastTimePauseUsed[client] = GetGameTime();

	if (g_bPause[client] == false && IsValidEntity(client))
	{
		if (GetConVarBool(g_hPauseServerside) == false && client != g_RecordBot)
		{
			PrintToChat(client, "%t", "Pause1", MOSSGREEN, WHITE, RED, WHITE);
			return;
		}
		g_bPause[client] = true;
		SetEntityMoveType(client, MOVETYPE_NONE);
		//Timer enabled?
		if (g_bTimeractivated[client] == true)
		{
			g_fStartPauseTime[client] = GetGameTime();
			if (g_fPauseTime[client] > 0.0)
				g_fStartPauseTime[client] = g_fStartPauseTime[client] - g_fPauseTime[client];
		}
		SetEntityRenderMode(client, RENDER_NONE);
		SetEntData(client, FindSendPropInfo("CBaseEntity", "m_CollisionGroup"), 2, 4, true);
	}
	else
	{
		if (g_fStartTime[client] != -1.0 && g_bTimeractivated[client] == true)
		{
			g_fPauseTime[client] = GetGameTime() - g_fStartPauseTime[client];
		}
		g_bNoClip[client] = false;
		g_bPause[client] = false;
		if (!g_bRoundEnd)
			SetEntityMoveType(client, MOVETYPE_WALK);
		SetEntityRenderMode(client, RENDER_NORMAL);
		if (GetConVarBool(g_hCvarNoBlock))
			SetEntData(client, FindSendPropInfo("CBaseEntity", "m_CollisionGroup"), 2, 4, true);
		else
			SetEntData(client, FindSendPropInfo("CBaseEntity", "m_CollisionGroup"), 2, 5, true);
	}
}

public Action Client_HideSpecs(int client, int args)
{
	HideSpecs(client);
	if (g_bShowSpecs[client] == true)
		PrintToChat(client, "%t", "HideSpecs1", MOSSGREEN, WHITE);
	else
		PrintToChat(client, "%t", "HideSpecs2", MOSSGREEN, WHITE);
	return Plugin_Handled;
}

public void HideSpecs(int client)
{
	g_bShowSpecs[client] = !g_bShowSpecs[client];
}


public int GoToMenuHandler(Menu menu, MenuAction action, int param1, int param2)
{
	if (action == MenuAction_Select)
	{
		char info[32];
		char szPlayerName[MAX_NAME_LENGTH];
		GetMenuItem(menu, param2, info, sizeof(info));
		for (int i = 1; i <= MaxClients; i++)
		{
			if (IsValidClient(i) && IsPlayerAlive(i) && i != param1)
			{
				GetClientName(i, szPlayerName, MAX_NAME_LENGTH);
				if (StrEqual(info, szPlayerName))
				{
					GotoMethod(param1, i);
				}
				else
				{
					if (i == MaxClients)
					{
						PrintToChat(param1, "%t", "Goto4", MOSSGREEN, WHITE, szPlayerName);
						Client_GoTo(param1, 0);
					}
				}
			}
		}
	}
	else
		if (action == MenuAction_End)
	{
		CloseHandle(menu);
	}
}

public void GotoMethod(int client, int target)
{
	if (!IsValidClient(client) || IsFakeClient(client))
		return;
	char szTargetName[MAX_NAME_LENGTH];
	GetClientName(target, szTargetName, MAX_NAME_LENGTH);
	if (GetEntityFlags(target) & FL_ONGROUND)
	{
		Client_Stop(client, 0);

		int ducked = GetEntProp(target, Prop_Send, "m_bDucked");
		int ducking = GetEntProp(target, Prop_Send, "m_bDucking");
		if (!(GetClientButtons(client) & IN_DUCK) && ducked == 0 && ducking == 0)
		{
			if (GetClientTeam(client) == 1 || GetClientTeam(client) == 0)
			{
				float position[3];
				float angles[3];
				GetClientAbsOrigin(target, position);
				GetClientEyeAngles(target, angles);

				AddVectors(position, angles, g_fTeleLocation[client]);
				g_fTeleLocation[client][0] = FloatDiv(g_fTeleLocation[client][0], 2.0);
				g_fTeleLocation[client][1] = FloatDiv(g_fTeleLocation[client][1], 2.0);
				g_fTeleLocation[client][2] = FloatDiv(g_fTeleLocation[client][2], 2.0);

				g_bRespawnPosition[client] = false;
				g_specToStage[client] = true;
				TeamChangeActual(client, 0);
			}
			else
			{
				float position[3];
				float angles[3];
				GetClientAbsOrigin(target, position);
				GetClientEyeAngles(target, angles);
				teleportEntitySafe(client, position, angles, view_as<float>( { 0.0, 0.0, -100.0 } ), true);
				//TeleportEntity(client, position, angles, Float:{0.0,0.0,-100.0});
				char szClientName[MAX_NAME_LENGTH];
				GetClientName(client, szClientName, MAX_NAME_LENGTH);
				PrintToChat(target, "%t", "Goto5", MOSSGREEN, WHITE, szClientName);
			}
		}
		else
		{
			PrintToChat(client, "%t", "Goto6", MOSSGREEN, WHITE, szTargetName);
			Client_GoTo(client, 0);
		}
	}
	else
	{
		PrintToChat(client, "%t", "Goto7", MOSSGREEN, WHITE, szTargetName);
		Client_GoTo(client, 0);
	}
}



public Action Client_GoTo(int client, int args)
{
	if (!GetConVarBool(g_hGoToServer))
		PrintToChat(client, "%t", "Goto1", MOSSGREEN, WHITE, RED, WHITE);
	else
		if (!GetConVarBool(g_hCvarNoBlock))
			PrintToChat(client, "%t", "Goto2", MOSSGREEN, WHITE);
		else
			if (g_bTimeractivated[client])
				PrintToChat(client, "%t", "Goto3", MOSSGREEN, WHITE, GREEN, WHITE);
			else
			{
				char szPlayerName[MAX_NAME_LENGTH];
				char szOrgTargetName[MAX_NAME_LENGTH];
				char szTargetName[MAX_NAME_LENGTH];
				char szArg[MAX_NAME_LENGTH];
				if (args == 0)
				{
					Menu menu = CreateMenu(GoToMenuHandler);
					SetMenuTitle(menu, "ckSurf - Goto menu");
					int playerCount = 0;
					for (int i = 1; i <= MaxClients; i++)
					{
						if (IsValidClient(i) && IsPlayerAlive(i) && i != client && !IsFakeClient(i))
						{
							GetClientName(i, szPlayerName, MAX_NAME_LENGTH);
							AddMenuItem(menu, szPlayerName, szPlayerName);
							playerCount++;
						}
					}
					if (playerCount > 0)
					{
						SetMenuOptionFlags(menu, MENUFLAG_BUTTON_EXIT);
						DisplayMenu(menu, client, MENU_TIME_FOREVER);
					}
					else
					{
						CloseHandle(menu);
						PrintToChat(client, "%t", "ChallengeFailed4", MOSSGREEN, WHITE);
					}
				}
				else
				{
					for (int i = 1; i < 20; i++)
					{
						GetCmdArg(i, szArg, MAX_NAME_LENGTH);
						if (!StrEqual(szArg, "", false))
						{
							if (i == 1)
								Format(szTargetName, MAX_NAME_LENGTH, "%s", szArg);
							else
								Format(szTargetName, MAX_NAME_LENGTH, "%s %s", szTargetName, szArg);
						}
					}
					Format(szOrgTargetName, MAX_NAME_LENGTH, "%s", szTargetName);
					StringToUpper(szTargetName);
					for (int i = 1; i <= MaxClients; i++)
					{
						if (IsValidClient(i) && IsPlayerAlive(i) && i != client)
						{
							GetClientName(i, szPlayerName, MAX_NAME_LENGTH);
							StringToUpper(szPlayerName);
							if ((StrContains(szPlayerName, szTargetName) != -1))
							{
								GotoMethod(client, i);
								return Plugin_Handled;
							}
						}
					}
					PrintToChat(client, "%t", "PlayerNotFound", MOSSGREEN, WHITE, szOrgTargetName);
				}
			}
	return Plugin_Handled;
}

public Action Client_QuakeSounds(int client, int args)
{
	QuakeSounds(client);
	if (g_bEnableQuakeSounds[client])
		PrintToChat(client, "%t", "QuakeSounds1", MOSSGREEN, WHITE);
	else
		PrintToChat(client, "%t", "QuakeSounds2", MOSSGREEN, WHITE);
	return Plugin_Handled;
}

public void QuakeSounds(int client)
{
	g_bEnableQuakeSounds[client] = !g_bEnableQuakeSounds[client];
}

public Action Client_Stop(int client, int args)
{
	if (g_bTimeractivated[client])
	{
		//PlayerPanel(client);
		g_bTimeractivated[client] = false;
		g_fStartTime[client] = -1.0;
		g_fCurrentRunTime[client] = -1.0;
	}

	if (g_bStageTimerRunning[client])
	{
		g_bStageTimerRunning[client] = false;
		g_fStageStartTime[client] = -1.0;
	}

	StopRecording(client);

	return Plugin_Handled;
}

public void Action_NoClip(int client)
{
	if (IsValidClient(client) && !IsFakeClient(client) && IsPlayerAlive(client) && GetConVarBool(g_hNoClipS))
	{
		g_fLastTimeNoClipUsed[client] = GetGameTime();
		int team = GetClientTeam(client);
		if (team == 2 || team == 3)
		{
			MoveType mt = GetEntityMoveType(client);
			if (mt == MOVETYPE_WALK)
			{
				if (g_bTimeractivated[client] || g_bStageTimerRunning[client])
				{
					Client_Stop(client, 1);
					g_fStartTime[client] = -1.0;
					g_fCurrentRunTime[client] = -1.0;
				}
				SetEntityMoveType(client, MOVETYPE_NOCLIP);
				SetEntityRenderMode(client, RENDER_NONE);
				SetEntData(client, FindSendPropInfo("CBaseEntity", "m_CollisionGroup"), 2, 4, true);
				g_bNoClip[client] = true;
				g_bNoclipped[client] = true;
			}
		}
	}
	return;
}

public void Action_UnNoClip(int client)
{
	if (IsValidClient(client) && !IsFakeClient(client) && IsPlayerAlive(client))
	{
		g_fLastTimeNoClipUsed[client] = GetGameTime();
		int team = GetClientTeam(client);
		if (team == 2 || team == 3)
		{
			MoveType mt = GetEntityMoveType(client);
			if (mt == MOVETYPE_NOCLIP)
			{
				SetEntityMoveType(client, MOVETYPE_WALK);
				SetEntityRenderMode(client, RENDER_NORMAL);
				if (GetConVarBool(g_hCvarNoBlock))
					SetEntData(client, FindSendPropInfo("CBaseEntity", "m_CollisionGroup"), 2, 4, true);
				else
					SetEntData(client, FindSendPropInfo("CBaseEntity", "m_CollisionGroup"), 5, 4, true);
				g_bNoClip[client] = false;
			}
		}
	}
	return;
}

public void ckTopMenu(int client)
{
	g_MenuLevel[client] = -1;
	Menu cktopmenu = CreateMenu(TopMenuHandler);
	SetMenuTitle(cktopmenu, "ckSurf - Top Menu");
	if (GetConVarBool(g_hPointSystem))
		AddMenuItem(cktopmenu, "Top 100 Players", "Top 100 Players");
	AddMenuItem(cktopmenu, "Top 5 Challengers", "Top 5 Challengers");
	AddMenuItem(cktopmenu, "Map Top", "Map Top");

	AddMenuItem(cktopmenu, "Bonus Top", "Bonus Top", !g_bhasBonus);

	AddMenuItem(cktopmenu, "Stage Top", "Stage Top", !g_bhasStages);


	SetMenuOptionFlags(cktopmenu, MENUFLAG_BUTTON_EXIT);
	DisplayMenu(cktopmenu, client, MENU_TIME_FOREVER);
}

public int TopMenuHandler(Menu menu, MenuAction action, int param1, int param2)
{
	if (action == MenuAction_Select)
	{
		if (GetConVarBool(g_hPointSystem))
		{
			switch (param2)
			{
				case 0:db_selectTopPlayers(param1);
				case 1:db_selectTopChallengers(param1);
				case 2:db_selectTopSurfers(param1, g_szMapName);
				case 3:BonusTopMenu(param1);
				case 4:StageTopMenu(param1);
			}
		}
		else
		{
			switch (param2)
			{
				case 0:db_selectTopChallengers(param1);
				case 1:db_selectTopProRecordHolders(param1);
				case 2:db_selectTopSurfers(param1, g_szMapName);
				case 3:BonusTopMenu(param1);
				case 4:StageTopMenu(param1);
			}
		}
	}
	else
		if (action == MenuAction_End)
		CloseHandle(menu);
}

public void BonusTopMenu(int client)
{
	if (g_mapZoneGroupCount > 2)
	{
		char buffer[3];
		Menu sMenu = new Menu(BonusTopMenuHandler);
		sMenu.SetTitle("Bonus selector");

		if (g_mapZoneGroupCount > 1)
		{
			for (int i = 1; i < g_mapZoneGroupCount; i++)
			{
				IntToString(i, buffer, 3);
				sMenu.AddItem(buffer, g_szZoneGroupName[i]);
			}
		}
		else
		{
			PrintToChat(client, "[%cSurf Timer%c] There are no bonuses in this map.", MOSSGREEN, WHITE);
			return;
		}

		sMenu.ExitButton = true;
		sMenu.Display(client, 60);
	}
	else
	{
		db_selectBonusTopSurfers(client, g_szMapName, 1);
	}
}

public int BonusTopMenuHandler(Menu menu, MenuAction action, int param1, int param2)
{
	if (action == MenuAction_Select)
	{
		db_selectBonusTopSurfers(param1, g_szMapName, param2 + 1);
	}
}

public void StageTopMenu(int client)
{
	Menu menu = new Menu(StageTopMenuHandler);

	menu.SetTitle("Stage Records: Select stage");


	for (int i = 1; i <= g_mapZonesTypeCount[0][3] + 1; i++)
	{
		char name[32];
		Format(name, sizeof(name), "Stage %d", i);

		menu.AddItem(name, name);
	}

	menu.Display(client, 60);
}

public int StageTopMenuHandler(Menu menu, MenuAction action, int param1, int param2)
{
	if (action != MenuAction_Select) return 0;

	db_viewStageRecords(param1, param2+1);

	return 0;
}

public void HelpPanel(int client)
{
	PrintConsoleInfo(client);
	Handle panel = CreatePanel();
	char title[64];
	Format(title, 64, "ckSurf Help (1/4) - v%s\nby Elzi", VERSION);
	DrawPanelText(panel, title);
	DrawPanelText(panel, " ");
	DrawPanelText(panel, "!help - opens this menu");
	DrawPanelText(panel, "!help2 - explanation of the ranking system");
	DrawPanelText(panel, "!menu - checkpoint menu");
	DrawPanelText(panel, "!options - player options menu");
	DrawPanelText(panel, "!top - top menu");
	DrawPanelText(panel, "!latest - prints in console the last map records");
	DrawPanelText(panel, "!profile/!ranks - opens your profile");
	DrawPanelText(panel, " ");
	DrawPanelItem(panel, "next page");
	DrawPanelItem(panel, "exit");
	SendPanelToClient(panel, client, HelpPanelHandler, 10000);
	CloseHandle(panel);
}

public int HelpPanelHandler(Menu menu, MenuAction action, int param1, int param2)
{
	if (action == MenuAction_Select)
	{
		if (param2 == 1)
			HelpPanel2(param1);
	}
}

public int HelpPanel2(int client)
{
	Handle panel = CreatePanel();
	char szTmp[64];
	Format(szTmp, 64, "ckSurf Help (2/4) - v%s\nby Elzi", VERSION);
	DrawPanelText(panel, szTmp);
	DrawPanelText(panel, " ");
	DrawPanelText(panel, "!start/!r - go back to start");
	DrawPanelText(panel, "!stop - stops the timer");
	DrawPanelText(panel, "!pause - on/off pause");
	DrawPanelText(panel, "!usp - spawns a usp silencer");
	DrawPanelText(panel, "!challenge - allows you to start a race against others");
	DrawPanelText(panel, "!spec [<name>] - select a player you want to watch");
	DrawPanelText(panel, "!goto [<name>] - teleports you to a given player");
	DrawPanelText(panel, "!compare [<name>] - compare your challenge results with a given player");
	DrawPanelText(panel, "!showsettings - shows ckSurf plugin settings");
	DrawPanelText(panel, " ");
	DrawPanelItem(panel, "previous page");
	DrawPanelItem(panel, "next page");
	DrawPanelItem(panel, "exit");
	SendPanelToClient(panel, client, HelpPanel2Handler, 10000);
	CloseHandle(panel);
}

public int HelpPanel2Handler(Menu menu, MenuAction action, int param1, int param2)
{
	if (action == MenuAction_Select)
	{
		if (param2 == 1)
			HelpPanel(param1);
		else
			if (param2 == 2)
			HelpPanel3(param1);
	}
}

public void HelpPanel3(int client)
{
	Handle panel = CreatePanel();
	char szTmp[64];
	Format(szTmp, 64, "ckSurf Help (3/4) - v%s\nby Elzi", VERSION);
	DrawPanelText(panel, szTmp);
	DrawPanelText(panel, " ");
	DrawPanelText(panel, "!maptop <mapname> - displays map top for a given map");
	DrawPanelText(panel, "!flashlight - on/off flashlight");
	DrawPanelText(panel, "!ranks - prints in chat the available ranks");
	DrawPanelText(panel, "!measure - allows you to measure the distance between 2 points");
	DrawPanelText(panel, "!language - opens the language menu");
	DrawPanelText(panel, "!wr - prints in chat the record of the current map");
	DrawPanelText(panel, "!avg - prints in chat the average map time");
	DrawPanelText(panel, "!stuck / !back - teleports player back to the start of the stage. Does not stop timer");
	DrawPanelText(panel, "!avg - !");
	DrawPanelText(panel, " ");
	DrawPanelItem(panel, "previous page");
	DrawPanelItem(panel, "exit");
	SendPanelToClient(panel, client, HelpPanel3Handler, 10000);
	CloseHandle(panel);
}
public int HelpPanel3Handler(Menu menu, MenuAction action, int param1, int param2)
{
	if (action == MenuAction_Select)
	{
		if (param2 == 1)
			HelpPanel2(param1);
		else
			if (param2 == 2)
			HelpPanel4(param1);
	}
}

public void HelpPanel4(int client)
{
	Handle panel = CreatePanel();
	char szTmp[64];
	Format(szTmp, 64, "ckSurf Help (4/4) - v%s\nby Elzi", VERSION);
	DrawPanelText(panel, szTmp);
	DrawPanelText(panel, " ");
	DrawPanelText(panel, "!cp - Creates a checkpoint to use in practice mode.");
	DrawPanelText(panel, "!tele / !teleport / !practice / !prac - Starts practice mode");
	DrawPanelText(panel, "!undo - Undoes your latest checkpoint");
	DrawPanelText(panel, " ");
	DrawPanelItem(panel, "previous page");
	DrawPanelItem(panel, "exit");
	SendPanelToClient(panel, client, HelpPanel4Handler, 10000);
	CloseHandle(panel);
}

public int HelpPanel4Handler(Menu menu, MenuAction action, int param1, int param2)
{
	if (action == MenuAction_Select)
	{
		if (param2 == 1)
			HelpPanel2(param1);
	}
}

public void ShowSrvSettings(int client)
{
	PrintToConsole(client, " ");
	PrintToConsole(client, "-----------------");
	PrintToConsole(client, "ckSurf settings");
	PrintToConsole(client, "-----------------");
	PrintToConsole(client, "ck_admin_clantag %b", GetConVarBool(g_hAdminClantag));
	PrintToConsole(client, "ck_attack_spam_protection %b", GetConVarBool(g_hAttackSpamProtection));
	//PrintToConsole(client, "ck_auto_timer %i", GetConVarBool(g_hAutoTimer));
	PrintToConsole(client, "ck_autoheal %i (requires ck_godmode 0)", GetConVarInt(g_hAutohealing_Hp));
	PrintToConsole(client, "ck_autorespawn %b", GetConVarBool(g_hAutoRespawn));
	PrintToConsole(client, "ck_challenge_points %b", GetConVarBool(g_hChallengePoints));
	PrintToConsole(client, "ck_clean_weapons %b", GetConVarBool(g_hCleanWeapons));
	PrintToConsole(client, "ck_connect_msg %b", GetConVarBool(g_hConnectMsg));
	PrintToConsole(client, "ck_country_tag %b", GetConVarBool(g_hCountry));
	PrintToConsole(client, "ck_custom_models %b", GetConVarBool(g_hPlayerSkinChange));
	PrintToConsole(client, "ck_dynamic_timelimit %b (requires ck_map_end 1)", GetConVarBool(g_hDynamicTimelimit));
	PrintToConsole(client, "ck_godmode %b", GetConVarBool(g_hCvarGodMode));
	PrintToConsole(client, "ck_goto %b", GetConVarBool(g_hGoToServer));
	PrintToConsole(client, "ck_info_bot %b", GetConVarBool(g_hInfoBot));
	PrintToConsole(client, "ck_noclip %b", GetConVarBool(g_hNoClipS));
	PrintToConsole(client, "ck_map_end %b", GetConVarBool(g_hMapEnd));
	PrintToConsole(client, "ck_noblock %b", GetConVarBool(g_hCvarNoBlock));
	PrintToConsole(client, "ck_pause %b", GetConVarBool(g_hPauseServerside));
	PrintToConsole(client, "ck_point_system %b", GetConVarBool(g_hPointSystem));
	PrintToConsole(client, "ck_ranking_extra_points_firsttime %i", GetConVarInt(g_hExtraPoints2));
	PrintToConsole(client, "ck_ranking_extra_points_improvements %i", GetConVarInt(g_hExtraPoints));
	PrintToConsole(client, "ck_replay_bot %b", GetConVarBool(g_hReplayBot));
	PrintToConsole(client, "ck_restore %b", GetConVarBool(g_hcvarRestore));
	PrintToConsole(client, "ck_use_radio %b", GetConVarBool(g_hRadioCommands));
	PrintToConsole(client, "---------------");
	PrintToConsole(client, "Server settings");
	PrintToConsole(client, "---------------");
	Handle hTmp;
	hTmp = FindConVar("sv_airaccelerate");
	float flAA = GetConVarFloat(hTmp);
	hTmp = FindConVar("sv_accelerate");
	float flA = GetConVarFloat(hTmp);
	hTmp = FindConVar("sv_friction");
	float flFriction = GetConVarFloat(hTmp);
	hTmp = FindConVar("sv_gravity");
	float flGravity = GetConVarFloat(hTmp);
	hTmp = FindConVar("sv_enablebunnyhopping");
	int iBhop = GetConVarInt(hTmp);
	hTmp = FindConVar("sv_autobunnyhopping");
	int iAutoBhop = GetConVarInt(hTmp);
	hTmp = FindConVar("sv_maxspeed");
	float flMaxSpeed = GetConVarFloat(hTmp);
	hTmp = FindConVar("sv_maxvelocity");
	float flMaxVel = GetConVarFloat(hTmp);
	hTmp = FindConVar("sv_staminalandcost");
	float flStamLand = GetConVarFloat(hTmp);
	hTmp = FindConVar("sv_staminajumpcost");
	float flStamJump = GetConVarFloat(hTmp);
	hTmp = FindConVar("sv_wateraccelerate");
	float flWaterA = GetConVarFloat(hTmp);
	if (hTmp != null)
		CloseHandle(hTmp);
	PrintToConsole(client, "sv_accelerate %.1f", flA);
	PrintToConsole(client, "sv_airaccelerate %.1f", flAA);
	PrintToConsole(client, "sv_friction %.1f", flFriction);
	PrintToConsole(client, "sv_gravity %.1f", flGravity);
	PrintToConsole(client, "sv_enablebunnyhopping %i", iBhop);
	PrintToConsole(client, "sv_autobunnyhopping %i", iAutoBhop);
	PrintToConsole(client, "sv_maxspeed %.1f", flMaxSpeed);
	PrintToConsole(client, "sv_maxvelocity %.1f", flMaxVel);
	PrintToConsole(client, "sv_staminalandcost %.2f", flStamLand);
	PrintToConsole(client, "sv_staminajumpcost %.2f", flStamJump);
	PrintToConsole(client, "sv_wateraccelerate %.1f", flWaterA);
	PrintToConsole(client, "-------------------------------------");
	PrintToChat(client, "[%cSurf Timer%c] See console for output!", MOSSGREEN, WHITE);
}

public void OptionMenu(int client)
{
	Menu optionmenu = CreateMenu(OptionMenuHandler);
	SetMenuTitle(optionmenu, "ckSurf - Options Menu");
	// #0
	if (g_bHide[client])
		AddMenuItem(optionmenu, "Hide Players  -  Enabled", "Hide other players  -  Enabled");
	else
		AddMenuItem(optionmenu, "Hide Players  -  Disabled", "Hide other players  -  Disabled");
	// #1
	if (g_bEnableQuakeSounds[client])
		AddMenuItem(optionmenu, "Quake sounds - Enabled", "Quake sounds - Enabled");
	else
		AddMenuItem(optionmenu, "Quake sounds - Disabled", "Quake sounds - Disabled");
	// #2
	if (g_bShowSpecs[client])
		AddMenuItem(optionmenu, "Spectator list  -  Enabled", "Spectator list  -  Enabled");
	else
		AddMenuItem(optionmenu, "Spectator list  -  Disabled", "Spectator list  -  Disabled");
	// #3
	if (g_bHideChat[client])
		AddMenuItem(optionmenu, "Hide Chat - Hidden", "Hide Chat - Hidden");
	else
		AddMenuItem(optionmenu, "Hide Chat - Visible", "Hide Chat - Visible");
	// #4
	if (g_bViewModel[client])
		AddMenuItem(optionmenu, "Hide Weapon - Visible", "Hide Weapon - Visible");
	else
		AddMenuItem(optionmenu, "Hide Weapon - Hidden", "Hide Weapon - Hidden");
	// #5
	if (g_bCheckpointsEnabled[client])
		AddMenuItem(optionmenu, "Checkpoints - Enabled", "Checkpoints - Enabled");
	else
		AddMenuItem(optionmenu, "Checkpoints - Disabled", "Checkpoints - Disabled");
	// #6
	if (g_bHideLeftHud[client])
		AddMenuItem(optionmenu, "Left Hud - Disabled", "Left Hud - Disabled");
	else
		AddMenuItem(optionmenu, "Left Hud - Enabled", "Left Hud - Enabled");

	SetMenuOptionFlags(optionmenu, MENUFLAG_BUTTON_EXIT);
	if (g_OptionsMenuLastPage[client] < 6)
		DisplayMenuAtItem(optionmenu, client, 0, MENU_TIME_FOREVER);
	else
		if (g_OptionsMenuLastPage[client] < 12)
			DisplayMenuAtItem(optionmenu, client, 6, MENU_TIME_FOREVER);
		else
			if (g_OptionsMenuLastPage[client] < 18)
				DisplayMenuAtItem(optionmenu, client, 12, MENU_TIME_FOREVER);
}


public int OptionMenuHandler(Menu menu, MenuAction action, int param1, int param2)
{
	if (action == MenuAction_Select)
	{
		switch (param2)
		{
			case 0:HideMethod(param1);
			case 1:QuakeSounds(param1);
			case 2:HideSpecs(param1);
			case 3:HideChat(param1);
			case 4:HideViewModel(param1);
			case 5:ToggleCheckpoints(param1, 1);
			case 6: g_bHideLeftHud[param1] = !g_bHideLeftHud[param1];
		}
		g_OptionsMenuLastPage[param1] = param2;
		OptionMenu(param1);
	}
	else
		if (action == MenuAction_End)
	{
		CloseHandle(menu);
	}
}

public Action Command_ViewStats(int client, int args)
{
	//ShowMOTDPanel(client, "Surf statistics", "http://2gcrew.space/motd.php?u=http://2gcrew.space/surf_stats/", MOTDPANEL_TYPE_URL);
	OpenMOTD(client, g_cWebStatsUrl_Base);
}

public Action Command_saveLoc(int client, int args)
{
	int id = g_SavedLocationsCount++;

	// Check if we reached the limit of savelocs
	if (id >= MAX_SAVELOCS)
	{
		PrintToChat(client, "[%cSurf Timer%c] We reached the limit of saved locations for this map.", MOSSGREEN, WHITE);
		return Plugin_Handled;
	}

	int target = client;

	// Check if the player is spectating
	if (!IsPlayerAlive(client) || GetClientTeam(client) <= 1)
		// Get the player who is being observed
		target = GetEntPropEnt(client, Prop_Send, "m_hObserverTarget");


	// Buffers
	float origin[3], velocity[3], angles[3];

	// Get location
	GetClientAbsOrigin(target, origin);
	GetEntPropVector(target, Prop_Data, "m_vecVelocity", velocity);
	GetClientEyeAngles(target, angles);

	// Get Creator and Target name
	GetClientName(client, g_SavedLocations[id][slCreator], 32);
	GetClientName(target, g_SavedLocations[id][slPlayer], 32);

	// Get current run time
	g_SavedLocations[id][slRunTime] = g_fCurrentRunTime[target];

	// Save location
	Array_Copy(origin, g_SavedLocations[id][slOrigin], sizeof(origin));
	Array_Copy(velocity, g_SavedLocations[id][slVelocity], sizeof(velocity));
	Array_Copy(angles, g_SavedLocations[id][slAngles], sizeof(angles));


	// Print saveloc's info to chat
	PrintToChat(client, "[%cSurf Timer%c] Your location was saved with the ID: %c#%d%c type %c!loadloc %d %cto teleport to the location.", MOSSGREEN, WHITE, GREEN, id, WHITE, GREEN, id, WHITE);

	return Plugin_Handled;
}

public Action Command_loadLoc(int client, int args)
{
	// Check if the client is in spectator
	if (GetClientTeam(client) <= 1 || !IsPlayerAlive(client) || !IsValidClient(client))
		return Plugin_Handled;

	int id;

	// Check if no args were given
	if (args < 1)
	{
		// Check if the player used an loadloc before
		if (g_LastSaveLocUsed[client] >= 0)
		{
			// Use the last used loadloc id
			id = g_LastSaveLocUsed[client];
		}
		else
		{
			PrintToChat(client, "[%cSurf Timer%c] Usage: %c!loadloc <id>", MOSSGREEN, WHITE, GREEN);
			return Plugin_Handled;
		}
	}
	else
	{
		// Get the argument given
		char arg1[5];
		GetCmdArg(1, arg1, sizeof(arg1));
		id = StringToInt(arg1);
	}

	// Make sure the saveloc id exists and is not from the past map
	if (g_SavedLocationsCount < id)
	{
		PrintToChat(client, "[%cSurf Timer%c] No location was found with the id %c#%d", MOSSGREEN, WHITE, GREEN, id);
		return Plugin_Handled;
	}

	// Make run as invalid
	g_bValidRun[client] = false;

	// stop stage timer
	g_bStageTimerRunning[client] = false;

	// Reset player velocity
	SetEntPropVector(client, Prop_Data, "m_vecVelocity", view_as<float>( { 0.0, 0.0, 0.0 } ));

	// Get saved location
	float origin[3], angles[3], velocity[3];

	Array_Copy(g_SavedLocations[id][slOrigin], origin, sizeof(origin));
	Array_Copy(g_SavedLocations[id][slAngles], angles, sizeof(angles));
	Array_Copy(g_SavedLocations[id][slVelocity], velocity, sizeof(velocity));

	// Teleport player
	teleportEntitySafe(client, origin, angles, velocity, true);

	// Check if its the first time the player is using this saved location
	if (g_LastSaveLocUsed[client] != id)
	{
		// Format run time
		char sTime[64];
		FormatTimeFloat(client, g_SavedLocations[id][slRunTime], 3, sTime, sizeof(sTime));

		// Print message to chat
		PrintToChat(client, "[%cSurf Timer%c] Loaded location %c#%d %ccreated by: %c%s %c[Player: %c%s %c| Time: %c%s%c]", MOSSGREEN, WHITE, GREEN, id, WHITE, GREEN, g_SavedLocations[id][slCreator], WHITE, GREEN, g_SavedLocations[id][slPlayer], WHITE, GREEN, sTime, WHITE);
	}

	// Store the id
	g_LastSaveLocUsed[client] = id;

	return Plugin_Handled;
}


public Action Command_Replay(int client, int args)
{
	if (!g_RecordBot)
	{
		PrintToChat(client, "[%cSurf Timer%c] No replay bots available.", MOSSGREEN, WHITE);
		return Plugin_Handled;
	}

	// Only restrict use if the player is not an admin or more people are watching the replay
	int spectators = CountSpectators(g_RecordBot);
	bool isSpectatingBot = GetEntPropEnt(client, Prop_Send, "m_hObserverTarget") == g_RecordBot;

	AdminId admin = GetUserAdmin(client);

	if (admin == INVALID_ADMIN_ID || !admin.HasFlag(Admin_Generic) || (spectators == 1 && isSpectatingBot)) 
	{
		if (g_bIsPlayingReplay)
		{
			PrintToChat(client, "[%cSurf Timer%c] The replay bot is currently busy. Wait for the current replay to finish.", MOSSGREEN, WHITE);
			return Plugin_Handled;
		}


		float requestDelay = GetGameTime() - g_fLastReplayRequested[client];
		if (requestDelay < 15.0)
		{
			PrintToChat(client, "[%cSurf Timer%c] Please wait %d seconds before requesting a new replay", MOSSGREEN, WHITE, RoundToCeil(15.0 - requestDelay));
			return Plugin_Handled;
		}
	}
	else if (g_bIsPlayingReplay && !g_bConfirmedReplayRestart[client])
	{
		Menu menu_confirm = CreateMenu(ReplayMenu_Confirm_Handler);

		menu_confirm.SetTitle("The replay bot is currently being in use");
		menu_confirm.AddItem("restart", "Change replay");
		menu_confirm.AddItem("replay", "Spectate");

		menu_confirm.Display(client, 60);
		return Plugin_Handled;
	}


	Menu menu = CreateMenu(ReplayMenu_Handler);

	SetMenuTitle(menu, "[Surf Timer] Replay");

	char sPath[256];

	BuildPath(Path_SM, sPath, sizeof(sPath), "%s%s.rec", CK_REPLAY_PATH, g_szMapName);

	menu.AddItem("0", "Map", !FileExists(sPath));

	if (g_bhasStages)
		menu.AddItem("stages", "Stages");

	if (g_bhasBonus)
		menu.AddItem("bonus", "Bonus");

	

	menu.Display(client, 60);

	return Plugin_Handled;
}


public int ReplayMenu_Handler(Menu tMenu, MenuAction action, int client, int item)
{
	if (action != MenuAction_Select) return 0;

	g_ReplayRequester = client;
	Format(g_sReplayRequester, sizeof(g_sReplayRequester), "%N", client);

	char id[8];

	tMenu.GetItem(item, id, sizeof(id));


	if (StrEqual(id, "stages")) 
	{
		Menu menu = CreateMenu(ReplayMenu_Handler);
		menu.SetTitle("[Surf Timer] Replay - Stages");

		for (int i = 1; i <= (g_mapZonesTypeCount[g_iClientInZone[client][2]][3] + 1); i++)
		{
			char sPath[256];

			// Check if file exists
			BuildPath(Path_SM, sPath, sizeof(sPath), "%s%s_stage_%d.rec", CK_REPLAY_PATH, g_szMapName, i);

			char sri[4], name[16];
			IntToString((i * -1), sri, sizeof(sri));

			Format(name, sizeof(name), "Stage %d", i);

			// Check if file exists
			menu.AddItem(sri, name, !FileExists(sPath));
		}

		menu.AddItem("back", "Go back");

		menu.Display(client, 60);
		return 0;
	}


	// Go to bonus menu
	if (StrEqual(id, "bonus"))
	{
		Menu menu = CreateMenu(ReplayMenu_Handler);
		menu.SetTitle("[Surf Timer] Replay - Bonus");

		for (int i = 1; i < g_mapZoneGroupCount; i++)
		{
			char sPath[256];

			// Check if file exists
			BuildPath(Path_SM, sPath, sizeof(sPath), "%s%s_bonus_%d.rec", CK_REPLAY_PATH, g_szMapName, i);

			char bri[4];
			IntToString(i, bri, sizeof(bri));
			menu.AddItem(bri, g_szZoneGroupName[i], !FileExists(sPath));
		}

		menu.AddItem("back", "Go back");

		menu.Display(client, 60);
		return 0;
	}

	// Go back to main replay menu
	if (StrEqual(id, "back"))
	{
		Command_Replay(client, 0);
		return 0;
	}



	g_CurrentReplay = StringToInt(id);

	PlayRecord(g_RecordBot, id);

	ChangeClientTeam(client, 1);
	SetEntPropEnt(client, Prop_Send, "m_hObserverTarget", g_RecordBot);
	SetEntProp(client, Prop_Send, "m_iObserverMode", 4);
	g_bConfirmedReplayRestart[client] = false;

	return 0;
}


public int ReplayMenu_Confirm_Handler(Menu menu, MenuAction action, int client, int item)
{
	 if (action != MenuAction_Select) return 0;

	 if (item == 0)
	 {
	 	g_bConfirmedReplayRestart[client] = true;
	 	Command_Replay(client, 0);
	 } 
	 else if (item == 1)
	 {
	 	SetEntPropEnt(client, Prop_Send, "m_hObserverTarget", g_RecordBot);
		SetEntProp(client, Prop_Send, "m_iObserverMode", 4);
	 }

	 return 0;
}


public Action Command_Repeat(int client, int args) {
	if (g_RepeatStage[client] != -1) {
		g_RepeatStage[client] = -1;
		PrintToChat(client, "[%cSurf Timer%c] Repeat mode is now disabled.", MOSSGREEN, WHITE);
		return Plugin_Handled;
	}

	// Check if player is in a bonus
	if (g_iClientInZone[client][2] != 0) {
		PrintToChat(client, "[%cSurf Timer%c] This command is not available in bonus.", MOSSGREEN, WHITE);
		return Plugin_Handled;
	}

	// Check if its not a staged map
	if (!g_bhasStages) {
		PrintToChat(client, "[%cSurf Timer%c] This command is not available in linear maps.", MOSSGREEN, WHITE);
		return Plugin_Handled;
	}


	g_RepeatStage[client] = g_Stage[0][client];
	PrintToChat(client, "[%cSurf Timer%c] Repeating mode is now enabled, repeating stage %d", MOSSGREEN, WHITE, g_RepeatStage[client]);
	return Plugin_Handled;
}


public Action Command_StageMaxVelocity(int args)
{
	if (args < 2)
	{
		LogError("[Surf Timer] Missing arguments. Usage sm_stagemaxvelocity <stage> <max velocity>");
		return Plugin_Handled;
	}

	char szStage[5], szMaxVel[8];

	// Get arguments value
	GetCmdArg(1, szStage, sizeof(szStage));
	GetCmdArg(2, szMaxVel, sizeof(szMaxVel));

	int stage = StringToInt(szStage);
	float maxvelocity = StringToFloat(szMaxVel);

	// Check if the map has stages
	if (!g_bhasStages)
	{
		LogError("[Surf Timer] sm_stagemaxvelocity: %s is a linear map.", g_szMapName);
		return Plugin_Handled;
	}

	// Check if the stage is valid
	if (stage == 0 || stage >= CPLIMIT)
	{
		LogError("[Surf Timer] sm_stagemaxvelocity: Invalid stage (%s).", szStage);
		return Plugin_Handled;
	}
	
	// Check if the stage exists
	if (stage > g_mapZonesTypeCount[0][3] + 1)
	{
		LogError("[Surf Timer] sm_stagemaxvelocity: Stage %d does not exist on map %s", stage, g_szMapName);
		return Plugin_Handled;
	}

	g_fStageMaxVelocity[stage] = maxvelocity;
	return Plugin_Handled;
}


public Action Command_StageAllowPrehop(int args)
{
	if (args < 2)
	{
		LogError("[Surf Timer] Missing arguments. Usage sm_stageallowprehop <stage> <1|0>");
		return Plugin_Handled;
	}

	char szStage[5], szAllow[8];

	// Get arguments value
	GetCmdArg(1, szStage, sizeof(szStage));
	GetCmdArg(2, szAllow, sizeof(szAllow));

	int stage = StringToInt(szStage);
	int allow = StringToInt(szAllow);

	// Check if the map has stages
	if (!g_bhasStages)
	{
		LogError("[Surf Timer] sm_stageallowprehop: %s is a linear map. ", g_szMapName, stage);
		return Plugin_Handled;
	}

	// Check if the stage is valid
	if (stage == 0 || stage >= CPLIMIT)
	{
		LogError("[Surf Timer] sm_stageallowprehop: Invalid stage %s.", szStage);
		return Plugin_Handled;
	}
	
	// Check if the stage exists
	if (stage > g_mapZonesTypeCount[0][3] + 1)
	{
		LogError("[Surf Timer] sm_stageallowprehop: Stage %d does not exist on map %s", stage, g_szMapName);
		return Plugin_Handled;
	}

	g_bStageIgnorePrehop[stage] = (allow == 1);
	return Plugin_Handled;
}

public Action Command_AllowHighJumps(int args)
{
	if (args < 2)
	{
		LogError("[Surf Timer] Missing arguments. Usage sm_stageallowhighjumps <stage> <1|0>");
		return Plugin_Handled;
	}

	char szStage[5], szAllow[8];

	// Get arguments value
	GetCmdArg(1, szStage, sizeof(szStage));
	GetCmdArg(2, szAllow, sizeof(szAllow));

	int stage = StringToInt(szStage);
	int allow = StringToInt(szAllow);

	// Check if the map has stages
	if (!g_bhasStages)
	{
		LogError("[Surf Timer] sm_stageallowhighjumps: %s is a linear map. ", g_szMapName, stage);
		return Plugin_Handled;
	}

	// Check if the stage is valid
	if (stage == 0 || stage >= CPLIMIT)
	{
		LogError("[Surf Timer] sm_stageallowhighjumps: Invalid stage %s.", szStage);
		return Plugin_Handled;
	}


	
	// Check if the stage exists
	if (stage > g_mapZonesTypeCount[0][3] + 1)
	{
		LogError("[Surf Timer] sm_stageallowhighjumps: Stage %d does not exist on map %s", stage, g_szMapName);
		return Plugin_Handled;
	}

	g_bStageAllowHighJumps[stage] = (allow == 1);
	return Plugin_Handled;
}

public Action Command_ShowZones(int client, int args)
{	
	g_bShowZones[client] = !g_bShowZones[client];

	PrintToChat(client, "[%cSurf Timer%c] Zone display is now %s.", MOSSGREEN, WHITE, (g_bShowZones[client] ? "enabled" : "disabled"));
}

/**
* Displays client map stats panel, shows rank for each stage, bonus and map itself.
*/
public Action Client_MapStats(int client, int args)
{
	if (IsValidClient(client))
	{	
		char szItem[4];
		char szValue[128];
		// char szTime[32];
		char szSteamId[32];
		getSteamIDFromClient(client, szSteamId, 32);
		int i;

		Menu mapInfoMenu = new Menu(MapStatsHandler);
		mapInfoMenu.Pagination = 10;

		//Adds map time

		if (g_fPersonalRecord[client] > 0.0) {
			Format(szValue, 128, "[Map Time]: %s | Rank: %i/%i", g_szPersonalRecord[client], g_MapRank[client], g_MapTimesCount);
			mapInfoMenu.AddItem("0", szValue, ITEMDRAW_DEFAULT);
		}
		else
			mapInfoMenu.AddItem("0", "Map Time: None", ITEMDRAW_DISABLED);

		// Counts stages and creates strings
		int stageCount = (g_mapZonesTypeCount[g_iClientInZone[client][2]][3]) + 1;
		Handle stringArray = CreateArray(stageCount);
	
		if (g_bhasStages) {
			for (i= 1; i<=stageCount; i++) {
				Format(szItem, sizeof(szItem), "%d", i);
				float stageTime = g_fStagePlayerRecord[client][i];
				// Format(szTime, 32, "Time: %f", stageTime);
				if (stageTime < 99999.0) {
					Format(szValue, 128, "Stage %i: %.2f | Rank: %i/%i", (i), stageTime, g_StagePlayerRank[client][i], g_StageRecords[i][srCompletions]);
					mapInfoMenu.AddItem(szItem, szValue, ITEMDRAW_DEFAULT);
				}
				else {
					Format(szValue, 128, "Stage %i: None", i);
					mapInfoMenu.AddItem(szItem, szValue, ITEMDRAW_DISABLED);
				}
				PushArrayString(stringArray, szValue);
			}
		}


		for (i = 1; i < g_mapZoneGroupCount; i++) {
			Format(szItem, sizeof(szItem), "-%d", i);
			float bonusTime = g_fPersonalRecordBonus[i][client];
			if (bonusTime>0) {
				Format(szValue, 128, "Bonus %i: %s | Rank: %i/%i", i, g_szPersonalRecordBonus[i][client], g_MapRankBonus[i][client], g_iBonusCount[i]);
				mapInfoMenu.AddItem(szItem, szValue, ITEMDRAW_DEFAULT);
			}
			else {
				Format(szValue, 128, "Bonus %i: None", i);
				mapInfoMenu.AddItem(szItem, szValue, ITEMDRAW_DISABLED);
			}
		}

		char title[64];
		Format(title, 64, "Map Statistics");
		mapInfoMenu.SetTitle(title);
		mapInfoMenu.OptionFlags = MENUFLAG_BUTTON_EXIT;
		mapInfoMenu.Display(client, MENU_TIME_FOREVER);
		CloseHandle(stringArray);
	}
	return Plugin_Handled;
}


public int MapStatsHandler(Menu menu, MenuAction action, int param1, int param2) {
	if (action != MenuAction_Select)
		return 0;

	char szItem[4];
	menu.GetItem(param2, szItem, sizeof(szItem));
	int id = StringToInt(szItem);


	PrintToChat(param1, "item: %d id: %d", szItem, id);
	// Map records
	if (id == 0)
		db_selectMapTopSurfers(param1, g_szMapName);
	else if (id > 0)
		db_viewStageRecords(param1, id);
	else if (id < 0)
		db_viewStageRecords(param1, id * -1);

	return 0;
}