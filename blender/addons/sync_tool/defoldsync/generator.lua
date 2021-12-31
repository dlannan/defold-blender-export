-- A simple set of methods for generating various Defold data files.
------------------------------------------------------------------------------------------------------------

local ffi                   = require("ffi")
local json                  = require("defoldsync.json")

local PATH_SEPARATOR        = "/"
local CMD_COPY              = "cp"
local CMD_MKDIR             = "mkdir -p"
local platform              =  ffi.os

-- The system OS name: "Darwin", "Linux", "Windows", "HTML5", "Android" or "iPhone OS"
if platform == "Windows" then
    PATH_SEPARATOR  = "\\"
    CMD_COPY        = "copy"
    CMD_MKDIR       = "mkdir"
end

local WHITE_PNG     = "\x89\x50\x4E\x47\x0D\x0A\x1A\x0A\x00\x00\x00\x0D\x49\x48\x44\x52\x00\x00\x00\x10\x00\x00\x00\x10\x08\x02\x00\x00\x00\x90\x91\x68\x36\x00\x00\x02\xDE\x7A\x54\x58\x74\x52\x61\x77\x20\x70\x72\x6F\x66\x69\x6C\x65\x20\x74\x79\x70\x65\x20\x65\x78\x69\x66\x00\x00\x78\xDA\xED\x97\x5D\x72\xE5\x28\x0C\x85\xDF\x59\xC5\x2C\x01\x49\x08\x89\xE5\x60\x30\x55\xBD\x83\x59\xFE\x1C\x30\xD7\xC9\xBD\x49\x77\xD5\xF4\xF4\xC3\x3C\x5C\x13\xF3\x23\xCB\x07\xD0\x27\x93\x24\x9C\x7F\xFF\x18\xE1\x2F\x5C\x54\x24\x86\xA4\xE6\xB9\xE4\x1C\x71\xA5\x92\x0A\x57\x74\x3C\x5E\xD7\xD5\x52\x4C\xAB\xDE\x83\xF8\xE8\x3C\xD9\xC3\xFD\x80\x61\x12\xB4\x72\x0D\xF3\xB9\xFD\x2B\xEC\xFA\xF1\x82\xA5\x6D\x3F\x9E\xED\xC1\xDA\xD6\xF1\x2D\xF4\x50\xDE\x82\x32\x67\x66\x74\xB6\x9F\x6F\x21\xE1\xCB\x4E\x7B\x1C\xCA\x7E\xAF\xA6\x4F\xDB\xD9\xF7\x68\xBC\x1E\xEB\x71\x3D\x7A\x1D\x27\x43\x30\xBA\x42\x4F\x38\xF0\x29\x24\x11\xB5\xCF\x59\x64\xDE\x24\x15\x37\xA3\xC6\x78\x3A\x89\xA0\x1F\xA5\xAC\x9A\xBE\x8F\x5D\xB8\xBB\x2F\xC1\xBB\x7B\x2F\xB1\x8B\x75\xDB\xE5\x39\x14\x21\xE6\xED\x90\x5F\x62\xB4\xED\xA4\xDF\xC7\x6E\x45\xE8\x85\xDA\x63\xE6\xA7\x07\x26\xF7\x14\x5F\x63\x37\xBA\x8F\x71\x5E\xBB\xAB\x29\x23\x52\x39\xEC\x4D\x3D\xB6\xB2\x7A\x70\x44\x38\x93\xAC\xD7\x32\x8A\xE1\x56\xF4\x6D\x95\x82\xE2\xD8\x62\x03\xB1\x0E\x9A\x07\x4A\x0B\x54\x88\x11\xED\x41\x89\x3A\x55\x1A\x74\xAE\xB6\x51\xC3\x12\x13\x9F\x6C\x68\x99\x1B\x18\x4C\x9B\x8B\x71\xE1\x36\x83\x2E\x69\x16\x1A\x6C\xC0\xD0\x83\x38\xA8\x34\x50\x13\x98\xF9\x5E\x0B\xAD\x79\xCB\x9A\xAF\x91\x63\xE6\x4E\xF0\x64\x82\xD8\x24\xFA\xA5\x84\xEF\x8C\xBF\x53\x6E\xA1\x31\x66\xEA\x12\x45\xBF\x63\x85\x75\xF1\xCC\x69\x2C\x63\x92\x9B\x35\xBC\x00\x84\xC6\x8E\xA9\xAE\xF8\xAE\x12\x3E\xE5\x4D\xFC\x04\x56\x40\x50\x57\x98\x1D\x1B\xAC\xF1\xB8\x24\x0E\xA5\x8F\xDC\x92\xC5\x59\xE0\xA7\x31\x85\x78\x7D\x1A\x64\x7D\x0B\x20\x44\x98\x5B\xB1\x18\x12\x10\x88\x99\x44\x29\x53\x34\x66\x23\x42\x1C\x1D\x7C\x2A\x56\xCE\x92\xF8\x00\x01\x52\xE5\x4E\x61\x80\x8D\x48\x06\x1C\xE7\x39\x37\xDE\x31\x5A\xBE\xAC\x7C\x99\x71\xB4\x00\x84\x4A\x16\x03\x1A\x7C\x28\x80\x95\x92\x22\x7F\x2C\x39\x72\xA8\xAA\x68\x0A\xAA\x9A\xD5\xD4\xB5\x68\xCD\x92\x53\xD6\x9C\xB3\xE5\x79\x46\x55\x13\x4B\xA6\x96\xCD\xCC\xAD\x58\x75\xF1\xE4\xEA\xD9\xCD\xDD\x8B\xD7\xC2\x45\x70\x84\x69\xC9\xC5\x42\xF1\x52\x4A\xAD\x98\xB4\x42\xBA\xE2\xED\x0A\x8F\x5A\x0F\x3E\xE4\x48\x87\x1E\xF9\xB0\xC3\x8F\x72\xD4\x86\xF4\x69\xA9\x69\xCB\xCD\x9A\xB7\xD2\x6A\xE7\x2E\x1D\x9F\x7F\xCF\xDD\x42\xF7\x5E\x7A\x3D\xE9\x44\x2A\x9D\xE9\xD4\x33\x9F\x76\xFA\x59\xCE\x3A\x90\x6B\x43\x46\x1A\x3A\xF2\xB0\xE1\xA3\x8C\x7A\x53\xDB\x54\x9F\xA9\xD1\x0B\xB9\x5F\x53\xA3\x4D\x6D\x12\x4B\xCB\xCF\x3E\xA8\xC1\x6C\xF6\x90\xA0\x79\x9C\xE8\x64\x06\x62\x9C\x08\xC4\x6D\x12\x40\x42\xF3\x64\x16\x9D\x52\xE2\x49\x6E\x32\x8B\x65\x1E\x57\xCA\xA0\x46\x3A\xE1\x74\x9A\xC4\x40\x30\x9D\xC4\x3A\xE8\x66\xF7\x41\xEE\x97\xDC\x82\xA6\x7F\xC5\x8D\x7F\x46\x2E\x4C\x74\x7F\x82\x5C\x98\xE8\x36\xB9\xAF\xDC\xBE\xA1\xD6\xEB\xFA\x8D\x22\x0B\xD0\xFC\x0A\x67\x4C\xA3\x0C\x1C\x6C\x70\xAA\xEC\xF8\xC1\x79\xFC\xFB\x6D\xF8\xAF\x02\x6F\xA1\xB7\xD0\x5B\xE8\x2D\xF4\x16\x7A\x0B\xBD\x85\xFE\x37\x42\x32\xF0\xC7\x03\xFE\x77\x0C\xFF\x00\x42\xA5\x91\xC8\x8A\x21\x2A\xB7\x00\x00\x00\x09\x70\x48\x59\x73\x00\x00\x2E\x23\x00\x00\x2E\x23\x01\x78\xA5\x3F\x76\x00\x00\x00\x07\x74\x49\x4D\x45\x07\xE5\x0C\x14\x0C\x27\x01\x34\x0E\x76\xCF\x00\x00\x00\x1A\x49\x44\x41\x54\x28\xCF\x63\xFC\xFF\xFF\x3F\x03\x29\x80\x89\x81\x44\x30\xAA\x61\x54\xC3\xD0\xD1\x00\x00\x55\x6D\x03\x1D\x9F\x2E\x15\xA2\x00\x00\x00\x00\x49\x45\x4E\x44\xAE\x42\x60\x82"
local NORMAL_PNG    = "\x89\x50\x4E\x47\x0D\x0A\x1A\x0A\x00\x00\x00\x0D\x49\x48\x44\x52\x00\x00\x00\x08\x00\x00\x00\x08\x08\x02\x00\x00\x00\x4B\x6D\x29\xDC\x00\x00\x02\xE2\x7A\x54\x58\x74\x52\x61\x77\x20\x70\x72\x6F\x66\x69\x6C\x65\x20\x74\x79\x70\x65\x20\x65\x78\x69\x66\x00\x00\x78\xDA\xED\x96\x4D\x92\xDC\x20\x0C\x85\xF7\x9C\x22\x47\x40\x12\x42\xE2\x38\x18\x4C\x55\x6E\x90\xE3\xE7\x81\x99\xFE\x9B\x49\xAA\x92\xCA\x22\x8B\x36\x65\x03\xB2\x90\xE0\x7D\x98\xEE\x70\xFE\xF8\x3E\xC2\x37\x5C\x54\x24\x86\xA4\xE6\xB9\xE4\x1C\x71\xA5\x92\x0A\x57\x34\x3C\x5E\xD7\x55\x53\x4C\xEB\xF9\x68\x9B\xFD\x27\x7B\xB8\xBD\x60\x98\x04\xB5\x5C\xDD\x7C\x6E\xFF\x0A\xBB\xDE\x07\x58\xDA\xF6\xE3\xD9\x1E\xAC\xED\x38\xBE\x03\x7D\x64\xDE\x01\x65\x66\x66\x34\xB6\x9F\xEF\x40\xC2\x97\x9D\x76\x3F\x94\x3D\xAE\xA6\x87\xA9\xEF\x7B\x34\x5E\xAF\xF5\xB8\x5E\xBD\xF6\x93\x41\x8C\xAE\x88\x27\x1C\xF8\x14\x92\x88\xA7\xCF\x2C\x32\x6F\x92\x8A\x9B\xF1\x14\x21\x38\xC5\xD5\x66\xF4\x2A\xDA\xF6\xB5\x76\xE1\xD6\x7C\x11\xEF\xD6\x7A\xD1\x2E\xD6\x6D\x97\x67\x29\x42\xCC\xDB\x21\xBF\x68\xB4\xED\xA4\x5F\x6B\xB7\x14\x7A\x9C\x11\xDD\x33\x3F\xBD\x00\x9D\x1C\x1F\xAF\x47\xED\x46\xF7\x31\xCE\x6B\x75\x35\x65\x28\x95\xC3\x5E\xD4\xC7\x52\x56\x0B\x8E\x90\x33\xC9\x1A\x96\x51\x0C\xB7\xA2\x6D\xAB\x14\x14\xC7\x12\x1B\x88\x75\xD0\x3C\x50\x5A\xA0\x42\x0C\xB5\x07\x25\xEA\x54\x69\xD0\xB9\xEA\x46\x0D\x53\x4C\x7C\xB2\xA1\x66\x6E\x60\x30\x6D\x2E\xC6\x85\x1B\x44\x27\x49\xB3\xD0\x60\x93\x22\x3D\x88\x83\x47\x03\x35\x81\x99\x6F\x73\xA1\x95\xB7\xAC\x7C\x8D\x1C\x99\x3B\xC1\x93\x09\xC1\x26\xD1\x4F\x25\x7C\x65\xFC\x9B\x72\x0B\x34\xC6\xDC\xBA\x44\xD1\x6F\x5A\x61\x5E\x3C\xF7\x34\xA6\x31\xC9\xCD\x27\xBC\x00\x84\xC6\xD6\x54\x97\xBE\xAB\x84\x87\x7D\x13\x1F\xC0\x0A\x08\xEA\x92\xD9\xB1\xC0\x1A\x8F\x2B\xC4\xA1\x74\xDF\x5B\xB2\x38\x0B\xFC\x34\xA6\x10\xAF\x4F\x83\xAC\xEF\x00\x90\x08\xB9\x15\x93\x21\x01\x81\x98\x49\x94\x32\x45\x63\x36\x22\xE8\xE8\xE0\x53\x31\x73\x96\xC4\x07\x08\x90\x2A\x77\x0A\x03\x6C\x44\x32\xE0\x38\xCF\xDC\x18\x63\xB4\x7C\x59\xF9\x32\xE3\x68\x01\x08\x95\x2C\x06\x34\x45\x2A\x60\xA5\xA4\xD8\x3F\x96\x1C\x7B\xA8\xAA\x68\x0A\xAA\x9A\xD5\xD4\xB5\x68\xCD\x92\x53\xD6\x9C\xB3\xE5\x79\x46\x55\x13\x4B\xA6\x96\xCD\xCC\xAD\x58\x75\xF1\xE4\xEA\xD9\xCD\xDD\x8B\xD7\xC2\x45\x70\x84\x69\xC9\xC5\x42\xF1\x52\x4A\xAD\x48\x5A\x11\xBA\x62\x74\x85\x47\xAD\x07\x1F\x72\xA4\x43\x8F\x7C\xD8\xE1\x47\x39\x6A\xC3\xF6\x69\xA9\x69\xCB\xCD\x9A\xB7\xD2\x6A\xE7\x2E\x1D\x9F\x7F\xCF\xDD\x42\xF7\x5E\x7A\x3D\xE9\xC4\x56\x3A\xD3\xA9\x67\x3E\xED\xF4\xB3\x9C\x75\x60\xAF\x0D\x19\x69\xE8\xC8\xC3\x86\x8F\x32\xEA\x8D\xDA\xA6\xFA\x4C\x8D\x5E\xC8\xFD\x9E\x1A\x6D\x6A\x93\x58\x5A\x7E\x76\xA7\x06\xB3\xD9\x47\x08\x9A\xC7\x89\x4E\x66\x20\xC6\x89\x40\xDC\x26\x01\x6C\x68\x9E\xCC\xA2\x53\x4A\x3C\xC9\x4D\x66\xB1\xCC\x83\x4A\x19\xD4\x48\x27\x9C\x4E\x93\x18\x08\xA6\x93\x58\x07\xDD\xD8\xDD\xC9\xFD\x96\x5B\xD0\xF4\x47\xDC\xF8\x57\xE4\xC2\x44\xF7\x2F\xC8\x85\x89\x6E\x93\xFB\xCC\xED\x0B\x6A\xBD\xAE\x5F\x14\x59\x80\xE6\x57\x38\x35\x8D\x32\x70\xB0\x1D\x3D\x29\xE1\x77\xB2\xE3\xBC\xC1\x59\x35\xDB\xF3\x57\xE6\x0F\xEB\xF0\xB7\x03\xDF\x81\xDE\x81\xDE\x81\xDE\x81\xDE\x81\xDE\x81\xDE\x81\xFE\xC7\x40\x86\xBF\x0F\x25\xFC\x04\xCD\x85\x30\x6D\x2F\x67\x28\x35\x00\x00\x00\x09\x70\x48\x59\x73\x00\x00\x2E\x23\x00\x00\x2E\x23\x01\x78\xA5\x3F\x76\x00\x00\x00\x07\x74\x49\x4D\x45\x07\xE5\x0C\x1E\x0F\x35\x09\x2F\xDA\xD0\x13\x00\x00\x00\x15\x49\x44\x41\x54\x08\xD7\x63\x6C\x68\xF8\xCF\x80\x0D\x30\x31\xE0\x00\x83\x53\x02\x00\x91\xD2\x02\x0F\x6C\x48\xCB\xBA\x00\x00\x00\x00\x49\x45\x4E\x44\xAE\x42\x60\x82"
local GREY_PNG      = "\x89\x50\x4E\x47\x0D\x0A\x1A\x0A\x00\x00\x00\x0D\x49\x48\x44\x52\x00\x00\x00\x10\x00\x00\x00\x10\x08\x02\x00\x00\x00\x90\x91\x68\x36\x00\x00\x02\xD6\x7A\x54\x58\x74\x52\x61\x77\x20\x70\x72\x6F\x66\x69\x6C\x65\x20\x74\x79\x70\x65\x20\x65\x78\x69\x66\x00\x00\x78\xDA\xED\x97\x5D\xB2\xDB\x20\x0C\x85\xDF\x59\x45\x97\x80\x24\x84\xC4\x72\x30\x98\x99\xEE\xA0\xCB\xEF\xC1\x26\xCE\x4D\x6E\x7A\x67\xFA\xF3\xD4\x89\x89\x01\xCB\xB2\x80\xF3\x09\x27\x09\xFB\x8F\xEF\x23\x7C\xC3\x41\x85\x3D\x24\x35\xCF\x25\xE7\x88\x23\x95\x54\xB8\xA2\xE3\xF1\x3C\xCE\x96\x62\x3A\xEA\x75\x11\x6F\x9D\x07\x7B\xB8\x6E\x30\x4C\x82\x56\xCE\xCB\xBC\x2F\xFF\x0A\xBB\xDE\x1F\xB0\xB4\xEC\xDB\xA3\x3D\x58\x5B\x71\x7C\x05\xBA\x45\x5E\x01\x65\x8E\xCC\xE8\x2C\x3F\x5F\x81\x84\x4F\x3B\xAD\xEB\x50\xD6\x73\x35\x7D\x58\xCE\x3A\x47\xE3\xE3\xB6\x6E\xE7\xAD\xE7\xEB\x64\x10\xA3\x2B\xE2\x09\x07\xDE\x85\x24\xA2\xF6\x39\x8A\xCC\x93\xA4\xE2\x64\xD4\x22\x04\xA7\x28\x86\xBE\x4A\x42\x1D\x45\x5E\x6B\x17\xAE\xEE\x93\x78\x57\xEF\x49\xBB\x58\x97\x5D\x1E\xA5\x08\x31\x2F\x87\xFC\xA4\xD1\xB2\x93\xBE\xD6\xEE\x50\xE8\x89\xDA\x6D\xE4\x87\x1B\x46\xD7\x10\x9F\xB5\x1B\xDD\xC7\xD8\xCF\xD5\xD5\x94\xA1\x54\x0E\x6B\x51\xB7\xA5\x1C\x3D\x38\x42\xCE\x74\xAA\x91\x51\x0C\xA7\xA2\x6F\x47\x29\x28\x8E\x25\x36\x10\xEB\xA0\xB9\xA1\xB4\x40\x85\x18\x6A\x0F\x4A\xD4\xA9\xD2\xA0\xFD\x68\x1B\x35\x4C\x31\xF1\xCE\x86\x96\xB9\x81\xC1\xB4\xB9\x18\x17\x6E\x10\x9D\x20\x3E\x0A\x0D\x36\x29\xD2\x83\x38\xF8\x34\x50\x13\x98\xF9\x9A\x0B\x1D\xE3\x96\x63\xBC\x46\x8E\x91\x3B\xC1\x93\x09\xC1\x26\xD1\x4F\x25\xBC\x32\xFE\x49\xB9\x02\x8D\x31\x53\x97\x28\xFA\xA5\x15\xE6\xC5\x33\xA7\x31\x8D\x49\x6E\xD6\xF0\x02\x10\x1A\x4B\x53\x3D\xF4\x3D\x4A\xF8\x90\x37\xF1\x03\x58\x01\x41\x3D\x64\x76\x2C\xB0\xC6\xED\x0C\xB1\x29\xDD\x73\x4B\x0E\xCE\x02\x3F\x8D\x29\xC4\x73\x6B\x90\xF5\x15\x00\x12\x61\x6C\xC5\x64\x48\x40\x20\x66\x12\xA5\x4C\xD1\x98\x8D\x08\x3A\x3A\xF8\x54\xCC\x9C\x25\xF1\x06\x02\xA4\xCA\x9D\xC2\x00\x1B\x91\x0C\x38\xCE\x73\x6C\x3C\x63\x74\xF8\xB2\xF2\x69\xC6\xAB\x05\x20\x54\x32\xB6\x8A\x83\x50\x05\xAC\x94\x14\xF9\x63\xC9\x91\x43\x55\x45\x53\x50\xD5\xAC\xA6\xAE\x45\x6B\x96\x9C\xB2\xE6\x9C\x2D\xCF\x77\x54\x35\xB1\x64\x6A\xD9\xCC\xDC\x8A\x55\x17\x4F\xAE\x9E\xDD\xDC\xBD\x78\x2D\x5C\x04\xAF\x30\x2D\xB9\x58\x28\x5E\x4A\xA9\x15\x83\x56\x84\xAE\x78\xBA\xC2\xA3\xD6\x8D\x37\xD9\xD2\xA6\x5B\xDE\x6C\xF3\xAD\x6C\xB5\x21\x7D\x5A\x6A\xDA\x72\xB3\xE6\xAD\xB4\xDA\xB9\x4B\xC7\xF6\xEF\xB9\x5B\xE8\xDE\x4B\xAF\x3B\xED\x48\xA5\x3D\xED\xBA\xE7\xDD\x76\xDF\xCB\x5E\x07\x72\x6D\xC8\x48\x43\x47\x1E\x36\x7C\x94\x51\x2F\x6A\x8B\xEA\x23\x35\x7A\x22\xF7\x35\x35\x5A\xD4\x26\xB1\x74\xF8\xD9\x9D\x1A\xCC\x66\xB7\x10\x34\x5F\x27\x3A\x99\x81\x18\x27\x02\x71\x9B\x04\x90\xD0\x3C\x99\x45\xA7\x94\x78\x92\x9B\xCC\x62\x61\x6C\x0A\x65\x50\x23\x9D\x70\x3A\x4D\x62\x20\x98\x76\x62\x1D\x74\xB1\xBB\x93\xFB\x92\x5B\xD0\xF4\x5B\xDC\xF8\x57\xE4\xC2\x44\xF7\x2F\xC8\x85\x89\x6E\x91\xFB\xCC\xED\x05\xB5\x5E\x8F\x6F\x14\x39\x00\xCD\x5D\x38\x35\x8D\x32\xC2\xFC\x22\xAA\xF8\xFC\x6D\xFB\x0E\xF4\x0E\xF4\x0E\xF4\x0E\xF4\x0E\xF4\x0E\xF4\x0E\xF4\xBF\x04\xC2\x0F\x07\xFC\x6F\x0C\x3F\x01\xB3\x32\x90\x67\x21\x02\x2F\xBD\x00\x00\x00\x09\x70\x48\x59\x73\x00\x00\x2E\x23\x00\x00\x2E\x23\x01\x78\xA5\x3F\x76\x00\x00\x00\x07\x74\x49\x4D\x45\x07\xE5\x0C\x1E\x15\x18\x04\x60\xF0\xD0\xE7\x00\x00\x00\x19\x49\x44\x41\x54\x28\xCF\x63\x6C\x68\x68\x60\x20\x05\x30\x31\x90\x08\x46\x35\x8C\x6A\x18\x3A\x1A\x00\xC9\x4C\x01\xA0\x93\xF0\xA8\x32\x00\x00\x00\x00\x49\x45\x4E\x44\xAE\x42\x60\x82"
local BLACK_PNG     = "\x89\x50\x4E\x47\x0D\x0A\x1A\x0A\x00\x00\x00\x0D\x49\x48\x44\x52\x00\x00\x00\x10\x00\x00\x00\x10\x08\x02\x00\x00\x00\x90\x91\x68\x36\x00\x00\x02\xDE\x7A\x54\x58\x74\x52\x61\x77\x20\x70\x72\x6F\x66\x69\x6C\x65\x20\x74\x79\x70\x65\x20\x65\x78\x69\x66\x00\x00\x78\xDA\xED\x97\x41\x92\xE4\x28\x0C\x45\xF7\x9C\x62\x8E\x80\x24\x84\xC4\x71\x30\x98\x88\xBE\xC1\x1C\x7F\x3E\x98\x74\x55\x66\x55\x77\xC4\xF4\xF4\x62\x16\x69\xC2\x18\xCB\xE2\x03\x7A\x82\xAC\x0A\xE7\xDF\x3F\x46\xF8\x0B\x17\x15\x89\x21\xA9\x79\x2E\x39\x47\x5C\xA9\xA4\xC2\x15\x0D\x8F\xD7\x75\x3D\x29\xA6\x55\xEF\x97\xF8\x68\x3C\xD9\xC3\xFD\x81\x61\x12\x3C\xE5\x7A\xCD\xE7\xF6\xAF\xB0\xEB\x47\x07\x4B\xDB\x7E\x3C\xDB\x83\xB5\xAD\xE3\x5B\xE8\xA1\xBC\x05\x65\x8E\xCC\x68\x6C\x3F\xDF\x42\xC2\x97\x9D\xF6\x7B\x28\xBB\x5F\x4D\x9F\x96\xB3\xEF\xD1\x78\x7D\xD6\xE3\xFA\xF4\xFA\x9E\x0C\xC1\xE8\x0A\x3D\xE1\xC0\xA7\x90\x44\xD4\x3E\x47\x91\x79\x93\x54\xDC\x8C\x5A\x84\xE0\x14\xC5\x97\xA5\xA0\x56\xE1\xEF\x63\x17\xEE\xE6\x4B\xF0\xEE\xD6\x4B\xEC\x62\xDD\x76\x79\x0E\x45\x88\x79\x3B\xE4\x97\x18\x6D\x3B\xE9\xF7\xB1\x5B\x11\x7A\xA1\xF6\x18\xF9\xE9\x83\xC9\x3D\xC4\xD7\xD8\x8D\xEE\x63\x9C\xD7\xEA\x6A\xCA\x88\x54\x0E\x7B\x51\x8F\xA5\xAC\x16\x1C\x11\xCE\x24\xAB\x5B\x46\x31\xDC\x8A\xB6\xAD\x52\x50\x1C\x4B\x6C\x20\xD6\x41\xF3\x40\x69\x81\x0A\x31\xA2\x3D\x28\x51\xA7\x4A\x83\xCE\xF5\x6C\xD4\x30\xC5\xC4\x27\x1B\x9E\xCC\x0D\x0C\xA6\xCD\xC5\xB8\x70\x03\x00\x92\x34\x0B\x0D\x36\x60\xE8\x01\x44\x58\x1A\xA8\x09\xCC\x7C\xCF\x85\xD6\xB8\x65\x8D\xD7\xC8\x31\x72\x27\x78\x32\x41\x6C\x12\xFD\x52\xC2\x77\xC6\xDF\x29\xB7\xD0\x18\x33\x75\x89\xA2\xDF\xB1\xC2\xBC\x78\x66\x0D\xA6\x31\xC9\xCD\x1A\x5E\x00\x42\x63\xC7\x54\x57\x7C\x57\x09\x9F\xF2\x26\x7E\x02\x2B\x20\xA8\x2B\xCC\x8E\x05\xD6\x78\x5C\x12\x87\xD2\x47\x6E\xC9\xE2\x2C\xF0\xD3\x98\x42\xBC\xB6\x06\x59\xDF\x02\x08\x11\xC6\x56\x4C\x86\x04\x04\x62\x26\x51\xCA\x14\x8D\xD9\x88\x10\x47\x07\x9F\x8A\x99\xB3\x24\x3E\x40\x80\x54\xB9\x53\x18\x60\x23\x92\x01\xC7\x79\x8E\x8D\x3E\x46\xCB\x97\x95\x2F\x33\x8E\x16\x80\x50\xC9\x62\x40\x83\x8D\x02\x58\x29\x29\xF2\xC7\x92\x23\x87\xAA\x8A\xA6\xA0\xAA\x59\x4D\x5D\x8B\xD6\x2C\x39\x65\xCD\x39\x5B\x9E\x67\x54\x35\xB1\x64\x6A\xD9\xCC\xDC\x8A\x55\x17\x4F\xAE\x9E\xDD\xDC\xBD\x78\x2D\x5C\x04\x47\x98\x96\x5C\x2C\x14\x2F\xA5\xD4\x8A\x41\x2B\xA4\x2B\x7A\x57\x78\xD4\x7A\xF0\x21\x47\x3A\xF4\xC8\x87\x1D\x7E\x94\xA3\x36\xA4\x4F\x4B\x4D\x5B\x6E\xD6\xBC\x95\x56\x3B\x77\xE9\xD8\xFE\x3D\x77\x0B\xDD\x7B\xE9\xF5\xA4\x13\xA9\x74\xA6\x53\xCF\x7C\xDA\xE9\x67\x39\xEB\x40\xAE\x0D\x19\x69\xE8\xC8\xC3\x86\x8F\x32\xEA\x4D\x6D\x53\x7D\xA6\x46\x2F\xE4\x7E\x4D\x8D\x36\xB5\x49\x2C\x2D\x3F\xFB\xA0\x06\xB3\xD9\x43\x82\xE6\x71\xA2\x93\x19\x88\x71\x22\x10\xB7\x49\x00\x09\xCD\x93\x59\x74\x4A\x89\x27\xB9\xC9\x2C\x16\xC6\xA6\x50\x06\x35\xD2\x09\xA7\xD3\x24\x06\x82\xE9\x24\xD6\x41\x37\xBB\x0F\x72\xBF\xE4\x16\x34\xFD\x2B\x6E\xFC\x33\x72\x61\xA2\xFB\x13\xE4\xC2\x44\xB7\xC9\x7D\xE5\xF6\x0D\xB5\x5E\xD7\x2F\x8A\x2C\x40\x73\x17\xCE\x98\x46\x19\x38\xD8\xE0\x70\x7A\x65\xAF\xF3\x37\xE9\xB7\x9F\xE1\xBF\x0A\xBC\x85\xDE\x42\x6F\xA1\xB7\xD0\x5B\xE8\x2D\xF4\x16\xFA\xFF\x08\x0D\xFC\xF1\x80\xFF\x1D\xC3\x3F\xE9\xE5\x92\x06\xB2\xBC\x24\x27\x00\x00\x00\x09\x70\x48\x59\x73\x00\x00\x2E\x23\x00\x00\x2E\x23\x01\x78\xA5\x3F\x76\x00\x00\x00\x07\x74\x49\x4D\x45\x07\xE5\x0C\x1E\x15\x31\x36\xEC\x61\x1E\x8C\x00\x00\x00\x10\x49\x44\x41\x54\x28\xCF\x63\x60\x18\x05\xA3\x60\x14\xC0\x00\x00\x03\x10\x00\x01\x68\x91\x6D\xC3\x00\x00\x00\x00\x49\x45\x4E\x44\xAE\x42\x60\x82"

------------------------------------------------------------------------------------------------------------

local gendata = {}

gendata.folders = {
    base        = "",
    images      = "images",
    meshes      = "meshes",
    gos         = "gameobjects",
    materials   = "materials",
    animations  = "animations",
}

gendata.images = {
	white 	= "temp.png",
	black 	= "tempBlack.png",
	norm 	= "tempNormal.png",
}

gendata.files = {
	bufferfile 	= "temp.buffer",
	gofile 		= "temp.go",
	meshfile 	= "temp.mesh",
	scriptfile 	= "temp.script",

	shaderfile 	= "pbr-simple.material",
}

------------------------------------------------------------------------------------------------------------
-- Dataset for each file type (defaults)

local bufferfiledata = [[
[
{
    "name": "position",
    "type": "float32",
    "count": 3,
    "data": [
MESH_VERTEX_DATA
    ]
},
{
    "name": "normal",
    "type": "float32",
    "count": 3,
    "data": [
MESH_NORMAL_DATA
    ]
},
{
    "name": "texcoord0",
    "type": "float32",
    "count": 2,
    "data": [
MESH_UV_DATA
    ]
}
]
]]

------------------------------------------------------------------------------------------------------------

local gofiledata = [[
components {
    id: "MESH_GO_NAME"
    component: "MESH_FILE_PATH"
    position {
        x: 0.0
        y: 0.0
        z: 0.0
    }
    rotation {
        x: 0.0
        y: 0.0
        z: 0.0
        w: 1.0
    }
}
GO_FILE_SCRIPT
]]

local gofiledatascript = [[
components {
    id: "script"
    component: "SCRIPT_FILE_PATH"
    position {
        x: 0.0
        y: 0.0
        z: 0.0
    }
    rotation {
        x: 0.0
        y: 0.0
        z: 0.0
        w: 1.0
    }
}
]]

------------------------------------------------------------------------------------------------------------
local gpbrsimple_vp_lightdir_local = [[normalize(vLightModelPosition - p.xyz)]]
local gpbrsimple_vp_lightdir_global = [[vec3(0.0, 2.0, 3.0)]]

local gpbrsimple_vp = [[
// Positions can be world or local space, since world and normal
// matrices are identity for world vertex space materials.
// If world vertex space is selected, you can remove the
// normal matrix multiplication for optimal performance.

attribute highp vec4 position;
attribute mediump vec2 texcoord0;
attribute mediump vec3 normal;

uniform mediump mat4 mtx_worldview;
uniform mediump mat4 mtx_view;
uniform mediump mat4 mtx_proj;
uniform mediump mat4 mtx_normal;
uniform mediump vec4 light;

//uniform mediump vec4 camPos;

// Original work by Martia A Saunders
// https://dominium.maksw.com/articles/physically-based-rendering-pbr/pbr-part-one/

// attribute vec3 aVertexTangent;

varying vec3 vvLocalSurfaceNormal ;
varying vec3 vvLocalSurfaceToLightDirection;
varying vec3 vvLocalReflectedSurfaceToViewerDirection;
varying vec3 vvLocalSurfaceToViewerDirection;
varying vec2 vuvCoord0 ;

void main()
{
	vec4 p = mtx_worldview * vec4(position.xyz, 1.0);
	vec3 vViewModelPosition = normalize(mtx_view * vec4(0.0, 0.0, 1.0, 0.0)).xyz;
	vvLocalSurfaceToViewerDirection = normalize(vViewModelPosition - p.xyz) ;

	vec3 vLightModelPosition = vec3(mtx_view * vec4(light.xyz, 1.0));
	vvLocalSurfaceToLightDirection = MATERIAL_VP_LIGHTDIR;

	vvLocalSurfaceNormal = normalize((mtx_normal * vec4(normal, 0.0)).xyz);
	//	vvLocalSurfaceNormal = normalize(gl_Normal) ; // use the actual normal from the actual geometry

	vec3 vLocalSurfaceToViewerDirection = normalize(vViewModelPosition - position.xyz) ;
	vvLocalReflectedSurfaceToViewerDirection = normalize(reflect(vLocalSurfaceToViewerDirection, vvLocalSurfaceNormal)) ;

	vuvCoord0 = texcoord0 ;

	gl_Position = mtx_proj * p;
}
]]

------------------------------------------------------------------------------------------------------------

local gpbrsimple_fp = [[
// Original work by Martia A Saunders
// https://dominium.maksw.com/articles/physically-based-rendering-pbr/pbr-part-one/

// uniform samplerCube cubeMap ;
uniform sampler2D emissiveMap ;
uniform sampler2D metallicMap;
uniform sampler2D roughnessMap;
uniform sampler2D albedoMap ;
uniform sampler2D normalMap ;

uniform vec4 tint;
uniform vec4 params;

varying vec3 vvLocalSurfaceNormal ;
varying vec3 vvLocalSurfaceToLightDirection;
varying vec3 vvLocalReflectedSurfaceToViewerDirection;
varying vec2 vuvCoord0 ;
varying vec3 vvLocalSurfaceToViewerDirection;

const float cpi = 3.14159265358979323846264338327950288419716939937510f ;

float computeFresnelTerm(float fZero, vec3 vSurfaceToViewerDirection, vec3 vSurfaceNormal)
{
	float baseValue = 1.0 - dot(vSurfaceToViewerDirection, vSurfaceNormal);
	float exponential = pow(baseValue, 5.0) ;
	float fresnel = exponential + fZero * (1.0 - exponential) ;

	return fresnel ;
}

float chiGGX(float f)
{
	return f > 0.0 ? 1.0 : 0.0 ;
}

// APPROVED! Works as expected
float computeGGXDistribution(vec3 vSurfaceNormal, vec3 vSurfaceToLightDirection, float fRoughness)
{
	float fNormalDotLight = clamp(dot(vSurfaceNormal, vSurfaceToLightDirection), 0.0, 1.0) ;
	float fNormalDotLightSquared = fNormalDotLight * fNormalDotLight ;
	float fRoughnessSquared = fRoughness * fRoughness ;
	float fDen = fNormalDotLightSquared * fRoughnessSquared + (1.0 - fNormalDotLightSquared);

	return clamp((chiGGX(fNormalDotLight) * fRoughnessSquared) / (cpi * fDen * fDen), 0.0, 1.0);
}

float computeGGXPartialGeometryTerm(vec3 vSurfaceToViewerDirection, vec3 vSurfaceNormal, vec3 vLightViewHalfVector, float fRoughness)
{
	float fViewerDotLightViewHalf = clamp(dot(vSurfaceToViewerDirection, vLightViewHalfVector), 0.0, 1.0) ;
	float fChi = chiGGX(fViewerDotLightViewHalf / clamp(dot(vSurfaceToViewerDirection, vSurfaceNormal), 0.0, 1.0));
	fViewerDotLightViewHalf *= fViewerDotLightViewHalf;
	float fTan2 = (1.0 - fViewerDotLightViewHalf) / fViewerDotLightViewHalf;

	return (fChi * 2.0) / (1.0 + sqrt(1.0 + fRoughness * fRoughness * fTan2)) ;
}

void main()
{
	vec3 mappedNormal = normalize(texture(normalMap, vuvCoord0).rgb * 2.0 - vec3(1.0));  
	vec3 vNormalisedLocalSurfaceNormal = normalize(vvLocalSurfaceNormal + mappedNormal * 0.4) ;

	vec3 vNormalisedLocalSurfaceToLightDirection = normalize(vvLocalSurfaceToLightDirection) ;
	vec3 vNormalisedLocalReflectedSurfaceToViewerDirection = normalize(vvLocalReflectedSurfaceToViewerDirection) ;
	vec3 vNormalisedLocalSurfaceToViewerDirection = normalize(vvLocalSurfaceToViewerDirection) ;

	vec3 vLocalLightViewHalfVector = normalize(vNormalisedLocalSurfaceToLightDirection + vNormalisedLocalSurfaceToViewerDirection) ;

	float fLightIntensity = max(dot(vNormalisedLocalSurfaceToLightDirection, vNormalisedLocalSurfaceNormal), 0.0) ;

	float fMetalness = texture(metallicMap, vuvCoord0).r ;
	float fRoughness = max(0.001, texture(roughnessMap, vuvCoord0).r ) ;

	float distributionMicroFacet = computeGGXDistribution(vNormalisedLocalSurfaceNormal, vNormalisedLocalSurfaceToLightDirection, fRoughness) ;
	float geometryMicroFacet = computeGGXPartialGeometryTerm(vNormalisedLocalSurfaceToViewerDirection, vNormalisedLocalSurfaceNormal, vLocalLightViewHalfVector, fRoughness) ;
	float microFacetContribution = distributionMicroFacet * geometryMicroFacet ;

	float fLightSourceFresnelTerm = computeFresnelTerm(0.5, vNormalisedLocalSurfaceToViewerDirection, vNormalisedLocalSurfaceNormal) ;

	vec3 rgbAlbedo = texture(albedoMap, vuvCoord0).rgb;
	vec3 rgbEmissive = texture(emissiveMap, vuvCoord0).rgb;

	vec3 rgbFragment = rgbAlbedo * (1.0 - fMetalness);

	//	vec3 rgbSourceReflection = textureCubeLod(cubeMap, vNormalisedLocalReflectedSurfaceToViewerDirection, 9.0 * fRoughness).rgb ;
	vec3 rgbSourceReflection = vec3(0.5);
	vec3 rgbReflection = rgbSourceReflection ;
	rgbReflection *= rgbAlbedo * fMetalness ;
	rgbReflection *= fLightSourceFresnelTerm ;
	rgbReflection = min(rgbReflection, rgbSourceReflection) ; // conservation of energy

	vec3 rgbSpecular = vec3(0.0) ;
	if (fLightIntensity > 0.0)
	{
		rgbSpecular = vec3(1.0) ;
		rgbSpecular *= microFacetContribution * fLightSourceFresnelTerm ;
		rgbSpecular = min(vec3(1.0), rgbSpecular) ; // conservation of energy
	}

	float ambientLevel = fLightIntensity * (1.0 - params.x) + params.x;
	rgbFragment += rgbSpecular; // * tint.xyz;
	rgbFragment *= ambientLevel;
	rgbFragment += rgbReflection ;
	rgbFragment += rgbEmissive ;

	gl_FragColor.rgb = rgbFragment;
	gl_FragColor.a = 1.0 ; // TODO : Worry about materials which allow transparency!
}
]]

------------------------------------------------------------------------------------------------------------

local gpbrsimplematerial = [[
name: "pbr-simple"
tags: "model"
vertex_program: "MATERIAL_VP"
fragment_program: "MATERIAL_FP"
vertex_space: VERTEX_SPACE_LOCAL
vertex_constants {
  name: "mtx_world"
  type: CONSTANT_TYPE_WORLD
  value {
    x: 0.0
    y: 0.0
    z: 0.0
    w: 0.0
  }
}
vertex_constants {
  name: "mtx_view"
  type: CONSTANT_TYPE_VIEW
  value {
    x: 0.0
    y: 0.0
    z: 0.0
    w: 0.0
  }
}
vertex_constants {
  name: "mtx_proj"
  type: CONSTANT_TYPE_PROJECTION
  value {
    x: 0.0
    y: 0.0
    z: 0.0
    w: 0.0
  }
}
vertex_constants {
  name: "mtx_normal"
  type: CONSTANT_TYPE_NORMAL
  value {
    x: 0.0
    y: 0.0
    z: 0.0
    w: 0.0
  }
}
vertex_constants {
  name: "light"
  type: CONSTANT_TYPE_USER
  value {
    x: 1.0
    y: 1.0
    z: 1.0
    w: 1.0
  }
}
vertex_constants {
  name: "mtx_worldview"
  type: CONSTANT_TYPE_WORLDVIEW
  value {
    x: 0.0
    y: 0.0
    z: 0.0
    w: 0.0
  }
}
fragment_constants {
  name: "tint"
  type: CONSTANT_TYPE_USER
  value {
    x: 1.0
    y: 1.0
    z: 1.0
    w: 1.0
  }
}
fragment_constants {
  name: "params"
  type: CONSTANT_TYPE_USER
  value {
    x: 0.5
    y: 0.0
    z: 0.0
    w: 0.0
  }
}
samplers {
  name: "albedoMap"
  wrap_u: WRAP_MODE_REPEAT
  wrap_v: WRAP_MODE_REPEAT
  filter_min: FILTER_MODE_MIN_NEAREST
  filter_mag: FILTER_MODE_MAG_NEAREST
}
samplers {
  name: "metallicMap"
  wrap_u: WRAP_MODE_REPEAT
  wrap_v: WRAP_MODE_REPEAT
  filter_min: FILTER_MODE_MIN_NEAREST
  filter_mag: FILTER_MODE_MAG_NEAREST
}
samplers {
    name: "roughnessMap"
    wrap_u: WRAP_MODE_REPEAT
    wrap_v: WRAP_MODE_REPEAT
    filter_min: FILTER_MODE_MIN_NEAREST
    filter_mag: FILTER_MODE_MAG_NEAREST
  }
samplers {
  name: "emissiveMap"
  wrap_u: WRAP_MODE_REPEAT
  wrap_v: WRAP_MODE_REPEAT
  filter_min: FILTER_MODE_MIN_NEAREST
  filter_mag: FILTER_MODE_MAG_NEAREST
}
samplers {
  name: "normalMap"
  wrap_u: WRAP_MODE_REPEAT
  wrap_v: WRAP_MODE_REPEAT
  filter_min: FILTER_MODE_MIN_NEAREST
  filter_mag: FILTER_MODE_MAG_NEAREST
}
]]

------------------------------------------------------------------------------------------------------------

local meshfiledata = [[
material: "MATERIAL_FILE_PATH"
vertices: "BUFFER_FILE_PATH"
MESH_TEXTURE_FILES
primitive_type: PRIMITIVE_TRIANGLES
position_stream: "position"
normal_stream: "normal"
]]

------------------------------------------------------------------------------------------------------------

local scriptfiledataupdate = [[
function update(self, dt)
end
]]

local scriptfiledatamsg = [[
function on_message(self, message_id, message, sender)
end
]]

local scriptfiledatainput = [[
function on_input(self, action_id, action)
end
]]

local scriptfiledata = [[
function init(self)
end

function final(self)
end

UPDATE_FUNC

MESSAGE_FUNC

INPUT_FUNC 

function on_reload(self)
end
]]

------------------------------------------------------------------------------------------------------------

local gcollectionroot = [[
embedded_instances {
    id: "root"
ROOT_CHILDREN
    data: ""
    position {
        x: 0.0
        y: 0.0
        z: 0.0
    }
    rotation {
        x: -0.70710677
        y: 0.0
        z: 0.0
        w: 0.70710677
    }
    scale3 {
        x: 1.0
        y: 1.0
        z: 1.0
    }
}
]]

local gocollectionheader = [[
name: "COLLECTION_NAME"
scale_along_z: 0
]]

local gocollectiondata = [[
instances {
    id: "GO_NAME"
    prototype: "GO_FILE_PATH"
GO_CHILDREN
    position {
        GO_POSITION
    }
    rotation {
        GO_ROTATION_QUATERNION
    }
    scale3 {
        GO_SCALE
    }
}
]]

local gocollectiongeneric = [[
embedded_instances {
    id: "GO_NAME"
    data: ""
    GO_CHILDREN
    position {
        GO_POSITION
    }
    rotation {
        GO_ROTATION_QUATERNION
    }
    scale3 {
        GO_SCALE
    }
}
]]

local gcollectioncamera = [[
embedded_instances {
    id: "GO_NAME"
    data: "embedded_components {\n"
    "  id: \"camera\"\n"
    "  type: \"camera\"\n"
    "  data: \"aspect_ratio: 1.0\\n"
    "fov: 0.7854\\n"
    "near_z: 0.1\\n"
    "far_z: 1000.0\\n"
    "auto_aspect_ratio: 0\\n"
    "\"\n"
    "  position {\n"
    "    x: 0.0\n"
    "    y: 0.0\n"
    "    z: 0.0\n"
    "  }\n"
    "  rotation {\n"
    "    x: 0.0\n"
    "    y: 0.0\n"
    "    z: 0.0\n"
    "    w: 1.0\n"
    "  }\n"
    "}\n"
    GO_CHILDREN
    position {
        GO_POSITION
    }
    rotation {
        GO_ROTATION_QUATERNION
    }
    scale3 {
        GO_SCALE
    }
}
]]

------------------------------------------------------------------------------------------------------------

local function localpathname( path )

    -- Subtract project path from pathname     
    local newpath = string.match(path, gendata.base.."(.*)")
    -- Local path should always use / 
    if(newpath) then newpath = string.gsub(newpath, "\\", "/") end
    return newpath or path 
end

------------------------------------------------------------------------------------------------------------

local function makefile( fpath, fdata )

    local fh = io.open(fpath, "w")
    fh:write(fdata)
    fh:close()
end

------------------------------------------------------------------------------------------------------------

local function makefilebinary( fpath, fdata )

    local fh = io.open(fpath, "wb")
    fh:write(fdata)
    fh:close()
end

------------------------------------------------------------------------------------------------------------

local function makefolders( collectionname, base )

    assert(collectionname ~= nil, "Invalid collectionname")
    assert(base ~= nil, "Invalid Base path string.")

    gendata.base = base

    -- Make the base path
    os.execute(CMD_MKDIR.." "..base..PATH_SEPARATOR..collectionname)
    -- Make the folders that files will be generated in 
    for k,v in pairs(gendata.folders) do 
        os.execute(CMD_MKDIR.." "..base..PATH_SEPARATOR..collectionname..PATH_SEPARATOR..v)
    end
end

------------------------------------------------------------------------------------------------------------

local function makebufferfile(name, filepath, mesh )

    local bufferdata = bufferfiledata
    local bufferfilepath = filepath..gendata.folders.meshes..PATH_SEPARATOR..name..".buffer"
    --print(bufferfilepath)
    --pprint(name, gendata.meshes[name] )
    if(mesh == nil) then return "" end

    local verts = mesh.vertices 
    local vertdata = {}
    local uvdata = {}
    local normdata = {}
    for k,v in pairs(mesh.tris) do 
        for i,t in pairs(v.tri) do 
            local vert = verts[t.vertex + 1]
            table.insert(vertdata, vert.x)
            table.insert(vertdata, vert.y)
            table.insert(vertdata, vert.z)
            table.insert(uvdata, t.uv.x)
            table.insert(uvdata, t.uv.y)
            table.insert(normdata, v.normal.x)
            table.insert(normdata, v.normal.y)
            table.insert(normdata, v.normal.z)
        end
    end
    
    bufferdata = string.gsub(bufferdata, "MESH_VERTEX_DATA", table.concat(vertdata, ","))
    bufferdata = string.gsub(bufferdata, "MESH_NORMAL_DATA", table.concat(normdata, ","))
    bufferdata = string.gsub(bufferdata, "MESH_UV_DATA", table.concat(uvdata, ","))
    
    makefile( bufferfilepath, bufferdata )
    return bufferfilepath
end

------------------------------------------------------------------------------------------------------------

local function processtexturefile( filepath, mesh, source, default )

    local texfile = filepath..gendata.folders.materials..PATH_SEPARATOR..default
    local outputfile = localpathname(gendata.project_path..PATH_SEPARATOR..gendata.folders.materials.."/"..default)
    if(mesh.textures[source]) then 
        texfile = string.match(mesh.textures[source], "([^"..PATH_SEPARATOR.."]+)$")
        -- copy to local folder first 
        local targetfile = filepath..gendata.folders.images..PATH_SEPARATOR..texfile
        os.execute(CMD_COPY..' "'..mesh.textures[source]..'" "'..targetfile..'"')
        outputfile = localpathname(filepath)..gendata.folders.images.."/"..texfile
    end
    return outputfile
end 

------------------------------------------------------------------------------------------------------------

local function maketexturefile( filepath, mesh )

    local texturefiles = {}
    if(mesh.textures) then 
        table.insert( texturefiles, processtexturefile(filepath, mesh, 'base_color', 'white.png') )
        table.insert( texturefiles, processtexturefile(filepath, mesh, 'metallic_color', 'black.png') )
        table.insert( texturefiles, processtexturefile(filepath, mesh, 'roughness_color', 'grey.png') )
        table.insert( texturefiles, processtexturefile(filepath, mesh, 'emissive_color', 'black.png') )
        table.insert( texturefiles, processtexturefile(filepath, mesh, 'normal_map', 'normal.png') )
    end 
    return texturefiles
end 

------------------------------------------------------------------------------------------------------------

local function makemeshfile(name, filepath, mesh )

    if(mesh == nil) then return "" end 
    
    local meshdata = meshfiledata
    local meshfilepath = filepath..gendata.folders.meshes..PATH_SEPARATOR..name..".mesh"

    local materialfile = localpathname(filepath)..gendata.folders.materials.."/pbr-simple.material"
    meshdata = string.gsub(meshdata, "MATERIAL_FILE_PATH", materialfile)

    -- If a texture file is found, copy it, then assign it
    local alltextures = maketexturefile( filepath, mesh )
    local texture_file_list = ""
    for k,v in pairs(alltextures) do 
        texture_file_list = texture_file_list..'textures: "'..v..'"\n'
    end
    meshdata = string.gsub(meshdata, "MESH_TEXTURE_FILES", texture_file_list)

    local bufferfilepath = makebufferfile( name, filepath, mesh )
    meshdata = string.gsub(meshdata, "BUFFER_FILE_PATH", localpathname(bufferfilepath))
    makefile( meshfilepath, meshdata )
    return meshfilepath
end

------------------------------------------------------------------------------------------------------------

local function makegofile( name, filepath, go )

    local godata = gofiledata
    local gofilepath = filepath..gendata.folders.gos..PATH_SEPARATOR..name..".go"

    godata = string.gsub(godata, "MESH_GO_NAME", go.name.."_mesh")

    if(go.type == "MESH") then 

        local meshfilepath = ""
        local meshpath = string.gsub( gendata.meshes[name], "\\", "\\\\" )
        local fh = io.open( meshpath, "rb" )
        if(fh) then
            local fdata = fh:read("*all")
            fh:close()
            local mesh = json.decode( fdata ) 
            meshfilepath = localpathname(makemeshfile(name, filepath, mesh))
        end

        godata = string.gsub(godata, "MESH_FILE_PATH", meshfilepath)
    end 

    godata = string.gsub(godata, "GO_FILE_SCRIPT", "")
    makefile( gofilepath, godata )
    return gofilepath
end

------------------------------------------------------------------------------------------------------------
-- Process children (take parents and work out their children)

local function processChildren(objs)

    local objects = {}
    -- Add to object list 
    for k,v in pairs(objs) do 
        if k then 
            objects[k] = v 
        end 
    end
    -- Regen children using parent information 
    for k,v in pairs(objects) do 
        if(v.parent and v.parent.name) then 
            local parent = objects[v.parent.name]
            if(parent) then
                parent.children = parent.children or {} 
                table.insert(parent.children, v.name)
            end
        end 
    end
    return objects
end

------------------------------------------------------------------------------------------------------------

local function makecollection( collectionname, objects, meshes )

    if(objects == nil) then return end 

    objects = processChildren(objects)
    gendata.meshes = meshes
    
    local project_path = gendata.base..PATH_SEPARATOR..collectionname
    gendata.project_path = project_path
    local colldata = gocollectionheader

    -- Make the default pbr material, and shaders
    local material_path = project_path..PATH_SEPARATOR..gendata.folders.materials..PATH_SEPARATOR
    local material_vp_path = material_path.."pbr-simple.vp"
    local material_fp_path = material_path.."pbr-simple.fp"
    local matstr = gpbrsimplematerial:gsub("MATERIAL_VP", localpathname(material_vp_path))
    matstr = matstr:gsub("MATERIAL_FP", localpathname(material_fp_path))
    makefile( material_path.."pbr-simple.material", matstr)

    gpbrsimple_vp = gpbrsimple_vp:gsub("MATERIAL_VP_LIGHTDIR", gpbrsimple_vp_lightdir_global)
    makefile( material_vp_path, gpbrsimple_vp )
    makefile( material_fp_path, gpbrsimple_fp )
    makefilebinary( material_path.."white.png", WHITE_PNG )
    makefilebinary( material_path.."normal.png", NORMAL_PNG )
    makefilebinary( material_path.."grey.png", GREY_PNG )
    makefilebinary( material_path.."black.png", BLACK_PNG )

    -- Objects need to be in flat table - straight from blender.

    local rootchildren = ""
    for k,v in pairs(objects) do 

        local name = v.name or ("Dummy"..k)
        local objdata = gocollectiongeneric
        if(v.type == "MESH") then 
            objdata = gocollectiondata

            local gofilepath = makegofile( name, project_path..PATH_SEPARATOR, v )
            objdata = string.gsub(objdata, "GO_FILE_PATH", localpathname(gofilepath))

        elseif(v.type == "CAMERA") then 
            objdata = gcollectioncamera
        elseif(v.type == "LIGHT") then 
            objdata = gocollectiongeneric
        end 
        
        objdata = string.gsub(objdata, "GO_NAME", name)

        -- Check if this object is a root level obj.
        if( v.parent == nil) then 
            rootchildren = rootchildren.."\tchildren: \""..name.."\"\n"
        end
                
        local children = ""
        if(v.children) then 
            for k,v in pairs(v.children) do
                children = "    children: \""..v.."\"\n"
            end
        end
        objdata = string.gsub(objdata, "GO_CHILDREN", children)

        local position = "x:0.0\n\ty:0.0\n\tz:0.0"
        if(v.location) then 
            position = "x:"..v.location.x.."\n\ty:"..v.location.y.."\n\tz:"..v.location.z
        end 
        objdata = string.gsub(objdata, "GO_POSITION", position)

        local rotation = "x:0.0\n\ty:0.0\n\tz:0.0\n\tw:1.0"
        if(v.rotation) then 
            rotation = "x:"..v.rotation.quat.x.."\n\ty:"..v.rotation.quat.y
            rotation = rotation.."\n\tz:"..v.rotation.quat.z.."\n\tw:"..v.rotation.quat.w
        end 
        objdata = string.gsub(objdata, "GO_ROTATION_QUATERNION", rotation)

        local scaling = "x:1.0\n\ty:1.0\n\tz:1.0"
        if(v.scaling) then 
            scaling = "x:"..v.scaling.x.."\n\ty:"..v.scaling.y.."\n\tz:"..v.scaling.z
        end 
        objdata = string.gsub(objdata, "GO_SCALE", scaling)

        colldata = colldata.."\n"..objdata
    end 

    -- Add the root instance 
    gcollectionroot = string.gsub(gcollectionroot, "ROOT_CHILDREN", rootchildren)
    colldata = colldata.."\n"..gcollectionroot
    
    -- Write the file
    makefile( project_path..PATH_SEPARATOR..collectionname..".collection", colldata )
end

------------------------------------------------------------------------------------------------------------

gendata.makefile        = makefile
gendata.makefolders     = makefolders
gendata.makecollection  = makecollection

return gendata
