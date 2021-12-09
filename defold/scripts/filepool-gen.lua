
local meshgen = {}

meshgen.images = {
	white 	= "temp.png",
	black 	= "tempBlack.png",
	norm 	= "tempNormal.png",
}

meshgen.files = {
	bufferfile 	= "temp.buffer",
	gofile 		= "temp.go",
	meshfile 	= "temp.mesh",
	scriptfile 	= "temp.script",

	shaderfile 	= "pbr-simple.material",
}

------------------------------------------------------------------------------------------------------------
-- Dataset for each file type (defaults)

local bufferfiledata = [[
[
{
	"name": "position",
	"type": "float32",
	"count": 3,
	"data": [
	]
},
{
	"name": "normal",
	"type": "float32",
	"count": 3,
	"data": [
	]
},
{
	"name": "texcoord0",
	"type": "float32",
	"count": 2,
	"data": [
	]
}
]
]]

------------------------------------------------------------------------------------------------------------

local gofiledata = [[
components {
	id: "temp"
	component: "MESH_FILE_PATH"
	position {
		x: 0.0
		y: 0.0
		z: 0.0
	}
	rotation {
		x: 0.0
		y: 0.0
		z: 0.0
		w: 1.0
	}
}
GO_FILE_SCRIPT
]]

local gofiledatascript = [[
components {
	id: "script"
	component: "SCRIPT_FILE_PATH"
	position {
		x: 0.0
		y: 0.0
		z: 0.0
	}
	rotation {
		x: 0.0
		y: 0.0
		z: 0.0
		w: 1.0
	}
}
]]

------------------------------------------------------------------------------------------------------------

local meshfiledata = [[
material: "SHADER_FILE_PATH"
vertices: "BUFFER_FILE_PATH"
textures: "IMAGE_FILE_PATH"
textures: "IMAGE_FILE_PATH"
textures: "IMAGE_FILE_PATH"
textures: "IMAGE_FILE_PATH"
primitive_type: PRIMITIVE_TRIANGLES
position_stream: "position"
normal_stream: "normal"
]]

------------------------------------------------------------------------------------------------------------

local scriptfiledataupdate = [[
function update(self, dt)
end
]]

local scriptfiledatamsg = [[
function on_message(self, message_id, message, sender)
end
]]

local scriptfiledatainput = [[
function on_input(self, action_id, action)
end
]]

local scriptfiledata = [[
function init(self)
end

function final(self)
end

UPDATE_FUNC

MESSAGE_FUNC

INPUT_FUNC 

function on_reload(self)
end
]]

------------------------------------------------------------------------------------------------------------

local gocollectionheader = [[
name: "default"
]]

local gocollectiondata = [[
instances {
	id: "GO_NAME"
	prototype: "GO_FILE_PATH"
	position {
		x: 0.0
		y: 0.0
		z: 0.0
	}
	rotation {
		x: 0.0
		y: 0.0
		z: 0.0
		w: 1.0
	}
	scale3 {
		x: 1.0
		y: 1.0
		z: 1.0
	}
}
]]

------------------------------------------------------------------------------------------------------------

local function makefile( fpath, fdata )

	local fh = io.open(fpath, "w")
	fh:write(fdata)
	fh:close()
end

------------------------------------------------------------------------------------------------------------

local function getfile( fpath )

		local fh = io.open(fpath, "r")
	assert(fh)
	local data = fh:read("*a")
	fh:close()
	return data
end

------------------------------------------------------------------------------------------------------------

local function init( tempbasepath, imagepath, materialpath )

	meshgen.tempbasepath 	= tempbasepath 
	meshgen.imagepath 		= imagepath
	meshgen.materialpath 	= materialpath
end

------------------------------------------------------------------------------------------------------------

local function makepoolfiles( count )

	local mdata = meshfiledata
	local bdata = bufferfiledata
	local gdata = gofiledata

	local tmpimg = getfile(meshgen.imagepath..meshgen.images.white)
	local tmpimgblack = getfile(meshgen.imagepath..meshgen.images.black)
	local tmpimgnorm = getfile(meshgen.imagepath..meshgen.images.norm)

	for i=1, count do 

		local mpath = meshgen.tempbasepath..string.format("%03d", i)..".mesh"
		local bpath = meshgen.tempbasepath..string.format("%03d", i)..".buffer"
		local gpath = meshgen.tempbasepath..string.format("%03d", i)..".go"
		local spath = meshgen.tempbasepath..string.format("%03d", i)..".script"
		
		-- Build a mesh file 
		local shaderpath = meshgen.materialpath..meshgen.files.shaderfile
		local newmdata = string.gsub(mdata, [[material: ("SHADER_FILE_PATH")]], "material: \"/"..shaderpath.."\"",1)		
		newmdata = string.gsub(newmdata, [[vertices: ("BUFFER_FILE_PATH")]], "vertices: \"/"..bpath.."\"",1)		
		
		local tapath = meshgen.tempbasepath..string.format("%03dA", i)..".png"
		newmdata = string.gsub(newmdata, [[textures: ("IMAGE_FILE_PATH")]], "textures: \"/"..tapath.."\"",1)		
		local trpath = meshgen.tempbasepath..string.format("%03dR", i)..".png"
		newmdata = string.gsub(newmdata, [[textures: ("IMAGE_FILE_PATH")]], "textures: \"/"..trpath.."\"",1)		
		local tmpath = meshgen.tempbasepath..string.format("%03dE", i)..".png"
		newmdata = string.gsub(newmdata, [[textures: ("IMAGE_FILE_PATH")]], "textures: \"/"..tmpath.."\"",1)		
		local nmpath = meshgen.tempbasepath..string.format("%03dN", i)..".png"
		newmdata = string.gsub(newmdata, [[textures: ("IMAGE_FILE_PATH")]], "textures: \"/"..nmpath.."\"",1)		
		makefile( mpath, newmdata )
		
		-- Write out a buffer file
		makefile( bpath, bufferfiledata )

		-- Write out a script file -- option for adding/removing update		
		local newsdata = string.gsub(scriptfiledata, "UPDATE_FUNC", "", 1)		
		newsdata = string.gsub(newsdata, "MESSAGE_FUNC", "", 1)		
		newsdata = string.gsub(newsdata, "INPUT_FUNC", "", 1)		
		makefile( spath, newsdata )

		-- Build a gameobject file 
		local newgdata = string.gsub(gdata, "MESH_FILE_PATH", string.format("temp%03d", i)..".mesh", 1)		

		-- Insert script here if needed
		newgdata = string.gsub(newgdata, "GO_FILE_SCRIPT", "", 1)
		newgdata = string.gsub(newgdata, "SCRIPT_FILE_PATH", string.format("temp%03d", i)..".script", 1)
						
		-- Write out the game object file
		makefile( gpath, newgdata )
				
		-- Write out image files 
		makefile( tapath, tmpimg )
		makefile( trpath, tmpimgblack )
		makefile( tmpath, tmpimgblack )
		makefile( nmpath, tmpimgnorm )

	end 
end

------------------------------------------------------------------------------------------------------------

local function maketempcollection( collfile, numgos )

	-- Make the meshes and images in the mesh pool
	makepoolfiles( numgos )

	-- Build the collection file.
	local fh = io.open( collfile, "w" )
	if(fh) then 
		fh:write( gocollectionheader )
		for i = 1, numgos do 
			local gdata = gocollectiondata
			local gpath = meshgen.tempbasepath..string.format("%03d", i)..".go"
			local gname = string.format("temp%03d", i)
			gdata = string.gsub(gdata, "GO_NAME", gname, 1)		
			gdata = string.gsub(gdata, "GO_FILE_PATH", "/"..gpath, 1)		
			fh:write( gdata )
		end
		fh:close()
	end 
end

------------------------------------------------------------------------------------------------------------
-- This may be necessary later to empty or clean pool folders
local function cleanup()

end

------------------------------------------------------------------------------------------------------------

meshgen.init 			= init 
meshgen.cleanup 		= cleanup
meshgen.makecollection 	= maketempcollection

return meshgen