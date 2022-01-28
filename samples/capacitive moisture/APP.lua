-- file : APP.lua
local module = {}  

local mqtt_id = 6666
local mqtt_topic_adc =  "/your_mqtt_topic/moisture_adc"
local adc_val = 0
local sleep_timer

local function cb_adc(val)
    adc_val = val
end

local function sleep()
    node.dsleep(60000000) -- 60 seconds
end

-- callback when MQTT is connected
local function callback_mqtt()
    mod_mqtt.send(mqtt_topic_adc, adc_val)
    sleep_timer = tmr.create()
    sleep_timer:alarm(2000, tmr.ALARM_SINGLE, sleep)    
end


-- callback on INITIAL wifi connect: start all required functionality
local function callback_connect()
    mod_mqtt.init(mqtt_id, callback_mqtt)
end

function module.start()  
    _G.APP_Version = "2.1"
    _G.APP_Name = "PLANT"
    mod_wifi.init(callback_connect)
    mod_adc.init(1000, 5, cb_adc)
end

return module

