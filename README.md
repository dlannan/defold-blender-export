# defold-blender-export
A blender import/export system for Defold

## Setup Notes
There are no exhaustive documents for this tool yet. Its just not complete, so everything is very much 'in flux'.
To use the tool follow the guide below.

1. Copy the blender/scripts python files to the blender plugins folder. See blender docs for this. 
2. Or.. you can copy the python scripts into the folder where your blender source file is, and the scripts should work from there.
3. Open the blender file you want to work in.
4. Open the text editor in blender and loadin in the script "defoldExportMeshes.py"
5. Run this file. You should see "bpy.ops.text.run_script()" in the Info Window in blender.
6. Open the 3D layout window in blender and ensure you are in "Object Mode". 
7. Press F3 and type "Defold". You shoul see the words "Start Defold Server" - press enter or select the command and it will run. 
8. You should see "bpy.ops.defold.serverstart()" in the Info Window in blender.

Blender is now setup and serving data streams. 
Now the Sync Tool needs to be run. 

Open and then run the Defold project in the defold/sync-tool folder.
You should be viewing the config tab for the sync-tool
1. Fill out the project path for where you want the Blender sync to write to. Make sure this is a Defold folder project path (where a project file exists).
2. Set the collection name you want to use.
3. Press the "Connect Localhost" button. 
4. Press the Active Streams tickboxes for Scene and Meshes

After doing the above, data will be getting sent from Blender to the SyncTool. You can check this is the case by looking at the Log (there should be entries in it) and examining the Blender Data tab panel where there should be Meshes and Objects that you can examine. 
If your Blender scene is empty, you may not see anything, so go and add a Cube! :)

Now select the Sync tickbox. Data will now be getting written into the folder you sepcified. 
Depending on the type of object you have in Blender, will depend on what data will exist the project folder. 

At a minimum you should see a collection file and some gameobjects (in the gameobjects folder). You can open this project and open the collection. 
While the "Sync" tickbox is enabled, data will be written to the collection file - do not save new objects into it while Sync is on - they will be overwritten. 
Sync can be unticked at any time and the data will stop pushing to the collection.

Once this is setup you can add/edit the blender scene as you need and any Sync's you do, will update the meshes, textures and object positions in Defold.

## Issues
There are a number of odd issues using this system. It is early days, so they will be ironed out. 
Some limitations on what Blender can stream:
- Only single texture for each object is used (this is a Defold thing).
- Object materials only use model materials at the moment. This might change to PBR materials.
- Lights and Camera are added in Defold, but they are not yet setup to operate correctly (TBD)
- Many features are only partially functional. Tread carefully :)

