
local dirpath = arg[1]
print("Lua generation started...")

package.path = package.path..";"..dirpath.."/?.lua"

-- Get config file - it should be in the dirpath 
local config = require("defoldsync.config")

-- Get the generator functions
local gen = require("defoldsync.generator")

-- Generate data based on incoming data set.
local data = require("defoldsync.temp.syncdata")

local collection_name = config.sync_scene or "Sample Scene"
if(string.len(collection_name) == 0) then collection_name = "Sample Scene" end 

-- Replace spaces in collection name - can cause problems with mkdirs
collection_name = collection_name:gsub(" ", "_") 

local project_path = config.sync_proj or "./Sample"
if(string.len(project_path) == 0) then project_path = "./Sample" end

-- Project path, escape any . charcters
project_path = project_path:gsub("%.", "%%%.")

if(config.sync_mode == "Sync Build") then
    gen.makefolders( collection_name, project_path )
    gen.makecollection( collection_name, data["OBJECTS"], data["MESHES"])
end

if(config.sync_mode == "Debug") then
    for k,v in pairs(data) do 
        print(k, tostring(v))
    end 
end

print("Sync Mode: "..config.sync_mode )
print( "Project: "..config.sync_proj )
print( "Scene: "..config.sync_scene )
print( "Stream Info: "..tostring(config.stream_info) )
print( "Stream Object: "..tostring(config.stream_object) )
print( "Stream Mesh: "..tostring(config.stream_mesh) )
print( "Stream Anim: "..tostring(config.stream_anim) )


print("Lua finished.")