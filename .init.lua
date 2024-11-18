-- register LuLPeg
require'lulpeg':register(not _ENV and _G)

-- bypass lapis.nginx
package.loaded['lapis.nginx'] = require'lapisbean'

function OnHttpRequest()
	local ok, err = xpcall(function()
		require'lapis'.serve(require'app')
	end, debug.traceback)
	if not ok then
    SetStatus(502)
    SetHeader('Content-Type','text/plain')
    Write("An uncaught exception occured:\n"..err)
  end
end
