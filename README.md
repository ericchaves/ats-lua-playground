Apache Traffic Server Lua Plugins
=================================

Basic docker-compose to be used during simple lua plugins development.

run `docker-compose up -d to build/start`

run `curl -v -x http://localhost:8080 http://ifconfig.co` to see it in action =)

you can edit the plugin/my_module.lua with container running and changes will be reflected immediatly.

to inspect the running container run `docker-compose exec trafficserver /bin/bash`