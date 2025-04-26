----------------------------------------------
-- Pickle.lua
-- A table serialization utility for lua
-- Steve Dekorte, http://www.dekorte.com, Apr 2000
-- Freeware
----------------------------------------------

local Pickle = {
    clone = function (t) 
        local nt={}
        for i, v in pairs(t) do nt[i]=v end 
        return nt 
    end 
}

function Pickle:pickle_(root)
    if type(root) ~= "table" then 
        error("can only pickle tables, not ".. type(root).."s")
    end
    self._tableToRef = {}
    self._refToTable = {}
    local savecount = 0
    self:ref_(root)
    local s = ""

    while table.getn(self._refToTable) > savecount do
        savecount = savecount + 1
        local t = self._refToTable[savecount]
        s = s.."{\n"
        for i, v in pairs(t) do
            s = string.format("%s[%s]=%s,\n", s, self:value_(i), self:value_(v))
        end
        s = s.."},\n"
    end
    return string.format("{%s}", s)
end

function Pickle:value_(v)
    local vtype = type(v)
    if     vtype == "string" then return string.format("%q", v)
    elseif vtype == "number" then return v
    elseif vtype == "table" then return "{"..self:ref_(v).."}"
    else --error("pickle a "..type(v).." is not supported")
    end  
end

function Pickle:ref_(t)
    local ref = self._tableToRef[t]
    if not ref then 
        if t == self then error("can't pickle the pickle class") end
        table.insert(self._refToTable, t)
        ref = table.getn(self._refToTable)
        self._tableToRef[t] = ref
    end
    return ref
end

local function pickle(t)
    return Pickle:clone():pickle_(t)
end

----------------------------------------------
-- unpickle
----------------------------------------------
local function unpickle(s)
    if type(s) ~= "string" then
        error("can't unpickle a "..type(s)..", only strings")
    end
    local gentables = loadstring("return "..s)
    local tables = gentables()

    for tnum = 1, table.getn(tables) do
        local t = tables[tnum]
        local tcopy = {}; for i, v in pairs(t) do tcopy[i] = v end
        for i, v in pairs(tcopy) do
        local ni, nv
        if type(i) == "table" then ni = tables[i[1]] else ni = i end
        if type(v) == "table" then nv = tables[v[1]] else nv = v end
        t[i] = nil
        t[ni] = nv
        end
    end
    return tables[1]
end

-- And here is some testcode to see that after loading the table it is not the same anymore
----------------------------------------------
-- PickleTest.lua
-- Testing code for Pickle.lua
-- Steve Dekorte, http://www.dekorte.com, Apr 2000
----------------------------------------------
--dofile("Pickle.lua")

function eq(b)
    if b then print(" succeeded") else print(" failed") end
end

function test()
    local t = {
        name = "foo", 
        ssn=123456789, 
        contact = { phone = "555-1\r\n212", email = "foo@foo.com"},
    }
    t.t = { 1 }
    t.contact.loop = t
    t["a b"] = "zzz"
    t[10] = 11
    t[t] = 5
    t[t.t] = 10
    local s = pickle(t)
    print("pickled string:\n\n"..s)
    local ut = unpickle(s) 
    print("pickled string:\n\n"..pickle( ut ))
    print("loop test:   "); eq(ut == ut.contact.loop)
    print("subitem test:"); eq(ut.contact.phone == t.contact.phone)
    print("number value:"); eq(ut.ssn == t.ssn)
    print("number index:"); eq(ut[10] == 11)
    print("table index: "); eq(ut[ut] == 5)
end

test()

----------------------------------------------

return {
    pickle          = pickle,
    unpickle        = unpickle,
}



----------------------------------------------