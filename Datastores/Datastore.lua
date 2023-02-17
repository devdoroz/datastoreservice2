local obj = {} obj.__index = obj
local serverStorage = game:GetService("ServerStorage")
local module = require(script.Parent.Parent:WaitForChild("Config")) module.__index = module
local httpService = game:GetService("HttpService")
local auth = script.Parent.Parent:WaitForChild("Server"):WaitForChild("GetAuthorization"):Invoke()
local functions = script.Parent.Parent:WaitForChild("Functions")
local serialization = require(functions:WaitForChild("Serialization"))
local request = require(functions:WaitForChild("Request"))
local onDataChange = require(functions:WaitForChild("OnDataChange"))
local dataStoreData = serverStorage:WaitForChild("DataStoreData")
local refreshDataStore = require(functions:WaitForChild("RefreshDataStore"))
local queue = serverStorage:WaitForChild("MessagingQueue")
local createDataStore = require(functions:WaitForChild("CreateDataStore"))

function obj:__init()
	if not self.Initalized then
		self.Initalized = true
		dataStoreData[self.Name]:WaitForChild("functionChanged").Changed:Connect(function()
			if dataStoreData[self.Name].functionChanged.Value then
				if self["onUpdate"] then
					dataStoreData[self.Name].functionChanged.Value = false
					self.onUpdate(self, dataStoreData[self.Name].functionChanged:GetAttribute("UpdatedKey"), dataStoreData:GetAttribute("isBackup"))
				end
			end
		end)
	else
		warn("Attempted to initalize, even though already initalized?")
	end
end

function obj:Update()
	if dataStoreData[self.Name]:GetAttribute("Changed") or queue:GetAttribute("UpdateMode") then
		local datastoreData = refreshDataStore(self.ID, self.Auth)
		if datastoreData[self.Name] then
			self.json = datastoreData[self.Name]
		else
			local req = createDataStore(self.ID, self.Auth, self.Name)
			datastoreData = refreshDataStore(self.ID, self.Auth)
			if req.Success then
				self.json = datastoreData[self.Name]
			else
				error(req.StatusCode, 0)
			end
		end
		dataStoreData[self.Name]:SetAttribute("Changed", false)
	else if module.debugMode then print("Saved a request!") end end
end

function obj:Backup()
	local req = request("backup-datastore", "POST", {name = self.Name, placeID = self.ID, rawAuth = auth, auth = self.Auth})
	if req.Success then return req.Body end
	return false
end

function obj:GetBackups()
	local req = request("get-backups", "GET", {name = self.Name, placeID = self.ID, rawAuth = auth, auth = self.Auth})
	if req.Success then return req.Body end
	return false
end

function obj:SetBackup(backupName: string?)
	local req = request("set-backup", "POST", {backupName = backupName, name = self.Name, placeID = self.ID, rawAuth = auth, auth = self.Auth})
	if req.Success then onDataChange(self, nil, true) return req.Body end
	local statusCode = req.StatusCode
	if statusCode == 400 then
		warn("Backup with specified name doesn't exist.")
	end
	return false
end

function obj:GetAsync(key: string?)
	key = tostring(key) or key
	self:Update()
	return if self.json then serialization:Deserialize(self.json[key]) else nil
end

function obj:GetRawAsync(key: string?)
	key = tostring(key) or key
	self:Update()
	return if self.json then self.json[key] else nil
end

function obj:RemoveAsync(key: string?)
	key = tostring(key) or key
	if typeof(key) ~= "string" then return warn("Strings are only supported for keys.") end
	local req = request("remove-key", "DELETE", {name = self.Name, placeID = self.ID, rawAuth = auth, auth = self.Auth, key = key})
	if req.Success then onDataChange(self, key, false) return req.Body end
	return false
end

function obj:SetAsync(key: string?, value, includeDescendants: boolean?)
	key = tostring(key) or key
	includeDescendants = includeDescendants or false
	if typeof(key) ~= "string" then return warn("Strings are only supported for keys.") end
	-- check if value is already set to value
	if self.json and self.json[key] and self.json[key] == value then return {Success = true, Body = {}} end
	local req = request("set-key", "POST", {name = self.Name, placeID = self.ID, rawAuth = auth, auth = self.Auth, key = key, value = serialization:Serialize(value, includeDescendants)})
	if req.Success then onDataChange(self, key, false) return req.Body end
	if req.StatusCode == 413 then
		warn("413: Payload Too Large | Data was over 5 megabytes, too large.")
	end
	return false
end

function obj:IncrementAsync(key: string?, value: number?)
	key = tostring(key) or key
	self:Update()
	local keyVal = self.json[key]
	if typeof(keyVal) ~= "number" then return warn("Value must be a number to increment!") end
	self:SetAsync(key, keyVal + value)
end

function obj:UpdateAsync(key: string?, transformFunction)
	key = tostring(key) or key
	if typeof(key) ~= "string" then return warn("Strings are only supported for keys.") end
	local pastData = self:GetAsync(key)
	local updateCheck = transformFunction(pastData)
	if updateCheck then
		self:SetAsync(key, updateCheck)
	end
end

return obj
