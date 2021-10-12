local module = {}  


local mod_timer
local currentsend = 1       -- current index
local sts = {}              -- string buffer 'still to send'
local mod_base_url = ""     -- user configurable URL for log method
local mod_log_url = ""      -- user configurable URL for log method

local mod_timer_handler    -- forward declaration

local function add_string(sta)
    local i
    for i=currentsend,currentsend+10 do
       if sts[i] == nil then
            sts[i] = sta
            break
       end
    end
end

local function http_handler(status,body,hdr)
    if sts[currentsend] ~= nil then
        mod_timer:alarm(500, tmr.ALARM_SINGLE, mod_timer_handler)
    end
end

local function mod_timer_handler_(tmr)
    if sts[currentsend] ~= nil then
        http.get(sts[currentsend], nil, http_handler)
        sts[currentsend] = nil
        currentsend = currentsend + 1
    end
end

--API

function module.send(astring)
    add_string(mod_base_url..astring)
    if mod_timer:state() ~= nil then
        running, mode = mod_timer:state()
        if running == false then
            mod_timer:alarm(500, tmr.ALARM_SINGLE, mod_timer_handler)
        end
    else
        mod_timer:alarm(500, tmr.ALARM_SINGLE, mod_timer_handler)
    end
end

function module.log(logstring)
    module.send(mod_log_url..logstring)
end
function module.init(base_url,log_url)
    if base_url ~= nil then
        mod_base_url = base_url
    end
    if log_url ~= nil then
        mod_log_url = log_url
    end
    mod_timer_handler = mod_timer_handler_
    mod_timer = tmr.create()
end

return module

