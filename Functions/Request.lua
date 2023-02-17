local module = require(script.Parent.Parent.Config)
local httpService = game:GetService("HttpService")
local url = "https://datastore.doroz-cats.com/api/v1/"

local function formatBodyIntoQuery(body)
	local result = "?"
	for name, value in pairs(body) do
		result = result..name.."="..value.."&"
	end
	return result:sub(1, #result - 1)
end

function request(urlMethod, method, body)
	local req
	local s, e = pcall(function()
		local requestID = math.round(tick()) - math.random(10000, 1000000)
		local success = false
		local tries = 0
		if module.AutomaticRetry then
			while not success do
				tries += 1
				local data = {
					Url = url..urlMethod,
					Method = method,
				}
				if method ~= "GET" then data.Headers = {["Content-Type"] = "application/json",} data.Body = httpService:JSONEncode(body) else
					data.Url = data.Url..formatBodyIntoQuery(body)	
				end
				req = httpService:RequestAsync(data)
				if module.debugMode then print("Made "..method.." request to "..data.Url) end
				if req.Success then success = true else print("Something went wrong. Retrying in 1 second... Request ID: "..requestID) task.wait(1) end
				if module.debugMode then if not req.Success then warn("Something went wrong. Error Code "..req.StatusCode) end end
				if tries > 5 then
					print("Try limit exceeded, request failed. Perhaps the servers are down?")
					break
				end
			end
		else
			local data = {
				Url = url..urlMethod,
				Method = method,
			}
			if method ~= "GET" then data.Headers = {["Content-Type"] = "application/json",} data.Body = httpService:JSONEncode(body) else
				data.Url = data.Url..formatBodyIntoQuery(body)	
			end
			req = httpService:RequestAsync(data)
			if module.debugMode then print("Made "..method.." request to "..data.Url) end
			if req.Success then success = true end
			if module.debugMode then if not req.Success then warn("Something went wrong. Error Code "..req.StatusCode) end end
		end
		return req
	end)
	if not s then
		if tostring(e) == "Number of requests exceeded limit" then
			error("Connection Failure: Too Many Requests", 10)
		else
			error("Connection Failure: Allow HTTP requests in Game Settings.", 10)
		end
	end
	return req
end

return request
