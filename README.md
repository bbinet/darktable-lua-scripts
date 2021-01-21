# darktable-lua-scripts

My lua scripts for darktable

## Normalize Import

A simple plugin to normalize directory path of imported images.
When a new image is imported, the plugin immediately moves the new image to the
following normalized path:
```
<photos_path>/YYYY/mm/dd/HHMMSS<.ext>
```

### Installation

* copy the `normalize-import.lua` file in `$CONFIGDIR/lua/` where `$CONFIGDIR`
  is your darktable configuration directory
* add the following line in the file `$CONFIGDIR/luarc`: `require "normalize-import"`

### Usage

* set the `<photos_path>` directory for storing normalized imported photos in
  preferences => lua => Photos path
* import your images as you usually do
* they are automatically moved to the `<photos_path>` directory

### Licence

MIT
