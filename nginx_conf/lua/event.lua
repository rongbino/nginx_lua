local json = require "dkjson"
local util = require "util"

ngx.var.event_data = 'NIL'
ngx.var.event_osname = 'NIL'

if ngx.req.get_method() ~= "POST" then
  util.exit(ngx.HTTP_NOT_ALLOWED);
end

local args = ngx.req.get_uri_args();

local appid = args.appId;
local udid = args.udId;
local token = args.token;
local appver = args.appVer;
local osname = args.osName;

if not token or not udid or not appid or not appver then
  util.exit(ngx.HTTP_BAD_REQUEST, "not token/udid/appid/appver found", "text/plain")
end

if not util.check_token(token, udid, appver) or udid == "cd9e459ea708a948d5c2f5a6ca8838cf" then
  util.exit(ngx.HTTP_OK, '{"code": 401, "message": "unauthorized"}')
end

if osname == nil then
  local start, e = string.find(token, ":")
  if start then
    osname = string.sub(token, start + 1)
  else
    util.exit(ngx.HTTP_OK, '{"code": 401, "message": "unauthorized"}')
  end
end

local oslist = {"ANDROID", "IOS", "WEB", "MACOS", "WINDOWS", "LINUX", "QNX",
                "WEB_ANDROID", "WEB_IOS", "WEB_WINDOWS", "WEB_MACOS", "WEB_LINUX"}

if not util.find(oslist, osname) then
  util.exit(ngx.HTTP_BAD_REQUEST, "unknow osname", "text/plain")
end
ngx.var.event_osname = osname

ngx.req.read_body()
local data = ngx.req.get_body_data()
if not data then
  util.exit(ngx.HTTP_BAD_REQUEST, "body was empty", "text/plain");
end
ngx.var.event_data = data

-- validate data is json
local obj = json.decode(data)
ngx.var.json_validation = obj and "OK" or "ERR"

util.exit(ngx.HTTP_OK, '{"code": 0, "message": "OK"}')
