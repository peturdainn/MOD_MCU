local module = {}  

-- CONFIG
local sla = 0x62    -- I2C address of SCD4x
local bus_id = 0

-- GLOBALS
_G.I2CINIT = 0  -- for multiple I2C modules


local callback
local callback_comm
local operations_timer
local operation_seq = 0
local calibration_seq = -1
local calibration_seq_action -- calculated count of timer to assure 3 minute measuring before calibration


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


local function scd4x_factoryreset()
    scd4x_protocol(string.char(0x36,0x32),0)
end

-- calculate CRC manually:
-- http://www.sunshine2k.de/coding/javascript/crc/crc_js.html
-- Poly 0x31, initial 0xFF, final 0x00, non-reflected
local function scd4x_force_recalib()
    response = scd4x_protocol(string.char(0x36,0x2F,0x01,0xA0,0x89),3) -- 416ppm
    if (response ~= nil) and (response ~= 0xFFFF) then
        return response - 0x8000
    else
        return -1
    end
end


local function scd4x_is_ready()
    response = scd4x_protocol(string.char(0xE4,0xB8),3)
    if (response ~= nil) and (response ~= 0x8000) then
        return 1
    end
    return 0
end


--[[
local function scd4x_check_ASC()
    response = scd4x_protocol(string.char(0x23,0x13),3)
    if (response ~= nil) and (response == 1) then
        print("ASC is ON")
    else
        print("ASC is OFF or error")
    end
end


local function scd4x_enable_ASC()
    response = scd4x_protocol(string.char(0x24,0x16,0x00,0x01,0xB0),0)
end
--]]


local function scd4x_get_measurements()
    w1,w2,w3 = scd4x_protocol(string.char(0xEC,0x05),9)
    if (w1 ~= nil) and (w1 ~= 0) then
        CO2 = w1
        TEMP = (w2 * 175 / 65536) - 45
        RH = w3 * 100 / 65536
        callback(CO2, TEMP, RH)
    end
end


local function calibration_sequence()
    callback_comm(calibration_seq)   
    if calibration_seq == 0 then
        scd4x_start()
    elseif calibration_seq < calibration_seq_action then
        -- measure for >3 minutes
        scd4x_get_measurements()
    elseif calibration_seq == calibration_seq_action then
        -- stop
        scd4x_stop()
    elseif calibration_seq == (calibration_seq_action + 1) then
        -- recalibrate
        retval = scd4x_force_recalib()
        callback_comm(retval)    
        calibration_seq = -666
    end
    calibration_seq = calibration_seq + 1
end


local function timer_handler(tmr)
    --print(operation_seq.." "..calibration_seq)
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
    elseif 3 == operation_seq then
        -- factory reset starts here
        scd4x_stop()
        operation_seq = 4
    elseif 4 == operation_seq then
        -- factory reset
        scd4x_factoryreset()
        operation_seq = 0
    elseif 5 == operation_seq then
        -- manual calibration starts here
        calibration_seq = 0
        operation_seq = 6
        calibration_sequence()
    elseif 6 == operation_seq then
        -- manual calibration
        calibration_sequence()
        if 0 > calibration_seq then
            operation_seq = 0
        end
    end
end


-- API

function module.command(cmd)
    if cmd == "RECALIB" then operation_seq = 5 end
    if cmd == "FACTORYRST" then operation_seq = 3 end
end
    
function module.init(time, scl, sda, cb_data,cb_comm)
    if _G.I2CINIT == 0 then
        i2c.setup(bus_id, sda, scl, i2c.SLOW)
        _G.I2CINIT = 1
    end
    callback = cb_data
    callback_comm = cb_comm
    if time <= 0 then time = 5000 end
    calibration_seq_action = 3*60*1000 / time
    operations_timer = tmr.create()
    operations_timer:alarm(time, tmr.ALARM_AUTO, timer_handler)
end

return module

