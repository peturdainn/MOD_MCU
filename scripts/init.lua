node.stripdebug(3)
for k,v in pairs(file.list()) do
    if nil == string.match(k, "init.lua") then
        if string.match(k, ".lua") then
            print(k.." ("..v.." b) compiling")
            node.compile(k)
            file.remove(k)
        end
    end
end

for k,v in pairs(file.list()) do
    print(k.." ("..v.." b)")
end

k = nil
v = nil

mod = require("CFG_MOD")
app = require("APP")
app.start()
