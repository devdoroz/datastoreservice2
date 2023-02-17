local key = "" -- https://datastore.doroz-cats.com/api/v1/generate-auth
local getAuthorizationFunction = script:WaitForChild('GetAuthorization')
local functions = script.Parent:WaitForChild("Functions")
local httpService = game:GetService("HttpService")
local dataStoreData = Instance.new("Folder", game.ServerStorage)
local messagingQueue = Instance.new("Folder")
messagingQueue.Parent = game.ServerStorage
messagingQueue.Name = "MessagingQueue"
messagingQueue:SetAttribute("UpdateMode", false)
messagingQueue:SetAttribute("Buffer", 0)
messagingQueue:SetAttribute("AvaliableRequests", 150 + 60 * #game.Players:GetPlayers())
messagingQueue:SetAttribute("MaximumRequests", 150 + 60 * #game.Players:GetPlayers())
coroutine.wrap(function()
	while true do
		task.wait(60)
		messagingQueue:SetAttribute("Buffer", 0)
		messagingQueue:SetAttribute("UpdateMode", false)
		messagingQueue:SetAttribute("MaximumRequests", 150 + 60 * #game.Players:GetPlayers())
		messagingQueue:SetAttribute("AvaliableRequests", 150 + 60 * #game.Players:GetPlayers())
	end
end)()
local request = require(functions:WaitForChild("Request"))
dataStoreData.Name = "DataStoreData"
local function getSecureAuth()
	local req = request("generate-auth", "GET", {})
	return req.Body
end
local auth; do
	local savedAuth = request("get-saved-auth", "GET", {key = key})
	if savedAuth.Success then
		auth = httpService:JSONDecode(savedAuth.Body)
	else
		local fernetKey = getSecureAuth()
		local keyAuth = fernetKey
		local req = request("save-auth", "PUT", {key = key, auth = keyAuth})
		if not req.Success then
			error("Key wasn't valid, generate a key from https://datastore.doroz-cats.com/api/v1/generate-auth", 10)
		else
			local savedAuth = request("get-saved-auth", "GET", {key = key})
			auth = httpService:JSONDecode(savedAuth.Body)
		end
	end
end

getAuthorizationFunction.OnInvoke = function()
	return auth["auth"], auth["verifyAuth"]
end
