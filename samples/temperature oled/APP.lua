-- file : APP.lua
local module = {}  
local pin_temp = 4      -- D4

local pin_scl = 5  
local pin_sda = 6  


local function cb_temp(temp)
    print(temp)
    e = temp / 10
    f = temp - (e * 10)
    mod_oled.clearscreen()
    mod_oled.textline(0,"Temperature:")
    mod_oled.textline(3,"    "..e.."."..f.." °C")
    mod_oled.update()
end

-- callback on wifi connect: start all required functionality
local function callback_connect()
    print("WIFI CONNECTED")
    print("APP: ".._G.APP_Name)
    print("VER: ".._G.APP_Version)
    print("MOD: ".._G.MOD_Version)
end

function module.start()  
    _G.APP_Version = "2.3"
    _G.APP_Name = "TEMP"
    mod_oled.init(pin_scl, pin_sda)
    mod_oled.clearscreen()
    mod_oled.textline(0,"STARTING")
    mod_oled.textline(3,"@peturdainn")
    mod_oled.update()

    mod_ds18b20.init(1000,pin_temp,0,cb_temp)
end

return module

