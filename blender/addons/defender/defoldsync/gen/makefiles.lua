------------------------------------------------------------------------------------------------------------
--Local version of the gendata - this is set before making any collections
local gendata   = nil

local json                  = require("defoldsync.utils.json")
local materialSimple        = require("defoldsync.material.textures")

local tinsert               = table.insert

table.count = function( tbl ) 
    local count = 0
    if(tbl == nil or type(tbl) ~= "table") then return count end
    for k,v in pairs(tbl) do count = count + 1 end 
    return count 
end

string.endswith = function( str, ending )
    return ending == "" or str:sub(-#ending) == ending
end

local collision_counter     = 1

------------------------------------------------------------------------------------------------------------
-- This will be used to allow custom materials and shaders (coming soon...)
local pbrsimple = require("defoldsync.material.pbrsimple")
local pbrlightmap = require("defoldsync.material.pbrlightmap")

------------------------------------------------------------------------------------------------------------

local templates     = require("defoldsync.gen.templates")

local default_rotation        = templates.default_rotation
local inv_rotation            = templates.inv_rotation
local grotation_mesh          = templates.grotation_mesh
local grotation_gltf          = templates.grotation_gltf

local bufferfiledata          = templates.bufferfiledata
local buffertexcoord1         = templates.buffertexcoord1

local gofiledata              = templates.gofiledata

local gomodelmaterialtexture  = templates.gomodelmaterialtexture
local gomodelcomponentembedded= templates.gomodelcomponentembedded
local gomodelcomponentfile    = templates.gomodelcomponentfile
local gomodelfiledata         = templates.gomodelfiledata
local gomodelcollisiondata    = templates.gomodelcollisiondata

local gofiledatascript        = templates.gofiledatascript

local meshfiledata            = templates.meshfiledata

local scriptfiledataupdate    = templates.scriptfiledataupdate
local scriptfiledatamsg       = templates.scriptfiledatamsg
local scriptfiledatainput     = templates.scriptfiledatainput
local scriptfiledata          = templates.scriptfiledata

local gopscript               = templates.gopscript

local gcollectionroot         = templates.gcollectionroot
local gcollectionrootscript   = templates.gcollectionrootscript
local gocollectionheader      = templates.gocollectionheader
local gocollectiondata        = templates.gocollectiondata
local gocollectiongeneric     = templates.gocollectiongeneric
local gcollectioncamera       = templates.gcollectioncamera

------------------------------------------------------------------------------------------------------------

local gen_utils     = require("defoldsync.gen.utils")

local rotatequat90            = gen_utils.rotatequat90
local split                   = gen_utils.split
local localpathname           = gen_utils.localpathname
local getextension            = gen_utils.getextension
local makefile                = gen_utils.makefile
local makefilebinary          = gen_utils.makefilebinary
local getdefoldprops          = gen_utils.getdefoldprops
local getcomponents           = gen_utils.getcomponents 

local PATH_SEPARATOR          = gen_utils.PATH_SEPARATOR
local CMD_COPY                = gen_utils.CMD_COPY
local CMD_MKDIR               = gen_utils.CMD_MKDIR

local WHITE_PNG               = gen_utils.WHITE_PNG
local NORMAL_PNG              = gen_utils.NORMAL_PNG
local GREY_PNG                = gen_utils.GREY_PNG
local BLACK_PNG               = gen_utils.BLACK_PNG

------------------------------------------------------------------------------------------------------------

local function setgendata( newgendata )
    gendata = newgendata 
end

------------------------------------------------------------------------------------------------------------

local function getGetGLTFBinFiles( sourcefilepath, filepath, name )
    
    -- Remove the extension from the sourcefilepath and replace with bin
    local newsourcefilepath, ext = string.match(sourcefilepath, "(.+)%.(.+)")
    if(ext == "gltf" or ext == "GLTF") then 
        newsourcefilepath = newsourcefilepath..".bin"
        local animfilepath = filepath..gendata.folders.animations..PATH_SEPARATOR..name..".bin"
        os.execute(CMD_COPY..' "'..newsourcefilepath..'" "'..animfilepath..'"')
    end
end

------------------------------------------------------------------------------------------------------------

local function getBlenderTexture( filepath, mesh, texturename, default )

    if(mesh.textures and mesh.textures[texturename]) then 
        -- copy to local folder first 
        return mesh.textures[texturename]
    else 
        return gendata.project_path..PATH_SEPARATOR..gendata.folders.materials..PATH_SEPARATOR..default
    end
end

------------------------------------------------------------------------------------------------------------

local function processtexturefile( filepath, mesh, source, default )

    local texfile = filepath..gendata.folders.materials..PATH_SEPARATOR..default
    local outputfile = localpathname(gendata, gendata.project_path..PATH_SEPARATOR..gendata.folders.materials..PATH_SEPARATOR..default)
    if(mesh.textures and mesh.textures[source]) then 
        texfile = string.match(mesh.textures[source], "([^"..PATH_SEPARATOR.."]+)$")
        -- copy to local folder first 
        local targetfile = filepath..gendata.folders.images..PATH_SEPARATOR..texfile
        os.execute(CMD_COPY..' "'..mesh.textures[source]..'" "'..targetfile..'"')
        outputfile = localpathname(gendata, filepath)..gendata.folders.images.."/"..texfile
    end
    return outputfile
end 

------------------------------------------------------------------------------------------------------------

local function processaomaetalroughness( filepath, mesh )

    local aofile = getBlenderTexture( filepath, mesh, "emissive_strength", 'white.png')
    local metalfile = getBlenderTexture( filepath, mesh, "metallic_map", 'black.png')
    local roughfile = getBlenderTexture( filepath, mesh, "roughness_map", 'grey.png')
    local outputfile = filepath..gendata.folders.images..PATH_SEPARATOR..mesh.name.."AMRtexture.png"
    materialSimple.genAMRMap( outputfile, aofile, metalfile, roughfile, 1024 )
    outputfile = localpathname(gendata, filepath)..gendata.folders.images.."/"..mesh.name.."AMRtexture.png"

    return outputfile
end

------------------------------------------------------------------------------------------------------------

local function processalbedomixshader( filepath, mesh )
    local source1file = getBlenderTexture( filepath, mesh, "base_color", 'white.png')
    local source2file = getBlenderTexture( filepath, mesh, "mix_color", 'black.png')
    local factor = tonumber(mesh.mix_shader_factor)
    local outputfile = filepath..gendata.folders.images..PATH_SEPARATOR..mesh.name.."AMixtexture.png"
    materialSimple.genAlbedoMixShaderMap( outputfile, source1file, source2file, factor, 1024 )
    outputfile = localpathname(gendata, filepath)..gendata.folders.images.."/"..mesh.name.."AMixtexture.png"

    return outputfile
end

------------------------------------------------------------------------------------------------------------

local function processalbedoalpha( filepath, mesh )

    if(mesh.textures == nil or mesh.textures["alpha_map"] == nil) then 
        return processtexturefile(filepath, mesh, 'base_color', 'white.png')
    end 

    local basefile = getBlenderTexture( filepath, mesh, "base_color", 'white.png')
    local alphafile = getBlenderTexture( filepath, mesh, "alpha_map", 'white.png')
    local outputfile = filepath..gendata.folders.images..PATH_SEPARATOR..mesh.name.."AlbedoAlpha.png"
--    print( outputfile, basefile, alphafile )
    if(basefile ~= 'white.png' and alphafile ~= 'white.png' and basefile == alphafile) then 
        os.execute(CMD_COPY..' "'..basefile..'" "'..outputfile..'"')
    else 
        materialSimple.genAlbedoAlphaMap( outputfile, basefile, alphafile, 1024 )
    end 
    outputfile = localpathname(gendata, filepath)..gendata.folders.images.."/"..mesh.name.."AlbedoAlpha.png"

    return outputfile
end

------------------------------------------------------------------------------------------------------------

local function makebufferfile(name, filepath, mesh )

    local bufferdata = bufferfiledata
    local bufferfilepath = filepath..gendata.folders.meshes..PATH_SEPARATOR..name..".buffer"
    --print(bufferfilepath)
    --pprint(name, gendata.meshes[name] )
    if(mesh == nil or mesh.tris == nil) then return "" end

    local verts = mesh.vertices 
    local normals = mesh.normals

    local vertdata = {}
    local uvdata = {}
    local uvdata2 = {}
    local normdata = {}
    for k,v in pairs(mesh.tris) do 
        for i,t in pairs(v.tri) do 
            local vert = verts[t.vertex + 1]
            tinsert(vertdata, vert.x)
            tinsert(vertdata, vert.y)
            tinsert(vertdata, vert.z)
            tinsert(uvdata, t.uv.x)
            tinsert(uvdata, t.uv.y)
            if(t.uv2) then 
                tinsert(uvdata2, t.uv2.x)
                tinsert(uvdata2, t.uv2.y)    
            end 
            if(normals) then 
                local norm = normals[t.normal + 1]
                if(norm) then 
                    tinsert(normdata, norm.x)
                    tinsert(normdata, norm.y) 
                    tinsert(normdata, norm.z)
                end
            end
        end
    end

    bufferdata = string.gsub(bufferdata, "MESH_VERTEX_DATA", table.concat(vertdata, ","))
    bufferdata = string.gsub(bufferdata, "MESH_NORMAL_DATA", table.concat(normdata, ","))
    bufferdata = string.gsub(bufferdata, "MESH_UV_DATA1", table.concat(uvdata, ","))

    -- Add uv2 coords to buffer - for Defold use.
    local texcoord1 = ""
    if(gendata.config.sync_mat_uv2 == true) then 
        texcoord1 = string.gsub(buffertexcoord1, "MESH_UV_DATA2", table.concat(uvdata2, ","))
    end
    bufferdata = string.gsub(bufferdata, "MESH_UV_TEXCOORD1", texcoord1)

    makefile( bufferfilepath, bufferdata )
    return bufferfilepath
end

------------------------------------------------------------------------------------------------------------

local function maketexturefile( filepath, mesh )

    local texturefiles = {}
    local texturenames = {}
    if(gendata.config.sync_shader == "PBR Simple") then 
        -- If a mix shader has been set, then process albedo differently.
        if(mesh.textures and mesh.textures["mix_color"]) then 
            tinsert( texturefiles, processalbedomixshader(filepath, mesh) )
        else 
            tinsert( texturefiles, processalbedoalpha(filepath, mesh ) )
        end 
        tinsert(texturenames, "albedoMap")

        -- Build an AO, metallic and roughness map
        tinsert( texturefiles, processaomaetalroughness(filepath, mesh) )
        tinsert(texturenames, "aoMetallicRoughnessMap")
        tinsert( texturefiles, processtexturefile(filepath, mesh, 'emissive_color', 'black.png') )
        tinsert(texturenames, "emissiveMap")
        tinsert( texturefiles, processtexturefile(filepath, mesh, 'normal_map', 'normal.png') )
        tinsert(texturenames, "normalMap")
        tinsert( texturefiles, processtexturefile(filepath, mesh, 'reflection_map', 'grey.png') )
        tinsert(texturenames, "reflectionMap")
    else 
        tinsert( texturefiles, processtexturefile(filepath, mesh, 'base_color', 'white.png') )
        tinsert(texturenames, "__sampler__0__0")
    end
    return texturefiles, texturenames
end 


------------------------------------------------------------------------------------------------------------

local function makemeshfile(name, filepath, mesh, material_override, mprops )

    if(mesh == nil) then return "" end 
    
    local meshdata = meshfiledata
    local meshfilepath = filepath..gendata.folders.meshes..PATH_SEPARATOR..name..".mesh"
    local materialfile = "/builtins/materials/model.material"
    if(material_override) then materialfile = material_override end

    if(gendata.config.sync_shader == "PBR Simple" and not material_override) then 
        materialfile = localpathname(gendata, filepath)..gendata.folders.materials.."/pbr-simple.material"
        if( mesh.matname and string.endswith(mesh.matname, "_LightMap")) then 
            materialfile = localpathname(gendata, filepath)..gendata.folders.materials.."/pbr-lightmap.material"
        end
        meshdata = string.gsub(meshdata, "MATERIAL_FILE_PATH", materialfile)
    else 
        meshdata = string.gsub(meshdata, "MATERIAL_FILE_PATH", materialfile)
    end 

    -- If a texture file is found, copy it, then assign it
    local alltextures, alltexturenames = maketexturefile( filepath, mesh )
    local texture_file_list = ""

    -- The alltextures file needs overriding itself to ensure textures are properly overridden
    for k,v in ipairs(alltextures) do 

        local name = alltexturenames[k]
        local texture_override = nil 

        if(mprops and mprops[1] and mprops[1].material_texture) then 
            name = mprops[1].material_texture
            alltexturenames[k] = name
            texture_override = {
                [name] = mprops[1].material_texture_defold
            }
            v = mprops[1].material_texture_defold
            alltextures[k] = mprops[1].material_texture_defold
        end

        -- if(mprops) then 
        --     print("===================>>>")
        --     --for k,v in pairs(mprops[1]) do print(k,v) end
        --     print(mprops[1].material_texture)
        --     print(mprops[1].material_texture_defold)
        --     print(name)
        --     print(v)
        --     print(alltextures[k])
        --     print("===================<<<")
        -- end        

        -- If there is a conversion, then check texture id mapping and replace.
        if(texture_override and texture_override[name]) then 
            local tmap = texture_override[name]
            texture_file_list = texture_file_list..'textures: "'..tmap..'"\n'
        else 
            texture_file_list = texture_file_list..'textures: "'..v..'"\n'
        end
    end
    meshdata = string.gsub(meshdata, "MESH_TEXTURE_FILES", texture_file_list)

    if( mesh.gltf) then
        local ext, base = getextension( mesh.gltf )
        local gltf_ext = "."..ext
        
        -- if(ext == "gltf") then 
        --     meshfilepath = filepath..gendata.folders.meshes..PATH_SEPARATOR..name..".bin"
        --     os.execute(CMD_COPY..' "'..base..'.bin" "'..meshfilepath..'"')
        -- end
        meshfilepath = filepath..gendata.folders.meshes..PATH_SEPARATOR..name..gltf_ext
        os.execute(CMD_COPY..' "'..mesh.gltf..'" "'..meshfilepath..'"')
        
        -- Check if there are bin files in the source path
        getGetGLTFBinFiles( mesh.gltf, filepath, name )
    else 
        local bufferfilepath = makebufferfile( name, filepath, mesh )
        meshdata = string.gsub(meshdata, "BUFFER_FILE_PATH", localpathname(gendata, bufferfilepath))
        makefile( meshfilepath, meshdata )
    end 
    -- Return meshfile path and mesh info (for model data)
    return meshfilepath, { matfile = materialfile, texfiles = alltextures, texnames = alltexturenames }
end

------------------------------------------------------------------------------------------------------------

local function makescriptfile( name, filepath, objs )

    if(objs == nil) then return "" end
    if(table.count(objs) < 1) then return "" end

    local locallua = localpathname(gendata, filepath..gendata.folders.scripts..PATH_SEPARATOR.."gop")
    locallua = locallua:sub(2, -1)
    locallua = locallua:gsub("/", "%.")

    local scriptfilepath = filepath..gendata.folders.scripts..PATH_SEPARATOR..name..".script"
    local scriptdata = "-- Autogenerated properties script\n"
    local propcount = 0

    scriptdata = scriptdata..'\nlocal gop = require("'..locallua..'")\n'
    local initscript = ""
    local updatescript = ""

    for k,v in pairs(objs) do 
        if(v.props) then 
            for pkey, pvalue in pairs(v.props) do 
                propcount = propcount + 1
                scriptdata = scriptdata..'gop.set("'..pkey..'", "'..pvalue..'")\n'
            end 
        end 
        if(v.defold_props) then 
            for k, v in ipairs(v.defold_props) do 
                if(v.command == "Set Key/Value") then 
                    propcount = propcount + 1
                    if(v.keyval.is_table == true) then 
                        scriptdata = scriptdata..'gop.set("'..tostring(v.keyval.key)..'", {} )\n'
                    else
                        scriptdata = scriptdata..'gop.set("'..tostring(v.keyval.key)..'", "'..tostring(v.keyval.value)..'")\n'
                    end
                end
                if(v.command == "Init Script") then 
                    propcount = propcount + 1
                    initscript = initscript.."    "..tostring(v.scipt_init)..'\n'
                end
                if(v.command == "Update Script") then 
                    propcount = propcount + 1
                    updatescript = updatescript.."    "..tostring(v.scipt_init)..'\n'
                end
            end
        end
    end 

    scriptdata = scriptdata..'\nfunction init(self)\n'
    scriptdata = scriptdata..'\tself.props = gop.getall()\n'
    scriptdata = scriptdata..'\t-- Run initial setup on properties here.\n'
    scriptdata = scriptdata..'\t-- pprint(self.props) -- Debug props\n'

    scriptdata = scriptdata..initscript

    scriptdata = scriptdata..'end\n'

    scriptdata = scriptdata..'\nfunction update(self)\n'
    scriptdata = scriptdata..updatescript
    scriptdata = scriptdata..'end\n'

    if(propcount == 0) then return "" end
    makefile( filepath..gendata.folders.scripts..PATH_SEPARATOR.."gop.lua", gopscript )
    makefile( scriptfilepath, scriptdata )
    return localpathname(gendata, filepath..gendata.folders.scripts..PATH_SEPARATOR..name..".script")
end

------------------------------------------------------------------------------------------------------------

local function makegofile( name, filepath, go )

    local godata = gofiledata
    local meshdata = nil

    local animname, animfile = nil, nil 
    if(go.animated and gendata.anims) or gendata.gltf then
        animname = go.name
        animfile = "gltf"
        if(gendata.anims) then animfile = gendata.anims[animname] end 

        if(animname and animfile) then 
            godata = gomodelfiledata[MODEL_VERSION]
            if( gendata.gltf ) then 
                godata = string.gsub(godata, "MESH_GO_ROTATION", inv_rotation)            
            else 
                godata = string.gsub(godata, "MESH_GO_ROTATION", default_rotation)
            end
        else 
            -- Fall back to mesh if anim isnt available
            go.type = "MESH"
            go.animated = nil
        end 
    end

    local gofilepath = filepath..gendata.folders.gos..PATH_SEPARATOR..name..".go"
    godata = string.gsub(godata, "MESH_GO_NAME", go.name.."_mesh")
    -- If animated need to use model type 
    local matname = nil
    if(go.type == "MESH")  then 

        local meshurl = gendata.meshes[name]
        if(meshurl) then 
            local meshfilepath = ""
            local meshpath = string.gsub( meshurl, "\\", "\\\\" )

            local fh = io.open( meshpath, "rb" )
            if(fh) then
                local fdata = fh:read("*all")
                fh:close()
                local mesh = {}
                mesh = json.decode( fdata )

                local material_override = nil
                local dprops = getdefoldprops(go, "Material Name")
                if(dprops) then 
                    -- Check to make sure we are replacing the correct material
                    material_override = dprops[1].material_defold
                end

                local mprops = getdefoldprops(go, "Material Texture")

                dprops = getdefoldprops(go, "Collider")
                if(dprops) then 
                    -- Add embedded collider component to go!
                    local collider_group = dprops[1].collider_group
                    local collider_mask = dprops[1].collider_mask
                    local colldata = gomodelcollisiondata
                    
                    colldata = string.gsub(colldata, "COLLISION_ID", collision_counter)
                    collision_counter = collision_counter + 1

                    colldata = string.gsub(colldata, "COLLISION_GROUP", collider_group)
                    colldata = string.gsub(colldata, "COLLISION_MASK", collider_mask)
                    colldata = string.gsub(colldata, "COLLISION_POS_X", "0.0")
                    colldata = string.gsub(colldata, "COLLISION_POS_Y", "0.0")
                    colldata = string.gsub(colldata, "COLLISION_POS_Z", "0.0")
                    colldata = string.gsub(colldata, "COLLISION_ROT_X", "0.0")
                    colldata = string.gsub(colldata, "COLLISION_ROT_Y", "0.0")
                    colldata = string.gsub(colldata, "COLLISION_ROT_Z", "0.0")
                    colldata = string.gsub(colldata, "COLLISION_DIM_X", go.dimensions.x / 2)
                    colldata = string.gsub(colldata, "COLLISION_DIM_Y", go.dimensions.y / 2)
                    colldata = string.gsub(colldata, "COLLISION_DIM_Z", go.dimensions.z / 2)
                
                    godata = string.gsub(godata, "GO_COLLIDER_COMPONENT", colldata)
                else 
                    godata = string.gsub(godata, "GO_COLLIDER_COMPONENT", "")
                end                

                local meshfile, mdata = makemeshfile(name, filepath, mesh, material_override, mprops)
                if( animfile == "gltf" ) then animfile = localpathname(gendata,  meshfile ) end
                meshdata = mdata 
                matname = mesh.matname
                meshfilepath = localpathname(gendata, meshfile)
            end

            if(go.animated == nil) then
                godata = string.gsub(godata, "MESH_FILE_PATH", meshfilepath)
            end
        end
    end 

    godata = string.gsub(godata, "GO_FILE_SCRIPT", "")
    godata = getcomponents( go, godata )

    -- Apply animation specific changes to model data
    if(animname and animfile) then 
        godata = string.gsub(godata, "MESH_FILE_PATH", animfile)

        if(meshdata) then 
            godata = string.gsub(godata, "MATERIAL_FILE_PATH", meshdata.matfile)
            local texfiles = ""
            local props = getdefoldprops(go, "Material Texture")
            local texture_override = nil 

            for k, texfile in ipairs(meshdata.texfiles) do
                local name = meshdata.texnames[k]
                texfiles = texfiles.."    \"textures {\\n\"\n"
                texfiles = texfiles.."    \"    sampler: \\\""..name.."\\\"\\n\"\n"

                if(gendata.config.sync_shader == "PBR Simple") then 
                    
                    if(props and props.material_texture == name) then 
                        texture_override = texture_override or {}
                        texture_override[props.material_texture] = props.material_texture_defold
                    end

                    -- If there is a conversion, then check texture id mapping and replace.
                    if(texture_override and texture_override[name]) then 
                        local tmap = texture_override[name]
                        texfiles = texfiles.."    \"    texture: \\\""..tmap.."\\\"\\n\"\n"
                    else 
                        texfiles = texfiles.."    \"    texture: \\\""..texfile.."\\\"\\n\"\n"
                    end
                else 
                    texfiles = texfiles.."    \"    texture: \\\""..texfile.."\\\"\\n\"\n"
                end
                texfiles = texfiles.."    \"}\\n\"\n"
            end
            godata = string.gsub(godata, "GO_MESH_TEXTURE_FILES", texfiles)

            if(MODEL_VERSION > 1 and matname) then 
                godata = string.gsub(godata, "MATERIAL_NAME", matname)        
            end
        end 

        if(gendata.anim) then 
            local animationfile = animfile
            if(MODEL_VERSION > 1) then 
                animfile = string.format('    "    skeleton: \\\"'..animfile..'\\\"\\n"')
                animationfile = string.format('    "    animations: \\\"'..animfile..'\\\"\\n"')
                animname = string.format('    "    default_animation: \\\"'..animname..'\\\"\\n"')
            end
            godata = string.gsub(godata, "MODEL_SKELETON_FILE", animfile)
            godata = string.gsub(godata, "MODEL_ANIM_FILE", animationfile)
            godata = string.gsub(godata, "MODEL_ANIM_NAME", animname)

        else
            godata = string.gsub(godata, "MODEL_SKELETON_FILE", "")
            godata = string.gsub(godata, "MODEL_ANIM_FILE", "")
            godata = string.gsub(godata, "MODEL_ANIM_NAME", "")
            godata = string.gsub(godata, "GO_DATA_FILE_COMPONENTS", "")
        end
    end 

    makefile( gofilepath, godata )
    return gofilepath
end


------------------------------------------------------------------------------------------------------------

local function genmaterial( material_path, vpname, fpname, matname, pbrmaterial )
    local material_vp_path = material_path..vpname
    local material_fp_path = material_path..fpname
    local matstr = pbrmaterial.material:gsub("MATERIAL_VP", localpathname(gendata, material_vp_path))
    matstr = matstr:gsub("MATERIAL_FP", localpathname(gendata, material_fp_path))

    local lv = gendata.config.sync_light_vec
    local light_vector = '\tx: '..lv.x..'\n\ty: '..lv.y..'\n\tz: '..lv.z..'\n\tw: 1.0'
    matstr = matstr:gsub("MATERIAL_LIGHT_VECTOR", light_vector)

    local mp = gendata.config.sync_mat_params
    local mat_params = '\tx: '..mp.x..'\n\ty: '..mp.y..'\n\tz: '..mp.z..'\n\tw: 0.1'
    matstr = matstr:gsub("MATERIAL_PARAMS", mat_params)

    makefile( material_path..matname, matstr)

    pbrmaterial.vp = pbrmaterial.vp:gsub("MATERIAL_VP_LIGHTDIR", pbrmaterial.vp_lightdir_global)
    makefile( material_vp_path, pbrmaterial.vp )
    makefile( material_fp_path, pbrmaterial.fp )
    makefilebinary( material_path.."white.png", WHITE_PNG )
    makefilebinary( material_path.."normal.png", NORMAL_PNG )
    makefilebinary( material_path.."grey.png", GREY_PNG )
    makefilebinary( material_path.."black.png", BLACK_PNG )
end 

------------------------------------------------------------------------------------------------------------

local function makecollection( collectionname, objects, objlist )

    local colldata = gocollectionheader

    -- Objects are children of a collection object (ideally)
    --    If no collections, then all in root. 
    local rootchildren = ""
    
    for k,v in pairs(objects) do 

        local name = v.name or ("Dummy"..k)
        local objdata = gocollectiongeneric
        if(v.type == "MESH") then 
            objdata = gocollectiondata

            local gofilepath = makegofile( name, gendata.project_path..PATH_SEPARATOR, v )
            objdata = string.gsub(objdata, "GO_FILE_PATH", localpathname(gendata, gofilepath))

        elseif(v.type == "CAMERA") then 
            objdata = gcollectioncamera
            if(v.settings) then 
                objdata = string.gsub(objdata, "GO_CAMERA_FOV", tostring(v.settings.fov))
                objdata = string.gsub(objdata, "GO_CAMERA_NEAR", tostring(v.settings.near))
                objdata = string.gsub(objdata, "GO_CAMERA_FAR", tostring(v.settings.far))
            else 
                objdata = string.gsub(objdata, "GO_CAMERA_FOV", tostring(0.7854))
                objdata = string.gsub(objdata, "GO_CAMERA_NEAR", tostring(0.1))
                objdata = string.gsub(objdata, "GO_CAMERA_FAR", tostring(1000.0))
            end

        elseif(v.type == "LIGHT") then 
            objdata = gocollectiongeneric
            objdata = getcomponents(v, objdata, true)
        else 
            objdata = getcomponents(v, objdata, true)
        end 

        objdata = string.gsub(objdata, "GO_NAME", name)

        -- Check if this object is a root level obj.
        if( v.parent == nil) then 
            rootchildren = rootchildren.."\tchildren: \""..name.."\"\n"
        end
                
        local children = ""
        if(v.children) then 
            for k,v in pairs(v.children) do
                children = children.."    children: \""..v.."\"\n"
            end
        end
        objdata = string.gsub(objdata, "GO_CHILDREN", children)

        local position = "x:0.0\n\ty:0.0\n\tz:0.0"
        if(v.location) then 
            if(gendata.gltf) then 
                position = "x:"..v.location.x.."\n\ty:"..v.location.y.."\n\tz:"..v.location.z
            else 
                position = "x:"..v.location.x.."\n\ty:"..v.location.y.."\n\tz:"..v.location.z
            end
        end 
        objdata = string.gsub(objdata, "GO_POSITION", position)

        local rotation = "x:0.0\n\ty:0.0\n\tz:0.0\n\tw:1.0"
        if(v.rotation) then 
            rotation = "x:"..v.rotation.quat.x.."\n\ty:"..v.rotation.quat.y
            rotation = rotation.."\n\tz:"..v.rotation.quat.z.."\n\tw:"..v.rotation.quat.w
        end 
        objdata = string.gsub(objdata, "GO_ROTATION_QUATERNION", rotation)

        local scaling = "x:1.0\n\ty:1.0\n\tz:1.0"
        if(v.scaling) then 
            scaling = "x:"..v.scaling.x.."\n\ty:"..v.scaling.y.."\n\tz:"..v.scaling.z
        end 
        objdata = string.gsub(objdata, "GO_SCALE", scaling)

        colldata = colldata.."\n"..objdata
    end 

    -- Setup collection script file
    local scriptpath = makescriptfile( collectionname, gendata.project_path..PATH_SEPARATOR, objlist )
    local rootscript = string.gsub(gcollectionrootscript, "ROOT_SCRIPT_NAME", collectionname) 
    rootscript = string.gsub(rootscript, "ROOT_SCRIPT", scriptpath) 
    if(scriptpath == "") then rootscript = '\"\"' end

    -- Add the root instance 
    local newcollection = string.gsub(gcollectionroot, "ROOT_CHILDREN", rootchildren)
    newcollection = string.gsub(newcollection, "ROOT_ROTATION", default_rotation)
    newcollection = string.gsub(newcollection, "COLLECTION_SCRIPT", rootscript)
    colldata = colldata.."\n"..newcollection
    
    -- Write the file
    local scenepath = gendata.project_path..PATH_SEPARATOR
    makefile( scenepath..collectionname..".collection", colldata )

end 

------------------------------------------------------------------------------------------------------------

return {
    makebufferfile              = makebufferfile,
    maketexturefile             = maketexturefile,
    makemeshfile                = makemeshfile,
    makescriptfile              = makescriptfile,
    makegofile                  = makegofile,
    genmaterial                 = genmaterial,
    makecollection              = makecollection,
    setgendata                  = setgendata,
}


------------------------------------------------------------------------------------------------------------