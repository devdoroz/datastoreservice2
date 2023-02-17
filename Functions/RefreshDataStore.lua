local functions = script.Parent
local httpService = game:GetService("HttpService")

local request = require(functions:WaitForChild("Request"))
local auth, identifier = script.Parent.Parent:WaitForChild("Server"):WaitForChild("GetAuthorization"):Invoke()

function refreshDataStore(id, pAuth)
	local req = request("get-datastore", "GET", {placeID = id, identifierAuth = identifier, auth = auth, placeAuth = pAuth})
	if req.Success then
		return httpService:JSONDecode(req.Body)
	end
	warn("Invalid datastore or invalid authorization? You shouldn't be getting this error without tinkering with the code.")
	return
end

return refreshDataStore
