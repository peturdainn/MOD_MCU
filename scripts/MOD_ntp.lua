local module = {}  

-- SETTINGS
NTP_INTERVAL = 1000*60*60    -- sync every hour


local mod_timer -- dynamic timer object

-- THE ACTUAL TIME SYNC
local function sntp_sync()
    sntp.sync()
end

-- API (none)

function module.init()  
    print("NTP client started")
    sntp_sync()                                                     -- do one now
    mod_timer = tmr.create()
    mod_timer:alarm(NTP_INTERVAL, tmr.ALARM_AUTO, sntp_sync)        -- and then every hour
end

return module

