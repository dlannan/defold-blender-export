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

modulesNames = ['DefoldSyncUI']

import bpy, time, queue, re, os, json, shutil, math
from bpy_extras.io_utils import axis_conversion
from io import BytesIO

# ------------------------------------------------------------------------

def to_srgb(c):
    if c < 0.0031308:
        srgb = 0.0 if c < 0.0 else c * 12.92
    else:
        srgb = 1.055 * pow(c, 1.0 / 2.4) - 0.055

    return srgb

# ------------------------------------------------------------------------

def toHex(r, g, b, a):
    return "%02x%02x%02x%02x" % (
        round(r * 255),
        round(g * 255),
        round(b * 255),
        round(a * 255),
    )

# ------------------------------------------------------------------------
def dump_lua(data):
    if type(data) is str:
        return f'"{data}"'
    if type(data) in (int, float):
        return f'{data}'
    if type(data) is bool:
        return data and "true" or "false"
    if type(data) is list:
        l = "{"
        l += ", ".join([dump_lua(item) for item in data])
        l += "}"
        return l
    if type(data) is dict:
        t = "{"
        t += ", ".join([f"['{k}']={dump_lua(v)}"for k,v in data.items()])
        t += "}"
        return t
    logging.error(f"Unknown type {type(data)}")

# ------------------------------------------------------------------------
# Is an object animated

def isAnimated( obj ):
  # If the mesh has a verex group, then this needs to be saved as a separate animation
  if(len(obj.modifiers) > 0):
    modifier = obj.modifiers[0]
    if(obj.vertex_groups != None and modifier.type == 'ARMATURE'):
      print("[ ANIM OBJ ] " + obj.name)
      return True

  # If an object has animation data then it is likely animated.
  if(obj.parent != None):
    if(obj.parent.animation_data):
      anim = obj.parent.animation_data
      if anim is not None and anim.action is not None:
        return True
  return False

# ------------------------------------------------------------------------
# Add errors or warnings to the Errors Panel.

def ClearErrors( mytool ):
  mytool.sync_errors_str.clear()

# ------------------------------------------------------------------------
# Add errors or warnings to the Errors Panel.

def ErrorLine(mytool, message = "", title="", level=""):

  mytool.sync_errors_str.append( "[" + str(title) + "] " + str(message) )
  mytool.msgcount = len(mytool.sync_errors_str)


# ------------------------------------------------------------------------
# update progress bar 

def update_progress( context, value, text ):

    scene = context.scene
    mytool = scene.sync_tool
    #update progess bar
    mytool.sync_progress = value
    mytool.sync_progress_label = text

    bpy.ops.wm.redraw_timer(type='DRAW_WIN_SWAP', iterations=1)

# ------------------------------------------------------------------------
# Get scene information - objects, names and parent names
def sceneInfo(context, f):
    dataobjs = {}

    scene = context.scene
    for obj in scene.objects:
    
        thisobj = {
          "name": str(obj.name),
          "type": str(obj.type)
        }

        if(obj.parent != None):
            thisobj["parent"] = {
              "name": str(obj.parent.name),
              "type": str(obj.parent_type)
            }
        
        dataobjs[thisobj["name"]] = thisobj

    f.write( dump_lua(dataobjs) )

# ------------------------------------------------------------------------

def has_keyframe(ob, attr):
    anim = ob.animation_data
    if anim is not None and anim.action is not None:
        for fcu in anim.action.fcurves:
            if fcu.data_path == attr:
                return len(fcu.keyframe_points) > 0
    return False

# ------------------------------------------------------------------------
# Get all available obejcts in the scene (including transforms)
def sceneObjects(context, f, config):

  f.write('{ \n')

  # m = axis_conversion(from_forward='-Y', 
  #         from_up='Z',
  #         to_forward='Z',
  #         to_up='Y').to_4x4()

  scene = context.scene
    
  prog_text = "Exporting objects..."
  objcount = 0
  #for coll in bpy.data.collections:
  for coll in bpy.context.view_layer.layer_collection.children:
    if coll.is_visible:
      objcount += len(coll.collection.objects)
  objcurr = 0

  # No collections in the list!! Need a collection!
  if( len(bpy.data.collections) == 0 ):
    ErrorLine( config, "No Collection found. Please add a collection.", "Scene", 'ERROR' )
    f.write('} \n')
    return

  #for coll in bpy.data.collections:
  for coll in bpy.context.view_layer.layer_collection.children:

    if coll.is_visible:
      # Add an object for the collection
      #   - Probably should make this a collection in Defold?

      f.write('["COLL_' + str(coll.name) + '"] = { \n')

      for obj in coll.collection.objects:
      
        update_progress(context, ((objcurr + 1)/objcount) * 100, prog_text )
        objcurr += 1

        thisobj = {
          "name": str(obj.name),
          "type": str(obj.type)
        }
          
        if(obj.parent != None):
            thisobj["parent"] = {
              "name": str(obj.parent.name),
              "type": str(obj.parent_type)
            }

        local_coord = obj.matrix_local.translation #obj.location
        thisobj["location"] = { 
          "x": local_coord.x, 
          "y": local_coord.y, 
          "z": local_coord.z 
        }

        rot = obj.rotation_quaternion.to_euler('XYZ')
#        quat = obj.rotation_quaternion

        if( obj.rotation_mode != "QUATERNION"):
          rot = obj.rotation_euler.copy()
          rot.order = 'XYZ'
        quat = rot.to_quaternion()
        
        thisobj["rotation"] = { 
          "quat": { 
            "x": quat.x,
            "y": quat.y,
            "z": quat.z,
            "w": quat.w
          },
          "euler": {
            "x": rot.x,
            "y": rot.y,
            "z": rot.z
          }
        }

        scl = obj.scale.copy()
        thisobj["scaling"] = {
          "x": scl.x,
          "y": scl.y,
          "z": scl.z
        }

        if( obj.type == "CAMERA" ):
          cam = obj.data
          thisobj["settings"] = {
            "fov": cam.angle_y,
            "near": cam.clip_start,
            "far" : cam.clip_end,
            "lens" : cam.lens,
            "ortho_scale": cam.ortho_scale
          }

        # Store custom properties too 
        if(len(obj.keys()) > 0):
          props = {}
          for K in obj.keys():
              if(isinstance(obj[K], str)):
                props[str(K)] = str(obj[K])
                #print( K , "-" , obj[K] )
          if(len(props) > 0):
            thisobj["props"] = props

        if( isAnimated(obj) == True ):
          thisobj["animated"] = True

        f.write('["' + str(obj.name) + '"] = ' + dump_lua(thisobj) + ', \n')
        #thisobj["name"] ] = thisobj 

      f.write('}, \n')

  f.write('} \n')

# ------------------------------------------------------------------------

def makeBlockPNG(texture_path, matname, name, col):

    gencolor = (to_srgb(col[0]), to_srgb(col[1]), to_srgb(col[2]), col[3])

    hexname = toHex(col[0], col[1], col[2], col[3])
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

def getImageNode( colors, index, mat, name, texture_path ):

  if(not index in colors):
    return None

  color_node = colors[index]

  # Get the link - this should extract embedded nodes too (need to test/check)
  if( color_node.is_linked ):
    link = color_node.links[0]
    link_node = link.from_node
    if link_node and link_node.type == 'TEX_IMAGE':
      imgnode = link_node.image
      if imgnode and imgnode.type == 'IMAGE':
        return imgnode
    elif link_node and link_node.type == 'MIX_RGB':
      if link_node.blend_type == 'MULTIPLY':
        color1node = link_node.inputs['Color1'].links[0].from_node
        color2node = link_node.inputs['Color2'].links[0].from_node

        if index == 'Base Color':
          baseimg = False
          if color2node and color2node.type == 'TEX_IMAGE':
            imgnode = color2node.image 
            if imgnode and imgnode.type == 'IMAGE':
              baseImg = imgnode 
          if color1node and color1node.type == 'TEX_IMAGE':
            lightnode = color1node.image 
            if lightnode and lightnode.type == 'IMAGE' and lightnode.name.endswith('_baked'):

              nodes = mat.node_tree.nodes
              links = mat.node_tree.links
              links.new(color1node.outputs[0],colors['Emission'])

          if baseimg:
            return baseimg

  # Handle metallic roughness and emission if they have just values set (make a little color texture)
  value_materials = ["metallic_color", "roughness_color", "emissive_color", "alpha_map"]
  if(color_node.type == "VALUE") and (name in value_materials):
    col       = color_node.default_value
    # If alpha is default, then base color will use default settings in alpha channel
    if(name == "alpha_map" and col == 1.0):
      return None
    return makeBlockPNG(texture_path, mat.name, name, [col, col, col, col])

  # if the node is a color vector. Make a tiny color png in temp
  # print( str(color_node.type) + "  " + str(color_node.name) + "   " + str(color_node.default_value))
  if((color_node.type == "RGBA" or color_node.type == "RGB") and name == "base_color" ):

    alpha     = 1.0 
    col       = color_node.default_value
    
    # check if this is linked 
    if( color_node.is_linked ):
      link = color_node.links[0]
      link_node = link.from_node
      col = link_node.outputs[0].default_value

    return makeBlockPNG(texture_path, mat.name, name, [col[0], col[1], col[2], alpha])

  return None 

# ------------------------------------------------------------------------

def addTexture( mat, textures, name, color_node, index, texture_path, context ):

  imgnode = getImageNode( color_node, index, mat, name, texture_path )

  if imgnode != None:
    img = imgnode.filepath_from_user()
    basename = os.path.basename(img)
    splitname = os.path.splitext(basename)

    print("[ IMG PATH ] " + str(img))
    print("[ IMG BASE PATH ] " + str(basename))

    if splitname[1] != '.png' and splitname[1] != '.PNG':
      pngimg = os.path.join(texture_path , splitname[0] + ".png")
      if(os.path.exists(pngimg) == False):
        
        imgnode.file_format='PNG' 
        image = bpy.data.images.load(img)

        image_settings = bpy.context.scene.render.image_settings
        image_settings.file_format = "PNG"
        image.file_format='PNG'
        image.save_render(pngimg)
      img = pngimg

    # This is done for internal blender images (embedded)
    if os.path.exists(img) == False:
      img = os.path.join(texture_path , basename)
      image_settings = bpy.context.scene.render.image_settings
      image_settings.file_format = "PNG"
      imgnode.filepath = img
      imgnode.save()
    
    # If this is an image texture, with an active image append its name to the list
    textures[ name ] = img.replace('\\','\\\\')

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
        print("[EMISSION NAME] " + str(link_node.name))
        if link_node.name.endswith("_Lightmap"):
          return True 
  return False

# ------------------------------------------------------------------------
# Get all available meshes in the scene (including data)

def sceneMeshes(context, fhandle, temppath, texture_path, config):

  fhandle.write('{ \n')
  UVObj = type('UVObj', (object,), {})
  
  scene = context.scene
  prog_text = "Exporting meshes..."
  objcount = len(scene.objects)
  objcurr = 0

  mode = config.stream_mesh_type
  #Deselect any selected object
  for o in context.selected_objects:
    o.select_set(False)

  animActionObjs = []
  for obj in scene.objects:

      update_progress(context, ((objcurr + 1)/objcount) * 100, prog_text )
      objcurr += 1

      # Only collect meshes in the scene
      if(obj.type == "MESH"):

        if(isAnimated(obj) == True):
          if(not obj.name in animActionObjs): 
            animActionObjs.append(obj.name)

        thisobj = {
          "name": str(obj.name),
          "type": str(obj.type)
        }
        
        if(obj.parent != None):
          thisobj["parent"] = str(obj.parent.name)

        if(obj.data):

          me = obj.data
          # Build the mesh into triangles
          # bpy.ops.mesh.quads_convert_to_tris(quad_method='BEAUTY', ngon_method='BEAUTY')
          me.calc_loop_triangles()

          # Get the vert data
          verts   = []
          normals = []
          verts_local = [v for v in obj.data.vertices.values()]
          # verts_world = [obj.matrix_world @ v_local for v_local in verts_local]

          # Gltf and Glb are stored in file. No need for this
          if( mode == "Collada" ):
            if(config.sync_mat_facenormals == True):
              for v in verts_local:
                verts.append( { "x": v.co.x, "y": v.co.y, "z": v.co.z } )
            else:
              for v in verts_local:
                verts.append( { "x": v.co.x, "y": v.co.y, "z": v.co.z } )
                normals.append( { "x": v.normal.x, "y": v.normal.y, "z": v.normal.z } )

          thisobj["vertices"] = verts
          textures = {}

          if obj is not None and obj.type == 'MESH' and obj.active_material:   
            mat = obj.active_material

          lightmap_enable = False

          bsdf_node_name = "Principled BSDF"
          if mat is not None and mat.use_nodes and bsdf_node_name in mat.node_tree.nodes:
            bsdf = mat.node_tree.nodes[bsdf_node_name] 

            # material names are cleaned here
            mat.name = re.sub(r'[^\w]', ' ', mat.name)

        #if( len(obj.material_slots) > 0 ):
        #  mat = obj.material_slots[0].material        
        #  if mat and mat.node_tree:
            # Get the nodes in the node tree
            #nodes = mat.node_tree.nodes
            # Get a principled node
            #bsdf = nodes.get("Principled BSDF") 
            # Get the slot for 'base color'
            if(bsdf is not None):

              print("[ BSDF ] : bsdf material type used.")
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
              print("[ ERROR ] : Uknown material type used.")
              ErrorLine( config, " Unknown material type used: ",  str(mat.name), "ERROR")
          else:
            print("[ ERROR ] : Uknown material type used.")
            ErrorLine( config, " Unknown material type used.",  str(mat.name), "ERROR")

          thisobj["matname"] = mat.name

          if(len(textures) > 0):
            thisobj["textures"] = textures

          tris = []
          nidx = 0

          if( mode == "Collada" ):
            for i, face in enumerate(me.loop_triangles):
              verts_indices = face.vertices[:]

              triobj = {}
              thistri = []
              facenormal = face.normal

              for ti in range(0, 3):
                idx = verts_indices[ti]
                nidx = idx

                # override normals if using facenormals
                if(config.sync_mat_facenormals == True):
                  normals.append( { "x": facenormal.x, "y": facenormal.y, "z": facenormal.z } )
                  nidx = nidx + 1
                  #print(idx, normal.x, normal.y, normal.z)

                uv_layer = None
                if(me.uv_layers.active != None):
                  uv_layer = me.uv_layers.active.data

                if(uv_layer):
                  uv = uv_layer[face.loops[ti]].uv
                
                tridata = { 
                  "vertex": idx,
                  "normal": nidx,
                  "uv": { "x": uv.x, "y": uv.y }
                }

                if( len(me.uv_layers) > 1 and ((config.sync_mat_uv2 == True) or (lightmap_enable == True)) ):
                  uvs = [uv for uv in obj.data.uv_layers if uv.active_render != True]
                  uv1 = uvs[0].data[face.loops[ti]].uv
                  tridata["uv2"] = { "x": uv1.x, "y": uv1.y }
                
                thistri.append( tridata )

              triobj["tri"] = thistri
              tris.append(triobj)

          thisobj["tris"] = tris
          #normals_world = [obj.matrix_world @ n_local for n_local in normals]
          thisobj["normals"]  = normals
        
        meshfile = os.path.abspath(temppath + str(thisobj["name"]) + '.json')

        if( mode == "GLTF" or mode == "GLB" ):

          # Select just this object to export
          for o in context.selected_objects:
            o.select_set(False)
          
          obj.select_set(True)
          context.view_layer.objects.active = obj

          thisobj["gltf"] = os.path.abspath(temppath + str(thisobj["name"]) + ".gltf")
          gltffiletype = "GLTF_EMBEDDED"
          if( mode == "GLB" ):
            thisobj["gltf"] = os.path.abspath(temppath + str(thisobj["name"]) + ".glb")
            gltffiletype = "GLB"

          bpy.ops.export_scene.gltf(filepath=thisobj["gltf"], 
                    export_skins=True,
                    export_format=gltffiletype,
                    #export_image_format='NONE',
                    #export_yup=True,
                    export_texture_dir="textures",
                    export_texcoords=True,
                    export_normals=True,
                    export_colors=True,
                    export_cameras=False,
                    export_lights=False,
                    use_renderable=True,
                    use_selection=True,
                    export_def_bones=True,
                    export_animations=True,
                    use_visible=True,
                    check_existing=False)
            
          thisobj["normals"] = {}
          thisobj["tris"] = {}
          thisobj["vertices"] = {}

        with open( meshfile, 'w') as f:
          f.write(json.dumps(thisobj))

        meshfile = meshfile.replace('\\','\\\\')

        # with open(meshfile, 'w') as fh:
        #   fh.write('return {\n')
        #   fh.write( '   mesh = ' + dump_lua(thisobj) + '\n' )
        #   fh.write('}\n')
        
        fhandle.write('["' + thisobj["name"] + '"] = "' + meshfile + '", \n')
        #dataobjs[ thisobj["name"] ] = thisobj 

  fhandle.write('} \n')
  return animActionObjs

# ------------------------------------------------------------------------
# Select parents up to the collection
def selectParent(obj):
  if(obj.type != "COLLECTION"):
    obj.select_set(True)
    if(obj.parent):
      selectParent(obj.parent)

# ------------------------------------------------------------------------
# Export scene animations
def sceneAnimations(context, f, temppath, config, animobjs):

  # write out the animation to a dae file. 
  #   This is then referenced in the model file (if it has an anim association)
  scene = context.scene
  f.write('{ \n')

  # Make a list of animations that are collected and output
  animmeshes = []

  # Select all the meshes
  for meshname in animobjs:
    meshobj = scene.objects[meshname]

    if(meshobj != None):
      for obj in bpy.data.objects: obj.select_set(False)

      # Select the mesh - and its parents (need full hierarchy)
      selectParent(meshobj)

      # Add the selection of the Armature modifier
      if(len(meshobj.modifiers) > 0):
        armature = meshobj.modifiers[0].object
        if(armature != None):
          if bpy.data.objects[armature.name]:
            bpy.data.objects[armature.name].select_set(True)

          # Set the mesh active
          if(armature.name in bpy.data.armatures):
            for a in bpy.data.armatures[armature.name].bones:
              a.select = True

          bpy.context.view_layer.objects.active = armature       

      if( config.stream_mesh_type == "GLTF" or config.stream_mesh_type == "GLB" ):
        animfile = temppath + meshobj.name + ".gltf"
        animfiletype = "GLTF_SEPARATE"
        if( config.stream_mesh_type == "GLB" ):
          animfile = temppath + meshobj.name + ".glb"
          animfiletype = "GLB"
        bpy.ops.export_scene.gltf(filepath=animfile, 
                  export_skins=True,
                  export_format=animfiletype,
                  #export_image_format='NONE',
                  #export_yup=True,
                  export_texture_dir="textures",
                  export_texcoords=True,
                  export_normals=True,
                  export_colors=True,
                  export_cameras=False,
                  export_lights=False,
                  use_renderable=True,
                  use_selection=True,
                  export_def_bones=True,
                  export_animations=True,
                  use_visible=True,
                  check_existing=False)
      else:
        animfile = temppath + meshobj.name + ".dae"
        bpy.ops.wm.collada_export(filepath=animfile, 
                triangulate = True,
                include_armatures=True,
                include_children=False,
                export_global_forward_selection='Z',
                export_global_up_selection='-Y',
                export_animation_type_selection='sample',
                export_animation_transformation_type_selection='matrix',
                #keep_keyframes=True,
                apply_global_orientation=True,
                selected=True,
                deform_bones_only=True,
                include_animations=True,
                #include_all_actions=True,
                filter_collada=True, 
                filter_folder=True, 
                filemode=8)

      animfile = os.path.normpath(animfile)
      animfile = animfile.replace("\\", "\\\\")
      animmeshes.append( [meshobj.name, animfile] )

  # Make sure we have vertex objects in this obj
  if( len(animmeshes) > 0 ):
    for a in animmeshes:
      f.write( "['" + a[0] + "'] = " + '\"' + a[1] + '\",\n')

  # TODO: Extract each individual action into a separate file 
  #
  # for action in bpy.data.actions:
  #   curves = {}
  #   for fcu in action.fcurves:

  #     channelname = str(fcu.data_path)
  #     if channelname not in curves:
  #       curves[channelname] = {}

  #     thisframe = []
  #     for keyframe in fcu.keyframe_points:
  #         print(keyframe.co) #coordinates x,y
  #         coord = keyframe.co

  #         thisframe.append({
  #           "x": coord.x,
  #           "y": coord.y,
  #           "handle_left": { "x":keyframe.handle_left.x, "y":keyframe.handle_left.y },
  #           "handle_right": { "x":keyframe.handle_right.x, "y":keyframe.handle_right.y },
  #           "easing": str(keyframe.easing),
  #           "interp": str(keyframe.interpolation)
  #         })

  #     samples = []
  #     for sample in fcu.sampled_points:
  #       samples.append({
  #         "x": sample.co.x, "y": sample.co.y
  #       })
  #     index = str(fcu.array_index)
  #     curves[channelname][index] = {
  #       "frames": thisframe,
  #       "samples": samples,
  #       "index": fcu.array_index
  #     }

  #   f.write("['" + action.name + "'] = " + dump_lua(curves) + ', \n')
  #   #animobjs[action.name] = curves
    
  f.write('} \n')

# ------------------------------------------------------------------------

def getData( context, clientcmds, dir, config):

  temppath = os.path.abspath(dir + '/defoldsync/temp')

  try:
      shutil.rmtree(temppath, ignore_errors=True)
  except OSError as e:
      print("Error: %s : %s" % (dir_path, e.strerror))

  ClearErrors( config )

  # Make temp folder if it doesnt exist
  os.makedirs( temppath, 511, True )
  texture_path = os.path.abspath( dir + "/textures" )
  os.makedirs( texture_path, 511, True )

  # Write data to temp data file for use by lua
  with open(os.path.abspath(dir + '/defoldsync/temp/syncdata.lua'), 'w') as f:

    f.write("return {\n")

    animobjs = []

    # Check to see what commands are enabled. And collect data if they changed
    # TODO: Optimise this into mapped methods
    for cmd in clientcmds:

      # Basic info of the scene
      if(cmd == 'info'):
        f.write('INFO = ')
        sceneInfo(context, f)
        f.write(', \n')

      # Object transforms and hierarchy
      if(cmd == 'scene'):
        f.write('OBJECTS = ')
        sceneObjects(context, f, config) 
        f.write(', \n')

      # Mesh data 
      if(cmd == 'meshes'):
        f.write('MESHES = ')
        animobjs = sceneMeshes(context, f, temppath + bpy.path.native_pathsep('/'), texture_path, config)
        f.write(', \n')
    
      # All bone animations in the scene
      if(cmd == 'anims'):
        f.write('ANIMS = ')
        sceneAnimations(context, f, temppath + bpy.path.native_pathsep('/'), config, animobjs)
        f.write(', \n')

    f.write("}\n")

# ------------------------------------------------------------------------
