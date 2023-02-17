local httpService = game:GetService("HttpService")
local serverStorage = game:GetService("ServerStorage")
local queue = serverStorage:WaitForChild("MessagingQueue")
local messagingService = game:GetService("MessagingService")

local function createQueueObject(data)
	if not queue:FindFirstChild(data.DataStoreKey) then
		local queueObject = Instance.new("StringValue", queue)
		queueObject.Name = data.DataStoreKey
		queueObject.Value = httpService:JSONEncode(data)
	else
		local queueObject = queue:FindFirstChild(data.DataStoreKey)
		queueObject.Value = httpService:JSONEncode(data)
	end
end

function onDataChange(object, key, isBackUp)
	local data = {
		DataStoreName = object.Name,
		DataStoreType = object.Type,
		DataStoreKey = key,
		IsBackup = isBackUp
	}
	local buffer = queue:GetAttribute("Buffer")
	coroutine.wrap(function() 
		local s, e = pcall(function()
			if not queue:GetAttribute("UpdateMode") and queue:GetAttribute("AvaliableRequests") <= math.round(queue:GetAttribute("MaximumRequests") / 1.35) then
				warn("A server has had too many requests in a short span of time, getting data might have a delay, this is a safety measure to prevent data being outdated. Key = "..key)
				messagingService:PublishAsync("DataChange", {Updated = {}, UpdateMode = true})
				coroutine.wrap(function()
					task.wait(15 + queue:GetAttribute("Buffer"))
					if queue:GetAttribute("UpdateMode") then
						print("Attempting to resume normal behavior.")
						queue:SetAttribute("UpdateMode", false)
						queue:SetAttribute("Buffer", queue:GetAttribute("Buffer") + 5)
						queue:SetAttribute("MaximumRequests", math.round(queue:GetAttribute("MaximumRequests") / 1.1))
						--queue:SetAttribute("AvaliableRequests", queue:GetAttribute("AvaliableRequests") - math.round(queue:GetAttribute("Buffer") + (queue:GetAttribute("MaximumRequests") - (queue:GetAttribute("MaximumRequests") / 1.75))))
						messagingService:PublishAsync("DataChange", {Updated = {}, UpdateMode = false})
					end
				end)()
			elseif not queue:GetAttribute("UpdateMode") then
				queue:SetAttribute("AvaliableRequests", queue:GetAttribute("AvaliableRequests") - 1)
				messagingService:PublishAsync("DataChange", {Updated = {data}}) 
				if queue:GetAttribute("UpdateMode") then
					queue:SetAttribute("AvaliableRequests", queue:GetAttribute("AvaliableRequests") - 1)
					messagingService:PublishAsync("DataChange", {Updated = {}, UpdateMode = false})
				end
			end
		end)
		if not s then
			warn("[CRUCIAL] MessagingService Failure: Rate Limited")
		end
	end)()
end

return onDataChange
