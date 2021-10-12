-- Single IO via interrupt and then debounces them
-- Part of MOD_LUA by Peter D'Hoye @peturdainn

local module = {}  

local io_callback = nil         -- fn(pin, state, time)
local io_pin                    -- IO pin number to watch
local io_timer                  -- timer for io
local io_stable                 -- last known stable value
local io_time                   -- stable duration
local io_idleping               -- time to call callback even if no change
local io_cfg_idleping           -- time to call callback even if no change
local io_cfg_debouncetime       -- debounce time check

local function pin_timer(debouncing)
   -- kill timer, if pin steady start idle timer
   -- if debouncing, set time = 0, else time += idle
    io_timer:unregister()
    if debouncing then
       if io_stable ~= gpio.read(io_pin) then
            -- changed! reset idle counters to zero
            io_stable = gpio.read(io_pin)
            io_time = 0
            io_idleping = 0
            io_callback(io_pin, io_stable, io_time)
        end
    else
        if io_cfg_idleping > 0 then 
            -- we want idle callbacks, count the seconds
            io_idleping = io_idleping + 1
            if io_idleping >= io_cfg_idleping then
--                print("idle")
                -- we reached the configured idle seconds
                io_time = io_time + io_cfg_idleping
                io_idleping = 0
                io_callback(io_pin, io_stable, io_time)
            end
        end
    end
    -- always restart idle timer!
    io_timer:alarm(1000, tmr.ALARM_SINGLE, function() pin_timer(0) end)
end


local function pin_change_int()
    -- kill timer, start debounce timer
    io_timer:unregister()
    io_timer:alarm(io_cfg_debouncetime, tmr.ALARM_SINGLE, function() pin_timer(1) end)
end

-- API

-- add io pin to watchlist
function module.watch(pin, debounce, idle)
    io_pin = pin
    io_timer = tmr.create()
    io_stable = gpio.read(pin)
    io_time = 0
    io_idleping = 0
    io_cfg_idleping = idle
    io_cfg_debouncetime = debounce
    -- prep            
    gpio.mode(pin, gpio.INT, gpio.PULLUP)
    gpio.trig(pin, "both", pin_change_int)
    io_timer:alarm(1000, tmr.ALARM_SINGLE, function() pin_timer(0) end)
    --            print("Watching IO pin "..pin.." (id "..io..") debounced "..debounce.."ms")
end


function module.input(pin)
    gpio.mode(pin, gpio.INPUT)
    if gpio.LOW == gpio.read(pin) then
        return 0
    else
        return 1
    end
end


function module.output(pin,value)
    gpio.mode(pin, gpio.OUTPUT)
    if value == 0 then
        gpio.write(pin, gpio.LOW)
    else
        gpio.write(pin, gpio.HIGH)
    end
end


function module.init(callback)
    io_callback = callback
end

return module

