local redis = require "resty.redis"

local _M = {
}

local host = token_redis_host
local port = token_redis_port
local pass = token_redis_pass

local function split(s, p)
  local regex = "[^" .. p .. "]+"
  local parts = {}
  string.gsub(s, regex, function(w) table.insert(parts, w) end)
  return parts;
end

local function find(array, item)
  for _,v in pairs(array) do
    if v == item then return true end
  end
  return false
end

local function exit(status, body, contentType)
  ngx.status = status
  if body then
    if contentType then
      ngx.header["Content-Type"] = contentType
    else
      ngx.header["Content-Type"] = "application/json;charset=UTF-8"
    end
    ngx.print(body)
  end
  ngx.exit(status)
end

local function req_body()
  ngx.req.read_body()
  local data = ngx.req.get_body_data()
  if not data then
    exit(ngx.HTTP_BAD_REQUEST)
  end
  return data
end

local function auth_info(appid, udid, token)
  local r = redis:new()
  r:set_timeout(500)

  local ok, err = r:connect(host, port)
  if not ok then return nil end

  if pass ~= nil then r:auth(pass) end

  local key = "PLUSTOKEN#" .. appid .. "#" .. udid;
  local value, err = r:get(key)

  local auth = false
  local info = {}

  if value ~= ngx.null then
    local parts = split(value, ":")
    auth = (token == parts[1])

    if #parts >= 2 then
      info.osname = parts[2]
    end
  end

  if auth then
    return r
  else
    exit(ngx.HTTP_OK, '{"code": 401, "message": "unauthorized"}')
  end
end

local function check_token(token, udid, appver)
  local start, e = string.find(token, ":")
  if start ~= nil then
    token = string.sub(token, 1, start-1)
  end

  -- local text = udid .. appver .. ngx.var.token_secret;
  local text = udid .. ngx.var.token_secret;
  return token == ngx.md5(text);
end

local function pack(...)
  return {n = select('#', ...); ...}
end

local function appendf(fname, ...)
  local f = ngx.var.log_directory .. "/" .. fname .. "." .. ngx.var.pid
  local fh = io.open(f, "a+")
  if not fh then
    ngx.log(ngx.ERR, "open ", f, " error")
    return
  end

  fh:write("v1.1 [")
  fh:write(ngx.var.time_local)
  fh:write("] ")

  local args = pack(...)

  for i = 1, args.n do
    fh:write(args[i])
    local sp = (i == args.n) and "\n" or " "
    fh:write(sp)
  end
  fh:close()
end

local _M = {
  split = split,
  find = find,
  exit = exit,
  req_body = req_body,
  check_token = check_token,
  appendf = appendf
}

return _M
