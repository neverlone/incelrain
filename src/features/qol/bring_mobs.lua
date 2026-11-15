

local feature = {};

local clientPart = Instance.new('Part', workspace)
local ok_peer, peer = pcall(gethiddenproperty, clientPart, "NetworkOwnerV3")
if not ok_peer then peer = nil end
clientPart:Destroy()

function feature:owner(part)
    local success, ID = pcall(function()
        return gethiddenproperty(part, "NetworkOwnerV3")
    end)
    if success then
        return ID == peer
    end
    return false
end

function feature:run()
	pcall(sethiddenproperty, local_player.instance, "MaxSimulationRadius", 3000);
	pcall(sethiddenproperty, local_player.instance, "SimulationRadius", 3000);

    local live = workspace:FindFirstChild("Live")
    if not live then return end
    for _, mob in pairs(live:GetChildren()) do
        if mob.Name:sub(1,1) ~= "." then continue end

        local root = mob:FindFirstChild("HumanoidRootPart");
        if not root then continue end

        for _, part in pairs(mob:GetChildren()) do
            if part:IsA("BasePart") and (self:owner(part)) then
                part.CFrame = local_player.root_part.CFrame;
                part.Velocity = Vector3.new(0, -12500, 0)
            end 
        end
    end
end

local feat = Feature:new("bring_mobs", game:GetService("RunService").Heartbeat, function()
    feature:run()
end);
return feat