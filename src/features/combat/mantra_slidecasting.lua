
local feature = Feature:new("mantra_slidecasting");
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

		if math.random() > aztup.flags.mantra_slidecasting_chance / 100 then
			return nil		
end

		if EffectReplicator:HasAny(
			"AirCombo",
			"NoSlide",
			"Action",
			"MobileAction",
			"UsingAbility",
			"LightAttack",
			"Blocking",
			"Parried",
			"ClientSlide2",
			"ClientSwim"
		) then
			return		
end;
		
        local v298 = Ray.new(local_player.root_part.Position, (Vector3.new(0, -10, 0)));
        local l_workspace_PartOnRayWithIgnoreList_1, _, _ = workspace:FindPartOnRayWithIgnoreList(v298, {
            workspace:WaitForChild("Live",5), 
            workspace:WaitForChild("NPCs",5), 
            workspace:WaitForChild("Thrown",5)
        });

		local l_MoveDirection_0 = local_player.humanoid.MoveDirection;
        if l_MoveDirection_0.Magnitude <= 0.1 then
			return nil        
end

		if not l_workspace_PartOnRayWithIgnoreList_1 then
			return nil		
end;

		if not EffectReplicator:FindEffect("Sprinting") then
			return nil		
end;

		if mantra and aztup_options.mantra_slidecasting_mantras.Value[mantra:GetAttribute("DefaultName")] then
			if not EffectReplicator:FindEffect("CastingSpell") then
				local casting_spell = EffectReplicator:CreateEffect("CastingSpell");
				if casting_spell then
					casting_spell:Debris(0.05); 
				end;
			end;

			Keybinds.ForceActionDown("Crouch")
			Keybinds.ForceActionUp("Crouch")
			
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
