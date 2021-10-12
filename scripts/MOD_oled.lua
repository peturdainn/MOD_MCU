local module = {}  

-- GLOBALS
_G.I2CINIT = 0

local sla = 0x3c        -- I2C address of display
local bus_id = 0        -- I2C bus number
local lineoffset = {0, 5}
local hasframe = 0

local function line2pixel(l)
    return 14 + (l * 15)    
end


-- API

function module.update()
    disp:sendBuffer()
end

function module.clearscreen()
    hasframe = 0
    disp:clearBuffer()
end

function module.textline(line, text)
    disp:drawUTF8(lineoffset[hasframe+1], line2pixel(line), text)
end

function module.drawframe(x, y, w, h)
    hasframe = 1
    disp:setDrawColor(1)
    disp:drawRFrame(x, y, w, h, 5)  
end

function module.drawprogress(x, y, w, h, percent)
    disp:setDrawColor(1)
    disp:drawRFrame(x, y, w, h, 4) -- outer shell
    w = w * percent / 100
    if w < 8 then w = 8 end
    disp:drawRBox(x+1, y+1, w, h-1, 3)
end

function module.orientation(val)
    if val == "0" then
       disp:setDisplayRotation(u8g2.R0)
    elseif val == "90" then
       disp:setDisplayRotation(u8g2.R1)
    elseif val == "180" then
       disp:setDisplayRotation(u8g2.R2)
    elseif val == "270" then
       disp:setDisplayRotation(u8g2.R3)
    elseif val == "MIRROR" then
       disp:setDisplayRotation(u8g2.MIRROR)
    end
end


function module.init(scl, sda)
    if _G.I2CINIT == 0 then
        i2c.setup(bus_id, sda, scl, i2c.SLOW)
        _G.I2CINIT = 1
    end
    disp = u8g2.ssd1306_i2c_128x64_noname(bus_id, sla)
    disp:setFont(u8g2.font_9x15B_tf)
    disp:setFontMode(1)
end

return module