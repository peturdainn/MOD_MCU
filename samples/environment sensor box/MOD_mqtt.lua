local module = {}

-- CONFIG
cfg_mqtt = require("CFG_mqtt")  

local m = nil
local m_conn = nil    -- m connection reference in connect handler
local mqtt_is_connected = 0 -- 0 (not connected), 1 (connecting), 2 (connected)
local mqtt_id = 0
local mqtt_hb_tx = 0
local mqtt_hb_rx = -1
local mqtt_hb_tmo = 0
local mqtt_telemetry_cnt = 0
local mqtt_reconnect_cnt = 0

local mqtt_health_leaky_bucket = 0
local mqtt_timer -- dynamic timer object

local mqtt_kill -- forward declaration needed by mqtt_connect()
local mqtt_connect
local mqtt_subscribe

local sub_callback = nil
local con_callback = nil
local mqtt_sub_handler = nil


local function mqtt_subscribe(conn, topic, callback)
--    print("MQTT subscribing to "..topic)
    if callback ~= nil then
        sub_callback = callback    
    end
    conn:subscribe(topic, cfg_mqtt.MQTT_QOS_SUB, mqtt_sub_handler)
end


-- mqtt start and error handling: kill connection and (re)start
local function mqtt_kill()
    -- first kill the connection if it still exists
    mqtt_is_connected = 0
    --print("MQTT (re)start")
    m:close()
    mqtt_reconnect_cnt = mqtt_reconnect_cnt + 1
    mqtt_health_leaky_bucket = mqtt_health_leaky_bucket + 1
    --print("MQTT LB NOK "..mqtt_health_leaky_bucket)
    if mqtt_health_leaky_bucket > 10 then
        -- too many MQTT restarts
        node.restart()
    end
end

-- mqtt connect handler
local function mqtt_conn_handler(conn)
    m_conn = conn
    --print("MQTT connected")
    mqtt_is_connected = 2
    mqtt_subscribe(conn, cfg_mqtt.HEARTBEAT_TOPIC..mqtt_id, nil)
    module.send(cfg_mqtt.HEARTBEAT_TOPIC..mqtt_id, mqtt_hb_tx)
    mqtt_telemetry_cnt = cfg_mqtt.TELEMETRY + 1
    if con_callback ~= nil then
        con_callback()
    end
    m_conn = nil
end

-- mqtt error handler
--local function mqtt_err_handler(conn,reason)
--    mqtt_is_connected = 0
    --print("MQTT error "..reason)
--end

-- mqtt subscription handler
local function mqtt_sub_handler(conn, topic, data) 
    if topic == cfg_mqtt.HEARTBEAT_TOPIC..mqtt_id then
        if data ~= nil then
            mqtt_hb_rx = data + 0
        else
            mqtt_hb_rx = 0
        end
    elseif sub_callback ~= nil then
        m_conn = conn
        sub_callback(topic, data)
        m_conn = nil
    end
end

-- mqtt connect routine, tries to connect and reconnect
local function mqtt_manager()
    if mqtt_is_connected == 0 then  
        mqtt_is_connected = 1
        mqtt_hb_rx = mqtt_hb_tx
        mqtt_hb_tmo = 0
        -- register message callback beforehand
        m:on("message", mqtt_sub_handler)
        m:on("offline", mqtt_kill)       
        -- Connect to broker
        m:connect(cfg_mqtt.MQTT_HOST, cfg_mqtt.MQTT_PORT, false, mqtt_conn_handler, function(conn,reason) mqtt_is_connected = 0 end)
    elseif mqtt_is_connected == 2 then  
        if mqtt_hb_rx == mqtt_hb_tx then
            mqtt_hb_tmo = 0
            mqtt_hb_tx = mqtt_hb_tx + 1
            --send heartbeat
            module.send(cfg_mqtt.HEARTBEAT_TOPIC..mqtt_id, mqtt_hb_tx)
            --send telemetry
            mqtt_telemetry_cnt = mqtt_telemetry_cnt + 1
            if mqtt_telemetry_cnt > cfg_mqtt.TELEMETRY then
                mqtt_telemetry_cnt = 0
                module.send(cfg_mqtt.TELEMETRY_TOPIC..mqtt_id, "[\"".._G.MOD_Version.."\",\"".._G.APP_Version.."\",\""..wifi.sta.getip().."\",\""..mqtt_reconnect_cnt.."\",\""..node.heap().."\",\""..tmr.time().."\"]")
                --
                if mqtt_health_leaky_bucket > 0 then
                    mqtt_health_leaky_bucket = mqtt_health_leaky_bucket - 1
                    --print("MQTT LB OK "..mqtt_health_leaky_bucket)
                end
            end
        else
            mqtt_hb_tmo = mqtt_hb_tmo + 1
            if mqtt_hb_tmo > 3 then
                --print("MQTT hb miss (tx "..mqtt_hb_tx..", rx "..mqtt_hb_rx..")")
                mqtt_kill()
            --else
                --print("MQTT hb miss, retry")
            end 
        end
    else
        -- stuck in connecting?
        mqtt_health_leaky_bucket = mqtt_health_leaky_bucket + 1
        --print("MQTT LB NOK2 "..mqtt_health_leaky_bucket)
        if mqtt_health_leaky_bucket > 10 then
            -- too many MQTT restarts
            node.restart()
        end
    end
end

-- API

function module.send(topic, data)
    if mqtt_is_connected == 2 then
        m:publish(topic, tostring(data), cfg_mqtt.MQTT_QOS_PUB, 0)
    end
end

-- PUBLIC Sends my id to the broker for registration
function module.subscribe(topic, callback)  
    if mqtt_is_connected == 2 then
        if m_conn ~= nil then
            -- called from within the connection callback!
            mqtt_subscribe(m_conn, topic, callback)
        else
            mqtt_subscribe(m, topic, callback)
        end            
    end
end

function module.init(id, callback)
    mqtt_id = id
    m = mqtt.Client(mqtt_id, 30)
    con_callback = callback
    mqtt_timer = tmr.create()
    mqtt_timer:alarm(cfg_mqtt.MQTT_TIME, tmr.ALARM_AUTO, mqtt_manager)
    print("MQTT client "..id.." started")    
end


return module

