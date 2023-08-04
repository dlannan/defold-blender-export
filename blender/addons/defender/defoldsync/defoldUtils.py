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

# ------------------------------------------------------------------------

def to_srgb(c):
    if c < 0.0031308:
        srgb = 0.0 if c < 0.0 else c * 12.92
    else:
        srgb = 1.055 * pow(c, 1.0 / 2.4) - 0.055

    return srgb

# ------------------------------------------------------------------------

def toHex(r, g, b, a):
    return "%02x%02x%02x%02x" % (
        round(r * 255),
        round(g * 255),
        round(b * 255),
        round(a * 255),
    )

# ------------------------------------------------------------------------
def dump_lua(data):
    if type(data) is str:
        return f'"{data}"'
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
        t += ", ".join([f"['{k}']={dump_lua(v)}"for k,v in data.items()])
        t += "}"
        return t
    logging.error(f"Unknown type {type(data)}")

# ------------------------------------------------------------------------
# Is an object animated

def isAnimated( obj ):
  # If the mesh has a verex group, then this needs to be saved as a separate animation
  if(len(obj.modifiers) > 0):
    modifier = obj.modifiers[0]
    if(obj.vertex_groups != None and modifier.type == 'ARMATURE'):
      print("[ ANIM OBJ ] " + obj.name)
      return True

  # If an object has animation data then it is likely animated.
  if(obj.parent != None):
    if(obj.parent.animation_data):
      anim = obj.parent.animation_data
      if anim is not None and anim.action is not None:
        return True
  return False

# ------------------------------------------------------------------------
# Add errors or warnings to the Errors Panel.

def ClearErrors( mytool ):
  mytool.sync_errors_str.clear()

# ------------------------------------------------------------------------
# Add errors or warnings to the Errors Panel.

def ErrorLine(mytool, message = "", title="", level=""):

  mytool.sync_errors_str.append( "[" + str(title) + "] " + str(message) )
  mytool.msgcount = len(mytool.sync_errors_str)

