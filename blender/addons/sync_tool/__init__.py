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
# Defold export tool
#    What is this?  This is a tool for the Defold game engine to export information/data from 
#    Blender to a Defold project tool. 
#    Allows users to create complex 3D scenes in Blender, and instantly be able to use those 3D
#    scenes in Defold - this may even be possible live (TODO)
#
#   General Structure
#     This server script that takes commands from a client and sends requested data 
#     An intermediary tool (Make in Defold) that requests the data and creates Defold components
#     The Defold project is assigned to the intermediary tool which allows direct export to the project
#
# Initial Tests:
#  - Some simple commands - Get Object, Get Mesh, Get Texture/UVs
#  - Display in intermediary tool
#  - Write a collection file, go files, mesh files and texture/image files

# Based on:
#  https://gist.github.com/p2or/2947b1aa89141caae182526a8fc2bc5as

bl_info = {
    "name": "Sync Tool",
    "description": "Sync a Blender Scene directly to Defold resources",
    "author": "dlannan",
    "version": (1, 0, 8),
    "blender": (2, 80, 0),
    "location": "3D View > Defold",
    "warning": "", # used for warning icon and text in addons panel
    "wiki_url": "",
    "tracker_url": "",
    "category": "Development"
}


import bpy, subprocess, os, sys, socket
import platform

from bpy.props import (StringProperty,
                       BoolProperty,
                       IntProperty,
                       FloatProperty,
                       FloatVectorProperty,
                       EnumProperty,
                       PointerProperty,
                       )
from bpy.types import (Panel,
                       Menu,
                       Operator,
                       PropertyGroup,
                       )

# ------------------------------------------------------------------------
# When bpy is already in local, we know this is not the initial import...
if "bpy" in locals():
    # ...so we need to reload our submodule(s) using importlib
    import importlib
    if "defoldCmds" in locals():
        importlib.reload(defoldCmds)

# ------------------------------------------------------------------------

import addon_utils
for mod in addon_utils.modules():
    if(mod.bl_info.get("name") == "Sync Tool"):
        dir = os.path.dirname(mod.__file__)

# dir = os.path.dirname(bpy.data.filepath)
if not dir in sys.path:
    sys.path.append(dir )

# ------------------------------------------------------------------------

from defoldsync import defoldCmds

data_changed = False

# ------------------------------------------------------------------------
#    Scene Properties
# ------------------------------------------------------------------------

def update_lightposition(self, context):
    scene = context.scene
    mytool = scene.sync_tool
    if(mytool.sync_light_obj != None):
        mytool.sync_light_vector[0] = mytool.sync_light_obj.location.x
        mytool.sync_light_vector[1] = mytool.sync_light_obj.location.z
        mytool.sync_light_vector[2] = -mytool.sync_light_obj.location.y

def update_lightglobal(self, context):
    scene = context.scene
    mytool = scene.sync_tool
    if(mytool.sync_light_mode == 'Light Global'):
        mytool.sync_light_vector = [0.0, -1.0, 0.0]
    else:
        mytool.sync_light_vector = [0.0, 0.0, 0.0]

class SyncProperties(PropertyGroup):

    stream_info: BoolProperty(
        name="Stream Info",
        description="Enable Info Stream",
        default = False
        )

    stream_mesh: BoolProperty(
        name="Stream Meshes",
        description="Enable Mesh Stream",
        default = True
        )

    stream_mesh_type: EnumProperty(
        name="Mesh Type",
        description="Select the type of mesh to use.",
        items=[ 
                ('Collada', "Collada (anims only)", ""),
                ('GLTF', "GLTF (mesh and anims)", ""),
               ]
    )

    stream_object: BoolProperty(
        name="Stream Objects",
        description="Enable Object Stream",
        default = True
        )

    stream_anim: BoolProperty(
        name="Export Animation",
        description="Enable Animation Stream",
        default = False
        )

    stream_anim_name: PointerProperty(
        name="Select Armature",
        description="Select an Armature for Animation export",
        type=bpy.types.Object
        )

    sync_light_mode: EnumProperty(
        name="Light Mode:",
        description="Select the type of global light to use.",
        update=update_lightglobal,
        items=[ 
                ('Light Local', "Use Local Point Light", ""),
                ('Light Global', "Use Global Directional Light", ""),
               ]
        )

    sync_light_vector: FloatVectorProperty(
        name = "Light Position/Direction",
        description="Direction or Position of the Scene Light.",
        default=(0.0, -1.0, 0.0), 
        ) 

    sync_light_obj: PointerProperty(
        name="Select Light",
        description="Select a Light for the Scene",
        type=bpy.types.Object,
        update=update_lightposition,
        ) 

    root_position: FloatVectorProperty(
        name = "Scene Position",
        description="Position of the scene in Defol",
        default=(0.0, 0.0, 0.0), 
        ) 
    
    sync_host: StringProperty(
        name="Host",
        description="Defold Sync Host:",
        default="localhost",
        maxlen=256,
        )

    sync_scene: StringProperty(
        name="Scene Name",
        description="Defold collcecion name:",
        default="My Scene",
        maxlen=256,
        )

    sync_proj: StringProperty(
        name = "Project Folder",
        description="Choose a directory:",
        default="",
        maxlen=1024,
        subtype='DIR_PATH'
        )

    sync_shader: EnumProperty(
        name="Shader:",
        description="Sync Tool Shader Type",
        items=[ 
                ('Model Material', "Builtin Model Material Shader", ""),
                ('PBR Simple', "PBR Material Shader", ""),
               ]
        )

    sync_mat_params: FloatVectorProperty(
        name = "Shader Params",
        description="Ambient, Albedo Percent and Specular.",
        default=(0.1, 1.0, 0.5), 
        ) 

    sync_mat_facenormals: BoolProperty(
        name="Face Normals",
        description="Use face normals instead of vertex normals",
        default = False
        )

    sync_mat_uv2: BoolProperty(
        name="Second UVs",
        description="Export second set of UV's if found in the mesh.",
        default = False
        )
        
    sync_mode: EnumProperty(
        name="Dropdown:",
        description="Sync Tool Operation Mode",
        items=[ ('Sync Build', "Sync Build", ""),
                ('Debug', "Debug", ""),
               ]
        )

    sync_progress: FloatProperty( 
        name="Progress", 
        subtype="PERCENTAGE",
        soft_min=0, 
        soft_max=100, 
        precision=0,
        )

    sync_progress_label: StringProperty()


# ------------------------------------------------------------------------
#    Operators
# ------------------------------------------------------------------------

class WM_OT_SyncTool(Operator):

    bl_label = "Sync Scene"
    bl_idname = "wm.sync_scene"

    def execute(self, context):
        scene = context.scene
        mytool = scene.sync_tool

        dirpath     = os.path.abspath(dir + '/defoldsync/main.lua')
       
        projpath    = os.path.realpath(bpy.path.abspath(mytool.sync_proj))
         # Convert \ in path to \\
        projpath    = projpath.replace('\\','\\\\')

        prm = mytool.sync_mat_params  
        lv = mytool.sync_light_vector  
        animname = ""
        if (mytool.stream_anim_name != None):
            animname = str(mytool.stream_anim_name.name)

        # Write all the sync tool properties to a config file
        with open(  os.path.abspath(dir + '/defoldsync/config.lua'), 'w') as f:
            f.write('-- Lua generated config - do not edit.\n')
            f.write('return {\n')
            f.write('   sync_mode        = "' + str(mytool.sync_mode) + '",\n')
            f.write('   sync_proj        = "' + projpath + '",\n')
            f.write('   sync_scene       = "' + mytool.sync_scene + '",\n')
            f.write('   sync_shader      = "' + str(mytool.sync_shader) + '",\n')
            f.write('   sync_light_mode  = "' + str(mytool.sync_light_mode) + '",\n')
            f.write('   sync_light_vec   = { x = ' + str(lv[0]) + ', y = ' + str(lv[1]) + ', z = ' + str(lv[2]) + ' },\n')
            f.write('   sync_mat_params   = { x = ' + str(prm[0]) + ', y = ' + str(prm[1]) + ', z = ' + str(prm[2]) + ' },\n')
            f.write('   sync_mat_facenormals = ' + str(mytool.sync_mat_facenormals).lower() + ',\n')
            f.write('   sync_mat_uv2     = ' + str(mytool.sync_mat_uv2).lower() + ',\n')
            f.write('   stream_info      = ' + str(mytool.stream_info).lower() + ',\n')
            f.write('   stream_object    = ' + str(mytool.stream_object).lower() + ',\n')
            f.write('   stream_mesh      = ' + str(mytool.stream_mesh).lower() + ',\n')
            f.write('   stream_mesh_type = "' + str(mytool.stream_mesh_type).lower() + '",\n')
            f.write('   stream_anim      = ' + str(mytool.stream_anim).lower() + ',\n')
            f.write('   stream_anim_name = "' + animname + '",\n')

            f.write('}\n')

        # Run with library demo
        # result = subprocess.check_output(['luajit', '-l', 'demo', '-e', 'test("a", "b")'])
        commands    = [ "scene", "meshes" ]
        if(mytool.stream_anim == True):
            commands.append("anims")

        # get the data from the objects in blender
        defoldCmds.getData(context, commands, dir, mytool)

        # Data is written for each stream. 
        platform_luajits = {
            "Linux": {
                "path": "luajit/linux/",
                "exe": "luajit"
            },
            "Windows": {
                "path": "luajit/win/",
                "exe": "luajit.exe"
            },
            "Darwin": {
                "path": "luajit/darwin/",
                "exe": "luajit"
            }
        }
        this_platform = platform.system()

        prog_text = "Generating Defold data..."
        defoldCmds.update_progress(context, 10, prog_text)
        defolddir = dir + '/defoldsync/'

        luajit_cmd = os.path.abspath(defolddir + platform_luajits[this_platform]["path"] + platform_luajits[this_platform]["exe"] )
        subprocess.check_output([luajit_cmd, dirpath, os.path.abspath(dir)])
        prog_text = "Process Complete."
        defoldCmds.update_progress(context, 100, prog_text)

        # print the values to the console
        if( str(mytool.sync_mode) == 'Debug' ):
            print("Sync Tool\n---------")
            print("Stream Info:", mytool.stream_info)
            print("Stream Objects:", mytool.stream_object)
            print("Stream Meshes:", mytool.stream_mesh)
            print("Stream Mesh Type:", mytool.stream_mesh_type)
            print("Stream Anims:", mytool.stream_anim)
            print("Host:", mytool.sync_host)
            print("Project Folder:", mytool.sync_proj)
            print("Scene Name:", mytool.sync_scene)
            print("Scene Pos:", mytool.root_position)

        return {'FINISHED'}

# ------------------------------------------------------------------------
#    Panel in Object Mode
# ------------------------------------------------------------------------

class OBJECT_PT_CustomPanel(Panel):
    bl_label = "Sync Tool"
    bl_idname = "OBJECT_PT_custom_panel"
    bl_space_type = "VIEW_3D"   
    bl_region_type = "UI"
    bl_category = "Defold"
    bl_context = "objectmode"   


    @classmethod
    def poll(self,context):
        return context.object is not None

    def draw(self, context):
        layout = self.layout
        scene = context.scene
        mytool = scene.sync_tool

        box = layout.box()
        row = box.row()
        row.prop(mytool, "sync_mode", text="")
        row = box.row() 
        row.prop(mytool, "sync_shader", text="") 

        row = box.row()
        row.prop(mytool, "stream_mesh_type")

        row = box.row()
        row.prop(mytool, "sync_mat_params")
        row = box.row()
        row.prop(mytool, "sync_mat_facenormals")
        row = box.row()
        row.prop(mytool, "sync_mat_uv2")

        layout.separator()

        box = layout.box()
        row = box.row()
        #layout.prop(mytool, "sync_host")
        row.prop(mytool, "sync_proj")
        row = box.row()
        row.prop(mytool, "sync_scene")
        row = box.row()
        row.prop(mytool, "root_position")
        row = box.row()
        layout.separator()

        box = layout.box()
        row = box.row()
        row.prop(mytool, "sync_light_mode")
        row = box.row()
        row.prop(mytool, "sync_light_vector")
        if(mytool.sync_light_mode == "Light Local"):
            row = box.row()
            row.prop(mytool, "sync_light_obj")

        layout.separator()

        #layout.prop(mytool, "stream_info")
        #layout.prop(mytool, "stream_object")
        #layout.prop(mytool, "stream_mesh")
        box = layout.box()
        row = box.row()
        row.prop(mytool, "stream_anim")
        # if(mytool.stream_anim == True):
        #     row = box.row()
        #     row.prop(mytool, "stream_anim_name")

        layout.separator()

        layout.operator("wm.sync_scene")
        layout.separator()

#        if mytool.progress: 
        row = layout.row()
        row.prop(mytool, "sync_progress", text=mytool.sync_progress_label)

# ------------------------------------------------------------------------
#    Registration
# ------------------------------------------------------------------------

classes = (
    SyncProperties,
    WM_OT_SyncTool,
    OBJECT_PT_CustomPanel
)

def register():
    from bpy.utils import register_class
    for cls in classes:
        register_class(cls)

    bpy.types.Scene.sync_tool = PointerProperty(type=SyncProperties)

def unregister():
    from bpy.utils import unregister_class
    for cls in reversed(classes):
        unregister_class(cls)
    del bpy.types.Scene.sync_tool


if __name__ == "__main__":
    register()