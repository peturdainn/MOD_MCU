local module = {}

-- CONFIG
cfg_wifi_ap = require("CFG_wifi_ap")  

local mod_timer -- dynamic timer object

local mod_callback = nil

local function wifi_wait_ip()  
    mod_timer:stop()
    mod_timer = nil
    mod_callback()
end

function module.init(cb)
    mod_callback = cb
    print("Setting up Wifi ...")
    wifi.setmode(wifi.SOFTAP)
    wifi.ap.setip(cfg_wifi_ap.WIFI_AP_SETUP)
    wifi.ap.dhcp.config(cfg_wifi_ap.WIFI_AP_DHCP)
    wifi.ap.config(cfg_wifi_ap.WIFI_AP_CFG)
    wifi.ap.dhcp.start()
    mod_timer = tmr.create()
    mod_timer:alarm(1000, tmr.ALARM_AUTO, wifi_wait_ip)
end

return module  
