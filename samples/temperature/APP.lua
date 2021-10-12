local module = {}  

local pin_temp = 1      -- D1

local mqtt_id = 6666
local mqtt_topic_temp = "/your_mqtt_topic/temp"

local temp_comp = 1     -- +0.1 degree (example)

-- callback on temperature measurement
local function cb_temp(temp)
    mod_mqtt.send(mqtt_topic_temp, temp)
end

-- callback when MQTT is connected
local function callback_mqtt()
end

-- callback on INITIAL wifi connect: start mqtt
local function callback_connect()
end

-- application start
function module.start()  
    _G.APP_Version = "2.1"
    _G.APP_Name = "TEST"    
    mod_wifi.init(callback_connect)
    mod_mqtt.init(mqtt_id, callback_mqtt)
    mod_ds18b20.init(5000,pin_temp,temp_comp,cb_temp)   -- temperature: pin 1, 5000ms interval
end

return module

