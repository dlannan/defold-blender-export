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

local png = require("png")

-- Take in three textures and combine into one
local function genAOMetallicRoughnessMap( ao, metallic, roughness )

    local aopng = png.pngLoad(ao)
    local metpng = png.pngLoad(metallic)
    local roughpng = png.pngLoad(roughness)
end

return {
    genAMRMap       = genAOMetallicRoughnessMap,
}