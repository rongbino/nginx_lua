local json   = require "dkjson"
local util = require "util"

mock_event_data = '[]';

local args = ngx.req.get_uri_args()

ngx.req.read_body();
local body = ngx.req.get_body_data();

local resp = ngx.location.capture(
  "/api-internal/v1/signup", {method = ngx.HTTP_POST, args = args, body = body})
if resp.status ~= ngx.HTTP_OK then
  util.exit(resp.status)
end

local obj = json.decode(resp.body)
if obj.code == 0 then
  local device = json.decode(body)
  if device ~= nil then
    ngx.var.mock_query_string = table.concat(
      {'appId=', args.appId, '&channel=', args.channel,
       '&network=', args.network, '&udId=', obj.data.udId,
       '&ts=', args.ts, '&appVer=', device.appVer, '&osName=', device.osName}, '')
    ngx.var.mock_event_data = mock_event_data
  end
  ngx.var.signup_appid = args.appId
  ngx.var.signup_udid = obj.data.udId
  if obj.data.isNew then
    ngx.var.signup_data = body
  end
end
util.exit(ngx.HTTP_OK, resp.body)
