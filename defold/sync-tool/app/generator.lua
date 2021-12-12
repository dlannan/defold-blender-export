-- A simple set of methods for generating various Defold data files.
------------------------------------------------------------------------------------------------------------

local PATH_SEPARATOR        = "/"
local info = sys.get_sys_info()
-- The system OS name: "Darwin", "Linux", "Windows", "HTML5", "Android" or "iPhone OS"
if info.system_name == "Windows" then
    PATH_SEPARATOR  = "\\"
end

local gendata = {}

gendata.folders = {
    base        = "",
    images      = "images",
    meshes      = "meshes",
    gos         = "gameobjects",
    materials   = "materials",
    animations  = "animations",
}

gendata.images = {
	white 	= "temp.png",
	black 	= "tempBlack.png",
	norm 	= "tempNormal.png",
}

gendata.files = {
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
	id: "MESH_GO_NAME"
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
name: "COLLECTION_NAME"
scale_along_z: 0
]]

local gocollectiondata = [[
instances {
    id: "GO_NAME"
    prototype: "GO_FILE_PATH"
    GO_CHILDREN
    position {
        GO_POSITION
    }
    rotation {
        GO_ROTATION_QUATERNION
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

local function makefolders( collectionname, base )

    assert(collectionname ~= nil, "Invalid collectionname")
    assert(base ~= nil, "Invalid Base path string.")

    gendata.base = base

    -- Make the base path
    os.execute("mkdir -p "..base..PATH_SEPARATOR..collectionname)
    -- Make the folders that files will be generated in 
    for k,v in pairs(gendata.folders) do 
        os.execute("mkdir -p "..base..PATH_SEPARATOR..collectionname..PATH_SEPARATOR..v)
    end
end

------------------------------------------------------------------------------------------------------------

local function makegofile( filepath, go )

    local meshdata = gofiledata

    meshdata = string.gsub(meshdata, "MESH_GO_NAME", go.name.."_mesh")
    meshdata = string.gsub(meshdata, "MESH_FILE_PATH", "")

    meshdata = string.gsub(meshdata, "GO_FILE_SCRIPT", "")
    makefile( filepath, meshdata )
end

------------------------------------------------------------------------------------------------------------

local function makecollection( collectionname, objects )

    if(objects == nil) then return end 
    local application_path = sys.get_application_path()
    print(application_path) 
    
    local project_path = gendata.base..PATH_SEPARATOR..collectionname
    local colldata = gocollectionheader
    -- Objects need to be in flat table - straight from blender.
    for k,v in pairs(objects) do 

        local name = v.name or ("Dummy"..k)
        local objdata = gocollectiondata
        objdata = string.gsub(objdata, "GO_NAME", name)
        local gofilepath = gendata.folders.gos..PATH_SEPARATOR..name..".go"

        makegofile( project_path..PATH_SEPARATOR..gofilepath, v )
        objdata = string.gsub(objdata, "GO_FILE_PATH", gofilepath)
        
        local children = ""
        if(v.children) then 
            children = "children: "..table.concat( v.children, "\nchildren: ")
        end
        objdata = string.gsub(objdata, "GO_CHILDREN", children)

        local position = "x:0.0\n\ty:0.0\n\tz:0.0"
        if(v.location) then 
            position = "x:"..v.location.x.."\n\ty:"..v.location.y.."\n\tz:"..v.location.z
        end 
        objdata = string.gsub(objdata, "GO_POSITION", position)

        local rotation = "x:0.0\n\ty:0.0\n\tz:0.0\n\tw:1.0"
        if(v.location) then 
            rotation = "x:"..v.rotation.quat.x.."\n\ty:"..v.rotation.quat.y
            rotation = rotation.."\n\tz:"..v.rotation.quat.z.."\n\tw:"..v.rotation.quat.w
        end 
        objdata = string.gsub(objdata, "GO_ROTATION_QUATERNION", rotation)
        
        colldata = colldata.."\n"..objdata
    end 

    -- Write the file
    makefile( project_path..PATH_SEPARATOR..collectionname..".collection", colldata )
end

------------------------------------------------------------------------------------------------------------

gendata.makefile        = makefile
gendata.makefolders     = makefolders
gendata.makecollection  = makecollection

return gendata
