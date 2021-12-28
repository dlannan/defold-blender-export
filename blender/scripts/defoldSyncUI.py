# Based on:
#  https://gist.github.com/p2or/2947b1aa89141caae182526a8fc2bc5as

bl_info = {
    "name": "Sync Tool",
    "description": "Sync a Blender Scene directly to Defold resources",
    "author": "dlannan",
    "version": (0, 0, 1),
    "blender": (2, 80, 0),
    "location": "3D View > Defold",
    "warning": "", # used for warning icon and text in addons panel
    "wiki_url": "",
    "tracker_url": "",
    "category": "Development"
}


import bpy, subprocess

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
#    Scene Properties
# ------------------------------------------------------------------------

class MyProperties(PropertyGroup):

    stream_info: BoolProperty(
        name="Stream Info",
        description="Enable Info Stream",
        default = False
        )

    stream_mesh: BoolProperty(
        name="Stream Meshes",
        description="Enable Mesh Stream",
        default = False
        )

    stream_object: BoolProperty(
        name="Stream Objects",
        description="Enable Object Stream",
        default = False
        )

    stream_anim: BoolProperty(
        name="Stream Animation",
        description="Enable Animation Stream",
        default = False
        )

    root_position: FloatVectorProperty(
        name = "Scene Position",
        description="Position of the scene in Defol",
        default=(0.0, 0.0, 0.0), 
        min= 0.0, # float
        max = 0.1
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
        name = "Directory",
        description="Choose a directory:",
        default="",
        maxlen=1024,
        subtype='DIR_PATH'
        )
        
    sync_mode: EnumProperty(
        name="Dropdown:",
        description="Sync Tool Operation Mode",
        items=[ ('OP1', "Sync Check", ""),
                ('OP2', "Sync Build", ""),
                ('OP3', "Debug", ""),
               ]
        )

# ------------------------------------------------------------------------
#    Operators
# ------------------------------------------------------------------------

class WM_OT_HelloWorld(Operator):
    bl_label = "Sync Scene"
    bl_idname = "wm.sync_scene"

    def execute(self, context):
        scene = context.scene
        mytool = scene.sync_tool

        # Run with library demo
        # result = subprocess.check_output(['luajit', '-l', 'demo', '-e', 'test("a", "b")'])
        
        result = subprocess.check_output(['luajit', '-e', 'for i=0,10 do print("hello "..i) end'])
        print(result)

        # print the values to the console
        print("Sync Tool\n---------")
        print("Stream Info:", mytool.stream_info)
        print("Stream Objects:", mytool.stream_object)
        print("Stream Meshes:", mytool.stream_mesh)
        print("Stream Anims:", mytool.stream_anim)
        print("Host:", mytool.sync_host)
        print("Project Folder:", mytool.sync_proj)
        print("Scene Name:", mytool.sync_scene)
        print("Scene Pos:", mytool.root_position)

        return {'FINISHED'}

# ------------------------------------------------------------------------
#    Menus
# ------------------------------------------------------------------------

class OBJECT_MT_CustomMenu(bpy.types.Menu):
    bl_label = "Select"
    bl_idname = "OBJECT_MT_custom_menu"

    def draw(self, context):
        layout = self.layout

        # Built-in operators
        layout.operator("object.select_all", text="Select/Deselect All").action = 'TOGGLE'
        layout.operator("object.select_all", text="Inverse").action = 'INVERT'
        layout.operator("object.select_random", text="Random")

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

        layout.prop(mytool, "sync_mode", text="") 
        layout.prop(mytool, "stream_info")
        layout.prop(mytool, "stream_object")
        layout.prop(mytool, "stream_mesh")
        layout.prop(mytool, "stream_anim")
        #layout.prop(mytool, "sync_host")
        layout.prop(mytool, "sync_proj")
        layout.prop(mytool, "sync_scene")
        layout.prop(mytool, "root_position")
        layout.operator("wm.sync_scene")
        layout.separator()

# ------------------------------------------------------------------------
#    Registration
# ------------------------------------------------------------------------

classes = (
    MyProperties,
    WM_OT_HelloWorld,
    OBJECT_MT_CustomMenu,
    OBJECT_PT_CustomPanel
)

def register():
    from bpy.utils import register_class
    for cls in classes:
        register_class(cls)

    bpy.types.Scene.sync_tool = PointerProperty(type=MyProperties)

def unregister():
    from bpy.utils import unregister_class
    for cls in reversed(classes):
        unregister_class(cls)
    del bpy.types.Scene.sync_tool


if __name__ == "__main__":
    register()