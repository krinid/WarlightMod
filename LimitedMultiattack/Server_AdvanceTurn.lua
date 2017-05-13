function Server_AdvanceTurn_Start (game,addNewOrder)
	boundtoacard=false;
	if(Mod.Settings.ReinforcementCard ~= nil)then
		if(Mod.Settings.ReinforcementCard)then
			boundtoacard=true;
		end
	end
	if(Mod.Settings.GiftCard ~= nil)then
		if(Mod.Settings.GiftCard)then
			boundtoacard=true;
		end
	end
	if(Mod.Settings.AirliftCard ~= nil)then
		if(Mod.Settings.AirliftCard)then
			boundtoacard=true;
		end
	end
	if(Mod.Settings.ReconnaisanceCard ~= nil)then
		if(Mod.Settings.ReconnaisanceCard)then
			boundtoacard=true;
		end
	end
	if(Mod.Settings.SpyCard ~= nil)then
		if(Mod.Settings.SpyCard)then
			boundtoacard=true;
		end
	end
	UbrigeAngriffe={};
	local Maximaleangriffe = Mod.Settings.MaxAttacks;
	if (Maximaleangriffe < 1) then Maximaleangriffe = 1 end;
	if (Maximaleangriffe > 100000) then Maximaleangriffe = 100000 end;
	for _, terr in pairs(game.Map.Territories) do
		if(boundtoacard)then
			UbrigeAngriffe[terr.ID] = 1;
		else
			UbrigeAngriffe[terr.ID] = Maximaleangriffe;
		end
	end
end
function Server_AdvanceTurn_Order(game, order, result, skipThisOrder, addNewOrder)
	--result GameOrderAttackTransferResult
	--order GameOrderAttackTransfer
	if(boundtoacard)then
		if(order.proxyType == 'GameOrderPlayCardAirlift') then
			local Maximaleangriffe = Mod.Settings.MaxAttacks;
			if (Maximaleangriffe < 1) then Maximaleangriffe = 1 end;
			if (Maximaleangriffe > 100000) then Maximaleangriffe = 100000 end;
			for _, terr in pairs(game.ServerGame.LatestTurnStanding.Territories) do
				if(terr.OwnerPlayerID == order.PlayerID)then
					UbrigeAngriffe[terr.ID] = Maximaleangriffe;
				end
			end
		end
		if(order.proxyType == 'GameOrderPlayCardReinforcement') then
			local Maximaleangriffe = Mod.Settings.MaxAttacks;
			if (Maximaleangriffe < 1) then Maximaleangriffe = 1 end;
			if (Maximaleangriffe > 100000) then Maximaleangriffe = 100000 end;
			for _, terr in pairs(game.ServerGame.LatestTurnStanding.Territories) do
				if(terr.OwnerPlayerID == order.PlayerID)then
					UbrigeAngriffe[terr.ID] = Maximaleangriffe;
				end
			end
		end
		if(order.proxyType == 'GameOrderPlayCardSpy') then
			local Maximaleangriffe = Mod.Settings.MaxAttacks;
			if (Maximaleangriffe < 1) then Maximaleangriffe = 1 end;
			if (Maximaleangriffe > 100000) then Maximaleangriffe = 100000 end;
			for _, terr in pairs(game.ServerGame.LatestTurnStanding.Territories) do
				if(terr.OwnerPlayerID == order.PlayerID)then
					UbrigeAngriffe[terr.ID] = Maximaleangriffe;
				end
			end
		end
		if(order.proxyType == 'GameOrderPlayCardReconnaissance') then
			local Maximaleangriffe = Mod.Settings.MaxAttacks;
			if (Maximaleangriffe < 1) then Maximaleangriffe = 1 end;
			if (Maximaleangriffe > 100000) then Maximaleangriffe = 100000 end;
			for _, terr in pairs(game.ServerGame.LatestTurnStanding.Territories) do
				if(terr.OwnerPlayerID == order.PlayerID)then
					UbrigeAngriffe[terr.ID] = Maximaleangriffe;
				end
			end
		end
		if(order.proxyType == 'GameOrderPlayCardSurveillance') then
			local Maximaleangriffe = Mod.Settings.MaxAttacks;
			if (Maximaleangriffe < 1) then Maximaleangriffe = 1 end;
			if (Maximaleangriffe > 100000) then Maximaleangriffe = 100000 end;
			for _, terr in pairs(game.ServerGame.LatestTurnStanding.Territories) do
				if(terr.OwnerPlayerID == order.PlayerID)then
					UbrigeAngriffe[terr.ID] = Maximaleangriffe;
				end
			end
		end
	end
	if(order.proxyType == 'GameOrderAttackTransfer') then
		if(UbrigeAngriffe[order.From] > 0)then
			if(result.IsSuccessful)then
				if(game.ServerGame.LatestTurnStanding.Territories[order.From].OwnerPlayerID ~= game.ServerGame.LatestTurnStanding.Territories[order.To].OwnerPlayerID)then
					UbrigeAngriffe[order.To] = UbrigeAngriffe[order.From];
				else
					UbrigeAngriffe[order.To] = 1;
				end
				if(Mod.Settings.MaxAttacks ~= 0 and UbrigeAngriffe[order.To] ~= 0)then
					UbrigeAngriffe[order.To] = UbrigeAngriffe[order.To] - 1;
				else
				end
			else
				UbrigeAngriffe[order.From] = 0;
			end
		else
			skipThisOrder(WL.ModOrderControl.Skip);
		end
	end
end
