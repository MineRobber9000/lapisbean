-- lapisbean mime shim (CC0)
local mime = {}

function mime.b64(C, D)
  return EncodeBase64(C..D)
end

function mime.unb64(C, D)
  return DecodeBase64(C..D)
end

return mime
