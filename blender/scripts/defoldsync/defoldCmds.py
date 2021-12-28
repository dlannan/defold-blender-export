import bpy, time, queue

# These are used to start/end a data stream block. 
TAG_START = "\n\n!!BCMD"
TAG_END   = "\n\n!!ECMD"

TAG_TAIL  = "!!\n\n"

# Kinda evil.. meh
gclients  = {}

# ------------------------------------------------------------------------
def dump_lua(data):
    if type(data) is str:
        return f'"{re.escape(data)}"'
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
        t += ", ".join([f'[\"{re.escape(k)}\"]={dump_lua(v)}'for k,v in data.items()])
        t += "}"
        return t
    logging.error(f"Unknown type {type(data)}")

# ------------------------------------------------------------------------
# Get scene information - objects, names and parent names
def sceneInfo(context):
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

    return dump_lua(dataobjs)

# ------------------------------------------------------------------------
# Get all available obejcts in the scene (including transforms)
def sceneObjects(context):

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

        dataobjs[ thisobj["name"] ] = thisobj 

    return dump_lua(dataobjs)

# ------------------------------------------------------------------------
# Get all available meshes in the scene (including data)
def sceneMeshes(context):

    dataobjs = {}

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
                uv = uv_layer[face.loops[i]].uv

                thistri.append( { 
                  "vertex": idx,
                  "uv": { "x": uv.x, "y": uv.y }
                } )
              triobj["tri"] = thistri
              tris.append(triobj)
            thisobj["tris"] = tris
          
          dataobjs[ thisobj["name"] ] = thisobj 

    return dump_lua(dataobjs)

# ------------------------------------------------------------------------

def sceneAnimations(context):

  animobjs = {}

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

    animobjs[action.name] = curves

  return dump_lua(animobjs)
      

# ------------------------------------------------------------------------
# Commands:
#    Each command is an enable/disable toggle for outputting data. 
#    The server continuously outputs information in a data stream once 
#    a client connects. This can be a big overhead. 
#
#    To limit this, and control updates, the client can determine what 
#    it needs to have active in the stream at any one time. 
#    Additionally, the server is smart enough to only send stream data 
#    that is both ACTIVE and MODIFIED on the blender side.
#
#    Unmodified data will not be sent, unless a RESEND command is sent

# Valid accepted commands
validcmds = [
  "info",
  "scene", 
  "meshes",
  "anims"
]

def runCommand(context, sock, client, cmd):
    
    # If this is a new client

    if( sock not in gclients):
      gclients[sock] = { 
        "client": sock,
        "cmds"  : []
      }
    clientobj = gclients[sock] 

    strcmd = str(cmd)
    if cmd in validcmds:
      cmds = clientobj["cmds"]
      strstate = "Active"
      if( strcmd in cmds ):
        strstate = "In-Active"
        cmds.remove(strcmd)
      else:
        cmds.append(strcmd)
      #print("Command: " + strcmd + "   State: " + strstate)

      ## client.put(str(TAG_END).encode('utf8'))
    return 

# ------------------------------------------------------------------------

def getData( context, clientcmds):
      
    data = ""

    # Check to see what commands are enabled. And collect data if they changed    

    # TODO: Optimise this into mapped methods
    for cmd in clientcmds:

      # Basic info of the scene
      if(cmd == 'info'):
          results = sceneInfo(context)
          data = data + (str(TAG_START + "01" + TAG_TAIL).encode('utf8'))
          data = data + (results.encode('utf8'))
          data = data + (str(TAG_END + "01" + TAG_TAIL).encode('utf8'))

      # Object level info of the scene
      if(cmd == 'scene'):
          results = sceneObjects(context)
          data = data + (str(TAG_START + "02" + TAG_TAIL).encode('utf8'))
          data = data + (results.encode('utf8'))
          data = data + (str(TAG_END + "02" + TAG_TAIL).encode('utf8'))

      # Object level info of the scene
      if(cmd == 'meshes'):
          results = sceneMeshes(context)
          data = data + (str(TAG_START + "03" + TAG_TAIL).encode('utf8'))
          data = data + (results.encode('utf8'))
          data = data + (str(TAG_END + "03" + TAG_TAIL).encode('utf8'))

      # All bone animations in the scene
      if(cmd == 'anims'):
          results = sceneAnimations(context)
          data = data + (str(TAG_START + "04" + TAG_TAIL).encode('utf8'))
          data = data + (results.encode('utf8'))
          data = data + (str(TAG_END + "04" + TAG_TAIL).encode('utf8'))
        
      return data

# ------------------------------------------------------------------------
