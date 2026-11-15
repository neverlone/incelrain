local get_score = services.ReplicatedStorage:WaitForChild("Requests",5):WaitForChild("GetScore",5);
local feature = Feature:new("no_echo_screen", is_depths and get_score.OnClientEvent or nil, function() 
	get_score:FireServer();

	local echo_score_screen = local_player.instance:FindFirstChild("EchoScoreScreen", true);
	echo_score_screen.Enabled = false;
end);

return feature  
