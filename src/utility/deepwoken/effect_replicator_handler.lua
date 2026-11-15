





if not getloadedmodules then
    return game:GetService(STR_TBL_SF_INVOKE("Players")).LocalPlayer:Kick(STR_TBL_SF_INVOKE("Executor is unsupported. [missing getloadedmodules, effect_replicator_handler]"))
end;


local Maid = require("@src/utility/maid");
getgenv().EffectReplicator = getgenv().EffectReplicator or {
    FindEffect = function() return nil end,
    HasEffect = function() return false end,
    HasAny = function() return false end,
    CreateEffect = function() return nil end,
    Effects = {}
};
local EffectReplicatorHandler = {};
EffectReplicatorHandler.__index = EffectReplicatorHandler;
EffectReplicatorHandler.hooks = {};
EffectReplicatorHandler.maid = Maid.new();

function EffectReplicatorHandler:hook(type, func)
    local hook = {};
    function hook:remove()
        table.remove(EffectReplicatorHandler.hooks, self.index);
    end; 

    hook.type = type;
    hook.call = func;
    hook.index = table.insert(EffectReplicatorHandler.hooks, hook);

    return hook
end;

function EffectReplicatorHandler:connect()
    self.maid:do_cleaning();

    local RawEffectReplicator = game:GetService("ReplicatedStorage"):WaitForChild("EffectReplicator", 3);
    if not RawEffectReplicator then return end;
    if typeof(getloadedmodules) == "function" and not table.find(getloadedmodules(), RawEffectReplicator) then
        local wait_attempts = 0;
        repeat 
            task.wait(0.06);
            wait_attempts += 1;
            if wait_attempts > 20 then break end;
        until table.find(getloadedmodules(), RawEffectReplicator);
    end;
    local ok_er, EffectReplicator = pcall(base_require, RawEffectReplicator);
    if not ok_er or not EffectReplicator then return end;
    getgenv().EffectReplicator = EffectReplicator;

    self.maid:give_task(EffectReplicator.EffectAdded:Connect(function(effect)
        setthreadidentity(8);
        for _, hook in pairs(EffectReplicatorHandler.hooks) do
            if hook.type == "added" and hook.call then
                task.spawn(xpcall, function()
                    hook.call(effect);
                end, function(err)
                    Logger.error(string.format("effectreplicator added hook: %s", err));
                end);
            end;
        end;
    end));
    
    self.maid:give_task(EffectReplicator.EffectRemoved:Connect(function(effect)
        for _, hook in pairs(EffectReplicatorHandler.hooks) do
            if hook.type == "removed" then
                xpcall(function()
                    hook.call(effect);
                end, function(err) 
                    Logger.error(string.format("effectreplicator removed hook: %s", err));
                end);
            end;
        end;  
    end));
end;

task.spawn(pcall, function()
    while not pcall(function() aztup.maid:give_task(EffectReplicatorHandler.maid); end) do task.wait() end;
end);

task.spawn(pcall, function()
    local requests = game:GetService("ReplicatedStorage"):WaitForChild("Requests", 5);
    local er = requests and requests:WaitForChild("EffectReplication", 5);
    local update = er and er:WaitForChild("_update", 5);
    if update then
        update.OnClientEvent:Connect(function(effect)
            if effect.updateType == "clear" or effect.updateType == "updatecontainer" then
                EffectReplicatorHandler:connect();  
            end;
        end);
    end

    EffectReplicatorHandler:connect();
end);
return EffectReplicatorHandler
