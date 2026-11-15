local self = Feature:new("no_clouds");

function self:remove_clouds()
    local marker_ws = services.ReplicatedStorage:FindFirstChild("MarkerWorkspace") or services.ReplicatedStorage:WaitForChild("MarkerWorkspace", 5);
    local weather_markers = marker_ws and marker_ws:WaitForChild("WeatherMarkers", 5);
    if not weather_markers then return end
    for _, item in weather_markers:GetChildren() do
        item:Destroy();
    end;

    for _, conn in getconnections(weather_markers.ChildAdded) do
        conn:Disable();
    end;
end

self.enable = function()
    return task.spawn(self.remove_clouds)
end;

return self
