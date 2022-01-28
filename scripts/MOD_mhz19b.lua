local module = {}  

-- state constants
-- 0 = init
-- 1 = locked
-- 2 = unlocked
local parser_state = 0

local mod_callback = nil
local mod_timer

local function request_measurement()
    uart.write(1, string.char(0xFF,0x01,0x86,0x00,0x00,0x00,0x00,0x00,0x79))
end


local function uart_rx(data)
    local dlen = string.len(data)
 
    if parser_state == 1 then
        -- synced state
        if dlen == 9 then
            local CMD = string.byte(data, 2)
            if CMD == 0x86 then
                PPM = string.byte(data, 4) + (string.byte(data, 3) * 256)
                mod_callback(PPM)
            end
        end
    else
        if dlen >= 9 then
            if 0xFF == string.byte(data, dlen-8) then
                parser_state = 1
            end
        end
    end        
end

-- API
    
function module.enable(on)
    if on == 1 then
        if parser_state == 0 then
            parser_state = 2
            uart.setup(0, 9600, 8, uart.PARITY_NONE, uart.STOPBITS_1, 0)
            uart.setup(1, 9600, 8, uart.PARITY_NONE, uart.STOPBITS_1, {tx = 16, rx = 17})
            uart.on("data",9,uart_rx, 0)         
        end
        mod_timer = tmr.create()
        mod_timer:alarm(10000, tmr.ALARM_AUTO, request_measurement)
    end
end

function module.init(start, cb)
    mod_callback = cb
    module.enable(start)
end

return module