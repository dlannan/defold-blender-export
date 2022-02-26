
-- Setup some paths to make test work from this folder 

package.path = package.path..";../blender/addons/sync_tool/?.lua"

-- Run merge tests
local material = require("defoldsync.material-textures")

-- Test
material.genAMRMap( "images/merge.png", "images/red.png", "images/blue.png", "images/green.png")
