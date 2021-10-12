local module = {}  

local pin_scl = 5 --yellow
local pin_sda = 4 --green

local mqtt_id = 6666
local mqtt_topic_co2 =   "/your_mqtt_topic/co2"
local mqtt_topic_temp =  "/your_mqtt_topic/temp"
local mqtt_topic_rh =    "/your_mqtt_topic/rh"

-- CO2 measurement callback
local function callback_co2(co2,temp,rh)
    --print("CO2 "..co2.." temp "..temp.." RH "..rh.." mem "..node.heap())
    mod_mqtt.send(mqtt_topic_co2, co2)
    mod_mqtt.send(mqtt_topic_temp, temp)
    mod_mqtt.send(mqtt_topic_rh, rh)
end

-- callback when MQTT is connected
local function callback_mqtt()

end

-- callback on INITIAL wifi connect
local function callback_connect()
end

function module.start()  
    _G.APP_Version = "2.1"
    _G.APP_Name = "TEST"    
    mod_wifi.init(callback_connect)
    mod_mqtt.init(mqtt_id, callback_mqtt)
    mod_scd4x.init(5000,pin_scl,pin_sda,callback_co2) -- measure every 5 seconds
end

return module
