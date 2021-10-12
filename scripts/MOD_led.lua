local module = {}  

-- CONFIG
cfg_led = require("CFG_led")  

local LED_ON = gpio.LOW
local LED_OFF = gpio.HIGH

local ledvalue = {} -- last state


local function led_validate(lednr)
    if lednr < 1 then
        lednr = 1
    end
    if lednr > cfg_led.LED_COUNT then
        lednr = cfg_led.LED_COUNT
    end
    return lednr
end

--API

function module.led_on(lednr)
    -- switch a led on
    lednr = led_validate(lednr)
    ledvalue[lednr] = LED_ON
    gpio.write(cfg_led.LED_PINS[lednr], ledvalue[lednr])
end

function module.led_off(lednr)
    -- switch a led off
    lednr = led_validate(lednr)
    ledvalue[lednr] = LED_OFF
    gpio.write(cfg_led.LED_PINS[lednr], ledvalue[lednr])
end

function module.led_toggle(lednr)
    -- toggle a led
    lednr = led_validate(lednr)
    if ledvalue[lednr] == LED_OFF then
        ledvalue[lednr] = LED_ON
    else
        ledvalue[lednr] = LED_OFF
    end
    gpio.write(cfg_led.LED_PINS[lednr], ledvalue[lednr])
end

function module.init()
    for lednr = 1, cfg_led.LED_COUNT do
       	gpio.mode(cfg_led.LED_PINS[lednr], gpio.OUTPUT)
        ledvalue[lednr] = LED_OFF
        l_led_off(lednr)
    end
end

return module

