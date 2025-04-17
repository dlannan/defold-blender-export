
-- All the templates for all the text file types in defold

local default_rotation = [[
    rotation {
        x: 0.0
        y: 0.0
        z: 0.0
        w: 1.0
    }
]]

-- local inv_rotation = [[
--     rotation {
--         x: 0.70710677
--         y: 0.0
--         z: 0.0
--         w: 0.70710677
--     }
-- ]]
local inv_rotation = [[
    rotation {
        x: 0.0
        y: 0.0
        z: 0.0
        w: 1.0
    }
]]

-- local grotation_mesh = [[
--     rotation {
--         x: -0.70710677
--         y: 0.0
--         z: 0.0
--         w: 0.70710677
--     }
-- ]]
local grotation_mesh = [[
    rotation {
        x: 0.0
        y: 0.0
        z: 0.0
        w: 1.0
    }
]]


-- local grotation_gltf = [[
--     rotation {
--         x: -0.70710677
--         y: 0.0
--         z: 0.0
--         w: 0.70710677
--     }
-- ]]
local grotation_gltf = [[
    rotation {
        x: 0.0
        y: 0.0
        z: 0.0
        w: 1.0
    }
]]

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
MESH_UV_DATA1
    ]
}MESH_UV_TEXCOORD1
]
]]

local buffertexcoord1 = [[
,
{
    "name": "texcoord1",
    "type": "float32",
    "count": 2,
    "data": [
MESH_UV_DATA2
    ]
}
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
GO_FILE_COMPONENTS
GO_COLLIDER_COMPONENT
GO_FILE_SCRIPT
]]

------------------------------------------------------------------------------------------------------------

local gomodelmaterialtexture = [[
    "    sampler: \"tex0\""
    "    texture: \"GO_MODEL_TEXTURE\""
]]

local gomodelcomponentembedded = [[
    "components {\n"
    "   id: \"GO_COMPONENT_ID\"\n"
    "   component: \"GO_COMPONENT_PATH\"\n"
    "}\n"
]]

local gomodelcomponentfile = [[
    components {
    id: "GO_COMPONENT_ID"
    component: "GO_COMPONENT_PATH"
    }
]]


local gomodelfiledata = {
-- Initial version. Will provide a way to set this on the exporter if needed.
[[
embedded_components {
    id: "MESH_GO_NAME"
    type: "model"
    data: "mesh: \"MESH_FILE_PATH\"\n"
    "material: \"MATERIAL_FILE_PATH\"\n"
    "GO_MESH_TEXTURE_FILES"
    "skeleton: \"MODEL_SKELETON_FILE\"\n"
    "animations: \"MODEL_ANIM_FILE\"\n"
    "default_animation: \"MODEL_ANIM_NAME\"\n"
    "name: \"unnamed\"\n"
    GO_DATA_FILE_COMPONENTS
    ""
    position {
        x: 0.0
        y: 0.0
        z: 0.0
    }
    MESH_GO_ROTATION
}
GO_FILE_SCRIPT
]],

-- Version 2 of the model format to suppurt multi material and other changes
[[
embedded_components {
    id: "MESH_GO_NAME"
    type: "model"
    data: "mesh: \"MESH_FILE_PATH\"\n"
    "name: \"{{NAME}}\"\n"
    "materials {\n"
    "    name: \"MATERIAL_NAME\"\n"
    "    material: \"MATERIAL_FILE_PATH\"\n"
GO_MESH_TEXTURE_FILES
MODEL_SKELETON_FILE
MODEL_ANIM_FILE
MODEL_ANIM_NAME
GO_DATA_FILE_COMPONENTS
    "}\n"

    position {
        x: 0.0
        y: 0.0
        z: 0.0
    }
    MESH_GO_ROTATION
}
GO_FILE_SCRIPT
]]
}

------------------------------------------------------------------------------------------------------------

local gomodelcollisiondata = 
[[
embedded_components {
id: "collisionobject_COLLISION_ID"
type: "collisionobject"
data: "type: COLLISION_OBJECT_TYPE_STATIC\n"
"mass: 0.0\n"
"friction: 0.1\n"
"restitution: 0.5\n"
"group: \"COLLISION_GROUP\"\n"
"mask: \"COLLISION_MASK\"\n"
"embedded_collision_shape {\n"
"  shapes {\n"
"    shape_type: TYPE_BOX\n"
"    position {\n"
"       x: COLLISION_POS_X\n"
"       x: COLLISION_POS_Y\n"
"       x: COLLISION_POS_Z\n"
"    }\n"
"    rotation {\n"
"       x: COLLISION_ROT_X\n"
"       x: COLLISION_ROT_Y\n"
"       x: COLLISION_ROT_Z\n"
"    }\n"
"    index: 0\n"
"    count: 3\n"
"  }\n"
"  data: COLLISION_DIM_X\n"
"  data: COLLISION_DIM_Y\n"
"  data: COLLISION_DIM_Z\n"
"}\n"
"locked_rotation: true\n"
""
}
]]

------------------------------------------------------------------------------------------------------------


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
MESH_TEXTURE_FILES
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
-- Credits: AJirenius @ https://forum.defold.com/t/accessing-internal-state-self-of-another-game-object-solved/2389/10
--    
local gopscript = [[
    local M = {}

    local gop_tables = {}
    
    function M.set(key, value)
        gop_tables[key] = value
    end
    
    function M.get(key)
        return gop_tables[key]
    end
    
    function M.getall()
        return gop_tables
    end

    M.tables = gop_tables

    return M
]]

------------------------------------------------------------------------------------------------------------

local gcollectionroot = [[
embedded_instances {
    id: "__root"
ROOT_CHILDREN
    data: COLLECTION_SCRIPT
    position {
        x: 0.0
        y: 0.0
        z: 0.0
    }
ROOT_ROTATION
    scale3 {
        x: 1.0
        y: 1.0
        z: 1.0
    }
}
]]

local gcollectionrootscript = [[
"components {\n"
    "    id: \"ROOT_SCRIPT_NAME\"\n"
    "    component: \"ROOT_SCRIPT\"\n" 
    "    position {\n"
    "        x: 0.0\n"
    "        y: 0.0\n"
    "        z: 0.0\n"
    "    }\n"
    "    rotation {\n"
    "        x: 0.0\n"
    "        y: 0.0\n"
    "        z: 0.0\n"
    "        w: 1.0\n"
    "    }\n"
    "}\n"
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
        GO_SCALE
    }
}
]]

local gocollectiongeneric = [[
embedded_instances {
    id: "GO_NAME"
    GO_DATA_FILE_COMPONENTS
GO_CHILDREN
    position {
        GO_POSITION
    }
    rotation {
        GO_ROTATION_QUATERNION
    }
    scale3 {
        GO_SCALE
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
    "  fov: GO_CAMERA_FOV\\n"
    "  near_z: GO_CAMERA_NEAR\\n"
    "  far_z: GO_CAMERA_FAR\\n"
    "  auto_aspect_ratio: 1\\n"
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
        GO_SCALE
    }
}
]]

------------------------------------------------------------------------------------

return {

    default_rotation        = default_rotation,
    inv_rotation            = inv_rotation,
    grotation_mesh          = grotation_mesh,
    grotation_gltf          = grotation_gltf,

    bufferfiledata          = bufferfiledata,
    buffertexcoord1         = buffertexcoord1,

    gofiledata              = gofiledata,

    gomodelmaterialtexture  = gomodelmaterialtexture,
    gomodelcomponentembedded= gomodelcomponentembedded,
    gomodelcomponentfile    = gomodelcomponentfile,
    gomodelfiledata         = gomodelfiledata,
    gomodelcollisiondata    = gomodelcollisiondata,

    gofiledatascript        = gofiledatascript,

    meshfiledata            = meshfiledata,

    scriptfiledataupdate    = scriptfiledataupdate,
    scriptfiledatamsg       = scriptfiledatamsg,
    scriptfiledatainput     = scriptfiledatainput,
    scriptfiledata          = scriptfiledata,

    gopscript               = gopscript,

    gcollectionroot         = gcollectionroot,
    gcollectionrootscript   = gcollectionrootscript,
    gocollectionheader      = gocollectionheader,
    gocollectiondata        = gocollectiondata,
    gocollectiongeneric     = gocollectiongeneric,
    gcollectioncamera       = gcollectioncamera,
}


------------------------------------------------------------------------------------