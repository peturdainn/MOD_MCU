local module = {}  

local pin_scl = 5   -- yellow
local pin_sda = 4   -- green

-- CO2 measurement callback
local function callback_co2(co2,temp,rh)
--    print("CO2 "..co2.." temp "..temp.." RH "..rh.." mem "..node.heap())
    mod_oled.clearscreen()
    mod_oled.textline(0,"CO2: "..co2.." PPM")
    mod_oled.textline(1,"T:   "..temp.."°C")
    mod_oled.textline(2,"RH:  "..rh.."%")
    mod_oled.update()
end


function module.start()  
    _G.APP_Version = "1.0"
    _G.APP_Name = "CO2"
    print("CO2 Measure Box")
    print("(c) petur@lunda.be")
    print("VER: ".._G.APP_Version)
    print("MOD: ".._G.MOD_Version)
  
    mod_oled.init(pin_scl, pin_sda)
    mod_oled.clearscreen()
    mod_oled.textline(0,"Ver: A".._G.APP_Version.." M".._G.MOD_Version)
    mod_oled.textline(2,"(c) 2021")
    mod_oled.textline(3,"@peturdainn")
    mod_oled.update()

    mod_scd4x.init(10000,pin_scl,pin_sda,callback_co2)

end

return module


