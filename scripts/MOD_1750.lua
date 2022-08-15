local module = {}  

-- GLOBALS
_G.I2CINIT = 0  -- for multiple I2C modules

-- CONFIG
local sla = 0x23    -- I2C address of 1750
local bus_id = 0

local mod_callback = nil
local mod_timer = nil

function module.do_now()
    local data,lux
    i2c.start(bus_id)
    i2c.address(bus_id, sla,i2c.RECEIVER)
    data = i2c.read(bus_id, 2)
    i2c.stop(bus_id)
    lux = (data:byte(1) * 256 + data:byte(2)) * 1000 / 12
    if data:byte(1) ~= 255 or data:byte(2) ~= 255 then
        mod_callback(lux)
    end
end

function module.init(time, scl, sda, cb)
    if _G.I2CINIT == 0 then
        i2c.setup(bus_id, sda, scl, i2c.SLOW)
        _G.I2CINIT = 1
    end
    mod_callback = cb
    -- start continuous hi-res measurement 
    i2c.start(bus_id)
    i2c.address(bus_id, sla, i2c.TRANSMITTER)
    i2c.write(bus_id, 0x10)
    i2c.stop(bus_id)

    if time ~= 0 then
        mod_timer = tmr.create()
        mod_timer:alarm(time, tmr.ALARM_AUTO, module.do_now)    
    end
end

return module
