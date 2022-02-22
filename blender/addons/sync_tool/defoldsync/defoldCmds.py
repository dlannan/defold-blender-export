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

import bpy, time, queue, re, os, json, shutil

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

  scene = context.scene
    
  prog_text = "Exporting objects..."
  objcount = 0
  for coll in bpy.data.collections:
    objcount += len(coll.objects)
  objcurr = 0

  for coll in bpy.data.collections:

    # Add an object for the collection
    #   - Probably should make this a collection in Defold?

    f.write('["COLL_' + str(coll.name) + '"] = { \n')

    for obj in coll.objects:
    
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

      rot = obj.rotation_quaternion.to_euler()
      quat = obj.rotation_quaternion

      if( obj.rotation_mode != "QUATERNION"):
        rot = obj.rotation_euler.copy()
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

      # Store custom properties too 
      if(len(obj.keys()) > 0):
        props = {}
        for K in obj.keys():
            if(isinstance(obj[K], str)):
              props[str(K)] = str(obj[K])
              #print( K , "-" , obj[K] )
        if(len(props) > 0):
          thisobj["props"] = props

      if( len(obj.vertex_groups) > 0 and config.stream_anim == True ):
        thisobj["animated"] = True

      f.write('["' + str(obj.name) + '"] = ' + dump_lua(thisobj) + ', \n')
      #thisobj["name"] ] = thisobj 

    f.write('}, \n')

  f.write('} \n')

# ------------------------------------------------------------------------

def getImageNode( colors, index, matname, name, texture_path ):
  
  color_node = colors[index]
  # Get the link
  if( color_node.is_linked ):
    link = color_node.links[0]
    link_node = link.from_node
    if link_node and link_node.type == 'TEX_IMAGE':
      imgnode = link_node.image
      if imgnode and imgnode.type == 'IMAGE':
        return imgnode   

  # if the node is a color vector. Make a tiny color png in temp
  # print( str(color_node.type) + "  " + str(color_node.name) + "   " + str(color_node.default_value))
  if((color_node.type == "RGBA" or color_node.type == "RGB") and name == "base_color" ):

    alpha     = colors["Alpha"].default_value
    col       = color_node.default_value
    
    # check if this is linked 
    if( color_node.is_linked ):
      link = color_node.links[0]
      link_node = link.from_node
      col = link_node.outputs[0].default_value

    gencolor  = (to_srgb(col[0]), to_srgb(col[1]), to_srgb(col[2]), alpha)

    hexname = toHex(col[0], col[1], col[2], alpha)
    texname = str(matname) + "_" + name + "_" + hexname
    imgw  = 16 
    imgh  = 16

    img = bpy.data.images.new(texname, width=imgw,height=imgh, alpha=True)
    img.file_format = 'PNG'
    img.generated_color = gencolor

    img.filepath_raw = texture_path + "/" + texname + ".png"
    img.save() 
    return img

  return None 

# ------------------------------------------------------------------------

def addTexture( matname, textures, name, color_node, index, texture_path, context ):

  imgnode = getImageNode( color_node, index, matname, name, texture_path )

  if imgnode != None:
    img = imgnode.filepath_from_user()
    splitname = os.path.splitext(os.path.basename(img))

    if splitname[1] != '.png' or splitname[1] != '.PNG':
      image = bpy.data.images.load(img)
      img = texture_path + "/" + splitname[0] + ".png"
      imgnode.file_format='PNG' 
      image.save_render(img)

    if os.path.exists(img) == False:
      img = texture_path + "/" + os.path.basename(img)
      imgnode.filepath = img
      imgnode.save()
    
    # If this is an image texture, with an active image append its name to the list
    textures[ name ] = img.replace('\\','\\\\')

# ------------------------------------------------------------------------
# Get all available meshes in the scene (including data)
def sceneMeshes(context, fhandle, temppath, texture_path, config):

  fhandle.write('{ \n')
  UVObj = type('UVObj', (object,), {})
  
  scene = context.scene
  prog_text = "Exporting meshes..."
  objcount = len(scene.objects)
  objcurr = 0

  for obj in scene.objects:

      update_progress(context, ((objcurr + 1)/objcount) * 100, prog_text )
      objcurr += 1

      # Only collect meshes in the scene
      if(obj.type == "MESH"):

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

          if(config.sync_mat_facenormals == True):
            for v in verts_local:
              verts.append( { "x": v.co.x, "y": v.co.y, "z": v.co.z } )
          else:
            for v in verts_local:
              verts.append( { "x": v.co.x, "y": v.co.y, "z": v.co.z } )
              normals.append( { "x": v.normal.x, "y": v.normal.y, "z": v.normal.z } )

          thisobj["vertices"] = verts

          vert_uv_map = {}
          for i, face in enumerate(me.loop_triangles):
              verts_indices = face.vertices[:]
              for ti in range(0, 3):
                  idx = verts_indices[ti]
                  uv = me.uv_layers.active.data[face.loops[ti]].uv
                  vert_uv_map.setdefault(idx, []).append((face.loops[ti], uv))

          textures = {}
          if( len(obj.material_slots) > 0 ):
            mat = obj.material_slots[0].material        
            if mat and mat.node_tree:
              # Get the nodes in the node tree
              nodes = mat.node_tree.nodes
              # Get a principled node
              bsdf = nodes.get("Principled BSDF") 
              # Get the slot for 'base color'
              if(bsdf):
                addTexture( mat.name, textures, "base_color", bsdf.inputs, "Base Color", texture_path, context )
                addTexture( mat.name, textures, "metallic_color", bsdf.inputs, "Metallic", texture_path, context )
                addTexture( mat.name, textures, "roughness_color", bsdf.inputs, "Roughness", texture_path, context )
                addTexture( mat.name, textures, "emissive_color" ,bsdf.inputs, "Emission", texture_path, context )
                addTexture( mat.name, textures, "normal_map", bsdf.inputs, "Normal", texture_path, context )
              
          if(len(textures) > 0):
            thisobj["textures"] = textures

          uv_layer = None
          if(me.uv_layers.active != None):
            uv_layer = me.uv_layers.active.data

          tris = []
          nidx = 0

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

              if(uv_layer):
                uv = uv_layer[face.loops[ti]].uv
              
              tridata = { 
                "vertex": idx,
                "normal": nidx,
                "uv": { "x": uv.x, "y": uv.y }
              }

              # if( len(uvs) > 1 and config.sync_mat_uv2 == True):
              #   tridata["uv2"] = { "x": uvs[1].x, "y": uvs[1].y }
              thistri.append( tridata )

            triobj["tri"] = thistri
            tris.append(triobj)

          thisobj["tris"] = tris
          #normals_world = [obj.matrix_world @ n_local for n_local in normals]
          thisobj["normals"]  = normals
        
        meshfile = os.path.abspath(temppath + str(thisobj["name"]) + '.json')
        with open( meshfile, 'w') as f:
          f.write(json.dumps(thisobj))
        # with open(meshfile, 'w') as fh:
        #   fh.write('return {\n')
        #   fh.write( '   mesh = ' + dump_lua(thisobj) + '\n' )
        #   fh.write('}\n')
        meshfile = meshfile.replace('\\','\\\\')

        fhandle.write('["' + thisobj["name"] + '"] = "' + meshfile + '", \n')
        #dataobjs[ thisobj["name"] ] = thisobj 

  fhandle.write('} \n')

# ------------------------------------------------------------------------

def sceneAnimations(context, f, temppath, config):

  # write out the animation to a dae file. 
  #   This is then referenced in the model file (if it has an anim association)
  scene = context.scene
  f.write('{ \n')

  # Select all the meshes
  for meshobj in bpy.context.scene.collection.all_objects:
    if meshobj != None and meshobj.type == "MESH":
      meshobj.select_set(True)

  armobj = config.stream_anim_name
  if armobj != None:
    armobj.select_set(True)

    animfile = temppath + scene.name + ".dae"
    bpy.ops.wm.collada_export(filepath=animfile, 
            include_armatures=True,
            export_global_forward_selection='Z',
            export_global_up_selection='-Y',
            export_animation_type_selection='sample',
            export_animation_transformation_type_selection='matrix',
            keep_keyframes=True,
            apply_global_orientation=True,
            selected=True,
            deform_bones_only=True,
            include_animations=True,
            include_all_actions=True,
            filter_collada=True, 
            filter_folder=True, 
            filemode=8)

    animfile = animfile.replace("\\", "\\\\")

    # Make sure we have vertex objects in this obj
    if( armobj != None ):
      for a in bpy.data.actions:
        #print(a.name)

        f.write( "['" + a.name + "'] = " + '\"' + animfile + '\",\n')

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

  # Make temp folder if it doesnt exist
  os.makedirs( temppath, 511, True )
  texture_path = os.path.abspath( dir + "/textures" )
  os.makedirs( texture_path, 511, True )

  # Write data to temp data file for use by lua
  with open(os.path.abspath(dir + '/defoldsync/temp/syncdata.lua'), 'w') as f:

    f.write("return {\n")

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
        sceneMeshes(context, f, temppath + '/', texture_path, config)
        f.write(', \n')
    
      # All bone animations in the scene
      if(cmd == 'anims'):
        f.write('ANIMS = ')
        sceneAnimations(context, f, temppath + '/', config)
        f.write(', \n')

    f.write("}\n")

# ------------------------------------------------------------------------
