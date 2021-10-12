local module = {}  


local mod_callback = nil    -- fn(code_as_number)
local bit_timer = nil       -- dynamic timer object
   
-- the wiegand input pins
local pin_D0 = -1
local pin_D1 = -1

local wg_code = 0

-- timeout waiting for a wiegand bit
local function wg_bit_tmo()
    bit_timer:stop()
    bit_timer:unregister()
    mod_callback(wg_code)    -- report received code
    wg_code = 0
    bit_timer:register(15, tmr.ALARM_SINGLE, wg_bit_tmo)
end

-- IRQ handler bit zero
local function rx_bit0()
    bit_timer:stop()
    wg_code = (wg_code * 2) + 0
    gpio.trig(wg_D0, "down", rx_bit0)
    bit_timer:start()
end

-- IRQ handler bit one
local function rx_bit1()
    bit_timer:stop()
    wg_code = (wg_code * 2) + 1
    gpio.trig(wg_D1, "down", rx_bit1)
    bit_timer:start()
end


-- API

function module.enable(ena)
    if ena == 0 then
        gpio.mode(wg_D0, gpio.INPUT)
        gpio.mode(wg_D1, gpio.INPUT)
    else
        wg_code = 0
        gpio.mode(wg_D0, gpio.INT)
        gpio.mode(wg_D1, gpio.INT)
        gpio.trig(wg_D0, "down", rx_bit0)
        gpio.trig(wg_D1, "down", rx_bit1)
    end
    bit_timer:stop()
end


function module.init(D0_pin, D1_pin, cb)
    if bit_timer ~= nil then
        -- cleanup first
        bit_timer:unregister()
        bit_timer = nil
    end
    mod_callback = cb
    wg_D0 = D0_pin
    wg_D1 = D1_pin
    bit_timer = tmr.create()
    bit_timer:register(15, tmr.ALARM_SINGLE, wg_bit_tmo)
end

return module

