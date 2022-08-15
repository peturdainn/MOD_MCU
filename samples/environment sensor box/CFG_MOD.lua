-- NodeMCU lua modules for quickly building apps
-- (c) 2022 Peter D'Hoye @peturdainn

_G.MOD_Version = "2.3"
_G.APP_Version = ""  	-- set in your app
_G.APP_Name = ""     	-- set in your app
mod_io = require("MOD_io_lite")  
mod_mqtt = require("MOD_mqtt")
mod_wifi = require("MOD_wifi")
mod_1750 = require("MOD_1750")
mod_sds011 = require("MOD_sds011")
mod_sht3x = require("MOD_sht3x")
