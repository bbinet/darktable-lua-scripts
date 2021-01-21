--[[
Normalize Import

A simple plugin to normalize directory path of imported images.
When a new image is imported, the plugin immediately moves the new image to the
following normalized directory path:
<photos_path>/YYYY/mm/dd/HHMMSS<.ext>

AUTHOR
Bruno Binet <binet.bruno@gmail.com>

INSTALLATION
* install lua lfs dependency: sudo apt install lua-filesystem
* copy this file in `$CONFIGDIR/lua/` where `$CONFIGDIR` is your darktable
configuration directory
* add the following line in the file `$CONFIGDIR/luarc`: `require "normalize-import"`

USAGE
* set the `<photos_path>` directory for storing normalized imported photos in
preferences => lua => Photos path
* import your images as you usually do
* they are automatically moved to the `<photos_path>` directory

LICENSE
MIT

]]

local dt = require "darktable"
local lfs = require "lfs"

print ("****** Lua - script load: normalize-import.lua *****")


function pathchunks(name)
    local chunks = {}
    for w in string.gmatch(name, "[^/\\]+") do
       table.insert(chunks, 1, w)
    end
    return chunks
end

function mkdir_p(path)
    local chunks = pathchunks(path)
    local originalpath = lfs.currentdir()
    lfs.chdir("/")
    for i=#chunks, 1, -1 do
        local c = chunks[i]
        local exists = lfs.attributes(c) ~= nil
        if(not exists) then
            lfs.mkdir(c)
        end
        lfs.chdir(c)
    end
    lfs.chdir(originalpath)
    return path
end


local function move_image(event, image)
    local photos_path = dt.preferences.read("normalize-import", "photos_path", "directory")
    local Y, m, d, H, M, S = string.match(
      image.exif_datetime_taken, "(%d+):(%d+):(%d+) (%d+):(%d+):(%d+)")
    local old_path = tostring(image)
    local ext = string.match(image.filename, "^.+(%..+)$")
    local dir_path = table.concat({photos_path, Y, m, d,}, '/')
    mkdir_p(dir_path)
    local new_film = dt.films.new(dir_path)
    --local old_film = image.film
    local new_name, new_path, idx = nil, nil, 0
    repeat
        if idx > 0 then
            new_name = table.concat({H, M, S, '_', tostring(idx), ext}, '')
        else
            new_name = table.concat({H, M, S, ext}, '')
        end
        new_path = table.concat({dir_path, new_name}, '/')
        idx = idx + 1
        --print(">>> new_path=" .. new_path)
    until lfs.attributes(new_path) == nil

    image.move(new_film, image, new_name)
    print(">>> move_image: " .. old_path .. ' ==> ' .. tostring(image))

    if (lfs.attributes(new_path) == nil) then
        print(">>> move_image has failed: image.delete(" .. tostring(image) ..")")
        image.delete(image)
    end

    -- old_film.delete(old_film)
    -- ^ do not delete old_film or the import will fail for the next images of
    -- the same old_film
    -- We may consider purging empty films on post-import-film event ?
end

dt.preferences.register("normalize-import", "photos_path",
  "directory", "Base path of the photos collection",
  "Photos will automatically be imported in this directory",
  "~/Photos")
dt.register_event("post-import-image", move_image)
