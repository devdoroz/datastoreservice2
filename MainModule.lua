-- DataStoreService2 by 31oq (doroz)
-- A faster DataStoreService.
-- Place this in ServerScriptService!
--[[
	Never ever share your authentication key with someone.
	Doing so will give them full access to your database!
--]]

local allowedParents = {game:GetService("ServerScriptService")}
local messagingService = game:GetService("MessagingService")
local serverStorage = game:GetService("ServerStorage")
local module = require(script:WaitForChild("Config")) module.__index = module
local obj = {} obj.__index = obj
local odsObj = require(script.Datastores:WaitForChild("OrderedDatastore"))
local httpService = game:GetService("HttpService")
local runService = game:GetService("RunService")
local placeID = game.PlaceId
local universeID = game.GameId
local auth, identifierAuth = script:WaitForChild("Server"):WaitForChild("GetAuthorization"):Invoke()
local sha1 = require(script.Functions:WaitForChild("SHA1"))
local placeAuth = sha1(identifierAuth..tostring(placeID)..auth)
local odsPlaceAuth = sha1(identifierAuth..tostring(-placeID)..auth)
local universalAuth = sha1(identifierAuth..tostring(-1)..auth)
local universeAuth = sha1(identifierAuth..tostring(universeID)..auth)
local functions = script:WaitForChild("Functions")
local request = require(functions:WaitForChild("Request"))
local onDataChange = require(functions:WaitForChild("OnDataChange"))
local switch = require(functions:WaitForChild("Switch"))
local dataStoreData = serverStorage:WaitForChild("DataStoreData")
local refreshDataStore = require(functions:WaitForChild("RefreshDataStore"))
local obj = require(script.Datastores:WaitForChild("Datastore"))
local createDataStore = require(functions:WaitForChild("CreateDataStore"))
local queue = serverStorage:WaitForChild("MessagingQueue")

local function makeDataStoreData(object)
	if not dataStoreData:FindFirstChild(object.Name) then
		local dataObject = Instance.new("StringValue", dataStoreData)
		dataObject.Name = object.Name
		dataObject:SetAttribute("Changed", true)
		local functionChanged = Instance.new("BoolValue", dataObject)
		functionChanged.Name = "functionChanged"
		functionChanged.Value = false
		functionChanged:SetAttribute("UpdatedKey", "none")
		functionChanged:SetAttribute("isBackup", false)
	end
end

if runService:IsServer() then
	if not table.find(allowedParents, script.Parent) then warn("Place this in ServerScriptService") script:Destroy() end
	function module:GetDataStore(dataStoreName: string?)
		if typeof(dataStoreName) ~= "string" then return warn("Strings are only supported for DataStore names.") end
		local datastoreData = refreshDataStore(placeID, placeAuth)
		local datastoreObject = setmetatable({}, obj)
		
		datastoreObject.Name = dataStoreName
		datastoreObject.ID = placeID
		datastoreObject.Type = "Normal"
		datastoreObject.Auth = placeAuth
		datastoreObject.json = datastoreData[dataStoreName]
		
		makeDataStoreData(datastoreObject)
		datastoreObject:__init()
		
		return datastoreObject
	end
	
	function module:GetUniversalDataStore(dataStoreName: string?)
		if typeof(dataStoreName) ~= "string" then return warn("Strings are only supported for DataStore names.") end
		local datastoreData = refreshDataStore(-1, universalAuth)
		local datastoreObject = setmetatable({}, obj)

		datastoreObject.Name = dataStoreName
		datastoreObject.Auth = universalAuth
		datastoreObject.Type = "Universal"
		datastoreObject.ID = -1
		datastoreObject.json = datastoreData[dataStoreName]

		makeDataStoreData(datastoreObject)
		datastoreObject:__init()

		return datastoreObject
	end
	
	function module:GetGlobalDataStore(dataStoreName: string?)
		if typeof(dataStoreName) ~= "string" then return warn("Strings are only supported for DataStore names.") end
		local datastoreData = refreshDataStore(universeID, universeAuth)
		local datastoreObject = setmetatable({}, obj)

		datastoreObject.Name = dataStoreName
		datastoreObject.Auth = universeAuth
		datastoreObject.Type = "Global"
		datastoreObject.ID = universeID
		datastoreObject.json = datastoreData[dataStoreName]
		
		makeDataStoreData(datastoreObject)
		datastoreObject:__init()

		return datastoreObject
	end
	
	function module:GetOrderedDataStore(dataStoreName: string?)
		if typeof(dataStoreName) ~= "string" then return warn("Strings are only supported for DataStore names.") end
		local datastoreData = refreshDataStore(-placeID, odsPlaceAuth)
		local datastoreObject = setmetatable({}, odsObj)

		datastoreObject.Name = dataStoreName
		datastoreObject.Auth = odsPlaceAuth
		datastoreObject.ID = -placeID
		datastoreObject.Type = "Ordered"
		datastoreObject.json = datastoreData[dataStoreName]
		datastoreObject.IsFinished = false
		
		makeDataStoreData(datastoreObject)
		datastoreObject:__init()

		return datastoreObject
	end
	
	messagingService:SubscribeAsync("DataChange", function(message)
		local data = message.Data
		local updated = data["Updated"]
		local updateMode = data["UpdateMode"] or queue:GetAttribute("UpdateMode")
		for index, data in pairs(updated) do
			local dataStoreName = data.DataStoreName
			local dataStoreKey = data.DataStoreKey
			local isBackup = data.isBackup
			local dataStoreType = data.DataStoreType
			local dataStoreObject; do
				switch(dataStoreType, {
					["Normal"] = function()
						dataStoreObject = module:GetDataStore(dataStoreName)
					end,
					["Global"] = function()
						dataStoreObject = module:GetGlobalDataStore(dataStoreName)
					end,
					["Ordered"] = function()
						dataStoreObject = module:GetOrderedDataStore(dataStoreName)
					end,
					["Universal"] = function()
						dataStoreObject = module:GetUniversalDataStore(dataStoreName)
					end,
				})
			end
			dataStoreData[dataStoreName]:SetAttribute("Changed", true)
			dataStoreData[dataStoreName].functionChanged:SetAttribute("isBackup", isBackup)
			dataStoreData[dataStoreName].functionChanged:SetAttribute("UpdatedKey", dataStoreKey)
			dataStoreData[dataStoreName].functionChanged.Value = true
		end
		queue:SetAttribute("UpdateMode", updateMode)
	end)
else
	warn("Module can only be required on server")
end

return module
