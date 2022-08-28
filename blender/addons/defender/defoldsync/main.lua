-- -----  MIT license ------------------------------------------------------------
-- Copyright (c) 2022 David Lannan

-- Permission is hereby granted, free of charge, to any person obtaining a copy
-- of this software and associated documentation files (the "Software"), to deal
-- in the Software without restriction, including without limitation the rights
-- to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
-- copies of the Software, and to permit persons to whom the Software is
-- furnished to do so, subject to the following conditions:

-- The above copyright notice and this permission notice shall be included in all
-- copies or substantial portions of the Software.

-- THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
-- IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
-- FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
-- AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
-- LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
-- OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
-- SOFTWARE.
------------------------------------------------------------------------------------------------------------

local dirpath = arg[1]
GDIR_PATH   = dirpath

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
    if( config.stream_mesh_type == "gltf" or config.stream_mesh_type == "glb") then 
        gen.gltf = true 
    end 
    if( config.stream_anim ) then gen.anim = true end
    
    gen.makefolders( collection_name, project_path, config )
    gen.makescene( collection_name, data["OBJECTS"], data["MESHES"], data["ANIMS"])
end

if(config.sync_mode == "Debug") then
    for k,v in pairs(data) do 
        print(k, tostring(v))
    end 
end

------------------------------------------------------------------------------------------------------------

print("Sync Mode: "..config.sync_mode )
print( "Project: "..config.sync_proj )
print( "Scene: "..config.sync_scene )
print( "Stream Info: "..tostring(config.stream_info) )
print( "Stream Object: "..tostring(config.stream_object) )
print( "Stream Mesh: "..tostring(config.stream_mesh) )
print( "Stream Anim: "..tostring(config.stream_anim) )


print("Lua finished.")

------------------------------------------------------------------------------------------------------------
