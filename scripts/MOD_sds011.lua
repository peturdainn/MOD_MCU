local module = {}  

local PM25_E = 0
local PM100 = 0

local PM25_E = 0
local PM25_D = 0
local PM100_E = 0
local PM100_D = 0

local state_notinit = 0

-- state constants
local STATE_NOTINIT =  0
local STATE_LOCKED =   1
local STATE_UNLOCKED = 2
local STATE_SLEEPING = 3

local parser_state = STATE_NOTINIT

local mod_callback = nil

local function uart_rx(data)
    dlen = string.len(data)
    if parser_state == STATE_LOCKED then
        -- synced state
        if dlen == 10 then
            CMD = string.byte(data, 2)
            if CMD == 0xC0 then
                PM25 = string.byte(data, 3) + (string.byte(data, 4) * 256)
                PM100 = string.byte(data, 5) + (string.byte(data, 6) * 256)
                PM25_E = PM25 / 10
                PM25_D = PM25 - (PM25_E * 10)
                PM100_E = PM100 / 10
                PM100_D = PM100 - (PM100_E * 10)
                mod_callback(PM25_E, PM25_D, PM100_E, PM100_D)
            end
        end
    else
        if dlen >= 10 then
            if 0xAA == string.byte(data, dlen-9) then
                parser_state = STATE_LOCKED
                uart.on("data")         
                uart.on("data",10,uart_rx, 0)         
            end
        end
    end        
end

-- API

    
function module.enable(on)
    if on == 1 then
        if parser_state == 0 then
            parser_state = STATE_UNLOCKED
            print("SDS011 is go")
            node.output(function(nodestr) end, 0) -- kill node output on UART TX !
            uart.setup(0, 9600, 8, uart.PARITY_NONE, uart.STOPBITS_1, 0)
            uart.on("data","\171",uart_rx, 0)         
        end
    end
end

function module.sleep(go_to_sleep)
    work = 0x00
    csum = 0x05 --0x205
    if 0 == go_to_sleep then
        work = 0x01
        csum = 0x06 --0x206
    end
    uart.write(0, string.char(0xAA,0xB4,0x06,0x01,work,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0xFF,0xFF,csum,0xAB))
end


function module.init(start, cb)
    mod_callback = cb
    module.enable(start)
end

return module