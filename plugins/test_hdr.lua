ts.add_package_path('/opt/lua-plugins/?.lua')
ts.add_package_path('/usr/local/share/lua/5.1/?.lua;/usr/local/share/lua/5.1/?/init.lua;./?.lua;/usr/local/share/luajit-2.0.5/?.lua')
ts.add_package_cpath('/usr/local/lib/lua/5.1/?.so;./?.so;/usr/local/lib/lua/5.1/loadall.so')

function do_remap()
  package.loaded.my_module = nil;
  local my_module = require 'my_module'
  local req_host = ts.client_request.header.Host
  ts.ctx['rhost'] = string.reverse(req_host)
  ts.hook(TS_LUA_HOOK_SEND_RESPONSE_HDR, my_module.send_response)
  return 0
end
