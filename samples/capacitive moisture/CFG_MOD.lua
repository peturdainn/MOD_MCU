-- NodeMCU lua modules for quickly building apps
-- (c) 2022 Peter D'Hoye @peturdainn

_G.MOD_Version = "2.1"
_G.APP_Version = ""  	-- set in your app
_G.APP_Name = ""     	-- set in your app
mod_mqtt = require("MOD_mqtt")
mod_wifi = require("MOD_wifi")
mod_adc = require("MOD_adc")
