-- lapisbean luasocket url shim
local url = {}

url.escape = EscapeSegment
function url.unescape(s)
	return (s:gsub('%%([0-9A-Fa-f][0-9A-Fa-f])',function(n) return string.char(tonumber(n,16)) end))
end

return url
