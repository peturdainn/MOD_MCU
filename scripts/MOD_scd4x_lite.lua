local module = {}  

-- CONFIG
local sla = 0x62    -- I2C address of SCD4x
local bus_id = 0

-- GLOBALS
_G.I2CINIT = 0  -- for multiple I2C modules


local callback
local operations_timer
local operation_seq = 0


local function scd4x_protocol(tx_string, rx_size)
    i2c.start(bus_id)
    if (i2c.address(bus_id, sla, i2c.TRANSMITTER)) then
        i2c.write(bus_id, tx_string)
        i2c.stop(bus_id)
        if rx_size > 0 then
            i2c.start(bus_id)
            i2c.address(bus_id, sla, i2c.RECEIVER)
            response = i2c.read(bus_id, rx_size)
            i2c.stop(bus_id)
            -- answer is either 3 or 9 bytes!
            if 3 == rx_size then
                return (string.byte(response, 1) * 256) + string.byte(response, 2)
            end
            if 9 == rx_size then
                w1 = (string.byte(response, 1) * 256) + string.byte(response, 2)
                w2 = (string.byte(response, 4) * 256) + string.byte(response, 5)
                w3 = (string.byte(response, 7) * 256) + string.byte(response, 8)
                return w1,w2,w3
            end
        end 
    end
    return nil
end    


local function scd4x_start()
    scd4x_protocol(string.char(0x21,0xB1),0)
end


local function scd4x_stop()
    scd4x_protocol(string.char(0x3F,0x86),0)
end


local function scd4x_is_ready()
    response = scd4x_protocol(string.char(0xE4,0xB8),3)
    if (response ~= nil) and (response ~= 0x8000) then
        return 1
    end
    return 0
end

local function scd4x_get_measurements()
    w1,w2,w3 = scd4x_protocol(string.char(0xEC,0x05),9)
    if (w1 ~= nil) and (w1 ~= 0) then
        CO2 = w1
        TEMP = (w2 * 175 / 65536) - 45
        RH = w3 * 100 / 65536
        callback(CO2, TEMP, RH)
    end
end


local function timer_handler(tmr)
    if 0 == operation_seq then
        -- normal operation starts here
        scd4x_stop()
        operation_seq = 1
    elseif 1 == operation_seq then
        -- startup normal measurements
        scd4x_start()
        operation_seq = 2
    elseif 2 == operation_seq then
        -- normal measuring operations loop
        if 1 == scd4x_is_ready() then
            scd4x_get_measurements()
        end
    end
end


-- API

function module.init(time, scl, sda, cb_data)
    if _G.I2CINIT == 0 then
        i2c.setup(bus_id, sda, scl, i2c.SLOW)
        _G.I2CINIT = 1
    end
    callback = cb_data
    if time <= 0 then time = 5000 end
    operations_timer = tmr.create()
    operations_timer:alarm(time, tmr.ALARM_AUTO, timer_handler)
end

return module

