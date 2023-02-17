return function(check, cases)
	while cases[check] do cases[check]() return end
	while cases["default"] do cases["default"]() break end
end
