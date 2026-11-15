local requests = services.ReplicatedStorage:FindFirstChild("Requests") or services.ReplicatedStorage:WaitForChild("Requests", 1);
local get_score = requests and (requests:FindFirstChild("GetScore") or requests:WaitForChild("GetScore", 1));
local feature = Feature:new("no_echo_screen", (is_depths and get_score) and get_score.OnClientEvent or nil, function() 
	if not get_score then return end
	get_score:FireServer();

	local echo_score_screen = local_player.instance:FindFirstChild("EchoScoreScreen", true);
	if echo_score_screen then
		echo_score_screen.Enabled = false;
	end
end);

return feature  
