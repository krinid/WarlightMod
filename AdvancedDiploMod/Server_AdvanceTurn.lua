require('Money');
function Server_AdvanceTurn_Start (game,addNewOrder)
	playerGameData = Mod.PlayerGameData;
	RemainingDeclerations = {};
end
function Server_AdvanceTurn_Order(game, order, result, skipThisOrder, addNewOrder)
	if(order.proxyType == "GameOrderAttackTransfer")then
		if(result.IsAttack)then
			local toowner = game.ServerGame.LatestTurnStanding.Territories[order.To].OwnerPlayerID;
			if(order.PlayerID ~= WL.PlayerID.Neutral and game.ServerGame.Game.Players[order.PlayerID].IsAI == false)then
				AddMoney(order.PlayerID,result.AttackingArmiesKilled.NumArmies*Mod.Settings.MoneyPerKilledArmy,playerGameData);
			end
			if(toowner ~= WL.PlayerID.Neutral and game.ServerGame.Game.Players[toowner].IsAI == false)then
				AddMoney(toowner,result.DefendingArmiesKilled.NumArmies*Mod.Settings.MoneyPerKilledArmy,playerGameData);
			end
			if(result.IsSuccessful)then
				if(game.ServerGame.Game.Players[order.PlayerID].IsAI == false)then
					AddMoney(order.PlayerID,Mod.Settings.MoneyPerCapturedTerritory,playerGameData);
					for _,boni in pairs(game.Map.Territories[order.To].PartOfBonuses)do
						local match = true;
						for _,terrid in pairs(game.Map.Bonuses[boni].Territories)do
							if(terrid ~= order.To)then
								if(game.ServerGame.LatestTurnStanding.Territories[terrid].OwnerPlayerID ~= order.PlayerID)then
									match = false;--> this bonus isn't captured
								end
							end
						end
						if(match == true)then
							AddMoney(order.PlayerID,Mod.Settings.MoneyPerCapturedBonus,playerGameData);
						end
					end
				end
			end
			if(toowner ~= WL.PlayerID.Neutral)then
				if(InWar(order.PlayerID,game.ServerGame.LatestTurnStanding.Territories[order.To].OwnerPlayerID) == false)then
					skipThisOrder(WL.ModOrderControl.Skip);
					if(game.ServerGame.Game.Players[order.PlayerID].IsAIOrHumanTurnedIntoAI == true)then
						DeclareWar(order.PlayerID,toowner,game);
					end
				end
			end
		end
	end
	if(order.proxyType == "GameOrderCustom")then
		--error("order custom");
		if(check(order.Message,"Declared war on"))then
			if(InWar(order.PlayerID,order.Payload) == false)then
				DeclareWar(order.PlayerID,tonumber(order.Payload),game);
			end
		end
		if(check(order.Message,"Buy Armies"))then
			local to = tonumber(stringtotable(order.Payload)[1]);
			if(game.ServerGame.LatestTurnStanding.Territories[to].OwnerPlayerID == order.PlayerID)then
				local money = GetMoney(order.PlayerID,playerGameData);
				local wants = tonumber(stringtotable(order.Payload)[2]);
				if(Mod.Settings.MoneyPerBoughtArmy*wants > money)then
					wants = math.floor(money/Mod.Settings.MoneyPerBoughtArmy);
				end
				if(wants > 0)then
					local effect = WL.TerritoryModification.Create(to);
					effect.SetArmiesTo = game.ServerGame.LatestTurnStanding.Territories[to].NumArmies.NumArmies + wants;
					addNewOrder(WL.GameOrderEvent.Create(order.PlayerID, "Bought " .. wants .. " Armies", {}, {effect}));
					RemoveMoney(order.PlayerID,Mod.Settings.MoneyPerBoughtArmy*wants,playerGameData);
					local message = {};
					message.Type = 7;
					message.Count = wants;
					message.Preis = money;
					message.terrid = to;
					addmessage(message,order.PlayerID);
				end
			end
		end
		if(check(order.Message,"Buy Territory"))then
			local payloadsplit = stringtotable(order.Payload);
			local von = tonumber(payloadsplit[1]);
			local terrid = tonumber(payloadsplit[2]);
			local playerGameData = Mod.PlayerGameData;
			if(game.ServerGame.LatestTurnStanding.Territories[terrid].OwnerPlayerID == von)then
				local terrselloffer = GetOffer(playerGameData[order.PlayerID].TerritorySellOffers,von,terrid);
				if(Terrselloffer == nil)then
					--Terrselloffer doesn't exist anylonger
					local message = {};
					message.Type = 12;
					message.Von = von;
					message.terrid = terrid;
					message.Turn = game.Game.NumberOfTurns;
					addmessage(message,order.PlayerID);
					error("order existiert nicht");
				else
					local Preis = Terrselloffer.Preis;
					if(exists == true)then
						if(Preis < 0 and GetMoney(playerid,playerGameData) < Preis*-1)then
							error("seller nicht genug geld");
							--Seller hasn't the money to pay the person who tries buys the territory
							local message = {};
							message.Type = 4;
							message.Von = von;
							message.Preis = Preis;
							message.terrid = terrid;
							message.Turn = game.Game.NumberOfTurns;
							addmessage(message,order.PlayerID);
							message = {};
							message.Type = 13;
							message.Buyer = order.PlayerID;
							message.Preis = Preis;
							message.YourMoney = GetMoney(playerid,playerGameData)
							message.terrid = terrid;
							message.Turn = game.Game.NumberOfTurns;
							addmessage(message,playerid);
						else
							if(Preis > 0 and GetMoney(order.PlayerID,playerGameData) < Preis)then
								--you haven't enough money
								error("kaufer nicht genug geld");
								local message = {};
								message.Type = 5;
								message.Von = von;
								message.Preis = Preis;
								message.YourMoney = GetMoney(order.PlayerID,playerGameData);
								message.terrid = terrid;
								message.Turn = game.Game.NumberOfTurns;
								addmessage(message,order.PlayerID);
								message = {};
								message.Type = 14;
								message.Buyer = order.PlayerID;
								message.Preis = Preis;
								message.terrid = terrid;
								message.Turn = game.Game.NumberOfTurns;
								addmessage(message,playerid);
							else
								--all players have the requirements for the offer
								--> buying the territory now
								Pay(order.PlayerID,playerid,Preis,playerGameData);
								local effect = WL.TerritoryModification.Create(terrid);
								effect.SetOwnerOpt = order.PlayerID;
								addNewOrder(WL.GameOrderEvent.Create(order.PlayerID, "Bought " .. game.Map.Territories[terrid].Name, {}, {effect}));
								local message = {};
								message.Type = 6;
								message.Von = von;
								message.buyer = order.PlayerID;
								message.Preis = Preis;
								message.terrid = terrid;
								message.Turn = game.Game.NumberOfTurns;
								addmessage(message,order.PlayerID);
								addmessage(message,von);
								--this is the message all other players can see(price is removed)
								for _,pid in pairs(game.ServerGame.Game.Players)do
									if(pid.IsAI == false)then
										if(playerGameData[pid.ID].TerritorySellOffers[von] ~= nil)then
											playerGameData[pid.ID].TerritorySellOffers[von][terrid] = nil;
										end
										if(tablelength(playerGameData[pid.ID].TerritorySellOffers[von]) == 0)then
											playerGameData[pid.ID].TerritorySellOffers[von] = nil;
										end
										if(pid.ID ~= order.PlayerID and pid.ID ~= von)then
											message = {};
											message.Type = 6;
											message.Von = von;
											message.buyer = order.PlayerID;
											message.terrid = terrid;
											message.Turn = game.Game.NumberOfTurns;
											addmessage(message,pid.ID);
										end
									end
								end
							end
						end
					end
				end
			else
				--This is the error code, that the person you are trying to buy the territory from, doesn't own the territory at the moment, you are trying to buy it
				local message = {};
				message.Type = 2;
				message.Von = von;
				message.terrid = terrid;
				message.Turn = game.Game.NumberOfTurns;
				addmessage(message,order.PlayerID);
				--This is the error code, that order.PlayerID was unable to buy terrid, since von didn't own it
				message = {};
				message.Type = 3;
				message.Player = order.PlayerID;
				message.terrid = terrid;
				message.Turn = game.Game.NumberOfTurns;
				addmessage(message,von);
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
	--add new war Declaretions
	local publicGameData = Mod.PublicGameData;
	for _,newwar in pairs(RemainingDeclerations)do
		publicGameData.War[newwar.S1][tablelength(publicGameData.War[newwar.S1])+1] = newwar.S2;
		publicGameData.War[newwar.S2][tablelength(publicGameData.War[newwar.S2])+1] = newwar.S1;
		local message = {};
		message.Type = 1;
		message.S1 = newwar.S1;
		message.S2 = newwar.S2;
		message.Turn = game.Game.NumberOfTurns;
		for _,pid in pairs(game.ServerGame.Game.Players)do
			if(pid.IsAI == false)then
				addmessage(message,pid.ID);
			end
		end
		--Removing all territory sell offers
		if(game.ServerGame.Game.Players[newwar.S1].IsAI == false)then
			playerGameData[newwar.S1].TerritorySellOffers[newwar.S2] = nil;
		end
		if(game.ServerGame.Game.Players[newwar.S2].IsAI == false)then
			playerGameData[newwar.S2].TerritorySellOffers[newwar.S1] = nil;
		end
	end
	RemainingDeclerations = {};
	--reducing the number of turns a player cant declare war on an other
	for _,pid in pairs(game.ServerGame.Game.Players)do
		for _,pid2 in pairs(game.ServerGame.Game.Players)do
			if(pid.ID ~= pid2.ID)then
				if(publicGameData.CantDeclare[pid.ID][pid2.ID] > 0)then
					publicGameData.CantDeclare[pid.ID][pid2.ID] = publicGameData.CantDeclare[pid.ID][pid2.ID] - 1;
				end
			end
		end
	end
	Mod.PublicGameData = publicGameData;
	--Giving Money per turn
	for _,pid in pairs(game.ServerGame.Game.PlayingPlayers)do
		if(pid.IsAI == false)then
			AddMoney(pid.ID,Mod.Settings.MoneyPerTurn,playerGameData);--Giving Money per turn
		end
	end
	Mod.PlayerGameData = playerGameData;
end
function toname(playerid,game)
	return game.ServerGame.Game.Players[playerid].DisplayName(nil, false);
end
function RemoveAlly(Player1,Player2)
	--removes an ally
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
					DeclareWar(Player1,Player2,game);
				end
				if(Mod.Settings.AIsDeclareAIs == true and game.ServerGame.Game.Players[Player1].IsAIOrHumanTurnedIntoAI == true)then
					DeclareWar(Player1,Player2,game);
				end
			else
				DeclareWar(Player1,Player2,game);
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
						DeclareWar(Player1,Player2,game);
					end
					if(Mod.Settings.AIsDeclareAIs == true and game.ServerGame.Game.Players[Player1].IsAIOrHumanTurnedIntoAI == true)then
						DeclareWar(Player1,Player2,game);
					end
				else
					DeclareWar(Player1,Player2,game);
				end
				return false;
			end
		end
		return false;
	end
end
function DeclareWar(Player1,Player2,game)
	--Allys Declare war on order.PlayerID if not allied with order.PlayerID
	if(IsAlly(Player1,Player2)==false and InWar(Player1,Player2) == false)then
		if(game.ServerGame.Game.Players[Player1].IsAIOrHumanTurnedIntoAI == true)then
			if(game.ServerGame.Game.Players[Player2].IsAIOrHumanTurnedIntoAI == true and Mod.Settings.AllowAIDeclaration == false)then
				return;
			end
			if(game.ServerGame.Game.Players[Player2].IsAIOrHumanTurnedIntoAI == false and Mod.Settings.AIsDeclareAIs == false)then
				return;
			end
		end
		for _,newwar in pairs(RemainingDeclerations)do
			local P1 = newwar.S1;
			local P2 = newwar.S2;
			if(P1 == Player1 or P1 == Player2)then
				if(P2 == Player1 or P2 == Player2)then
					--declaration is already pending
					return;
				end
			end
		end
		if(Mod.PublicGameData.CantDeclare[Player1][Player2] > 0)then
			--the player have enforced peace
			return;
		end
		RemainingDeclerations[tablelength(RemainingDeclerations)+1] = {};
		RemainingDeclerations[tablelength(RemainingDeclerations)].S1 = Player1;
		RemainingDeclerations[tablelength(RemainingDeclerations)].S2 = Player2;
	else
		RemoveAlly(Player1,Player2);
	end
end
function InWar(Player1,Player2)	
	if(Mod.PublicGameData.War[Player1] ~= nil)then
		for _,pID in pairs(Mod.PublicGameData.War[Player1])do
			if(pID == Player2)then
				--both players are in war
				return true;
			end
		end
	end
	return false;
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
			return false;
		end
		num = num + 1;
	end
	return match;
end
function addmessage(message,spieler)
	playerGameData[spieler].Nachrichten[tablelength(playerGameData[spieler].Nachrichten)+1] = message;
	playerGameData[spieler].NeueNachrichten[tablelength(playerGameData[spieler].NeueNachrichten)+1] = message;
end
function GetOffer(offerType,spieler2,terr)
	if(offerType ~= nil)then
		error("Test1");
		if(offerType[spieler2] ~= nil)then
			error("Test2");
			if(terr ~= nil)then
				error("Test3");
				if(offerType[spieler2][terr] ~= nil)then
					error("Test4");
					return offerType[spieler2][terr];
				end
			else
				error("Test5");
				return offerType[spieler2];
			end
		end
	end
	return nil;
end