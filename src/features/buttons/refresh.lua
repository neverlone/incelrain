return function()
    local character = local_player and local_player.character
    local root = local_player and local_player.root_part
    local old_cf = root and root.CFrame
    local respawn = require("@src/features/buttons/respawn")
    if typeof(respawn) == "function" then
        respawn()
    end
    if old_cf and local_player then
        task.spawn(function()
            local new_root = local_player.root_added and local_player.root_added:wait()
            if new_root then
                task.wait(0.1)
                new_root.CFrame = old_cf
            end
        end)
    end
end
