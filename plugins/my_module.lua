
local my_module = {}

local redis = require 'redis'
local redis_server = os.getenv('REDIS_SERVER') or 'redis'
local redis_port   = os.getenv('REDIS_PORT') or 6379
local client = redis.connect(redis_server, redis_port)

function my_module.send_response()
  ts.debug('executing my_module.send_response')
  local value = ts.ctx['rhost']
  client:set('usr:nrk',  value)
  ts.client_response.header['Rhost'] = client:get('usr:nrk')
  return 0
end

return my_module