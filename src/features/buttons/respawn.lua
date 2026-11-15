return function()
    if replicatesignal then
        replicatesignal(local_player.instance.Kill)
        task.delay(1, function()
            if local_player.humanoid.Health <= 1 then return end

            local_player.root_part.CFrame *= CFrame.new(0,5,0);
        end);
    else
        local_player.root_part.CFrame *= CFrame.new(0,5,0);
    end
end

