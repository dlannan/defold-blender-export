
print(arg[1], arg[2])

local dirpath = arg[1]
local command = arg[2]

package.path = package.path..";"..dirpath.."\\?.lua"

local gen = require("defoldsync.generator")

-- Get config file - it should be in the dirpath 
local config = require("defoldsync.config")
print( "Project: "..config.sync_proj )
print( "Scene: "..config.sync_scene )
print( "Stream Info: "..tostring(config.stream_info) )
print( "Stream Object: "..tostring(config.stream_object) )
print( "Stream Mesh: "..tostring(config.stream_mesh) )
print( "Stream Anim: "..tostring(config.stream_anim) )


print("Lua finished.")