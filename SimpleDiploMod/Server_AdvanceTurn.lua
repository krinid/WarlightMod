function Server_AdvanceTurn_Start (game,addNewOrder)
	AllAIs = {};
	AllPlayerIDs = {};
	local orders= "";
	for _,pid in pairs(game.ServerGame.Game.PlayingPlayers)do
		local Match = false;
		if(pid.IsAIOrHumanTurnedIntoAI)then
			for _,knownAIs in pairs(AllAIs)do
				if(pid.ID == knownAIs)then
					Match = true;
				end
			end
			if(Match == false)then
				AllAIs[tablelength(AllAIs)] = pid.ID;
			end
		else
			for _,knownPlayers in pairs(AllPlayerIDs)do
				if(pid.ID == knownPlayers)then
					Match = true;
				end
			end
			if(Match == false)then
				AllPlayerIDs[tablelength(AllPlayerIDs)] = pid.ID;
			end
		end
		for _,order in pairs(game.ServerGame.ActiveTurnOrders[pid.ID]) do
				orders = orders .. " " .. order.proxyType;
		end
	end
	--error(orders);
	Attacksbetween = {};
end
function Server_AdvanceTurn_Order(game, order, result, skipThisOrder, addNewOrder)
	if(order.proxyType == "GameOrderAttackTransfer")then
		if(result.IsAttack and game.ServerGame.LatestTurnStanding.Territories[order.To].OwnerPlayerID ~= WL.PlayerID.Neutral)then
			--error("attack2");
			if(InWar(order.PlayerID,game.ServerGame.LatestTurnStanding.Territories[order.To].OwnerPlayerID) == true)then
				local playerGameData = Mod.PlayerGameData;
				if(result.IsSuccessful)then
					if(game.ServerGame.Game.Players[order.PlayerID].IsAI == false)then
						playerGameData[order.PlayerID].Money = Mod.PlayerGameData[order.PlayerID].Money+ Mod.Settings.MoneyPerCapturedTerritory;
						--for _,boni in pairs(game.Map.Territories[order.To].PartOfBonuses)do
						--	local match = false;
						--	for _,terrid in pairs(game.Map.Bonuses[boni].Territories)do
						--		if(game.ServerGame.LatestTurnStanding.Territories[terrid].OwnerPlayerID ~= order.PlayerID and terrid ~= order.To)then
						--			match = true;
						--		end
						--	end
						--	if(match == true)then
						--		playerGameData[order.PlayerID].Money = Mod.PlayerGameData[order.PlayerID].Money + Mod.Settings.MoneyPerCapturedBonus;
						--	end
						--end
					end
				end
				if(game.ServerGame.Game.Players[order.PlayerID].IsAI == false)then
					playerGameData[order.PlayerID].Money = Mod.PlayerGameData[order.PlayerID].Money+ result.AttackingArmiesKilled.NumArmies*Mod.Settings.MoneyPerKilledArmy;
				end
				local toowner = game.ServerGame.LatestTurnStanding.Territories[order.To].OwnerPlayerID;
				if(toowner ~= WL.PlayerID.Neutral and game.ServerGame.Game.Players[toowner].IsAI == false)then
					playerGameData[toowner].Money = playerGameData[toowner].Money + result.DefendingArmiesKilled.NumArmies*Mod.Settings.MoneyPerKilledArmy;
				end
				Mod.PlayerGameData = playerGameData;
			else
				local toowner = game.ServerGame.LatestTurnStanding.Territories[order.To].OwnerPlayerID;
				skipThisOrder(WL.ModOrderControl.Skip);
				if(game.ServerGame.Game.Players[order.PlayerID].IsAIOrHumanTurnedIntoAI == true)then
					DeclearWar(order.PlayerID,toowner,game);
				end
			end
		end
	end
	if(order.proxyType == "GameOrderCustom")then
		--error("order custom");
		if(check(order.Message,"Declared war on"))then
			if(InWar(order.PlayerID,order.Payload) == false)then
				DeclearWar(order.PlayerID,tonumber(order.Payload),game);
			end
		end
		if(check(order.Message,"Buy Armies"))then
			local to = tonumber(stringtotable(order.Payload)[1]);
			if(game.ServerGame.LatestTurnStanding.Territories[to].OwnerPlayerID == order.PlayerID)then
				local money = tonumber(Mod.PlayerGameData[order.PlayerID].Money);
				local wants = tonumber(stringtotable(order.Payload)[2]);
				if(Mod.Settings.MoneyPerBoughtArmy*wants > money)then
					wants = math.floor(money/Mod.Settings.MoneyPerBoughtArmy);
				end
				if(wants > 0)then
					local effect = WL.TerritoryModification.Create(to);
					effect.SetArmiesTo = game.ServerGame.LatestTurnStanding.Territories[to].NumArmies.NumArmies + wants;
					addNewOrder(WL.GameOrderEvent.Create(order.PlayerID, "Bought " .. wants .. " Armies", {}, {effect}));
					playerdata = Mod.PlayerGameData;
					--Here must come a army bought message(just for the one player)
					playerdata[order.PlayerID].Money = playerdata[order.PlayerID].Money - Mod.Settings.MoneyPerBoughtArmy*wants;
					Mod.PlayerGameData = playerdata;
				end
			end
		end
		if(check(order.Message,"Buy Territory"))then
			local payloadsplit = stringtotable(order.Payload);
			local playerid = tonumber(payloadsplit[1]);
			local terrid = tonumber(payloadsplit[2]);
			local playerdata = Mod.PlayerGameData;
			if(game.ServerGame.LatestTurnStanding.Territories[terrid].OwnerPlayerID == playerid)then
				local terrsellofferssplit = stringtotable(playerdata[order.PlayerID].Terrselloffers);
				local num = 1;
				local Preis = 0;
				local exists = false;
				while(terrsellofferssplit[num+3] ~=nil)do
					if(terrsellofferssplit[num] == tostring(playerid) and terrsellofferssplit[num+1] == tostring(terrid))then
						Preis = tonumber(terrsellofferssplit[num+2]);
					end
					num = num +3;
					exists = true;
				end
				if(exists == true)then
					if(Preis < 0 and tonumber(playerdata[playerid].Money) < Preis*-1)then
						--Seller hasn't the money to pay the person who tries buys the territory
						addmessage(playerid .. ",7,".. tostring(game.Game.NumberOfTurns) .. "," .. terrid .. ",",order.PlayerID);
					else
						if(Preis > 0 and playerdata[order.PlayerID].Money < Preis)then
							addmessage(",8,".. tostring(game.Game.NumberOfTurns) .. "," .. terrid .. ",",order.PlayerID);
						else
							--all players have the requirements for the offer
							--> buying the territory now
							playerdata[order.PlayerID].Money = playerdata[order.PlayerID].Money - Preis;
							playerdata[playerid].Money = playerdata[playerid].Money + Preis;
							local effect = WL.TerritoryModification.Create(terrid);
							effect.SetOwnerOpt = order.PlayerID;
							addNewOrder(WL.GameOrderEvent.Create(order.PlayerID, "Bought " .. game.Map.Territories[terrid].Name, {}, {effect}));
							Mod.PlayerGameData = playerdata;
							for _,pid in pairs(game.ServerGame.Game.Players)do
								if(pid.IsAI == false)then
									playerdata = Mod.PlayerGameData;
									if(playerdata[pid.ID] ~= nil)then
										if(playerdata[pid.ID].Terrselloffers ~= nil)then
											num = 1;
											terrsellofferssplit = stringtotable(playerdata[pid.ID].Terrselloffers);
											playerdata[pid.ID].Terrselloffers = ","
											while(terrsellofferssplit[num+3] ~=nil)do
												if(terrsellofferssplit[num] ~= tostring(playerid) or terrsellofferssplit[num+1] ~= tostring(terrid))then
													playerdata[pid.ID].Terrselloffers = playerdata[pid.ID].Terrselloffers .. terrsellofferssplit[num] .. "," .. terrsellofferssplit[num+1] .. "," .. terrsellofferssplit[num+2] .. ",";
												end
												num = num + 3;
											end
										end
										Mod.PlayerGameData = playerdata;
										addmessage(order.PlayerID .. ",9,".. tostring(game.Game.NumberOfTurns) .. "," .. terrid .. ",",pid.ID);
									end
								end
							end
						end
					end
				end
			else
				addmessage(playerid .. ",6," .. tostring(game.Game.NumberOfTurns) .. "," .. terrid .. ",",order.PlayerID);
			end
		end
		skipThisOrder(WL.ModOrderControl.SkipAndSupressSkippedMessage);
	end
	if(order.proxyType == "GameOrderPlayCardSanctions")then
		--error("sanction");
		if(IsPlayable(order.PlayerID,order.SanctionedPlayerID,game,Mod.Settings.SanctionCardRequireWar,Mod.Settings.SanctionCardRequirePeace,Mod.Settings.SanctionCardRequireAlly) == false)then
			skipThisOrder(WL.ModOrderControl.Skip);
		end
	end
	if(order.proxyType == "GameOrderPlayCardBomb")then
		--error("bomb");
		if(IsPlayable(order.PlayerID,game.ServerGame.LatestTurnStanding.Territories[order.TargetTerritoryID].OwnerPlayerID,game,Mod.Settings.BombCardRequireWar,Mod.Settings.BombCardRequirePeace,Mod.Settings.BombCardRequireAlly) == false)then
			skipThisOrder(WL.ModOrderControl.Skip);
		end
	end
	if(order.proxyType == "GameOrderPlayCardSpy")then
		--error("spy");
		if(IsPlayable(order.PlayerID,order.TargetPlayerID,game,Mod.Settings.SpyCardRequireWar,Mod.Settings.SpyCardRequirePeace,Mod.Settings.SpyCardRequireAlly) == false)then
			skipThisOrder(WL.ModOrderControl.Skip);
		end
	end
	if(order.proxyType == "GameOrderPlayCardGift")then
		--error("gift");
		if(IsPlayable(order.PlayerID,order.GiftTo,game,Mod.Settings.GiftCardRequireWar,Mod.Settings.GiftCardRequirePeace,Mod.Settings.GiftCardRequireAlly) == false)then
			skipThisOrder(WL.ModOrderControl.Skip);
		end
	end
end
function Server_AdvanceTurn_End (game,addNewOrder)
	--add new war decleartions
	local playerGameData = Mod.PlayerGameData;
	if(RemainingDeclerations ~= nil)then
		for _,newwar in pairs(RemainingDeclerations)do
			local P1 = tonumber(stringtotable(newwar)[1]);
			local P2 = tonumber(stringtotable(newwar)[2]);
			local publicGameData = Mod.PublicGameData;
			if(Mod.PublicGameData.War[P1] ~= nil)then
				local with = Mod.PublicGameData.War[P1] .. tostring(P2) .. ",";
				publicGameData.War[P1] = with;
			else
				publicGameData.War[P1] = "," .. tostring(P2) .. ",";
			end
			addNewOrder(WL.GameOrderEvent.Create(P1, "Declared war on " .. toname(P2,game), nil,{}));
			local num = 1;
			if(game.ServerGame.Game.Players[P1].IsAI == false)then
				if(playerGameData[P1].Terrselloffers~=nil)then
					local terrsellofferssplit = stringtotable(playerGameData[P1].Terrselloffers);
					playerGameData[P1].Terrselloffers = ","
					while(terrsellofferssplit[num+3] ~=nil)do
						if(terrsellofferssplit[num] ~= tostring(P2))then
							playerGameData[P1].Terrselloffers = playerGameData[P1].Terrselloffers .. terrsellofferssplit[num] .. "," .. terrsellofferssplit[num+1] .. "," .. terrsellofferssplit[num+2] .. ",";
						end
						num = num + 3;
					end
				end
			end
			local P3 = P2;
			P2 = P1;
			P1 = P3;
			if(Mod.PublicGameData.War[P1] ~= nil)then
				local with = Mod.PublicGameData.War[P1] .. tostring(P2) .. ",";
				publicGameData.War[P1] = with;
			else
				publicGameData.War[P1] = "," .. tostring(P2) .. ",";
			end
			if(game.ServerGame.Game.Players[P1].IsAI == false)then
				num = 1;
				if(playerGameData[P1] ~= nil)then
					if(playerGameData[P1].Terrselloffers~=nil)then
						terrsellofferssplit = stringtotable(playerGameData[P1].Terrselloffers);
						playerGameData[P1].Terrselloffers = ","
						while(terrsellofferssplit[num+3] ~=nil)do
							if(terrsellofferssplit[num] ~= tostring(P2))then
								playerGameData[P1].Terrselloffers = playerGameData[P1].Terrselloffers .. terrsellofferssplit[num] .. "," .. terrsellofferssplit[num+1] .. "," .. terrsellofferssplit[num+2] .. ",";
							end
							num = num + 3;
						end
					end
				end
			end
			Mod.PublicGameData = publicGameData;
			for _, spieler in pairs(AllPlayerIDs)do
				if(playerGameData[spieler].NeueNachrichten==nil)then
					playerGameData[spieler].NeueNachrichten = ",";
				end
				if(playerGameData[spieler].Nachrichten==nil)then
					playerGameData[spieler].Nachrichten = ",";
				end
				playerGameData[spieler].NeueNachrichten = playerGameData[spieler].NeueNachrichten ..  P2 .. ",0," .. (game.Game.NumberOfTurns+1) ..",".. P1 .. ",";
				playerGameData[spieler].Nachrichten = playerGameData[spieler].Nachrichten ..  P2 .. ",0,".. (game.Game.NumberOfTurns+1).."," .. P1 .. ",";
			end
		end
	end
	RemainingDeclerations = {};
	local privateGameData = Mod.PrivateGameData;
	if(privateGameData.Cantdeclare~= nil)then
		privateGameData.Cantdeclare[game.Game.NumberOfTurns] = ",";
	end
	Mod.PrivateGameData = privateGameData;
	--Giving Money per turn
	for _,spieler in pairs(AllPlayerIDs)do
		if(playerGameData[spieler] ~= nil)then
			playerGameData[spieler].Money = playerGameData[spieler].Money + Mod.Settings.MoneyPerTurn;--Giving Money per turn
		end
	end
	Mod.PlayerGameData = playerGameData;
	--if(Mod.Settings.SeeAllyTerritories)then
		--play on every ally territory a reconnaisance card
		--for _, player in pairs(AllPlayerIDs)do
			--for _, terr in pairs(game.ServerGame.LatestTurnStanding.Territories)do
				--if(IsAlly(player,terr.OwnerPlayerID))then
					--addNewOrder(WL.GameOrderPlayCardReconnaissance.Create(WL.NoParameterCardInstance.Create(100, WL.CardID.Reconnaissance), player, terr));
				--end
			--end
		--end
	--end
end
function getplayerid(playername,game)
	for _,playerinfo in pairs(game.ServerGame.Game.Players)do
		local name = playerinfo.DisplayName(nil, false);
		if(name == playername)then
			return playerinfo.ID;
		end
	end
	return 0;
end
function toname(playerid,game)
	return game.ServerGame.Game.Players[playerid].DisplayName(nil, false);
end
function RemoveAlly(Player1,Player2)
	
end
function IsPlayable(Player1,Player2,game,requirewarsetting,requirepeacesetting,requireallysetting)
	if(Player2 == WL.PlayerID.Neutral)then
		return true;
	end
	if(requirepeacesetting == nil and requireallysetting == nil)then
		if(InWar(Player1,Player2)==false and requirewarsetting ~= nil and requirewarsetting == true)then
			--Declare war
			if(game.ServerGame.Game.Players[Player1].IsAIOrHumanTurnedIntoAI == true)then
				if(Mod.Settings.AllowAIDeclaration == true and game.ServerGame.Game.Players[Player1].IsAIOrHumanTurnedIntoAI == false)then
					DeclearWar(Player1,Player2,game);
				end
				if(Mod.Settings.AIsdeclearAIs == true and game.ServerGame.Game.Players[Player1].IsAIOrHumanTurnedIntoAI == true)then
					DeclearWar(Player1,Player2,game);
				end
			else
				DeclearWar(Player1,Player2,game);
			end
			return false;
		else
			return true;
		end
	else
		if(requirepeacesetting == true and InWar(Player1,Player2) == false and IsAlly(Player1,Player2) == false)then
			return true;
		end
		if(requireallysetting == true and IsAlly(Player1,Player2) == true)then
			return true;
		end
		if(requirewarsetting == true)then
			if(InWar(Player1,Player2) == true)then
				return true;
			else
				--Declare war
				if(game.ServerGame.Game.Players[Player1].IsAIOrHumanTurnedIntoAI == true)then
					if(Mod.Settings.AllowAIDeclaration == true and game.ServerGame.Game.Players[Player1].IsAIOrHumanTurnedIntoAI == false)then
						DeclearWar(Player1,Player2,game);
					end
					if(Mod.Settings.AIsdeclearAIs == true and game.ServerGame.Game.Players[Player1].IsAIOrHumanTurnedIntoAI == true)then
						DeclearWar(Player1,Player2,game);
					end
				else
					DeclearWar(Player1,Player2,game);
				end
				return false;
			end
		end
		return false;
	end
end
function DeclearWar(Player1,Player2,game)
	--Allys declear war on order.PlayerID if not allied with order.PlayerID
	if(IsAlly(Player1,Player2)==false and InWar(Player1,Player2) == false)then
		if(game.ServerGame.Game.Players[Player1].IsAIOrHumanTurnedIntoAI == true)then
			if(game.ServerGame.Game.Players[Player2].IsAIOrHumanTurnedIntoAI == false and Mod.Settings.AllowAIDeclaration == false)then
				return;
			end
			if(game.ServerGame.Game.Players[Player2].IsAIOrHumanTurnedIntoAI == true and Mod.Settings.AIsdeclearAIs == false)then
				return;
			end
		end
		if(RemainingDeclerations == nil)then
			RemainingDeclerations = {};
		end
		local Match = false;
		for _,newwar in pairs(RemainingDeclerations)do
			local P1 = tonumber(stringtotable(newwar)[1]);
			local P2 = tonumber(stringtotable(newwar)[2]);
			if(P1 == Player1 or P1 == Player2)then
				if(P2 == Player1 or P2 == Player2)then
					Match = true;
				end
			end
		end
		if(Match == false)then
			if(Mod.PrivateGameData.Cantdeclare ~= nil and Mod.PrivateGameData.Cantdeclare[game.Game.NumberOfTurns] ~= nil)then
				local privateGameDatasplit = stringtotable(Mod.PrivateGameData.Cantdeclare[game.Game.NumberOfTurns]);
				local num = 1;
				while(privateGameDatasplit[num] ~= nil and privateGameDatasplit[num+1] ~= nil and privateGameDatasplit[num+1] ~= "")do
					if(tonumber(privateGameDatasplit[num]) == Player1 or tonumber(privateGameDatasplit[num+1]) == Player1)then
						if(tonumber(privateGameDatasplit[num]) == Player2 or tonumber(privateGameDatasplit[num+1]) == Player2)then
							Match = true;
						end
					end
					num = num + 2;
				end
			end
			if(Match == false)then
				RemainingDeclerations[tablelength(RemainingDeclerations)] = "," .. Player1 .. "," ..Player2;
			end
		end
	else
		RemoveAlly(Player1,Player2);
	end
end
function InWar(Player1,Player2)	
	if(Mod.PublicGameData.War == nil)then
		print('neu gesetzt');
		local publicGameData = Mod.PublicGameData;
 		publicGameData.War={};
		Mod.PublicGameData=publicGameData;
	end
	print('I2');
	if(Mod.PublicGameData.War[Player1] ~= nil)then
		local with = stringtotable(Mod.PublicGameData.War[Player1]);
		for _,pID in pairs(with)do
			print(pID .. " " .. Player2);
			if(tostring(pID) == tostring(Player2))then
				print("sind im krieg");
				return true;
			end
		end
	end
	print('I3');
	return false;
end
function DeclearAlly(Player1,Player2)
	
end
function IsAlly(Player1,Player2)
	return false;
end
function tablelength(T)
	local count = 0;
	for _,elem in pairs(T)do
		count = count + 1;
	end
	return count;
end
function stringtochararray(variable)
	chartable = {};
	while(string.len(variable)>0)do
		chartable[tablelength(chartable)] = string.sub(variable, 1 , 1);
		variable = string.sub(variable, 2);
	end
	return chartable;
end
function stringtotable(variable)
	chartable = {};
	while(string.len(variable)>0)do
		chartable[tablelength(chartable)] = string.sub(variable, 1 , 1);
		variable = string.sub(variable, 2);
	end
	local newtable = {};
	local tablepos = 0;
	local executed = false;
	for _, elem in pairs(chartable)do
		if(elem == ",")then
			tablepos = tablepos + 1;
			newtable[tablepos] = "";
			executed = true;
		else
			if(executed == false)then
				tablepos = tablepos + 1;
				newtable[tablepos] = "";
				executed = true;
			end
			if(newtable[tablepos] == nil)then
				newtable[tablepos] = elem;
			else
				newtable[tablepos] = newtable[tablepos] .. elem;
			end
		end
	end
	return newtable;
end
function check(message,variable)
	local match = true;
	local mess = stringtochararray(message);
	local varchararray = stringtochararray(variable);
	local num = 0;
	while(varchararray[num] ~= nil)do
		if(mess[num] ~= varchararray[num])then
			print(mess[num] .. ' ' .. varchararray[num]);
			return false;
		end
		num = num + 1;
	end
	return match;
end
function addmessage(message,spieler)
	local playerdata = Mod.PlayerGameData;
	if(playerdata[spieler].Nachrichten== nil)then
		playerdata[spieler].Nachrichten = ",";
	end
	if(playerdata[spieler].NeueNachrichten== nil)then
		playerdata[spieler].NeueNachrichten = ",";
	end
	playerdata[spieler].Nachrichten = playerdata[spieler].Nachrichten .. message;
	playerdata[spieler].NeueNachrichten = playerdata[spieler].NeueNachrichten .. message;
	Mod.PlayerGameData = playerdata;
end
