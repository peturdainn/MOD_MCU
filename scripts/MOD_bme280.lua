local module = {}  

-- SETTINGS
OVERSAMPLING = 1     -- 1x oversampling
STANDBY_TIME = 6     -- 10s cycle
FILTER = 0           -- filter off
T_COMPENSATION = -80 -- n/100

-- GLOBALS
_G.I2CINIT = 0  -- for multiple I2C modules


local mod_timer
local mod_callback = nil


local function timer_handler()
    T, P, H = bme280.read()
    bme280.startreadout()
    if T ~= nil then
        T = T + T_COMPENSATION
        tu = T / 100
        td = (T - (tu * 100)) / 10
        hu = H / 1000
        hd = (H - (hu * 1000)) / 100
        pu = P / 1000
        pd = (P - (pu * 1000)) / 100 
        callback(tu, td, hu, hd, pu, pd)
    end
end

function module.init(time, scl, sda, cb)
    if _G.I2CINIT == 0 then
        i2c.setup(0, sda, scl, i2c.SLOW)
        _G.I2CINIT = 1
    end
    bme280.setup(OVERSAMPLING,OVERSAMPLING,OVERSAMPLING,0,STANDBY_TIME,FILTER)
    bme280.startreadout()
    mod_callback = cb
    mod_timer = tmr.create()
    mod_timer:alarm(time, tmr.ALARM_AUTO, timer_handler)
end

return module