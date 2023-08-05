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
from defoldsync import defoldMaterials

# ------------------------------------------------------------------------

modulesNames = ['DefoldSyncUI']

import bpy, time, queue, re, os, json, shutil, math, mathutils
from bpy_extras.io_utils import axis_conversion
from io import BytesIO

from math import radians
from mathutils import Euler, Matrix

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

    f.write( defoldUtils.dump_lua(dataobjs) )

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
    defoldUtils.ErrorLine( config, "No Collection found. Please add a collection.", "Scene", 'ERROR' )
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

        # Force all scaling to unity - otherwise things are difficult to manage
        objType = getattr(obj, 'type', '')
        print(objType + "   " + obj.name)
        if(objType not in ["LAMP", "LIGHT"]):
          obj.select_set(True)
          bpy.ops.object.transform_apply(scale=True)
          obj.select_set(False)

        thisobj = {
          "name": str(obj.name),
          "type": str(obj.type)
        }

        local_coord = obj.matrix_local.translation #obj.location

        rot = obj.rotation_quaternion.to_euler('XYZ')
        if( obj.rotation_mode != "QUATERNION"):
          rot = obj.rotation_euler.copy()
          rot.order = 'XYZ'
          
        if(obj.parent != None):
            thisobj["parent"] = {
              "name": str(obj.parent.name),
              "type": str(obj.parent_type)
            }

        # This is a parent object in the collection. Adjust its location and rotation
        else:
          euler =  Matrix.Rotation( radians(-90), 4, 'X')
          rot = (euler @ rot.to_matrix().to_4x4()).to_euler('XYZ')
          local_coord = euler @ local_coord

        thisobj["location"] = { 
          "x": local_coord.x, 
          "y": local_coord.y, 
          "z": local_coord.z 
        }

#        quat = obj.rotation_quaternion
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

        if( defoldUtils.isAnimated(obj) == True ):
          thisobj["animated"] = True

        f.write('["' + str(obj.name) + '"] = ' + defoldUtils.dump_lua(thisobj) + ', \n')
        #thisobj["name"] ] = thisobj 

      f.write('}, \n')

  f.write('} \n')

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

        if(defoldUtils.isAnimated(obj) == True):
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

          if obj is not None and obj.type == 'MESH' and obj.active_material:   
            mat = obj.active_material

          thisobj = defoldMaterials.ProcessMaterial(thisobj, mat, texture_path, context, config)

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
        #   fh.write( '   mesh = ' + defoldUtils.dump_lua(thisobj) + '\n' )
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

  #   f.write("['" + action.name + "'] = " + defoldUtils.dump_lua(curves) + ', \n')
  #   #animobjs[action.name] = curves
    
  f.write('} \n')

# ------------------------------------------------------------------------

def getData( context, clientcmds, dir, config):

  temppath = os.path.abspath(dir + '/defoldsync/temp')

  try:
      shutil.rmtree(temppath, ignore_errors=True)
  except OSError as e:
      print("Error: %s : %s" % (dir_path, e.strerror))

  defoldUtils.ClearErrors( config )

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
