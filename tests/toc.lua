-- toc.lua -- the TOC and the tree must agree.
--
-- The client loads exactly what the TOC lists, in that order. A file that
-- exists but is not declared simply never loads, with no error anywhere: the
-- addon comes up missing a feature and nothing says why. This is cheap
-- insurance against that.

local ADDON_DIR = "../Silvertongue/"
local TOC       = ADDON_DIR .. "Silvertongue.toc"

local errors = 0
local function fail(fmt, ...)
    errors = errors + 1
    print("FAIL: " .. string.format(fmt, ...))
end

local function exists(path)
    local f = io.open(path, "r")
    if f then f:close() return true end
    return false
end

-- Everything the TOC declares has to be there.
local declared = {}
local toc = assert(io.open(TOC, "r"), "no TOC at " .. TOC)
for line in toc:lines() do
    line = line:gsub("\r", "")
    if line:match("%.lua$") or line:match("%.xml$") then
        declared[line] = true
        local path = ADDON_DIR .. line:gsub("\\", "/")
        if not exists(path) then fail("declared in the TOC but missing: %s", line) end
    end
end
toc:close()

-- And everything there, apart from the vendored libraries, has to be declared.
local found = io.popen('find ' .. ADDON_DIR .. ' -name "*.lua" -not -path "*/Libs/*"')
local count = 0
for path in found:lines() do
    count = count + 1
    local rel = path:gsub("^" .. ADDON_DIR, ""):gsub("/", "\\")
    if not declared[rel] then
        fail("present but not declared in the TOC: %s", rel)
    end
end
found:close()

if count == 0 then fail("found no Lua files at all, which cannot be right") end

print(string.format("%d files declared, %d on disk", (function()
    local n = 0
    for _ in pairs(declared) do n = n + 1 end
    return n
end)(), count))
print(errors == 0 and "TOC OK" or (errors .. " PROBLEMS"))
os.exit(errors == 0 and 0 or 1)
