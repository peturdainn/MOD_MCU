-- Watches IO via interrupt and then debounces them
-- Part of MOD_LUA by Peter D'Hoye @peturdainn

local module = {}  

local io_count = 1              -- set during init
local io_callback = nil         -- fn(pin, state, time)
local io_pin = {}               -- list of IO pin numbers to watch
local io_timer = {}             -- list of timers, one for each io
local io_stable = {}            -- last known stable value
local io_time = {}              -- stable duration
local io_idleping = {}          -- time to call callback even if no change
local io_cfg_idleping = {}      -- time to call callback even if no change
local io_cfg_debouncetime = {}  -- debounce time check

local function pin_timer(io, debouncing)
   -- kill timer, if pin steady start idle timer
   -- if debouncing, set time = 0, else time += idle
    io_timer[io]:unregister()
    if 0 < debouncing then
        io_now = gpio.read(io_pin[io])        
        if io_stable[io] ~= io_now then
            -- changed! reset idle counters to zero
            io_stable[io] = io_now
            io_time[io] = 0
            io_idleping[io] = 0
            io_callback(io_pin[io], io_stable[io], io_time[io])
        end
    else
        if io_cfg_idleping[io] > 0 then 
            -- we want idle callbacks, count the seconds
            io_idleping[io] = io_idleping[io] + 1
            if io_idleping[io] >= io_cfg_idleping[io] then
--                print("idle")
                -- we reached the configured idle seconds
                io_time[io] = io_time[io] + io_cfg_idleping[io]
                io_idleping[io] = 0
                io_callback(io_pin[io], io_stable[io], io_time[io])
            end
        end
    end
    -- always restart idle timer!
    io_timer[io]:alarm(1000, tmr.ALARM_SINGLE, function() pin_timer(io, 0) end)
end


local function pin_change_int(io)
    -- kill timer, start debounce timer
    io_timer[io]:unregister()
    io_timer[io]:alarm(io_cfg_debouncetime[io], tmr.ALARM_SINGLE, function() pin_timer(io, 1) end)
end

-- API

-- add io pin to watchlist
function module.watch(pin, debounce, idle)
    local io
    for io = 1, io_count do
        if io_pin[io] == -1 then
            io_pin[io] = pin
            io_timer[io] = tmr.create()
            gpio.mode(pin, gpio.INPUT)
            io_stable[io] = gpio.read(pin)
            io_time[io] = 0
            io_idleping[io] = 0
            io_cfg_idleping[io] = idle
            io_cfg_debouncetime[io] = debounce
            -- prep            
        	gpio.mode(pin, gpio.INT, gpio.PULLUP)
            gpio.trig(pin, "both", function() pin_change_int(io) end)
            io_timer[io]:alarm(1000, tmr.ALARM_SINGLE, function() pin_timer(io, 0) end)
--            print("Watching IO pin "..pin.." (id "..io..") debounced "..debounce.."ms")
            break
        end
    end
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


function module.init(count_, callback)
    io_count = count_
    io_callback = callback
    local io
    for io = 1, io_count do
        io_pin[io] = -1
    end
end

return module

