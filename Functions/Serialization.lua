local serialization = {}
local functions = script.Parent
local getProperties = require(script:WaitForChild("GetProperties"))
local switch = require(functions:WaitForChild("Switch"))
local propertiesInherit = {
	["Part"] = {"BasePart"},
	["MeshPart"] = {"BasePart"}
}
local ignoredProperties = {
	"Parent",
	"Faces",
	"AssemblyRootPart",
	"ResizeableFaces"
}
local ignoreClassNames = {"LocalScript", "Script", "ModuleScript"}
local alwaysProperties = {"Name"}

function ConvertVector3(v3: Vector3)
	return {Identifier = "Vector3", X = v3.X, Y = v3.Y, Z = v3.Z}
end

function ConvertBrickColor(bc: BrickColor)
	return {Identifier = "BrickColor", Color = tostring(bc)}
end

function ConvertCFrame(cf: CFrame)
	return {Identifier = "CFrame", X = cf.X, Y = cf.Y, Z = cf.Z, XVector = {X = cf.XVector.X, Y = cf.XVector.Y, Z = cf.XVector.Z}, YVector = {X = cf.YVector.X, Y = cf.YVector.Y, Z = cf.YVector.Z}, ZVector = {X = cf.ZVector.X, Y = cf.ZVector.Y, Z = cf.ZVector.Z}}
end

function ConvertColor3(c3: Color3)
	return {Identifier = "Color3", Hex = c3:ToHex()}
end

function ConvertEnumItem(enumItem: EnumItem)
	return {Identifier = "EnumItem", EnumType = tostring(enumItem.EnumType), Name = enumItem.Name}
end

function ConvertInstance(instance: Instance, includeDescendants: boolean)
	local className = instance.ClassName
	local properties = getProperties(className)
	local result = {Identifier = "Instance", ClassName = className, Properties = {}, Children = {}}
	if not table.find(ignoreClassNames, className) then
		if propertiesInherit[className] then
			for index, class in pairs(propertiesInherit[className]) do
				for index, property in pairs(getProperties(class)) do
					properties[#properties + 1] = property
				end
			end
		end
		for index, class in pairs(alwaysProperties) do
			pcall(function()
				properties[#properties + 1] = class
			end)
		end
		if properties then
			for index, property in pairs(properties) do
				if not table.find(ignoredProperties, property) then
					pcall(function()
						local value = instance[property]
						local serializedValue = serialization:Serialize(value, includeDescendants)
						result["Properties"][property] = serializedValue
					end)
				end
			end
		end
		if includeDescendants then
			result.Children = serialization:Serialize(instance:GetChildren(), includeDescendants)
		end
	end
	return result
end

local objFunctions = {
	["Vector3"] = ConvertVector3,
	["EnumItem"] = ConvertEnumItem,
	["CFrame"] = ConvertCFrame,
	["Color3"] = ConvertColor3,
	["BrickColor"] = ConvertBrickColor,
	["Instance"] = ConvertInstance
}

local serializedTypes = {"Instance", "Vector3", "EnumItem", "CFrame", "Color3", "BrickColor"}

function serialization:Serialize(obj, includeDescendants)
	local objType = typeof(obj)
	if objType == "table" then
		local newTable = {}
		for index, value in pairs(obj) do
			newTable[index] = serialization:Serialize(value, includeDescendants)
		end
		return newTable
	else
		local func = objFunctions[objType]
		if func then
			return func(obj, includeDescendants)
		end
	end
	return obj
end

function serialization:Deserialize(serializedObj)
	local deserializedObj = serializedObj
	if typeof(serializedObj) == "table" then
		if serializedObj["Identifier"] then
			local objType = serializedObj.Identifier
			if table.find(serializedTypes, objType) then
				switch(objType, {
					["Vector3"] = function()
						deserializedObj = Vector3.new(serializedObj.X, serializedObj.Y, serializedObj.Z)
					end,
					["CFrame"] = function()
						deserializedObj = CFrame.new(serializedObj.X, serializedObj.Y, serializedObj.Z, serializedObj.XVector.X, serializedObj.XVector.Y, serializedObj.XVector.Z, serializedObj.YVector.X, serializedObj.YVector.Y, serializedObj.YVector.Z, serializedObj.ZVector.X, serializedObj.ZVector.Y, serializedObj.ZVector.Z)
					end,
					["BrickColor"] = function()
						deserializedObj = BrickColor.new(serializedObj.Color)
					end,
					["Color3"] = function()
						deserializedObj = Color3.fromHex(serializedObj.Hex)
					end,
					["EnumItem"] = function()
						deserializedObj = Enum[serializedObj.EnumType][serializedObj.Name]
					end,
					["Instance"] = function()
						local properties = serializedObj.Properties
						local className = serializedObj.ClassName
						local inst = Instance.new(className)
						for property, value in pairs(properties) do
							local s, e = pcall(function()
								inst[property] = serialization:Deserialize(value)
							end)
						end
						if serializedObj["Children"] then
							for index, instance in pairs(serializedObj.Children) do
								pcall(function()
									serialization:Deserialize(instance).Parent = inst
								end)
							end
						end
						deserializedObj = inst
					end,
				})
			end
		else
			local deserializedTable = {}
			for index, value in pairs(serializedObj) do
				deserializedTable[index] = serialization:Deserialize(value)
			end
			deserializedObj = deserializedTable
		end
	end
	return deserializedObj
end

return serialization
