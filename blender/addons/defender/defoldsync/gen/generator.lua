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

-- A simple set of methods for generating various Defold data files.
------------------------------------------------------------------------------------------------------------

local ffi                   = require("ffi")
local json                  = require("defoldsync.utils.json")
local materialSimple        = require("defoldsync.material.textures")
local utils                 = require("defoldsync.gen.utils")

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

------------------------------------------------------------------------------------------------------------
-- Change this to change model version use
local MODEL_VERSION     = 2

------------------------------------------------------------------------------------------------------------

local gendata = {}

gendata.folders = {
    base        = "",
    images      = "images",
    meshes      = "meshes",
    gos         = "gameobjects",
    materials   = "materials",
    animations  = "animations",
    scripts     = "scripts",
}

gendata.images = {
    white 	    = "temp.png",
    black 	    = "tempBlack.png",
    norm 	    = "tempNormal.png",
}

gendata.files = {
    version     = MODEL_VERSION,

    bufferfile 	= "temp.buffer",
    gofile 		= "temp.go",
    meshfile 	= "temp.mesh",
    scriptfile 	= "temp.script",

    shaderfile 	= "pbr-simple.material",
}

------------------------------------------------------------------------------------------------------------
-- This will be used to allow custom materials and shaders (coming soon...)
local pbrsimple = require("defoldsync.material.pbrsimple")
local pbrlightmap = require("defoldsync.material.pbrlightmap")

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

local function makefolders(collectionname, base, subfolder, config)
    gen_utils.makefolders(collectionname, base, subfolder, config, gendata)
end

------------------------------------------------------------------------------------------------------------

local gen_make      = require("defoldsync.gen.makefiles")

local genmaterial             = gen_make.genmaterial
local makecollection          = gen_make.makecollection
local setupgendata            = gen_make.setgendata

------------------------------------------------------------------------------------------------------------
-- Process children (take parents and work out their children)

local function processSceneChildren(objs)

    tempobjs = utils.deepcopy(objs)
    newobjs = {}

    -- Process all root objects first
    for k,v in pairs(tempobjs) do 

        if(v.parent == nil and v.name) then 
            newobjs[v.name] = v
            newobjs[v.name].children = nil
            tempobjs[v.name] = nil
        end
    end 

    -- Only children should now remain. Process parents that are in newobjs only. 
    --  Keep doing this (down each level) until the tempobjs have all been assigned 
    local levellookup = { newobjs }

    -- More than 10 levels is stupid. Seriously, reorg your structure!
    for level = 1, 10 do 
        local nextlevel = {}
        local LL = levellookup[level]
        for k,v in pairs(tempobjs) do 

            if(v.parent and v.parent.name) then 
                if(LL[v.parent.name]) then 
                    local pobj = LL[v.parent.name]
                    if(pobj) then 
                        pobj.children = pobj.children or {}
                        pobj.children[v.name] = v
                        tempobjs[k] = nil
                    end
                end

                if(v.children) then 
                    nextlevel[v.name] = v 
                    v.children = nil
                end
            end
        end
        levellookup[level+1] = nextlevel
    end
    return newobjs
end
------------------------------------------------------------------------------------------------------------

local function generateScene( scenelist )
    local allobjs = processSceneChildren(scenelist)
    -- print(json.encode(allobjs))
    return allobjs
end

------------------------------------------------------------------------------------------------------------
-- Process children (take parents and work out their children)

local function processChildren(objs)

    -- Regen children using parent information 
    for k,v in pairs(objs) do 
        local p = v['parent'] or { name = 'nil' }
        if(v['parent'] and v['parent']['name']) then 
            local pobj = objs[v['parent']['name']]
            if(pobj) then
                pobj.children = pobj.children or {} 
                tinsert(pobj.children, v['name'])
            end
        end 
    end
    return objs
end
------------------------------------------------------------------------------------------------------------

local function setupmaterials( project_path )
    -- Make the default pbr material, and shaders
    local material_path = project_path..PATH_SEPARATOR..gendata.folders.materials..PATH_SEPARATOR

    -- Material types can be simple or lightmap now, generate both anyway
    genmaterial( material_path, "pbr-simple.vp", "pbr-simple.fp", "pbr-simple.material", pbrsimple )
    genmaterial( material_path, "pbr-lightmap.vp", "pbr-lightmap.fp", "pbr-lightmap.material", pbrlightmap )
end

------------------------------------------------------------------------------------------------------------

local function setupanimations(  anims )

    for k,v in pairs(anims) do

        -- copy to local folder first 
        local afile = string.match(v, "([^"..PATH_SEPARATOR.."/]+)$")
        local targetfile = gendata.project_path..PATH_SEPARATOR..gendata.folders.animations..PATH_SEPARATOR..afile
        os.execute(CMD_COPY..' "'..v..'" "'..targetfile..'"')
        anims[k] = localpathname(gendata.project_path)..'/'..gendata.folders.animations..'/'..afile
    end 
end 

------------------------------------------------------------------------------------------------------------

local function makescene( scenename, objects, meshes, anims )

    if(objects == nil) then return end 

    gendata.meshes  = meshes
    gendata.anims   = anims
    
    local project_path = gendata.base..gendata.subfolder..PATH_SEPARATOR..scenename
    gendata.project_path = project_path

    setupgendata(gendata)
    setupmaterials( project_path )

    if(anims) then 
        setupanimations( anims ) 
    end

    -- Check for collections first. There may be root objects then collections
    --   below them.
    local collectionlist = {}
    local objectlist = {} 
    for k,v in pairs(objects) do 
        if(k:sub(1, 5) == "COLL_") then 
            collectionlist[k:sub(6, -1)] = v
        else 
            tinsert(objectlist, v)
        end 
    end

    -- Go through the collections in the OBJECTS table 
    for k,v in pairs(collectionlist) do 
        local collobjs = processChildren(v)
        local sceneobjs = generateScene(v)
        makecollection( k, collobjs, sceneobjs )
    end

    local rootobjs = processChildren(objectlist)
    if(table.count(sceneobjs) > 0) then makecollection( scenename, rootobjs ) end 
end

------------------------------------------------------------------------------------------------------------

gendata.makefile        = makefile
gendata.makefolders     = makefolders
gendata.makescene       = makescene

return gendata
