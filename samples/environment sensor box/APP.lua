-- file : APP.lua
local module = {}  
local pin_sda = 3
local pin_scl = 4
local pin_jumper = 5    -- D5 jumper (low jumper) = CLI

-- config!
local SENSOR_TIME = 10      -- seconds!
local SDS_ON_TIME = 20      -- seconds!
local SDS_OFF_TIME = 580    -- seconds!
local time_sensors = 0
local time_sds = 0
local sds_sleeping = 1
local act_timer = nil

local mqtt_id = 6672
local mqtt_topic_lux =  "your_mqtt_path/lux"
local mqtt_topic_pir =  "your_mqtt_path/pir"
local mqtt_topic_pm =   "your_mqtt_path/pm"
local mqtt_topic_temp = "your_mqtt_path/temp"
local mqtt_topic_rh =   "your_mqtt_path/rh"


local function cb_lux(lux)
    mod_mqtt.send(mqtt_topic_lux, lux)
    print(lux.." lx")
end

local function cb_sds011(PM25, PM100)
    mod_mqtt.send(mqtt_topic_pm, "[\""..PM25.."\",\""..PM100.."\"]")
end

local function cb_sht3x(T,H)
    mod_mqtt.send(mqtt_topic_temp, T)
    mod_mqtt.send(mqtt_topic_rh, H)
    print(T.." C")
    print(H.." %RH")
end

local function act_timer_routine()
    if sds_sleeping == 1 then
        -- when sds sleeps, do sensors
        time_sensors = time_sensors + 1
        if time_sensors >= SENSOR_TIME then
            time_sensors = 0
            mod_1750.do_now()
            mod_sht3x.do_now()
        end
        time_sds = time_sds + 1
        if time_sds >= SDS_OFF_TIME then
            time_sds = 0
            sds_sleeping = 0
            if 1 == mod_io.input(pin_jumper) then
                mod_sds011.sleep(sds_sleeping)
            end
        end
    else
        time_sds = time_sds + 1
        if time_sds >= SDS_ON_TIME then
            time_sds = 0
            sds_sleeping = 1
            if 1 == mod_io.input(pin_jumper) then
                mod_sds011.sleep(sds_sleeping)
            end
        end
    end
end


-- callback when MQTT is connected
local function callback_mqtt()
end


-- callback on INITIAL wifi connect: start all required functionality
local function callback_connect()
end

function module.start()  
    _G.APP_Version = "2.3"
    _G.APP_Name = "SENSORBOX"
    mod_wifi.init(callback_connect)
    mod_mqtt.init(mqtt_id, callback_mqtt)
    
    mod_1750.init(0, pin_scl, pin_sda, cb_lux)          -- light measurement
    mod_sht3x.init(0, pin_scl, pin_sda, cb_sht3x)       -- temperature and humidity
    mod_sds011.init(0, cb_sds011)                       -- dust particles

    act_timer = tmr.create()
    act_timer:alarm(1000, tmr.ALARM_AUTO, act_timer_routine)

    -- start SDS if no jumper present
    if 1 == mod_io.input(pin_jumper) then
        mod_sds011.enable(1)
        mod_sds011.sleep(sds_sleeping)
    end
end

return module

