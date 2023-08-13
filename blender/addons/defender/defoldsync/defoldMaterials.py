# -----  MIT license ------------------------------------------------------------
# Copyright (c) 2022 David Lannan

# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:

# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.

# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.
# ------------------------------------------------------------------------

from defoldsync import defoldUtils
from defoldsync import blenderNodeCompiler as bNC

# ------------------------------------------------------------------------

modulesNames = ['DefoldSyncUI']

import bpy, time, queue, re, os, json, shutil, math
from bpy_extras.io_utils import axis_conversion
from io import BytesIO

# ------------------------------------------------------------------------

def makeBlockPNG(texture_path, matname, name, col):

    gencolor = (defoldUtils.to_srgb(col[0]), defoldUtils.to_srgb(col[1]), defoldUtils.to_srgb(col[2]), col[3])

    hexname = defoldUtils.toHex(col[0], col[1], col[2], col[3])
    texname = str(matname) + "_" + name + "_" + hexname
    imgw  = 16 
    imgh  = 16
    filename = texture_path + "/" + texname + ".png"

    img = bpy.data.images.new(texname, width=imgw,height=imgh, alpha=True)
    img.file_format = 'PNG'
    img.generated_color = gencolor

    img.filepath_raw = filename
    img.save() 
    return img

# ------------------------------------------------------------------------

def getImageNodeFromColor(color_node, mat, name, texture_path):

  # Get the link - this should extract embedded nodes too (need to test/check)
  if( color_node.is_linked ):
    link = color_node.links[0]
    link_node = link.from_node
    # print(str(link_node.type))

    if link_node and link_node.type == 'TEX_IMAGE':
      imgnode = link_node.image
      if imgnode and imgnode.type == 'IMAGE':
        return imgnode

    elif link_node and link_node.type == 'VALTORGB':
        
        position  = link_node.inputs["Fac"].default_value
        col       = link_node.color_ramp.evaluate(position)
        return makeBlockPNG(texture_path, mat.name, name, [col[0], col[1], col[2], 1.0])       

    elif link_node and link_node.type == 'BSDF_DIFFUSE':
       return getImageNode( link_node.inputs, "Color", mat, name, texture_path)
    
    elif link_node and link_node.type == 'BSDF_PRINCIPLED':
       return getImageNode( link_node.inputs, "Base Color", mat, name, texture_path)
      
    # elif link_node and link_node.type == 'MIX_RGB':
    #   if link_node.blend_type == 'MULTIPLY':
    #     color1node = link_node.inputs['Color1'].links[0].from_node
    #     color2node = link_node.inputs['Color2'].links[0].from_node

    #     if index == 'Base Color' or index == 'Color':
    #       baseimg = False
    #       if color2node and color2node.type == 'TEX_IMAGE':
    #         imgnode = color2node.image 
    #         if imgnode and imgnode.type == 'IMAGE':
    #           baseImg = imgnode 
    #       if color1node and color1node.type == 'TEX_IMAGE':
    #         lightnode = color1node.image 
    #         if lightnode and lightnode.type == 'IMAGE' and lightnode.name.endswith('_baked'):

    #           nodes = mat.node_tree.nodes
    #           links = mat.node_tree.links
    #           links.new(color1node.outputs[0], colors['Emission'])

    #       if baseimg:
    #         return baseimg

  # Handle metallic roughness and emission if they have just values set (make a little color texture)
#   value_materials = ["metallic_color", "roughness_color", "emissive_color", "alpha_map", "mix_color"]
#   if(color_node.type == "VALUE") and (name in value_materials):
#     col       = color_node.default_value
#     # If alpha is default, then base color will use default settings in alpha channel
#     if(name == "alpha_map" and col == 1.0):
#       return None
#     return makeBlockPNG(texture_path, mat.name, name, [col, col, col, col])

  # if the node is a color vector. Make a tiny color png in temp
  # print( str(color_node.type) + "  " + str(color_node.name) + "   " + str(color_node.default_value))
#   if((color_node.type == "RGBA" or color_node.type == "RGB") and (name == "base_color" or name == "mix_color") ):

#     alpha     = 1.0 
#     col       = color_node.default_value
    
#     # check if this is linked 
#     if( color_node.is_linked ):
#       link = color_node.links[0]
#       link_node = link.from_node
#       col = link_node.outputs[0].default_value

#     return makeBlockPNG(texture_path, mat.name, name, [col[0], col[1], col[2], alpha])

  return None 

def getImageNode( colors, index, mat, name, texture_path ):

  if(not index in colors):
    return None

  color_node = colors[index]
  return getImageNodeFromColor( color_node, mat, name, texture_path)


def addTextureImageNode( mat, textures, name, imgnode, texture_path, context ):
  
  if imgnode != None:
    img = imgnode.filepath_from_user()
    basename = os.path.basename(img)
    splitname = os.path.splitext(basename)

    # print("[ IMG PATH ] " + str(img))
    # print("[ IMG BASE PATH ] " + str(basename))

    if splitname[1] != '.png' and splitname[1] != '.PNG':
      pngimg = os.path.join(texture_path , splitname[0] + ".png")
      if(os.path.exists(pngimg) == False):

        maxwidth = 1024
        maxheight = 1024
        
        imgnode.file_format='PNG' 
        image = bpy.data.images.load(img)
        imgsize = image.size

        image_settings = bpy.context.scene.render.image_settings
        image_settings.color_mode = 'RGBA'        
        image_settings.file_format = "PNG"  
        image.file_format = 'PNG'
        image.colorspace_settings.name = 'sRGB'
        image.alpha_mode = 'CHANNEL_PACKED'

        # Should have some sort of scaling check
        imgscale = 1.0
        if(imgsize[0] > maxwidth):
           imgscale = maxwidth / imgsize[0]
        elif(imgsize[1] > maxheight):
           imgscale = maxheight / imgsize[1]

        image.scale( int(imgsize[0] * imgscale), int(imgsize[1] * imgscale) )
        image.save_render(pngimg)
      img = pngimg

    # This is done for internal blender images (embedded)
    if os.path.exists(img) == False:
      img = os.path.join(texture_path , basename)
      image_settings = bpy.context.scene.render.image_settings
      image_settings.color_mode = 'RGBA'        
      image_settings.file_format = "PNG"     
      imgnode.filepath = img
      imgnode.colorspace_settings.name = 'Linear'
      imgnode.alpha_mode = 'CHANNEL_PACKED'
      imgnode.scale( 1024, 1024 )
      imgnode.save()
    
    # If this is an image texture, with an active image append its name to the list
    textures[ name ] = img.replace('\\','\\\\')

# ------------------------------------------------------------------------

def addTexture( mat, textures, name, color_node, index, texture_path, context ):

  imgnode = getImageNode( color_node, index, mat, name, texture_path )
  addTextureImageNode(mat, textures, name, imgnode, texture_path, context )


# ------------------------------------------------------------------------
# Check if a lightmap looks like it has been set

def HasLightmap( color_node ):

  if(not "Emission" in color_node):
    return False

  node = color_node["Emission"]
  if node and len(node.links) > 0:
    link = node.links[0]
    if link:
      link_node = link.from_node
      if link_node:
        # print("[EMISSION NAME] " + str(link_node.name))
        if link_node.name.endswith("_Lightmap"):
          return True 
  return False


# ------------------------------------------------------------------------
# Convert Principled BSDF to Our PBR format

def ConvertPrincipledBSDF( thisobj, mat, texture_path, context, config ):

    textures = {}
    lightmap_enable = False

    bsdf = mat.node_tree.nodes["Principled BSDF"] 

    # material names are cleaned here
    mat.name = re.sub(r'[^\w]', ' ', mat.name)
    if(bsdf is not None):

        # print("[ Principled BSDF ] : Principled bsdf material type used.")
        addTexture( mat, textures, "base_color", bsdf.inputs, "Base Color", texture_path, context )
        addTexture( mat, textures, "metallic_color", bsdf.inputs, "Metallic", texture_path, context )
        addTexture( mat, textures, "roughness_color", bsdf.inputs, "Roughness", texture_path, context )
        addTexture( mat, textures, "emissive_color", bsdf.inputs, "Emission", texture_path, context )
        addTexture( mat, textures, "emissive_strength", bsdf.inputs, "Emission Strength", texture_path, context )
        addTexture( mat, textures, "normal_map", bsdf.inputs, "Normal", texture_path, context )
        addTexture( mat, textures, "alpha_map", bsdf.inputs, "Alpha", texture_path, context )

        lightmap_enable = HasLightmap( bsdf.inputs )
        if lightmap_enable:
            mat.name = mat.name + "_LightMap"
    else:
        print("[ ERROR ] : Material type is not Principled BSDF.")
        defoldUtils.ErrorLine( config, " Material type is not Principled BSDF: ",  str(mat.name), "ERROR")

    thisobj["matname"] = mat.name

    if(len(textures) > 0):
        thisobj["textures"] = textures

    return thisobj

# ------------------------------------------------------------------------
# Convert Principled BSDF to Our PBR format

def ConvertDiffuseBSDF( thisobj, mat, texture_path, context, config ):

    textures = {}
    lightmap_enable = False

    diffusebsdf = mat.node_tree.nodes["Diffuse BSDF"] 

    # material names are cleaned here
    mat.name = re.sub(r'[^\w]', ' ', mat.name)
    if(diffusebsdf is not None):

        # print("[ Diffuse BSDF ] : Diffuse bsdf material type used.")
        addTexture( mat, textures, "base_color", diffusebsdf.inputs, "Color", texture_path, context )
        addTexture( mat, textures, "roughness_color", diffusebsdf.inputs, "Roughness", texture_path, context )
        addTexture( mat, textures, "normal_map", diffusebsdf.inputs, "Normal", texture_path, context )

        lightmap_enable = HasLightmap( diffusebsdf.inputs )
        if lightmap_enable:
            mat.name = mat.name + "_LightMap"
    else:
        print("[ ERROR ] : Material type is not Diffuse BSDF.")
        defoldUtils.ErrorLine( config, " Material type is not Diffuse BSDF: ",  str(mat.name), "ERROR")

    thisobj["matname"] = mat.name

    if(len(textures) > 0):
        thisobj["textures"] = textures

    return thisobj

# ------------------------------------------------------------------------
# Convert Emission Surface Shader to Our PBR format

def ConvertEmissionShader( thisobj, mat, texture_path, context, config ):

    textures = {}
    lightmap_enable = False

    emission = mat.node_tree.nodes["Emission"] 

    # material names are cleaned here
    mat.name = re.sub(r'[^\w]', ' ', mat.name)
    if(emission is not None):

        # print("[ Emission ] : Emission material type used.")
#        addTexture( mat, textures, "base_color", emission.inputs, "Base Color", texture_path, context )
#        addTexture( mat, textures, "metallic_color", emission.inputs, "Metallic", texture_path, context )
#        addTexture( mat, textures, "roughness_color", emission.inputs, "Roughness", texture_path, context )
        addTexture( mat, textures, "emissive_color", emission.inputs, "Color", texture_path, context )
        addTexture( mat, textures, "emissive_strength", emission.inputs, "Strength", texture_path, context )
#        addTexture( mat, textures, "normal_map", emission.inputs, "Normal", texture_path, context )
#        addTexture( mat, textures, "alpha_map", emission.inputs, "Alpha", texture_path, context )

        lightmap_enable = HasLightmap( emission.inputs )
        if lightmap_enable:
            mat.name = mat.name + "_LightMap"
    else:
        print("[ ERROR ] : Material is not Emission type.")
        defoldUtils.ErrorLine( config, " Material is not Emission type: ",  str(mat.name), "ERROR")

    thisobj["matname"] = mat.name

    if(len(textures) > 0):
        thisobj["textures"] = textures

    return thisobj

# ------------------------------------------------------------------------
# Convert Mix Shader to Our PBR format

def ConvertMixShader( thisobj, mat, texture_path, context, config ):

    textures = {}
    lightmap_enable = False

    mixshader = mat.node_tree.nodes["Mix Shader"] 

    # material names are cleaned here
    mat.name = re.sub(r'[^\w]', ' ', mat.name)
    if(mixshader is not None):

        # print("[ Mix Shader ] : Mix Shader material type used.")
        # Check inputs. Only support two inputs of supported types.

        if(len(mixshader.inputs) == 3):

            node_count = 0
            for node in mixshader.inputs:
                # print("[ Mix Shader ] Node Name: " + str(node.name))

                if(node.name == "Fac"):
                   # print("[ Mix Shader ] Fac: " + str(node.default_value ))
                   thisobj["mix_shader_factor"] = node.default_value 

                if(node.name == "Shader"):
                    pbr_name = "mix_color"
                    if(node_count == 0):
                       pbr_name = "base_color"
                    imgnode = getImageNodeFromColor( node, mat, pbr_name, texture_path )
                    addTextureImageNode( mat, textures, pbr_name, imgnode, texture_path, context )
                    node_count = node_count + 1

            # addTexture( mat, textures, "metallic_color", mixshader.outputs, "Metallic", texture_path, context )
            # addTexture( mat, textures, "roughness_color", mixshader.outputs, "Roughness", texture_path, context )
            # addTexture( mat, textures, "emissive_color", mixshader.outputs, "Color", texture_path, context )
            # addTexture( mat, textures, "emissive_strength", mixshader.outputs, "Strength", texture_path, context )
            # addTexture( mat, textures, "normal_map", mixshader.outputs, "Normal", texture_path, context )
            # addTexture( mat, textures, "alpha_map", mixshader.outputs, "Alpha", texture_path, context )
        else:
            print("[ ERROR ] : Material Mix Shader only supports two inputs.")
            defoldUtils.ErrorLine( config, " Material Mix Shader only supports two inputs: ",  str(mat.name), "ERROR")

    else:
        print("[ ERROR ] : Material is not Mix Shader type.")
        defoldUtils.ErrorLine( config, " Material is not Mix Shader type: ",  str(mat.name), "ERROR")

    thisobj["matname"] = mat.name

    if(len(textures) > 0):
        thisobj["textures"] = textures

    return thisobj

# ------------------------------------------------------------------------
# Check material type and convert to something we can export to PBR

node_convert_list = {
    "Principled BSDF": ConvertPrincipledBSDF,
    "Diffuse BSDF": ConvertDiffuseBSDF,
    "Emission": ConvertEmissionShader,
    "Mix Shader": ConvertMixShader, 
}

def ProcessMaterial( mat, texture_path, context, config ):

    matobj = {}

    if mat is not None and mat.use_nodes:
        print("[MATNAME] "+mat.name)

        # Compile the shader, then assign it to the material
        node_compiler = bNC.MaterialNodesCompiler(mat.node_tree)
        node_compiler.texture_path = texture_path
        shader = node_compiler.compile()
        matobj["shader"] = shader       
        matobj["textures"] = node_compiler.texture_paths
        matobj["matname"] = mat.name
    else:
        print("[ ERROR ] : Material type missing or not supported.")
        defoldUtils.ErrorLine( config, " Material type missing or not supported.",  str(mat.name), "ERROR")

    return matobj
