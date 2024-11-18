-- lapisbean dispatcher

-- multipart parser; taken from fullmoon (MIT license; https://github.com/pkulchenko/fullmoon/blob/master/LICENSE)
local parseMultipart
do
  local function argerror(cond, narg, extramsg, name)
    if cond then return cond end
    name = name or debug.getinfo(2, "n").name or "?"
    local msg = ("bad argument #%d to %s%s"):format(narg, name, extramsg and " "..extramsg or  "")
    return error(msg, 3)
  end
  local patts = {}
  local function getParameter(header, name)
    local function optignorecase(s)
      if not patts[s] then
        patts[s] = (";%s*"
          ..s:gsub("%w", function(s) return ("[%s%s]"):format(s:upper(), s:lower()) end)
          ..[[=["']?([^;"']*)["']?]])
      end
      return patts[s]
    end
    return header:match(optignorecase(name))
  end
  local CRLF, TAIL = "\r\n", "--"
  local CRLFlen = #CRLF
  local MULTIVAL = "%[%]$"
  local function parseMultipart(body, ctype)
    argerror(type(ctype) == "string", 2, "(string expected)")
    local parts = {
      boundary = getParameter(ctype, "boundary"),
      start = getParameter(ctype, "start"),
    }
    local boundary = "--"..argerror(parts.boundary, 2, "(boundary expected in Content-Type)")
    local bol, eol, eob = 1
    while true do
      repeat
        eol, eob = string.find(body, boundary, bol, true)
        if not eol then return nil, "missing expected boundary at position "..bol end
      until eol == 1 or eol > CRLFlen and body:sub(eol-CRLFlen, eol-1) == CRLF
      if eol > CRLFlen then eol = eol - CRLFlen end
      local headers, name, filename = {}
      if bol > 1 then
        -- find the header (if any)
        if string.sub(body, bol, bol+CRLFlen-1) == CRLF then -- no headers
          bol = bol + CRLFlen
        else -- headers
          -- find the end of headers (CRLF+CRLF)
          local boh, eoh = 1, string.find(body, CRLF..CRLF, bol, true)
          if not eoh then return nil, "missing expected end of headers at position "..bol end
          -- join multi-line header values back if present
          local head = string.sub(body, bol, eoh+1):gsub(CRLF.."%s+", " ")
          while (string.find(head, CRLF, boh, true) or 0) > boh do
            local p, e, header, value = head:find("([^:]+)%s*:%s*(.-)%s*\r\n", boh)
            if p ~= boh then return nil, "invalid header syntax at position "..bol+boh end
            header = header:lower()
            if header == "content-disposition" then
              name = getParameter(value, "name")
              filename = getParameter(value, "filename")
            end
            headers[header] = value
            boh = e + 1
          end
          bol = eoh + CRLFlen*2
        end
        -- epilogue is processed, but not returned
        local ct = headers["content-type"]
        local b, err = string.sub(body, bol, eol-1)
        if ct and ct:lower():find("^multipart/") then
          b, err = parseMultipart(b, ct) -- handle multipart/* recursively
          if not b then return b, err end
        end
        local first = parts.start and parts.start == headers["content-id"] and 1
        local v = {name = name, headers = headers, filename = filename, data = b}
        table.insert(parts, first or #parts+1, v)
        if name then
          if string.find(name, MULTIVAL) then
            parts[name] = parts[name] or {}
            table.insert(parts[name], first or #parts[name]+1, v)
          else
            parts[name] = parts[name] or v
          end
        end
      end
      local tail = body:sub(eob+1, eob+#TAIL)
      -- check if the encapsulation or regular boundary is present
      if tail == TAIL then break end
      if tail ~= CRLF then return nil, "missing closing boundary at position "..eol end
      bol = eob + #tail + 1
    end
    return parts
  end
end

-- loosely based on lapis' inbuilt nginx/openresty support
local lazy__mt = {}
local FUNCTIONS = {} -- sentinel

function lazy__mt:__index(k)
  local fn = self[FUNCTIONS][k]
  if fn then
    self[k] = fn(self)
  end
  return rawget(self,k)
end

local function lazytbl(fntbl)
  return setmetatable({[FUNCTIONS]=fntbl},lazy__mt)
end

local function stub_tbl() return {} end
local _unpack, _pack = table.unpack, table.pack
local function value_range(_start,_end,...)
  return _unpack(_pack(...),_start,_end)
end
local function ip(func)
  return function()
    return string.format(
      "%d.%d.%d.%d",
      value_range(1,4,string.unpack(
        "BBBB",
        string.pack(">I4",(func()))
      ))
    )
  end
end
local function flatten_params(params)
  local out = {}
  for _,v in ipairs(params) do out[v[1]]=v[2] end
  return out
end
local _req = {
  -- deprecated parameters
  referer = function() return GetHeader('Referer') end;
  cmd_mth = function() return GetMethod() end;
  cmd_uri = function() return GetUrl() end;
  relpath = function(self) return self.parsed_url.path end;
  srv = function() return '' end; -- not sure what would be given here

  headers = function() return GetHeaders() end;
  method = function() return GetMethod() end;

  scheme = function() return GetScheme() end;
  port = function() return select(2,GetServerAddr()) end;
  server_addr = ip(GetServerAddr);
  remote_addr = ip(GetClientAddr);
  request_uri = function() return GetUrl() end;

  read_body_as_string = function() return GetBody end;
  parsed_url = function() return ParseUrl(GetUrl()) end;

  params_post = function()
    local content_type = (GetHeader('Content-Type') or '')
    if content_type:match('^multipart/') then return parseMultipart(GetBody(), content_type) end
    if content_type:match('application/x-www-form-urlencoded') then
      local params = (ParseUrl("?"..url) or {}).params
      return flatten_params(params or {})
    end
    return {}
  end;
  params_get = function() 
    return flatten_params(GetParams())
  end;
}

local function build_response()
  return {
    req = lazytbl(_req);
    add_header = function(self, k, v)
      old = self.headers[k]
      if old==nil then
        self.headers[k] = v
      elseif type(old)=="table" then
        table.insert(old,v)
      else
        self.headers[k] = {old,v}
      end
    end;
    headers = {};
  }
end

local function dispatch(app)
  local res = build_response()
  app:dispatch(res.req, res)
  SetStatus(res.status or 200)
  for k,v in pairs(res.headers) do
    if type(v)=="table" then
      SetHeader(k,v[#v])
    else
      SetHeader(k,v)
    end
  end
  Write(res.content)
end

return {
  dispatch = dispatch;
}