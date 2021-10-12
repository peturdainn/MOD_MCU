local module = {}

-- CONFIG
cfg_wifi = require("CFG_wifi")  

local mod_timer -- dynamic timer object

local mod_callback = nil

local function wifi_wait_ip()  
    if wifi.sta.getip()== nil then
        print("IP?")
    else
        mod_timer:unregister()
        mod_timer = nil
        print("IP: "..wifi.sta.getip())
--        print("MAC: " .. wifi.ap.getmac())
        if mod_callback ~= nil then
            mod_callback()
        end
    end
end

function module.init(cb)
    mod_callback = cb
    wifi.setmode(wifi.STATION)
    wifi.sta.config(cfg_wifi.WIFICFG)
    mod_timer = tmr.create()
    mod_timer:alarm(1000, tmr.ALARM_AUTO, wifi_wait_ip)
end

return module  
