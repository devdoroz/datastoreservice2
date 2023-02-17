-- made by 31oq

local propertiesList = require(script:WaitForChild("PropertiesTable"))

function getProperties(className)
	local properties = propertiesList[className]
	return properties
end

return getProperties
