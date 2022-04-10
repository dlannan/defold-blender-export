# defold-blender-export
A Blender export system for the Defold game engine.

## Setup Notes
Download the release.zip and install the addon from Blender preferences panel as described here:

https://docs.blender.org/manual/en/latest/editors/preferences/addons.html

![alt text](https://raw.githubusercontent.com/dlannan/defold-blender-export/main/images/sync-tool-2022-02-22_17-54.png)

Once installed you should see where it has been installed under the property: File.

Go to this path, the open the folder ```defoldync/luajit/<your platform>/```
- your platform would be one of linux, windows or OSX (darwin)

You will see a file called luajit - this is a very small lua interpreter. It needs to have permissions to generate files for the Defold projects.

To do this, usually right click on the file and give "execution" permissions. See appropriate OS docs to do this if you are having problems.

Thats it. If you select the tick box to enable it, you should see a new panel in the "View tabs list" on the right of the main layout screen.

You must be in Object Mode to view the panel.   

### OSX Install

You will need Homebrew installed on OSX to do the following. 

Installing Homebrew is simple and safe:

Source: https://brew.sh/

What to do. Run this in a Terminal: 
```/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"```

There are a couple of little "gotchas" that may make running on OSX fail during sync. 
1. As mentioned above, the execution persmission may be broken on OSX (I have recently checked in one with new persmissions). 
If you see this error:
```
Traceback (most recent call last):
  File "/Users/{USERNAME}/Library/Application Support/Blender/2.83/scripts/addons/sync_tool/__init__.py", line 313, in execute
    subprocess.check_output([luajit_cmd, dirpath, os.path.abspath(dir)])
  File "/Applications/Blender.app/Contents/Resources/2.83/python/lib/python3.7/subprocess.py", line 395, in check_output
    **kwargs).stdout
  File "/Applications/Blender.app/Contents/Resources/2.83/python/lib/python3.7/subprocess.py", line 472, in run
    with Popen(*popenargs, **kwargs) as process:
  File "/Applications/Blender.app/Contents/Resources/2.83/python/lib/python3.7/subprocess.py", line 775, in __init__
    restore_signals, start_new_session)
  File "/Applications/Blender.app/Contents/Resources/2.83/python/lib/python3.7/subprocess.py", line 1522, in _execute_child
    raise child_exception_type(errno_num, err_msg, err_filename)
PermissionError: [Errno 13] Permission denied: '/Users/{USERNAME}/Library/Application Support/Blender/2.83/scripts/addons/sync_tool/defoldsync/luajit/darwin/luajit'

location: <unknown location>:-1
```

It the permissions are incorrect then you need to open a terminal window and apply the following:

``` chmod +x /Users/{you user folder}/Library/Application\ Support/Blender/{Blender version number}/scripts/addons/sync_tool/defoldsync/luajit/darwin/luajit```

*Note:* Only do this, if you see an error relating to running luajit.

2. Libpng is needed for data conversion. You may need to install libpng. 

If you see this error in Blender when exporting (look at the Information window when installing)
```
Traceback (most recent call last):
  File "/Users/{USERNAME}/Library/Application Support/Blender/2.83/scripts/addons/sync_tool/__init__.py", line 313, in execute
    subprocess.check_output([luajit_cmd, dirpath, os.path.abspath(dir)])
  File "/Applications/Blender.app/Contents/Resources/2.83/python/lib/python3.7/subprocess.py", line 395, in check_output
    **kwargs).stdout
  File "/Applications/Blender.app/Contents/Resources/2.83/python/lib/python3.7/subprocess.py", line 487, in run
    output=stdout, stderr=stderr)
subprocess.CalledProcessError: Command '['/Users/{USERNAME}/Library/Application Support/Blender/2.83/scripts/addons/sync_tool/defoldsync/luajit/darwin/luajit', '/Users/{USERNAME}/Library/Application Support/Blender/2.83/scripts/addons/sync_tool/defoldsync/main.lua', '/Users/{USERNAME}/Library/Application Support/Blender/2.83/scripts/addons/sync_tool']' returned non-zero exit status 1.

location: <unknown location>:-1
```

To install libpng:

Open a Terminal window and type:

```brew install libpng```

*Note:* This needs an internet connection and Homebrew installed

If you have any problems please contact me on Discord: dlannan#1808

## Hardware Notes
Some issues have been experienced when using the PBR Material. At the moment this material is _very_ inefficient and needs alot of GFPU resources to work well. If you are running on a laptop with minimal GPU capabilities, you can export to Defold default model material and the model should be visible in Defold. With limited GPU's complex 3D scenes may not be visible with the Simple PBR material.

Sync Time can be longer when:
- There are many textures to convert from non-PNG texture types (just convert them before syncing to save time)
- Large geometries and hierarchies can take some time to sync - more data, more time.
- When Defold imports new files that have large images or meshes, this can take some time - because they are all text files. There are some ways around this, but this is not available in this version of Sync Tool. 

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

