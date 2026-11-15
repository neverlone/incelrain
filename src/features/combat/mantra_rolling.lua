
local feature = Feature:new("action_rolling");
local _real_kb = nil;
local function get_kb()
    if _real_kb then return _real_kb end;
    local kb_obj = game:GetService("ReplicatedStorage"):FindFirstChild("KeyBinds");
    if kb_obj and typeof(base_require) == "function" then
        local ok, res = pcall(base_require, kb_obj);
        if ok and typeof(res) == "table" and res.IsActionHeld then
            _real_kb = res;
            return _real_kb;
        end;
    end;
    return nil;
end;
local Keybinds = {
    IsActionHeld = function(...) local kb = get_kb(); return (kb and kb.IsActionHeld) and kb.IsActionHeld(...) or false end,
    ForceActionDown = function(...) local kb = get_kb(); if kb and kb.ForceActionDown then kb.ForceActionDown(...) end end,
    ForceActionUp = function(...) local kb = get_kb(); if kb and kb.ForceActionUp then kb.ForceActionUp(...) end end,
};

function feature:enable()
	self.on_mantra_req = local_player.tracker.on_mantra_request.Event:Connect(function(mantra)
		local backpack = local_player.instance:FindFirstChild("Backpack");
		if not backpack then return nil end;

		local ether = local_player.character:FindFirstChild("Ether");
		if not ether or ether.Value <= mantra:GetAttribute("SpellCost") then
			return nil		
end

		if math.random() > aztup.flags.action_rolling_chance / 100 then
			return nil		
end

		if mantra and aztup_options.action_rolling_mantras.Value[mantra:GetAttribute("DefaultName")] then
			Keybinds.ForceActionDown("Dodge")
			Keybinds.ForceActionUp("Dodge")
			
			task.delay(0.15, function()
				local client_feint = EffectReplicator:CreateEffect("ClientFeint");
		
				if client_feint then
					client_feint:Debris(0.1);
				end;
			end)
		end

		return nil	
end)
end;

function feature:disable()
	if self.on_mantra_req then
		self.on_mantra_req:Disconnect();
	end;
end;

return feature