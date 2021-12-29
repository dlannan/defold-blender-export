import bpy, time, queue, re

# These are used to start/end a data stream block. 
TAG_START = "\n\n!!BCMD"
TAG_END   = "\n\n!!ECMD"

TAG_TAIL  = "!!\n\n"

# Kinda evil.. meh
gclients  = {}

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
        t += ", ".join([f'[\"{k}\"]={dump_lua(v)}'for k,v in data.items()])
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


      f.write('"'..thisobj["name"]..'" = '..dump_lua(thisobj)..', \n')
      #thisobj["name"] ] = thisobj 

  f.write('} \n')

# ------------------------------------------------------------------------
# Get all available meshes in the scene (including data)
def sceneMeshes(context, f):

  f.write('{ \n')

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

          textures = []
          for f in obj.data.polygons:
            mat = obj.material_slots[f.material_index].material
            for n in mat.node_tree.nodes:
                if n.type=='TEX_IMAGE':
                  img=n.image.filepath_from_user()
                  # If this is an image texture, with an active image append its name to the list
                  if( img not in textures):
                    textures.append( img )

          if(len(textures) > 0):
            thisobj["textures"] = textures

          uv_layer = NoneType
          if(me.uv_layers.active != NoneType):
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

              uv = { "x": 0.0, "y": 0.0 }
              if(uv_layer):
                uv = uv_layer[face.loops[i]].uv

              thistri.append( { 
                "vertex": idx,
                "uv": { "x": uv.x, "y": uv.y }
              } )
            triobj["tri"] = thistri
            tris.append(triobj)
          thisobj["tris"] = tris
        
        f.write('"'..thisobj["name"]..'" = '..dump_lua(thisobj)..', \n')
        #dataobjs[ thisobj["name"] ] = thisobj 

  f.write('} \n')

# ------------------------------------------------------------------------

def sceneAnimations(context, f):

  f.write('{ \n')

  scene = context.scene
  for action in bpy.data.actions:
    curves = {}
    for fcu in action.fcurves:

      channelname = str(fcu.data_path)
      if channelname not in curves:
        curves[channelname] = {}

      thisframe = []
      for keyframe in fcu.keyframe_points:
          print(keyframe.co) #coordinates x,y
          coord = keyframe.co

          thisframe.append({
            "x": coord.x,
            "y": coord.y,
            "handle_left": { "x":keyframe.handle_left.x, "y":keyframe.handle_left.y },
            "handle_right": { "x":keyframe.handle_right.x, "y":keyframe.handle_right.y },
            "easing": str(keyframe.easing),
            "interp": str(keyframe.interpolation)
          })

      samples = []
      for sample in fcu.sampled_points:
        samples.append({
          "x": sample.co.x, "y": sample.co.y
        })

      index = str(fcu.array_index)
      curves[channelname][index] = {
        "frames": thisframe,
        "samples": samples,
        "index": fcu.array_index
      }

    f.write('"'..action.name..'" = '..dump_lua(curves)..', \n')
    #animobjs[action.name] = curves
    
  f.write('} \n')

# ------------------------------------------------------------------------

def getData( context, clientcmds, dir):
      
  # Write data to temp data file for use by lua
  with open(os.path.abspath(dir + '/defoldsync/syncdata.lua'), 'w') as f:

    f.write("return {\n")

    # Check to see what commands are enabled. And collect data if they changed    

    # TODO: Optimise this into mapped methods
    for cmd in clientcmds:

      # Basic info of the scene
      if(cmd == 'info'):
        f.write('INFO = ')
        sceneInfo(context, f)
        f.write(', \n')

      # Object level info of the scene
      if(cmd == 'scene'):
        f.write('OBJECTS = ')
        sceneObjects(context, f)
        f.write(', \n')

      # Object level info of the scene
      if(cmd == 'meshes'):
        f.write('MESHES = ')
        sceneMeshes(context, f)
        f.write(', \n')

      # All bone animations in the scene
      if(cmd == 'anims'):
        f.write('ANIMS = ')
        sceneAnimations(context, f)
        f.write(', \n')
    
    f.write("}\n")

# ------------------------------------------------------------------------
