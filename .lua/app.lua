local lapis = require"lapis"
local app = lapis.Application()
app:enable("etlua")

app:match("/",function(self)
  return {redirect_to=self:url_for("hello")}
end)

app:match("hello","/hello",function(self)
  self.redbean_version = string.format("%d.%d.%d",string.unpack("BBB",string.pack(">I3",GetRedbeanVersion())))
  return {render=true,layout="hello"}
end)

app:match("params","/params",function(self)
  self:write({content_type="text/plain",layout=false})
  for k,v in pairs(self.GET) do
    self:write(string.format('%s: %s\n',tostring(k),tostring(v)))
  end
end)

return app
