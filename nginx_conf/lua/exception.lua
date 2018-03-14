local util  = require "util"

if ngx.req.get_method() ~= "POST" then
  util.exit(ngx.HTTP_BAD_REQUEST);
end

local args = ngx.req.get_uri_args();

local appid = args.appId;
local udid = args.udId;
local token = args.token;
local appver = args.appVer;

if not token or not udid or not appid or not appver then
  util.exit(ngx.HTTP_BAD_REQUEST)
end

local auth = util.check_token(token, udid, appver)
if auth then
  util.appendf("exception", ngx.var.args, util.req_body())
  util.exit(ngx.HTTP_OK, '{"code": 0, "message": "OK"}')  
else
  util.exit(ngx.HTTP_OK, '{"code": 401, "message": "unauthorized"}')
end
