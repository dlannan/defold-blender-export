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

import bpy, bpy_extras, time, queue, re, os, json, shutil, math, mathutils
from bpy_extras.io_utils import axis_conversion
from io import BytesIO

from math import radians
from mathutils import Euler, Matrix, Vector

# Using the space conversion helper
convert_mat = axis_conversion(from_forward='Y', from_up='Z',
                            to_forward='-Z', to_up='Y').to_4x4()

# ------------------------------------------------------------------------
# Helper for making objects

class Struct(object):
    def __init__(self, d):
        for key in d.keys():
            self.__setattr__(key, d[key])

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

    scene_objects = [ obj for obj in context.scene if obj in bpy.context.visible_objects ]
    for obj in scene_objects:

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

def getProperties(obj, thisobj):
    # Store custom properties too 
    if(len(obj.keys()) > 0):
        props = {}
        for K in obj.keys():
            if(isinstance(obj[K], str)):
                props[str(K)] = str(obj[K])
                #print( K , "-" , obj[K] )
        if(len(props) > 0 and thisobj != None):
            thisobj["props"] = props
            return props
    return None

# ------------------------------------------------------------------------

def processDefoldProperties(obj, thisobj):

    if(obj == None):
        return 

    proplist = obj.demo_list
    active_material_name = "default"
    if( obj.active_material != None and obj.active_material.name != None ):
        active_material_name = obj.active_material.name

    # override props if parent has props and the Apply children flag is set!
    if( obj.parent != None and obj.parent.demo_list != None and len(obj.parent.demo_list) > 0):
        parentObj = obj.parent

        if( obj.parent.apply_children == True):
            proplist = parentObj.demo_list
            if( parentObj.active_material != None and parentObj.active_material.name != None ):
                active_material_name = parentObj.active_material.name

    if( len(proplist) > 0 ):
        defold_output_props = []
        for item in proplist:
            defold_item = {
                "command": str(item.command)
            }

            if item.command == "Collider":
                defold_item["collider_group"] = item.collider_group
                defold_item["collider_mask"] = item.collider_mask
                defold_item["collider_type"] = item.collider_type

            if item.command == "Add FileComponent":
                defold_item["filecomponent_id"] = item.filecomponent_id
                defold_item["filecomponent_path"] = item.filecomponent_path

            if item.command == "Material Name":
                defold_item["material_obj"] = active_material_name
                defold_item["material_defold"] = item.material_defold 

            if item.command == "Material Texture":
                defold_item["material_obj"] = active_material_name
                defold_item["material_texture"] = item.material_texture
                defold_item["material_texture_defold"] = item.material_texture_defold 

            if item.command == "Set Key/Value":
                val = (item.store_value).replace('"', '\\"')
                defold_item["keyval"] = { "key": item.store_key, "value": val, "is_table": item.store_is_table }

            if item.command == "Init Script":
                defold_item["scipt_init"] = item.command_init.replace('"', '\\"')

            if item.command == "Update Script":
                defold_item["scipt_update"] = item.command_update.replace('"', '\\"')
            
            defold_output_props.append(defold_item)

        if(len(defold_output_props) > 0):
            thisobj["defold_props"] = defold_output_props

# ------------------------------------------------------------------------
# Get all available obejcts in the scene (including transforms)
def sceneObjects(context, f, config, handled):

    f.write('{ \n')
    scene = context.scene

    # Axis convert everything
    convert_rot = convert_mat.to_quaternion().to_matrix().to_4x4()
    convert_irot = convert_rot.inverted()       
    for obj in scene.objects: 

        obj.matrix_world = convert_mat @ obj.matrix_world                                         
        if obj.type == "MESH":
            # obj.data.transform(convert_rot)
            obj.matrix_world = obj.matrix_world @ convert_irot
        else:
            obj.matrix_world = obj.matrix_world @ convert_irot
            
        # else:
        # if obj.parent == None:
        #     # Rotate the position too (to simulate rotation around scene origin)
        #     pos = obj.location
        #     obj.location = convert_rot @ pos
        #     print("------->" + str(obj.name))
        #     else:
        #         obj.matrix_world = convert_mat @ obj.matrix_world


    prog_text = "Exporting objects..."
    objcount = 0
    #for coll in bpy.data.collections:
    for coll in bpy.context.view_layer.layer_collection.children:
        if coll.is_visible:
            collection_objects = [ obj for obj in coll.collection.objects if obj in bpy.context.visible_objects ]
            objcount += len(collection_objects)
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

            collection_objects = [ obj for obj in coll.collection.objects if obj in bpy.context.visible_objects ]
            for obj in collection_objects:
                            
                if(handled[obj.name] == False):

                    update_progress(context, ((objcurr + 1)/objcount) * 100, prog_text )
                    objcurr += 1

                    # Force all scaling to unity - otherwise things are difficult to manage
                    objType = getattr(obj, 'type', '')
                    if(objType not in ["LAMP", "LIGHT"]):
                        obj.select_set(True)
                        # Make objects single users and apply scale
                        bpy.ops.object.make_single_user(object=True, obdata=True)
                        bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)          
                        obj.select_set(False)

                    thisobj = {
                        "name": str(obj.name),
                        "type": str(obj.type)
                    }

                    #Override Type if this is a grouped object - always a mesh
                    if(obj.defold_props.group_children == True):
                        thisobj["type"] = "MESH"

                    local_coord = obj.matrix_local.translation # obj.location

                    rot = obj.rotation_quaternion.to_euler()
                    if( obj.rotation_mode != "QUATERNION"):
                        rot = obj.rotation_euler.copy()
                        rot.order = 'XYZ'
                        
                    dimensions = obj.dimensions

                    if(obj.parent != None):
                        thisobj["parent"] = {
                            "name": str(obj.parent.name),
                            "type": str(obj.parent_type)
                        }

                    # This is a parent object in the collection. Adjust its location and rotation
                    # else:
                    #     euler = Matrix.Rotation( radians(-90), 4, 'X')
                    #     rot = (euler @ rot.to_matrix().to_4x4()).to_euler('XYZ')
                    #     local_coord = euler @ local_coord

                    dimensions = (convert_mat @ dimensions)

                    thisobj["location"] = { 
                        "x": local_coord.x, 
                        "y": local_coord.y, 
                        "z": local_coord.z 
                    }

                    thisobj["dimensions"] = { 
                        "x": abs(dimensions.x), 
                        "y": abs(dimensions.y), 
                        "z": abs(dimensions.z) 
                    }

                    # quat = obj.rotation_quaternion
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

                    getProperties(obj, thisobj)

                    # Process the new game data command (additional to custom)
                    processDefoldProperties(obj, thisobj)

                    if( defoldUtils.isAnimated(obj) == True ):
                        thisobj["animated"] = True

                    f.write('["' + str(obj.name) + '"] = ' + defoldUtils.dump_lua(thisobj) + ', \n')
                    #thisobj["name"] ] = thisobj 

            f.write('}, \n')

    f.write('} \n')

# ------------------------------------------------------------------------
# Little util to taverse children and return a list

def getChildren(myObject): 
    children = [] 
    for ob in bpy.data.objects: 
        if ob.parent == myObject: 
            children.append(ob) 
    return children 

# ------------------------------------------------------------------------
# Mesh Buffer Export helper

def exportMeshBuffer(context, mat, config, thisobj, obj, texture_path):
    
    lightmap_enable = mat.name.endswith( "_LightMap")
    me = obj.data
    # Build the mesh into triangles
    # bpy.ops.mesh.quads_convert_to_tris(quad_method='BEAUTY', ngon_method='BEAUTY')
    me.calc_loop_triangles()

    # Get the vert data
    verts   = []
    normals = []

    # Apply the matrix directly to vertex coordinates
    verts_local = [convert_mat @ v.co for v in obj.data.vertices]
    convert_rot = convert_mat.to_quaternion().to_matrix().to_4x4()
    convert_irot = convert_rot.inverted()       

    normals_transformed = [convert_irot @ v.normal for v in obj.data.vertices]

    # Gltf and Glb are stored in file. No need for this
    if(config.sync_mat_facenormals == True):
        for v in verts_local:
            verts.append( { "x": v.x, "y": v.y, "z": v.z } )
    else:
        idx = 0
        for v in verts_local:
            normal = normals_transformed[idx]
            verts.append( { "x": v.x, "y": v.y, "z": v.z } )
            normals.append( { "x": normal.x, "y": normal.y, "z": normal.z } )
            idx = idx + 1

    thisobj["vertices"] = verts
    thisobj = defoldMaterials.ProcessMaterial(thisobj, mat, texture_path, context, config)

    tris = []
    nidx = 0

    for i, face in enumerate(me.loop_triangles):
        verts_indices = face.vertices[:]

        triobj = {}
        thistri = []
        facenormal = convert_irot @ face.normal

        for ti in range(0, 3):
            idx = verts_indices[ti]
            nidx = idx
            uv = None

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
            
            if(uv is None):
                uv = Struct({ "x": 0.0, "y": 0.0 })

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


# ------------------------------------------------------------------------
# GLTF Export helper

def exportGLTF(context, thisobj, obj, temppath, mode, children):
    # Select just this object to export
    for o in context.selected_objects:
        o.select_set(False)

    obj.select_set(True)
    if(children == True):
        for ch in obj.children:
            ch.select_set(True)

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
            # export_yup=False,
            export_texture_dir="textures",
            export_texcoords=True,
            export_normals=True,
            # export_colors=True,
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

# ------------------------------------------------------------------------
# Get all available meshes in the scene (including data)

def sceneMeshes(context, fhandle, temppath, texture_path, config, handled):

    scene = context.scene
    all_objects = bpy.data.objects[:]
    objectsall = [obj for obj in all_objects if obj in bpy.context.visible_objects]

    mode = config.stream_mesh_type
    fhandle.write('{ \n')
    UVObj = type('UVObj', (object,), {})

    prog_text = "Exporting meshes..."
    objcount = 0
    objcurr = 0

    #Deselect any selected object
    for o in context.selected_objects:
        o.select_set(False)

    animActionObjs = []

    for obj in objectsall:

        # Collate child collapsed meshes ready for processed
        if obj.defold_props.group_children == True:      
            thisobj = {
                "name": str(obj.name),
                "type": "MESH"      # Always force to object.
            }

            mat = obj.active_material  
            if obj is not None and obj.type == 'MESH' and obj.active_material:      
                thisobj["matname"] = mat.name  

            if(obj.parent != None):
                thisobj["parent"] = str(obj.parent.name)

            meshfile = os.path.abspath(temppath + str(thisobj["name"]) + '.json')

            if( mode == "GLTF" or mode == "GLB" ):
                exportGLTF(context, thisobj, obj, temppath, mode, True)

            with open( meshfile, 'w') as f:
                f.write(json.dumps(thisobj))

            meshfile = meshfile.replace('\\','\\\\')       
            fhandle.write('["' + thisobj["name"] + '"] = "' + meshfile + '", \n')
            objcount = objcount + 1
        else:
            if(handled[obj.name] == False):
                objcount = objcount + 1

    # iterate all the scene objects
    sceneobjectsall = [obj for obj in scene.objects if obj in bpy.context.visible_objects]
    for obj in sceneobjectsall:

        update_progress(context, ((objcurr + 1)/objcount) * 100, prog_text )
        objcurr += 1

        # Only collect meshes in the scene
        if(obj.type == "MESH" and handled[obj.name] == False):

            if(defoldUtils.isAnimated(obj) == True):
                if(not obj.name in animActionObjs): 
                    animActionObjs.append(obj.name)

            thisobj = {
                "name": str(obj.name),
                "type": str(obj.type)
            }

            if obj is not None and obj.type == 'MESH' and obj.active_material:   
                mat = obj.active_material       
                thisobj["matname"] = mat.name  
            
            if(obj.parent != None):
                thisobj["parent"] = str(obj.parent.name)

            if(obj.data and mode == "MESH"):
                exportMeshBuffer(context, mat, config, thisobj, obj, texture_path)
            

            meshfile = os.path.abspath(temppath + str(thisobj["name"]) + '.json')

            if( mode == "GLTF" or mode == "GLB" ):
                exportGLTF(context, thisobj, obj, temppath, mode, False)

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
    update_progress(context, 100, prog_text )
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
                animfiletype = "GLTF_EMBEDDED"
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
        handled = {}

        data_objects = [o for o in bpy.data.objects if o in bpy.context.visible_objects]
        #data_objects = [obj for obj in bpy.data.objects if obj.hide_viewport == False]
        print("Sizes: " + str(len(bpy.data.objects)) + "   " + str(len(data_objects)))

        for obj in data_objects:
            # Parent object can be anything. If it is set as the geom group node
            #   then export everything under it, but also remove any from this children set
            #   in the scene.objects set
            if obj.defold_props.group_children == True:
                children = getChildren(obj)
                for ch in children:
                    handled[ch.name] = True

        for obj in data_objects:
            if(handled.get(obj.name) is None):
                handled[obj.name] = False


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
                sceneObjects(context, f, config, handled) 
                f.write(', \n')

            # Mesh data 
            if(cmd == 'meshes'):
                f.write('MESHES = ')
                animobjs = sceneMeshes(context, f, temppath + bpy.path.native_pathsep('/'), texture_path, config, handled)
                f.write(', \n')

            # All bone animations in the scene
            if(cmd == 'anims'):
                f.write('ANIMS = ')
                sceneAnimations(context, f, temppath + bpy.path.native_pathsep('/'), config, animobjs)
                f.write(', \n')

        f.write("}\n")

# ------------------------------------------------------------------------
