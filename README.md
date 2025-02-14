# winimectl.nvim

A Neovim plugin for controlling Windows IME state using LuaJIT FFI.

## Features

- Automatically manages IME state when entering/leaving insert mode
- Preserves IME state between mode switches
- Uses Windows IME Control messages via LuaJIT FFI
- Configurable debug mode for troubleshooting
- Customizable IME modes for different input methods
- Robust window handle management

## Requirements

- Neovim
- Windows OS

## Installation

Using your preferred plugin manager:

### lazy.nvim

```lua
{
  "hirsaeki/winimectl.nvim",
  event = "VeryLazy",
  config = function()
    require("winimectl").setup()
  end,
}
```

### packer.nvim

```lua
use {
  'hirsaeki/winimectl.nvim',
  config = function()
    require('winimectl').setup()
  end
}
```

## Configuration

The plugin can be configured with the following options:

```lua
require('winimectl').setup({
  debug = false,  -- Enable debug messages
  ime_mode = {
    jp = 1025,   -- Japanese input mode (customize if needed)
    en = 0,      -- English input mode
  },
  retry = {
    count = 3,      -- Number of retries for IME operations
    interval = 100,  -- Retry interval in milliseconds
  },
})
```

## Debugging

For troubleshooting, you can use the following global functions:

- `:lua winimectl_get_mode()` - Get current IME mode
- `:lua winimectl_set_mode(mode)` - Set IME mode directly

When debug mode is enabled, the plugin will output detailed information about:

- Window handle acquisition
- IME mode changes
- Operation success/failure

## License

MIT

## Author

hsaeki
