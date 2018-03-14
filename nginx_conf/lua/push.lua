local redis  = require "resty.redis"
local util = require "util"

local ngx_exit = function(status, body)
  if body then
    ngx.header["Content-Type"] = "application/json;charset=UTF-8"
    ngx.print(body)
  end
  ngx.exit(status)
end

if ngx.req.get_method() ~= "GET" then
  ngx_exit(ngx.HTTP_BAD_REQUEST);
end

local args = ngx.req.get_uri_args();

local udid = args.udId;
local ts = args.ts;
local ver = args.ver;

if not udid or not ts or not ver then
  ngx_exit(ngx.HTTP_BAD_REQUEST)
end

local latest_ver = 2
local latest_script = string.format("http://%s/api/v1/config/push/a.script", "plus.sogou.com")
local data = '{}'
if latest_ver > tonumber(ver) then
 data = string.format('{"ver": %s, "ts": %s, "scripts": ["%s"]}', latest_ver, ngx.now() * 1000, latest_script)
end
local body = string.format('{"code": 0, "message": "OK", data: %s}', data)

util.exit(ngx.HTTP_OK, body)

