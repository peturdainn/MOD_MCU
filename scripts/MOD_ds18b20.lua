local module = {}  

-- EXTERNAL
ds = require("ds18b20")

local ds18b20_pin = nil
local temperature_busy = 0
local mod_callback = nil   -- fn(temp)
local temperature_comp = 0
local mod_timer

local function on_ds_read(temps)
    local temperature = -666
    if ds.sens then
        for addr, temp in pairs(temps) do
            temperature = temp
        end
    end
    temperature_busy = 0
    mod_callback(temperature + temperature_comp)
end

function module.do_now()
    if temperature_busy == 0 then
        temperature_busy = 1
        ds:read_temp(on_ds_read, ds18b20_pin, nil, nil)
    end
end

function module.init(time, pin, compensation, callback)
    ds18b20_pin = pin
    mod_callback = callback
    temperature_comp = compensation
    if time ~= 0 then
    mod_timer = tmr.create()
        mod_timer:alarm(time, tmr.ALARM_AUTO, module.do_now)
    end
end

return module