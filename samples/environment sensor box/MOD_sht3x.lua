local module = {}  

-- CONFIG: see protocol function

-- GLOBALS
_G.I2CINIT = 0  -- for multiple I2C modules


local mod_callback = nil
local mod_timer = nil

local operation_seq = 0


local function sht3x_protocol(tx_string, rx_size)
    local sla = 0x44    -- I2C address of SHT3x
    local bus_id = 0
    i2c.start(bus_id)
    if (i2c.address(bus_id, sla, i2c.TRANSMITTER)) then
        i2c.write(bus_id, tx_string)
        i2c.stop(bus_id)
        if rx_size > 0 then
            i2c.start(bus_id)
            i2c.address(bus_id, sla, i2c.RECEIVER)
            response = i2c.read(bus_id, rx_size)
            i2c.stop(bus_id)
            -- answer is either 3 or 6 bytes...
            if 3 == rx_size then
                return (string.byte(response, 1) * 256) + string.byte(response, 2)
            end
            if 6 == rx_size then
                w1 = (string.byte(response, 1) * 256) + string.byte(response, 2)
                w2 = (string.byte(response, 4) * 256) + string.byte(response, 5)
                return w1,w2
            end
        end 
    end
    return nil
end    


local function sht3x_start()
--    sht3x_protocol(string.char(0x20,0x24),0)  -- 0x2024 = medium repeatability, 0.5 measurements per second
--    sht3x_protocol(string.char(0x20,0x32),0)  -- 0x2032 = high repeatability, 0.5 measurements per second    
    sht3x_protocol(string.char(0x21,0x30),0)  -- 0x2130 = high repeatability, 1 measurement per second
--    sht3x_protocol(string.char(0x22,0x36),0)  -- 0x2236 = high repeatability, 2 measurements per second
end


local function sht3x_stop()
    sht3x_protocol(string.char(0x30,0x93),0)    -- BREAK command
    sht3x_protocol(string.char(0x30,0x41),0)    -- clear status :)
end


--local function sht3x_status()
--    local response
--    response = sht3x_protocol(string.char(0xF3,0x2D),3)
--    print(string.format("0x%x",response))     -- debug: dump status register
--end

function module.do_now()
    local w1,w2,TEMP,RH
    w1,w2 = sht3x_protocol(string.char(0xE0,0x00),6)
    if (w1 ~= nil) and (w1 ~= 0) then
        --print("raw T "..w1.." H "..w2)
        TEMP = (((w1 * 1750) + 32767) / 65535) - 450    -- convert to 0.1 degree units
        RH = ((w2 * 100) + 32767) / 65535
        mod_callback(TEMP, RH)
    end
end


local function timer_handler(tmr)
    if 0 == operation_seq then
        -- normal operation starts here
        sht3x_stop()
        operation_seq = 1
    elseif 1 == operation_seq then
        -- startup normal measurements
        sht3x_start()
        operation_seq = 2
    elseif 2 == operation_seq then
        -- normal measuring operations loop
        module.do_now()
    end
end


-- API

function module.init(time, scl, sda, cb_data)
    if _G.I2CINIT == 0 then
        i2c.setup(bus_id, sda, scl, i2c.SLOW)
        _G.I2CINIT = 1
    end
    mod_callback = cb_data
    if time ~= 0 then
        mod_timer = tmr.create()
        mod_timer:alarm(time, tmr.ALARM_AUTO, timer_handler)
    else
        sht3x_stop()
        sht3x_start()
    end        
end

return module

