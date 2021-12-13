import json
import time, threading, queue

# These are used to start/end a data stream block. 
TAG_START = "\n\n!!BCMD"
TAG_END   = "\n\n!!ECMD"

TAG_TAIL  = "!!\n\n"

# Kinda evil.. meh
gclients    = {}

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

    return json.dumps(dataobjs)

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

        local_coord = obj.location
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

    return json.dumps(dataobjs)



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
            for v in me.vertices:
              verts.append( { "x": v.co.x, "y": v.co.y, "z": v.co.z } )
            thisobj["vertices"] = verts

            tris = []
            uv_layer = me.uv_layers.active.data
            for tri in me.loop_triangles:

              triobj = {}
              thistri = []
              triobj["normal"] = {
                "x": tri.normal.x, 
                "y": tri.normal.y,
                "z": tri.normal.z
              }

              for tri_index in range(0, 3):
                v = tri.vertices[tri_index]
                uv = uv_layer[tri_index].uv

                thistri.append( { 
                  "vertex": v,
                  "uv": { "x": uv.x, "y": uv.y }
                } )
              triobj["tri"] = thistri
              tris.append(triobj)
            thisobj["tris"] = tris
          
          dataobjs[ thisobj["name"] ] = thisobj 

    return json.dumps(dataobjs)


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
  "meshes"
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

def sendData( context, sock, client ):
      
    # Check to see what commands are enabled. And collect data if they changed
    if(sock not in gclients):
      return

    clientobj = gclients[sock]
    
    if("cmds" in clientobj):

      clientcmds = clientobj["cmds"]

      # TODO: Optimise this into mapped methods
      for cmd in clientcmds:

        # Basic info of the scene
        if(cmd == 'info'):
            results = sceneInfo(context)
            client.put(str(TAG_START + "01" + TAG_TAIL).encode('utf8'))
            client.put(results.encode('utf8'))
            client.put(str(TAG_END + "01" + TAG_TAIL).encode('utf8'))

        # Object level info of the scene
        if(cmd == 'scene'):
            results = sceneObjects(context)
            client.put(str(TAG_START + "02" + TAG_TAIL).encode('utf8'))
            client.put(results.encode('utf8'))
            client.put(str(TAG_END + "02" + TAG_TAIL).encode('utf8'))

        # Object level info of the scene
        if(cmd == 'meshes'):
            results = sceneMeshes(context)
            client.put(str(TAG_START + "03" + TAG_TAIL).encode('utf8'))
            client.put(results.encode('utf8'))
            client.put(str(TAG_END + "03" + TAG_TAIL).encode('utf8'))

# ------------------------------------------------------------------------
