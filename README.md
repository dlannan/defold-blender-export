# defold-blender-export
A Blender export system for the Defold game engine.

## Setup Notes
There are no exhaustive documents for this tool yet. Its just not complete, so everything is very much 'in flux'.

Note: The Sync Tool is now a Blender Only addon. This makes building Defold resource collections much simpler. 

To use the tool follow the guide below.

1. Copy the blender/addons/sync_tool folder to the blender addons folder. See blender docs for this. 
2. Or.. you can copy the blender/addons/sync_tool/* files into the folder where your blender source file is, and the scripts should work from there.
3. Open the blender file you want to work in (or open the test.blend to see an example already setup)
4. Open the text editor in blender and loadin in the script "defoldSynUI.py"
5. Run this file. You should see "bpy.ops.text.run_script()" in the Info Window in blender.
6. Open the 3D layout window in blender and ensure you are in "Object Mode". 
7. Examine the Tools menu on the right side of the Layout 3D View (see below)
![alt text](https://raw.githubusercontent.com/dlannan/defold-blender-export/main/images/sync-tool-2021-12-29_15-22.png)
8. Enter the appropriate properties for Scene Name and Directory (project directory to save into).
9. Select "Sync Build" for the scene mode and press the "Sync Scene" button when ready.

A folder will be created in the target project directory with all the resources needed to load the scene into Defold. 

At a minimum you should see a collection file and some gameobjects (in the gameobjects folder). You can open this project and open the collection. 
While the "Sync" tickbox is enabled, data will be written to the collection file - do not save new objects into it while Sync is on - they will be overwritten. 
Sync can be unticked at any time and the data will stop pushing to the collection.

Once this is setup you can add/edit the blender scene as you need and any Sync's you do, will update the meshes, textures and object positions in Defold.

Todo: Add this module as a downloadable on the online community modules. Once the tool has stabilized I will do this.

## Example
I decided to add some improvements for large scene support. A sample Blender scene was used from here:

https://cloud.blender.org/p/gallery/5dd6d7044441651fa3decb56

I loaded into Blender. Here it is with Sync Tool open and setup. 
![alt text](https://raw.githubusercontent.com/dlannan/defold-blender-export/main/images/sync-tool-2021-12-30_22-19.png)

After pressing the 'Sync Scene' the resulting collection (after taking a while to load) was:
![alt text](https://raw.githubusercontent.com/dlannan/defold-blender-export/main/images/sync-tool-2021-12-30_22-20.png)

It is surprisingly decent, and is able to be edited within the editor ok. 
I will be adding more optimisations and support for more texture channels (only Base Color supported atm).

## Issues
There are a number of odd issues using this system. It is early days, so they will be ironed out. 
Some limitations on what Blender can stream:
- Only single texture for each object is used (this is a Defold thing).
- Object materials only use model materials at the moment. This might change to PBR materials.
- Lights and Camera are added in Defold, but they are not yet setup to operate correctly (TBD)
- Many features are only partially functional. Tread carefully :)

