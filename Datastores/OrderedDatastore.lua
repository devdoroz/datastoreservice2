local obj = require(script.Parent:WaitForChild("Datastore"))
local dataStorePages = require(script:WaitForChild("DataStorePages"))

local function pageSorted(list, pageSize: number, keyList)
	local listSize = #list
	local amountPages = math.ceil(listSize / pageSize)
	local index = 0
	local sorted = {}
	for i = 1,amountPages,1 do
		local indexAdd = 0 + (pageSize * (i - 1))
		sorted[i] = {}
		while indexAdd < pageSize + (pageSize * (i - 1)) do
			indexAdd += 1
			local listObj = list[indexAdd]
			if not listObj then break end
			sorted[i][#sorted[i] + 1] = {value = listObj, key = keyList[listObj]}
		end
	end
	return sorted
end

function obj:GetSortedAsync(isAscending: boolean, pageSize: number)
	self:Update()
	isAscending = isAscending or false
	pageSize = pageSize or 10
	local function sortFunction(atable)
		local integerValues = {}
		local valueKey = {}
		local indexValue = {}
		local sorted = {}
		for key, value in pairs(atable) do
			if typeof(value) ~= "number" then warn("Value isn't a number, skipping.") continue end
			integerValues[#integerValues + 1] = value
			valueKey[value] = key
			indexValue[value] = #integerValues
		end
		while #integerValues ~= #sorted do
			local highestVal = if not isAscending then -math.huge else math.huge
			task.wait()
			for index, val in pairs(integerValues) do
				if not table.find(sorted, val) then
					if not isAscending then
						if val > highestVal then
							highestVal = val
						end
					else
						if val < highestVal then
							highestVal = val
						end
					end
				end
			end
			sorted[#sorted + 1] = highestVal
			--print(indexValue[highestVal])
			--table.remove(integerValues, indexValue[highestVal])
		end
		sorted = pageSorted(sorted, pageSize, valueKey)
		return sorted
	end
	local sorted = sortFunction(self.json)
	local pageObject = dataStorePages.new(sorted)
	return pageObject
end

return obj
