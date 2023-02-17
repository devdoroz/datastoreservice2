local functions = script.Parent
local httpService = game:GetService("HttpService")

local request = require(functions:WaitForChild("Request"))
local auth = script.Parent.Parent:WaitForChild("Server"):WaitForChild("GetAuthorization"):Invoke()

function createDataStore(id, pAuth, name)
	local req = request("create-datastore", "POST", {placeID = id, auth = auth, placeAuth = pAuth, name = name})
	return req
end

return createDataStore
