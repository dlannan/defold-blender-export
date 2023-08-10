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

local png = require("defoldsync.png")
local str = tostring

------------------------------------------------------------------------------------------------------------
-- Helper to create a colorramp texture that matches Blenders ColorRamp (roughly)
-- Params:
--   target - target texture that will be the target for the merge texture
--   ramp_values - the data needed to make the color ramp
--

local function genRampTexture( target, ramp_values )

end

------------------------------------------------------------------------------------------------------------
-- Helper to mix pngs together. Use the source textures and mix source1 with source2 by factor X
-- Params:
--   target - target texture that will be the target for the merge texture
--   source1 - source texture to mix
--   source2 - second source texture to mix
--   Factor - 0->1 factor proportion of source1. Source2 proportion is 1-factor
--
-- Note: Textures will attempt to merge different sizes by scaling. 
--       It is faster if they are the same size.

local function mixTextures( target, source1, source2, factor )

    local in1 = source1 
    local in2 = source2
    local scalex = target.info_ptr.width / in1.info_ptr.width
    local scaley = target.info_ptr.height / in1.info_ptr.height 

    local targetchannels = target.info_ptr.channels
    local amp1 = factor * 1000.0
    local amp2 = (1.0 - factor) * 1000.0

    for y = 0, target.info_ptr.height-1 do 
        local sy = math.floor(y / scaley)
        local srcrow1 = in1.row_pointers[sy]
        local srcrow2 = in2.row_pointers[sy]
        local dstrow = target.row_pointers[y]
        for x = 0, target.info_ptr.width-1 do
            local srcpixel1 = srcrow1 + math.floor(x / scalex) * in1.info_ptr.channels
            local srcpixel2 = srcrow2 + math.floor(x / scalex) * in2.info_ptr.channels
            local dstpixel = dstrow + x * targetchannels
            for rgb = 0, 2 do 
                dstpixel[rgb] = math.floor((srcpixel1[rgb] * amp1 + srcpixel2[rgb] * amp2) * 0.001)
            end
            dstpixel[3] = 0xff
        end
    end 
end 

------------------------------------------------------------------------------------------------------------
-- Helper to merge pngs together. Use the source texture to merge dest into it. 
-- Params:
--   target - target texture that will be the target for the merge texture
--   merge - the texture that will be added ito the target texture
--   taerget_channel - where the incoming channel will be copied to
--   merge_channel - where the merge texture channel is sourced from 
--
-- Note: Textures will attempt to merge different sizes by scaling. 
--       It is better if they are the same size. 

local function mergeTextures( target, merge, target_channel, merge_channel)

    -- print("[ COLOR TYPE TARGET ] "..str(target.info_ptr.color_type))
    -- print("[ COLOR TYPE MERGE ] "..str(merge.info_ptr.color_type))

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
    for y = 0, target.info_ptr.height-1 do 
        local sy = math.floor(y / scaley)
        local srcrow = merge.row_pointers[sy]
        local dstrow = target.row_pointers[y]
        for x = 0, target.info_ptr.width-1 do
            local srcpixel = srcrow + math.floor(x / scalex) * mergechannels + merge_channel
            local dstpixel = dstrow + x * targetchannels + target_channel
            dstpixel[0] = srcpixel[0]
        end
    end
end

------------------------------------------------------------------------------------------------------------
-- Generate a Mix Texture from mix shader source files
local function genAlbedoMixShaderMap( mergefile, base_color, mix_color, factor, outsize )

    local outpng = png.create( mergefile, outsize, outsize, true )
    mixTextures( outpng, png.load(base_color), png.load(mix_color), factor )  
    png.save( mergefile, outpng )
end

------------------------------------------------------------------------------------------------------------
-- Take in three textures and combine into one
local function genAOMetallicRoughnessMap( mergefile, ao, metallic, roughness, outsize )

    local outpng = png.create( mergefile, outsize, outsize, true )
    mergeTextures( outpng, png.load(ao), 0, 0 )           -- red
    mergeTextures( outpng, png.load(metallic), 2, 2 )     -- green
    mergeTextures( outpng, png.load(roughness), 1, 1 )    -- blue
    -- mergeTextures( aopng, png.load(roughness), 3, 1 ) -- alpha
    png.save( mergefile, outpng )
end

------------------------------------------------------------------------------------------------------------
-- Take in three textures and combine into one
local function genAlbedoAlphaMap( mergefile, albedo, alpha, outsize )

    local outpng =  png.load(albedo)
    mergeTextures( outpng, png.load(alpha), 3, 0 )          -- red -> alpha
    png.save( mergefile, outpng )
end


-- Make a simple 16x16 32bit value texture 
local function genValueTexture( filename, value )

end

-- Test
-- genAOMetallicRoughnessMap( "merge.png", "red.png", "blue.png", "green.png")

------------------------------------------------------------------------------------------------------------

return {
    genAMRMap               = genAOMetallicRoughnessMap,
    genAlbedoAlphaMap       = genAlbedoAlphaMap,
    genValueTexture         = genValueTexture,
    genAlbedoMixShaderMap   = genAlbedoMixShaderMap,
}

------------------------------------------------------------------------------------------------------------
