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
use({
  'hirsaeki/winimectl.nvim',
  config = function()
    require('winimectl').setup()
  end
})
```

## Configuration

The plugin can be configured with the following options:

```lua
require('winimectl').setup({
  insert = {
    enable = true,    -- Enable/disable IME control for insert mode
    on_leave = {
      ime_off = true, -- Turn IME off when leaving insert mode
      set_mode = 0,   -- Set IME mode when leaving (0 = English in almost all IMEs)
    }
  },
  cmdline = {
    enable = true,    -- Enable/disable IME control for command-line mode
    on_leave = {
      ime_off = true, -- Turn IME off when leaving command-line mode
      set_mode = 0,   -- Set IME mode when leaving (0 = English in almost all IMEs
    }
  }
})
```

All options have sensible defaults, so you only need to configure what you want to change.

Example: Keep IME on in command-line mode

```lua
require('winimectl').setup({
  cmdline = {
    on_leave = {
      ime_off = false,  -- Don't turn IME off
    }
  }
})
```

Example: Disable IME control for insert mode

```lua
require('winimectl').setup({
  insert = {
    enable = false  -- Disable IME control for insert mode
  }
})
```

Note: The plugin automatically preserves and restores IME state when entering/leaving modes. This core functionality is not configurable.

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
