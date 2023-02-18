local pages = {IsFinished = false} pages.__index = pages

function pages.new(sorted)
	local object = setmetatable({}, pages)
	object.data = sorted
	object.page = 1
	if #object.data <= 1 then
		object.IsFinished = true
	end
	
	return object
end

function pages:GetCurrentPage()
	return self.data[self.page] or {}
end

function pages:AdvanceToNextPageAsync()
	self.page = math.clamp(self.page + 1, 1, #self.data)
	if self.page >= #self.data then self.IsFinished = true else self.IsFinished = false end
end

return pages
