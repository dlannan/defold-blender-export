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

-- material-textures.lua
--  A set of methods to do the following:
-- https://www.khronos.org/blog/art-pipeline-for-gltf
--    Merge AO, Metallic and Roughness textures into a single texture
--    Merge emission with reflection/env textures into a single texture
--
--  AO-Metallic-Roughness texture will be 32 bit png rgba - 8bit AIO (r) 8bit Metallic (b) + 8bit Roughness (g)
--  The above intends to make the Simple PBR material only require 5 texture samplers (would prefer 4)
-- 
--  AO is sourced from the BSDF Emission Strength parameter. This may also be able to be used as a 
--    shadow map potentially.
-- 
--  Other features will be via shader params:
--    param.x - Ambient light response 
--    param.y - Gloss response level        -- These may become Gloss/Specular texture.
--    param.z - Specular response level
------------------------------------------------------------------------------------------------------------

local png = require("png")
local str = tostring
------------------------------------------------------------------------------------------------------------
-- Helper to merge pngs together. Use the source texture to merge dest into it. 
-- Params:
--   target - target texture that will be the target for the merge texture
--   merge - the texture that will be added into the target texture
--   taerget_channel - where the incoming channel will be copied to
--   merge_channel - where the merge texture channel is sourced from 
--
-- Note: Textures will attempt to merge different sizes by scaling. 
--       It is better if they are the same size. 

local function mergeTextures( target, merge, target_channel, merge_channel)

    print("[ COLOR TYPE TARGET ] "..str(target.info_ptr.color_type))
    print("[ COLOR TYPE MERGE ] "..str(merge.info_ptr.color_type))

    local scalex = target.info_ptr.width / merge.info_ptr.width
    local scaley = target.info_ptr.height / merge.info_ptr.height 
    
    -- Only support 8 bit depth channels atm.
    local targetwide = target.info_ptr.rowbytes
    local mergewide = merge.info_ptr.rowbytes

    local targetchannels = target.info_ptr.channels
    local mergechannels = merge.info_ptr.channels

    -- Iterate height then rows
    local merge_pos = 0 
    local target_pos = 0
    for y = 0, merge.info_ptr.height-1 do 
        local srcrow = merge.row_pointers[y]
        local dstrow = target.row_pointers[math.floor(y * scaley + 0.4999)]
        for x = 0, merge.info_ptr.width-1 do
            local srcpixel = srcrow + x * mergechannels + merge_channel
            local dstpixel = dstrow + math.floor(x * scalex + 0.4999) * targetchannels + target_channel
            dstrow[dstpixel] = srcrow[srcpixel]
        end
    end
end

------------------------------------------------------------------------------------------------------------

-- Take in three textures and combine into one
local function genAOMetallicRoughnessMap( mergefile, ao, metallic, roughness )

    local aopng = png.pngLoad(ao)
    mergeTextures( aopng, png.pngLoad(metallic), 2, 2 )
    mergeTextures( aopng, png.pngLoad(roughness), 3, 3 )
    png.pngSave( mergefile, aopng )
end

------------------------------------------------------------------------------------------------------------

return {
    genAMRMap       = genAOMetallicRoughnessMap,
}

------------------------------------------------------------------------------------------------------------
