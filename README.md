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
- Windows OS or WSL2

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

## WSL Support

This plugin also works in WSL (Windows Subsystem for Linux) environments. The platform is automatically detected at startup.

### How It Works

Since LuaJIT FFI cannot directly call Windows APIs from WSL, the plugin uses a helper executable (`ImeControl.exe`) to control the Windows IME. This executable is included with the plugin in the `wsl/` directory.

### Requirements

- WSL2 environment
- Windows IME enabled on the host system
- `ImeControl.exe` compiled and placed in the `wsl/` directory

### Building ImeControl.exe

If `ImeControl.exe` is not included or you need to rebuild it:

```bash
# From WSL or Windows, in the plugin directory
cd wsl
csc ImeControl.cs
```

### Troubleshooting

**ImeControl.exe not found:**
- Ensure `ImeControl.exe` exists in the `wsl/` directory of the plugin
- If missing, compile it from `wsl/ImeControl.cs` using `csc ImeControl.cs`

**IME control not working:**
- Verify that Windows IME is enabled and working on the host
- Make sure the terminal window has focus when testing
- Check that WSL can execute Windows executables (WSLInterop must be enabled)

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
