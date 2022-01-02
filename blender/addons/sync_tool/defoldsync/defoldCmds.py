import bpy, time, queue, re, os, json, shutil

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
# Get all available obejcts in the scene (including transforms)
def sceneObjects(context, f):

  f.write('{ \n')

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

      local_coord = obj.matrix_local.translation #obj.location
      thisobj["location"] = { 
        "x": local_coord.x, 
        "y": local_coord.y, 
        "z": local_coord.z 
      }

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

      if( len(obj.vertex_groups) > 0 ):
        thisobj["animated"] = True

      f.write('["' + thisobj["name"] + '"] = ' + dump_lua(thisobj) + ', \n')
      #thisobj["name"] ] = thisobj 

  f.write('} \n')

# ------------------------------------------------------------------------

def getImageNode( color_node ):
    # Get the link
  if( color_node.is_linked ):
    link = color_node.links[0]
    link_node = link.from_node
    if link_node and link_node.type == 'TEX_IMAGE':
      imgnode = link_node.image
      if imgnode and imgnode.type == 'IMAGE':
        return imgnode 
  return None 

# ------------------------------------------------------------------------

def addTexture( textures, name, color_node, texture_path ):

  imgnode = getImageNode( color_node )

  if imgnode != None:
    img=imgnode.filepath_from_user()

    if os.path.exists(img) == False:

      img = texture_path + "/" + os.path.basename(img)
      imgnode.filepath = img
      imgnode.save()
    
    # If this is an image texture, with an active image append its name to the list
    textures[ name ] = img.replace('\\','\\\\')

# ------------------------------------------------------------------------
# Get all available meshes in the scene (including data)
def sceneMeshes(context, fhandle, temppath, texture_path):

  fhandle.write('{ \n')
  UVObj = type('UVObj', (object,), {})

  scene = context.scene
  for obj in scene.objects:
  
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
          verts = []
          verts_local = [v.co for v in obj.data.vertices.values()]
          verts_world = [obj.matrix_world @ v_local for v_local in verts_local]

          for v in verts_local:
            verts.append( { "x": v.x, "y": v.y, "z": v.z } )
          thisobj["vertices"] = verts

          textures = {}
          for f in obj.data.polygons:
            if(len(obj.material_slots) > 0):
              mat = obj.material_slots[f.material_index].material
              if mat:
                # Get the nodes in the node tree
                nodes = mat.node_tree.nodes
                # Get a principled node
                bsdf = nodes.get("Principled BSDF") 
                # Get the slot for 'base color'
                if(bsdf):
                  addTexture( textures, "base_color", bsdf.inputs[0], texture_path )
                  addTexture( textures, "metallic_color", bsdf.inputs[4], texture_path )
                  addTexture( textures, "roughness_color", bsdf.inputs[7], texture_path )
                  addTexture( textures, "emissive_color" ,bsdf.inputs[17], texture_path )
                  addTexture( textures, "normal_map", bsdf.inputs[19], texture_path )
            
          if(len(textures) > 0):
            thisobj["textures"] = textures

          uv_layer = None
          if(me.uv_layers.active != None):
            uv_layer = me.uv_layers.active.data
          tris = []

          for i, face in enumerate(me.loop_triangles):
            verts_indices = face.vertices[:]

            triobj = {}
            thistri = []
            normal = face.normal
            triobj["normal"] = {
              "x": normal.x, 
              "y": normal.y,
              "z": normal.z
            }

            for i in range(0, 3):
              idx = verts_indices[i]

              uv = UVObj()
              uv.x = 0.0
              uv.y = 0.0

              if(uv_layer):
                uv = uv_layer[face.loops[i]].uv

              thistri.append( { 
                "vertex": idx,
                "uv": { "x": uv.x, "y": uv.y }
              } )
            triobj["tri"] = thistri
            tris.append(triobj)
          thisobj["tris"] = tris
        
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

  obj = config.stream_anim_name
  if obj != None:
    obj.select_set(True)

    animfile = temppath + scene.name + ".dae"
    bpy.ops.wm.collada_export(filepath=animfile, 
            include_armatures=False,
            selected=True,
            include_all_actions=True,
            export_animation_type_selection='keys',
            filter_collada=True, 
            filter_folder=True, 
            filemode=8)

    animfile = animfile.replace("\\", "\\\\")

    # Make sure we have vertex objects in this obj
    if( len(obj.vertex_groups) > 0 ):
      for a in bpy.data.actions:
        print(a.name)

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
        sceneObjects(context, f)
        f.write(', \n')

      # Mesh data 
      if(cmd == 'meshes'):
        f.write('MESHES = ')
        sceneMeshes(context, f, temppath + '/', texture_path)
        f.write(', \n')
    
      # All bone animations in the scene
      if(cmd == 'anims'):
        f.write('ANIMS = ')
        sceneAnimations(context, f, temppath + '/', config)
        f.write(', \n')

    f.write("}\n")

# ------------------------------------------------------------------------
