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

Since LuaJIT FFI cannot directly call Windows APIs from WSL, the plugin uses a helper executable (`ImeControl.exe`) to control the Windows IME.

### Setup

**Option 1: Add to Windows PATH (Recommended)**

1. Build `ImeControl.exe`:
   ```cmd
   cd <plugin_dir>\wsl
   csc.exe /out:ImeControl.exe ImeControl.cs
   ```

2. Copy `ImeControl.exe` to a directory in your Windows PATH (e.g., `C:\Users\<username>\bin\`)

3. Configure your plugin:
   ```lua
   require("winimectl").setup()
   ```

**Option 2: Specify path in config**

1. Build `ImeControl.exe` as above

2. Configure with explicit path:
   ```lua
   require("winimectl").setup({
     exe_path = "/mnt/c/path/to/ImeControl.exe"
   })
   ```

### Requirements

- WSL2 environment
- Windows IME enabled on the host system
- WSLInterop enabled (default in WSL2)

### Troubleshooting

**ImeControl.exe not found:**
- Ensure `ImeControl.exe` is in your Windows PATH, or
- Specify the path explicitly via `exe_path` option

**IME control not working:**
- Verify that Windows IME is enabled and working on the host
- Make sure the terminal window has focus when testing
- Check that WSL can execute Windows executables (`wsl.exe` should work)

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
