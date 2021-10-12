local module = {}

module.MQTT_HOST = "192.168.1.19"  
module.MQTT_PORT = 1883
module.MQTT_QOS_SUB = 2     -- QoS when subscribing
module.MQTT_QOS_PUB = 2     -- QoS when publishing

module.MQTT_TIME = 10000	-- MQTT management every 10 seconds
module.TELEMETRY = 6        -- x MQTT_TIME so 60 seconds

module.TELEMETRY_TOPIC = "/NodeTelemetry/"
module.HEARTBEAT_TOPIC = "/NodeHB/"

return module  
