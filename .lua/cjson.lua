-- lapisbean lua-cjson shim
local json = {}

json.encode = EncodeJson
json.decode = DecodeJson
json.empty_array = {[0]=false}

return json
