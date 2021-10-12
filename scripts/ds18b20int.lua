--------------------------------------------------------------------------------
-- DS18B20 one wire module for NODEMCU
-- NODEMCU TEAM
-- LICENCE: http://opensource.org/licenses/MIT
-- @voborsky, @devsaurus, TerryE  26 Mar 2017
--------------------------------------------------------------------------------
local modname = ...

local conversion

local DS18B20FAMILY   = 0x28
local DS1920FAMILY    = 0x10  -- and DS18S20 series
local CONVERT_T       = 0x44
local READ_SCRATCHPAD = 0xBE
local READ_POWERSUPPLY= 0xB4
local MODE = 1

local pin, cb, unit = 3
local status = {}

--------------------------------------------------------------------------------
-- Implementation
--------------------------------------------------------------------------------

local function to_string(addr, esc)
  if type(addr) == 'string' and #addr == 8 then
    return ( esc == true and
             '"\\%u\\%u\\%u\\%u\\%u\\%u\\%u\\%u"' or
             '%02X:%02X:%02X:%02X:%02X:%02X:%02X:%02X '):format(addr:byte(1,8))
  else
    return tostring(addr)
  end
end

local function readout(self)
  local next = false
  local sens = self.sens
  local temp = self.temp
  for i, s in ipairs(sens) do
    if status[i] == 1 then
      ow.reset(pin)
      local addr = s:sub(1,8)
      ow.select(pin, addr)   -- select the  sensor
      ow.write(pin, READ_SCRATCHPAD, MODE)
      local data = ow.read_bytes(pin, 9)

      local t=(data:byte(1)+data:byte(2)*256)
      -- t is actually signed so process the sign bit and adjust for fractional bits
      -- the DS18B20 family has 4 fractional bits and the DS18S20s, 1 fractional bit
      t = ((t <= 32767) and t or t - 65536) *
          ((addr:byte(1) == DS18B20FAMILY) and 625 or 5000)
      local crc, b9 = ow.crc8(string.sub(data,1,8)), data:byte(9)

      -- integer version
      if unit == 'F' then
        t = (t * 18)/10 + 320000
      elseif unit == 'K' then
        t = t + 2731500
      end
      local sgn = t<0 and -1 or 1
      local tA = sgn*t
      local tH=tA/10000
      local tL=(tA%10000)/1000 + ((tA%1000)/100 >= 5 and 1 or 0)

      if tH and (t~=850000) then
        if crc==b9 then temp[addr]= sgn * ((tH * 10) + tL) end
        status[i] = 2
      end
      -- end integer version

    end
    next = next or status[i] == 0
  end
  if next then
    node.task.post(node.task.LOW_PRIORITY, function() return conversion(self) end)
  else
    --sens = {}
    if cb then
      node.task.post(node.task.LOW_PRIORITY, function() return cb(temp) end)
    end
  end
end

conversion = (function (self)
  local sens = self.sens
  local powered_only = true
  for _, s in ipairs(sens) do powered_only = powered_only and s:byte(9) ~= 1 end
  if powered_only then
    ow.reset(pin)
    ow.skip(pin)  -- skip ROM selection, talk to all sensors
    ow.write(pin, CONVERT_T, MODE)  -- and start conversion
    for i, _ in ipairs(sens) do status[i] = 1 end
  else
    local started = false
    for i, s in ipairs(sens) do
      if status[i] == 0 then
        local addr, parasite = s:sub(1,8), s:byte(9) == 1
        if parasite and started then break end -- do not start concurrent conversion of powered and parasite
        ow.reset(pin)
        ow.select(pin, addr)  -- select the sensor
        ow.write(pin, CONVERT_T, MODE)  -- and start conversion
        status[i] = 1
        if parasite then break end -- parasite sensor blocks bus during conversion
        started = true
      end
    end
  end
  tmr.create():alarm(750, tmr.ALARM_SINGLE, function() return readout(self) end)
end)

local function _search(self, lcb, lpin, search, save)
  self.temp = {}
  if search then self.sens = {}; status = {} end
  local sens = self.sens
  pin = lpin or pin

  local addr
  if not search and #sens == 0 then
    -- load addreses if available
    local s,check,a = pcall(dofile, "ds18b20_save.lc")
    if s and check == "ds18b20" then
      for i = 1, #a do sens[i] = a[i] end
    end
  end

  ow.setup(pin)
  if search or #sens == 0 then
    ow.reset_search(pin)
    -- ow.target_search(pin,0x28)
    -- search the first device
    addr = ow.search(pin)
  else
    for i, _ in ipairs(sens) do status[i] = 0 end
  end
  local function cycle()
    if addr then
      local crc=ow.crc8(addr:sub(1,7))
      if (crc==addr:byte(8)) and ((addr:byte(1)==DS1920FAMILY) or (addr:byte(1)==DS18B20FAMILY)) then
        ow.reset(pin)
        ow.select(pin, addr)
        ow.write(pin, READ_POWERSUPPLY, MODE)
        local parasite = (ow.read(pin)==0 and 1 or 0)
        sens[#sens+1]= addr..string.char(parasite)
        status[#sens] = 0
      end
      addr = ow.search(pin)
      node.task.post(node.task.LOW_PRIORITY, cycle)
    else
      ow.depower(pin)
      -- place powered sensors first
      table.sort(sens, function(a, b) return a:byte(9)<b:byte(9) end) -- parasite
      -- save sensor addreses
      if save then
        local addr_list = {}
        for i =1, #sens do
          local s = sens[i]
          addr_list[i] = to_string(s:sub(1,8), true)..('.."\\%u"'):format(s:byte(9))
        end
        local save_statement = 'return "ds18b20", {' .. table.concat(addr_list, ',') .. '}'
        local save_file = file.open("ds18b20_save.lc","w")
        save_file:write(string.dump(loadstring(save_statement)))
        save_file:close()
      end
      -- end save sensor addreses
      if lcb then node.task.post(node.task.LOW_PRIORITY, lcb) end
    end
  end
  cycle()
end

local function read_temp(self, lcb, lpin, lunit, force_search, save_search)
  cb, unit = lcb, lunit or unit
  _search(self, function() return conversion(self) end, lpin, force_search, save_search)
end

 -- Set module name as parameter of require and return module table
local M = {
  sens = {},
  temp = {},
  C = 'C', F = 'F', K = 'K',
  read_temp = read_temp
}
_G[modname or 'ds18b20'] = M
return M
