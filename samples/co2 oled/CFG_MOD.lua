-- NodeMCU lua modules for quickly building apps
-- (c) 2021 Peter D'Hoye @peturdainn

_G.MOD_Version = "2.1"
_G.APP_Version = ""  	-- set in your app
_G.APP_Name = ""     	-- set in your app

-- enable modules as required

--mod_1750 = require("MOD_1750")
--mod_adc = require("MOD_ADC")
--mod_bme280 = require("MOD_bme280")
--mod_ds18b20 = require("MOD_ds18b20")
--mod_http = require("MOD_http")  
--mod_io = require("MOD_io")  
--mod_io = require("MOD_io_lite")  
--mod_led = require("MOD_led")
--mod_mhz19b = require("MOD_mhz19b")
--mod_mqtt = require("MOD_mqtt")
--mod_ntp = require("MOD_ntp")  
mod_oled = require("MOD_oled")
--mod_scd4x = require("MOD_scd4x")
mod_scd4x = require("MOD_scd4x_lite")
--mod_sds011 = require("MOD_sds011")
--mod_telnet = require("MOD_telnet")
--mod_wiegand = require("MOD_wiegand")  
--mod_wifi = require("MOD_wifi")
--mod_wifi_ap = require("MOD_wifi_ap")
