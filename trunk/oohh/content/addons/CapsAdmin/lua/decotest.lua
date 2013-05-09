print(jit and jit.version or _VERSION)

local upvalue

function test()
    local last
    for j = 1, 20 do
        last = upvalue
    end
    print(last, upvalue)
end

for i = 1, 8 do
    upvalue = i
    test()
end

--[[ LuaJIT output:

LuaJIT 2.0.0-beta11
1       1
2       2
3       3
3       4
3       5
3       6
3       7
3       8
]]