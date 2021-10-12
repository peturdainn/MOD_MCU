local module = {}  

local adc_value = {} -- array of measurements
local mod_timer
local mod_callback = nil
local adc_total = 1
local adc_count = 1
local adc_ready = 0

local function adc_measure()
    adc_value[adc_count] = adc.read(0)
    --print("ADC RAW "..adc_value[adc_count].." cnt "..adc_count.."/"..adc_total)
    adc_count = adc_count + 1
    if adc_count > adc_total then
        adc_count = 1
        adc_ready = 1
    end
    if adc_ready == 1 then
        local c
        local avg = 0
        for c = 1, adc_total do
            --print("#"..c.." "..adc_value[c])
            avg = avg + adc_value[c]
        end        
        mod_callback((avg + (adc_total / 2)) / adc_total)        
    end
end

-- API

function module.init(time, count, cb)
    -- select external ADC, if selection changed we must reboot
    if adc.force_init_mode(adc.INIT_ADC) then
      node.restart()
      return
    end
    mod_callback = cb
    adc_total = count
    mod_timer = tmr.create()
    mod_timer:alarm(time, tmr.ALARM_AUTO, adc_measure)    
end

return module

