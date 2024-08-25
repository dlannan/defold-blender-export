
import bpy
from bpy.props import (StringProperty,
                       BoolProperty,
                       IntProperty,
                       FloatProperty,
                       FloatVectorProperty,
                       CollectionProperty,
                       EnumProperty,
                       PointerProperty,
                       )
from bpy.types import (Panel,
                       Menu,
                       Operator,
                       UIList,
                       PropertyGroup,
                       )

class DefoldProperties(PropertyGroup):

    defold_errors_str = []

    group_children: BoolProperty(
        name="Group Children into Single Model",
        description="Group children meshes into a single model file (GLB/GLTF)",
        default = False
        )
    
    apply_children: BoolProperty(
        name="Apply Commands to Children",
        description="Generate mesh buffers for children instead of gameobjects",
        default = True
        )
    
    add_defold_cmd: EnumProperty(
        name="Add Cmd",
        description="Add a command to the properties list",
        items=[ 
                ("None", "None", "No command is applied."),
                ('Collider', 'Collider', "Create a box collider for this object"),
                ('Material Name', 'Material Name', "Convert Material name to Defold material name"),
                ('Material Texture', 'Material Texture', "Convert Texture name to Defold texture name"),
                ('Set Key/Value', 'Set Key/Value', "Set Global Property Value"),
                ('Init Script', 'Init Script', "Run Script on Init"),
                ('Update Script', 'Update Script', "Run Script on Update"),
               ]
        )

#-----------------------------------------------------------------------------
#
# An extremely simple class that is used as the list item in the UIList.
# It is possible to use a builtin type instead but this allows customization.
# The content is fairly arbitrary, execpt that the member should be
# bpy.props (ToDo: Verify this.)
# Since it contains bpy.props, it must be registered.
class ListItem(PropertyGroup):
    """Group of properties representing an item in the list."""

    command: StringProperty(
           name="Command",
           description="The command to be run",
           default="Untitled")

    material_obj: PointerProperty(
        name="Material",
        description="Select a Material for the Scene",
        type=bpy.types.Object,
    ) 

    material_defold: StringProperty(
           name="Defold Material",
           description="Name of the Defold material to use",
           default="/builtin/materials/model.material"
    )

    material_texture: StringProperty(
        name="Material Texture",
        description="Name of this Material Slot to replace",
        default="Albedo"
    ) 

    material_teexture_defold: StringProperty(
        name="Material Texture Defold",
        description="Name of the Defold Material to use inplace",
        default="/builtin/materials/model.material"
    ) 

    store_key: StringProperty(
           name="Key",
           description="Name of the key to store in gop",
           default=""
    )

    store_value: StringProperty(
           name="Value",
           description="Name of the value to store in gop",
           default=""
    )

    command_init: StringProperty(
           name="Script Init",
           description="A single lua script line to run on init",
           default=""
    )

    command_update: StringProperty(
           name="Script Update",
           description="A single lua script line to run on update",
           default=""
    )

#-----------------------------------------------------------------------------
#
# https://docs.blender.org/api/current/bpy.types.UIList.html#bpy.types.UIList
# The actual UIList class
# This class has a filter function that can be used to sort the properties
# into ascending or descending order using their name property.
class TOOL_UL_List(UIList):
    """Demo UIList."""
    bl_idname = "TOOL_UL_List"
    layout_type = "DEFAULT" # could be "COMPACT" or "GRID"
    # list_id ToDo

    # Custom properties, used in the filter functions
    # This property applies only if use_order_name is True.
    # In that case it determines whether to reverse the order of the sort.
    use_name_reverse: bpy.props.BoolProperty(
        name="Reverse Name",
        default=False,
        options=set(),
        description="Reverse name sort order",
    )

    # This properties tells whether to sort the list according to
    # the alphabetical order of the names.
    use_order_name: bpy.props.BoolProperty(
        name="Name",
        default=False,
        options=set(),
        description="Sort groups by their name (case-insensitive)",
    )

    # This property is the value for a simple name filter.
    filter_string: bpy.props.StringProperty(
        name="filter_string",
        default = "",
        description="Filter string for name"
    )

    # This property tells whether to invert the simple name filter
    filter_invert: bpy.props.BoolProperty(
        name="Invert",
        default = False,
        options=set(),
        description="Invert Filter"
    )

    #-------------------------------------------------------------------------
    # This function does two things, and as a result returns two arrays:
    # flt_flags - this is the filtering array returned by the filter
    #             part of the function. It has one element per item in the
    #             list and is set or cleared based on whether the item
    #             should be displayed.
    # flt_neworder - this is the sorting array returned by the sorting
    #             part of the function. It has one element per item
    #             the item is the new position in order for the
    #             item.
    # The arrays must be the same length as the list of items or empty
    def filter_items(self, context,
                    data, # Data from which to take Collection property
                    property # Identifier of property in data, for the collection
        ):


        items = getattr(data, property)
        if not len(items):
            return [], []

        # https://docs.blender.org/api/current/bpy.types.UI_UL_list.html
        # helper functions for handling UIList objects.
        if self.filter_string:
            flt_flags = bpy.types.UI_UL_list.filter_items_by_name(
                    self.filter_string,
                    self.bitflag_filter_item,
                    items, 
                    propname="command",
                    reverse=self.filter_invert)
        else:
            flt_flags = [self.bitflag_filter_item] * len(items)

        # https://docs.blender.org/api/current/bpy.types.UI_UL_list.html
        # helper functions for handling UIList objects.
        if self.use_order_name:
            flt_neworder = bpy.types.UI_UL_list.sort_items_by_name(items, "command")
            if self.use_name_reverse:
                flt_neworder.reverse()
        else:
            flt_neworder = []    


        return flt_flags, flt_neworder        

    def draw_filter(self, context,
                    layout # Layout to draw the item
        ):

        row = layout.row(align=True)
        row.prop(self, "filter_string", text="Filter", icon="VIEWZOOM")
        row.prop(self, "filter_invert", text="", icon="ARROW_LEFTRIGHT")


        row = layout.row(align=True)
        row.label(text="Order by:")
        row.prop(self, "use_order_name", toggle=True)

        icon = 'TRIA_UP' if self.use_name_reverse else 'TRIA_DOWN'
        row.prop(self, "use_name_reverse", text="", icon=icon)

    def draw_item(self, context,
                    layout, # Layout to draw the item
                    data, # Data from which to take Collection property
                    item, # Item of the collection property
                    icon, # Icon of the item in the collection
                    active_data, # Data from which to take property for the active element
                    active_propname, # Identifier of property in active_data, for the active element
                    index, # Index of the item in the collection - default 0
                    flt_flag # The filter-flag result for this item - default 0
            ):

        # Make sure your code supports all 3 layout types
        if self.layout_type in {'DEFAULT', 'COMPACT'}:
            layout.label(text=item.command)

        elif self.layout_type in {'GRID'}:
            layout.alignment = 'CENTER'
            layout.label(text="")

#-----------------------------------------------------------------------------
#
# An extremely simple list add operator
# Replace context.active_object.demo_list with the actual list
class TOOL_OT_List_Add(Operator):
    """ Add an Item to the UIList"""
    bl_idname = "tool.list_add"
    bl_label = "Add"
    bl_description = "add a new item to the list."
    
    @classmethod
    def poll(cls, context):
        return context.active_object
    
    def execute(self, context):
        mytool = context.active_object.defold_props
        if(mytool.add_defold_cmd != "None"):
            item = context.active_object.demo_list.add()
            item.command = mytool.add_defold_cmd
        
        return {'FINISHED'}

#-----------------------------------------------------------------------------
#
# An extremely simple list remove operator
# Replace context.active_object.demo_list with the actual list
# It's only possible to remove the item that is indexed
# The reorder routine keeps track of the index.
class TOOL_OT_List_Remove(Operator):
    """ Add an Item to the UIList"""
    bl_idname = "tool.list_remove"
    bl_label = "Add"
    bl_description = "Remove an new item from the list."
    
    @classmethod
    def poll(cls, context):
        """ We can only remove items from the list of an active object
            that has items in it, but the list may be empty or doesn't
            yet exist and there's no reason to remove an item from an empty
            list.
        """
        return (context.active_object 
                and context.active_object.demo_list
                and len(context.active_object.demo_list))
    
    def execute(self, context):
        alist = context.active_object.demo_list
        index = context.active_object.list_index
        context.active_object.demo_list.remove(index)
        context.active_object.list_index = min(max(0, index - 1), len(alist) - 1)
        return {'FINISHED'}

#-----------------------------------------------------------------------------
#
# An extremely simple list reordering operator
# Replace context.object.demo_list with the actual list
class TOOL_OT_List_Reorder(Operator):
    """ Add an Item to the UIList"""
    bl_idname = "tool.list_reorder"
    bl_label = "Add"
    bl_description = "add a new item to the list."
    
    direction: bpy.props.EnumProperty(items=(('UP', 'Up', ""),
                                              ('DOWN', 'Down', ""),))
    
    @classmethod
    def poll(cls, context):
        """ No reason to try to reorder a list with fewer than
            two items in it.
        """
        return (context.active_object 
                and context.active_object.demo_list
                and len(context.active_object.demo_list) > 1)

    def move_index(self):
        """ Move index of an item while clamping it. """
        index = bpy.context.active_object.list_index
        list_length = len(bpy.context.active_object.demo_list) - 1
        new_index = index + (-1 if self.direction == 'UP' else 1)

        bpy.context.active_object.list_index = max(0, min(new_index, list_length))

    def execute(self, context):
        alist = context.object.demo_list
        index = context.object.list_index

        neighbor = index + (-1 if self.direction == 'UP' else 1)
        alist.move(neighbor, index)
        self.move_index()
        return {'FINISHED'}

#-----------------------------------------------------------------------------
#
class TOOL_PT_Defold_Properties(Panel):
    """ Tool panel to demonstrate UIList
    """
    bl_space_type = 'VIEW_3D'
    bl_region_type = 'UI'
    bl_category = "Defold"
    bl_idname = "TOOL_PT_Defold_Properties"
    bl_label = "Defold Properties"
    bl_description = "Defold properties can be added to any object"
    bl_options = {
        'HEADER_LAYOUT_EXPAND',
    }

    def draw(self, context):
        """ Draw a UI List and its controls using the same format used by
            various UI Lists in the user interface, such as Vertex Groups
            or Shape Keys in the Object Properties Tab of the Properties
            Editor.
        """

        # The list is attached to an object.  Each object can have its own
        # Unique list; so the logic of the panel is to use the list associated
        # with the active object.
        object = context.active_object
        layout = self.layout
        mytool = object.defold_props
        box = layout.box()

        # Since we're in the View3d UI it might be useful to remind the user
        # what object they're currently interacting with.
        row = box.row()
        row.alignment = "CENTER"
        row.label(text=object.name)

        row = box.row()
        row.prop(mytool, "group_children")

        row = box.row()
        row.prop(mytool, "apply_children")

        row = box.row()
        row.prop(mytool, "add_defold_cmd")

        # There are two rows.  The first row contains two columns.
        # The column on the left has the actual template_list.
        # The column on the right has the controls for editing
        # the list as a list.
        box = layout.box()
        row = box.row()
        row.alignment = "CENTER"

        if object:
            # The left column, containing the list.
            col = row.column(align=True)
            col.template_list("TOOL_UL_List", "The_List", object,
                              "demo_list", object, "list_index")

            # The right column, containing the controls.
            col = row.column(align=True)
            col.operator("tool.list_add", text="", icon="ADD")
            col.operator("tool.list_remove", text="", icon="REMOVE")

            # Only display the movement controls if the list is long enough
            # to justify movement
            if len(object.demo_list) > 1:
                col.operator("tool.list_reorder", text="",
                    icon="TRIA_UP").direction = "UP"
                col.operator("tool.list_reorder", text="",
                    icon="TRIA_DOWN").direction = "DOWN"


            row = box.row()
            if object.list_index >= 0 and object.demo_list:
                item = object.demo_list[object.list_index]

                if item.command == "Collider":
                    row = box.row()
                    row.prop(item, "command")

                if item.command == "Material Name":
                    row = box.row()
                    row.prop(item, "command")
                    row = box.row()
                    row.prop(item, "material_defold")

                if item.command == "Material Texture":
                    row = box.row()
                    row.prop(item, "command")
                    row = box.row()
                    row.prop(item, "material_texture")
                    row = box.row()
                    row.prop(item, "material_texture_defold")

                if item.command == "Set Key/Value":
                    row = box.row()
                    row.prop(item, "command")
                    row = box.row()
                    row.prop(item, "store_key")
                    row = box.row()
                    row.prop(item, "store_value")

                if item.command == "Init Script":
                    row = box.row()
                    row.prop(item, "command")
                    row = box.row()
                    row.prop(item, "command_init")

                if item.command == "Update Script":
                    row = box.row()
                    row.prop(item, "command")
                    row = box.row()
                    row.prop(item, "command_update")


#-----------------------------------------------------------------------------
#
classes = [
    DefoldProperties,
    ListItem,
    TOOL_UL_List,
    TOOL_OT_List_Add,
    TOOL_OT_List_Remove,
    TOOL_OT_List_Reorder,
    TOOL_PT_Defold_Properties,
]

def register():
    for c in classes:
        bpy.utils.register_class(c)

    bpy.types.Object.defold_props = PointerProperty(type=DefoldProperties)
    bpy.types.Object.demo_list = CollectionProperty(type = ListItem)
    bpy.types.Object.list_index = IntProperty(name = "Index for demo_list",
                                             default = 0)


def unregister():
    for c in classes:
        bpy.utils.unregister_class(c)
    del bpy.types.Object.demo_list
    del bpy.types.Object.list_index
    del bpy.types.Object.defold_props

    
    