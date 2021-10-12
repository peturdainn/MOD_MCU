local module = {}

module.WIFI_AP_SETUP = {}
module.WIFI_AP_SETUP.ip = "10.10.10.10"
module.WIFI_AP_SETUP.netmask="255.255.255.0"
module.WIFI_AP_SETUP.gateway="10.10.10.10"

module.WIFI_AP_DHCP = {}
module.WIFI_AP_DHCP.start = "10.10.10.100"

module.WIFI_AP_CFG = {}
module.WIFI_AP_CFG.ssid="YOUR_SSID"
module.WIFI_AP_CFG.pwd="YOUR_PASSWORD"

return module  
