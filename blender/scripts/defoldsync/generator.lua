-- A simple set of methods for generating various Defold data files.
------------------------------------------------------------------------------------------------------------

local ffi                   = require("ffi")

local PATH_SEPARATOR        = "/"
local CMD_COPY              = "cp"
local CMD_MKDIR             = "mkdir -p"
local platform              =  ffi.os

-- The system OS name: "Darwin", "Linux", "Windows", "HTML5", "Android" or "iPhone OS"
if platform == "Windows" then
    PATH_SEPARATOR  = "\\"
    CMD_COPY        = "copy"
    CMD_MKDIR       = "mkdir"
end

------------------------------------------------------------------------------------------------------------

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
MESH_VERTEX_DATA
    ]
},
{
    "name": "normal",
    "type": "float32",
    "count": 3,
    "data": [
MESH_NORMAL_DATA
    ]
},
{
    "name": "texcoord0",
    "type": "float32",
    "count": 2,
    "data": [
MESH_UV_DATA
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
material: "MATERIAL_FILE_PATH"
vertices: "BUFFER_FILE_PATH"
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

local gcollectionroot = [[
embedded_instances {
    id: "root"
ROOT_CHILDREN
    data: ""
    position {
        x: 0.0
        y: 0.0
        z: 0.0
    }
    rotation {
        x: -0.70710677
        y: 0.0
        z: 0.0
        w: 0.70710677
    }
    scale3 {
        x: 1.0
        y: 1.0
        z: 1.0
    }
}
]]

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

local gocollectiongeneric = [[
embedded_instances {
    id: "GO_NAME"
    data: ""
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

local gcollectioncamera = [[
embedded_instances {
    id: "GO_NAME"
    data: "embedded_components {\n"
    "  id: \"camera\"\n"
    "  type: \"camera\"\n"
    "  data: \"aspect_ratio: 1.0\\n"
    "fov: 0.7854\\n"
    "near_z: 0.1\\n"
    "far_z: 1000.0\\n"
    "auto_aspect_ratio: 0\\n"
    "\"\n"
    "  position {\n"
    "    x: 0.0\n"
    "    y: 0.0\n"
    "    z: 0.0\n"
    "  }\n"
    "  rotation {\n"
    "    x: 0.0\n"
    "    y: 0.0\n"
    "    z: 0.0\n"
    "    w: 1.0\n"
    "  }\n"
    "}\n"
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

local function localpathname( path )

    -- Subtract project path from pathname     
    local newpath = string.match(path, gendata.base.."(.*)")
    -- Local path should always use / 
    if(newpath) then newpath = string.gsub(newpath, "\\", "/") end
    return newpath or path 
end

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
    os.execute(CMD_MKDIR.." "..base..PATH_SEPARATOR..collectionname)
    -- Make the folders that files will be generated in 
    for k,v in pairs(gendata.folders) do 
        os.execute(CMD_MKDIR.." "..base..PATH_SEPARATOR..collectionname..PATH_SEPARATOR..v)
    end
end

------------------------------------------------------------------------------------------------------------

local function makebufferfile(name, filepath, mesh )

    local bufferdata = bufferfiledata
    local bufferfilepath = filepath..gendata.folders.meshes..PATH_SEPARATOR..name..".buffer"
    --print(bufferfilepath)
    --pprint(name, gendata.meshes[name] )

    local mesh = gendata.meshes[name] 
    if(mesh == nil) then return "" end

    local verts = mesh.vertices 
    local vertdata = {}
    local uvdata = {}
    local normdata = {}
    for k,v in pairs(mesh.tris) do 
        for i,t in pairs(v.tri) do 
            local vert = verts[t.vertex + 1]
            table.insert(vertdata, vert.x)
            table.insert(vertdata, vert.y)
            table.insert(vertdata, vert.z)
            table.insert(uvdata, t.uv.x)
            table.insert(uvdata, t.uv.y)
            table.insert(normdata, v.normal.x)
            table.insert(normdata, v.normal.y)
            table.insert(normdata, v.normal.z)
        end
    end
    
    bufferdata = string.gsub(bufferdata, "MESH_VERTEX_DATA", table.concat(vertdata, ","))
    bufferdata = string.gsub(bufferdata, "MESH_NORMAL_DATA", table.concat(normdata, ","))
    bufferdata = string.gsub(bufferdata, "MESH_UV_DATA", table.concat(uvdata, ","))
    
    makefile( bufferfilepath, bufferdata )
    return bufferfilepath
end

------------------------------------------------------------------------------------------------------------

local function maketexturefile( name, filepath, mesh )

    local texturefile = ""
    if(mesh.textures and mesh.textures[1]) then 
        local texturefilename = string.match(mesh.textures[1], "([^"..PATH_SEPARATOR.."]+)$")
        -- copy to local folder first 
        local targetfile = filepath..gendata.folders.images..PATH_SEPARATOR..texturefilename
        os.execute(CMD_COPY.." "..mesh.textures[1].." "..targetfile)
        texturefile = localpathname(filepath)..gendata.folders.images.."/"..texturefilename
    end 
    return texturefile
end 

------------------------------------------------------------------------------------------------------------

local function makemeshfile(name, filepath, mesh )

    if(mesh == nil) then return "" end 
    
    local meshdata = meshfiledata
    local meshfilepath = filepath..gendata.folders.meshes..PATH_SEPARATOR..name..".mesh"

    meshdata = string.gsub(meshdata, "MATERIAL_FILE_PATH", "/builtins/materials/model.material")

    -- If a texture file is found, copy it, then assign it
    local texturefilepath = maketexturefile( name, filepath, mesh )
    meshdata = string.gsub(meshdata, "IMAGE_FILE_PATH", texturefilepath)

    local bufferfilepath = makebufferfile( name, filepath, mesh )
    meshdata = string.gsub(meshdata, "BUFFER_FILE_PATH", localpathname(bufferfilepath))
    makefile( meshfilepath, meshdata )
    return meshfilepath
end

------------------------------------------------------------------------------------------------------------

local function makegofile( name, filepath, go )

    local godata = gofiledata
    local gofilepath = filepath..gendata.folders.gos..PATH_SEPARATOR..name..".go"

    godata = string.gsub(godata, "MESH_GO_NAME", go.name.."_mesh")

    if(go.type == "MESH") then 
        local mesh = gendata.meshes[name] 
        local meshfilepath = makemeshfile(name, filepath, mesh)
        godata = string.gsub(godata, "MESH_FILE_PATH", localpathname(meshfilepath))
    end 

    godata = string.gsub(godata, "GO_FILE_SCRIPT", "")
    makefile( gofilepath, godata )
    return gofilepath
end

------------------------------------------------------------------------------------------------------------
-- Process children (take parents and work out their children)

local function processChildren(objs)

    local objects = {}
    -- Add to object list 
    for k,v in pairs(objs) do 
        if k then 
            objects[k] = v 
        end 
    end
    -- Regen children using parent information 
    for k,v in pairs(objects) do 
        if(v.parent and v.parent.name) then 
            local parent = objects[v.parent.name]
            if(parent) then
                parent.children = parent.children or {} 
                table.insert(parent.children, v.name)
            end
        end 
    end
    return objects
end

------------------------------------------------------------------------------------------------------------

local function makecollection( collectionname, objects, meshes )

    if(objects == nil) then return end 

    objects = processChildren(objects)
    gendata.meshes = meshes
    
    local project_path = gendata.base..PATH_SEPARATOR..collectionname
    gendata.project_path = project_path
    local colldata = gocollectionheader
    -- Objects need to be in flat table - straight from blender.

    local rootchildren = ""
    for k,v in pairs(objects) do 

        local name = v.name or ("Dummy"..k)
        local objdata = gocollectiongeneric
        if(v.type == "MESH") then 
            objdata = gocollectiondata

            local gofilepath = makegofile( name, project_path..PATH_SEPARATOR, v )
            objdata = string.gsub(objdata, "GO_FILE_PATH", localpathname(gofilepath))

        elseif(v.type == "CAMERA") then 
            objdata = gcollectioncamera
        elseif(v.type == "LIGHT") then 
            objdata = gocollectiongeneric
        end 
        
        objdata = string.gsub(objdata, "GO_NAME", name)

        -- Check if this object is a root level obj.
        if( v.parent == nil) then 
            rootchildren = rootchildren.."\tchildren: \""..name.."\"\n"
        end
                
        local children = ""
        if(v.children) then 
            for k,v in pairs(v.children) do
                children = "    children: \""..v.."\"\n"
            end
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

    -- Add the root instance 
    gcollectionroot = string.gsub(gcollectionroot, "ROOT_CHILDREN", rootchildren)
    colldata = colldata.."\n"..gcollectionroot
    
    -- Write the file
    makefile( project_path..PATH_SEPARATOR..collectionname..".collection", colldata )
end

------------------------------------------------------------------------------------------------------------

gendata.makefile        = makefile
gendata.makefolders     = makefolders
gendata.makecollection  = makecollection

return gendata
