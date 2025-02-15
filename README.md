# winimectl.nvim

A Neovim plugin for controlling Windows IME state using LuaJIT FFI.

## Features

- Automatically manages IME state when entering/leaving insert or command mode
- Preserves IME state between mode switches
- Uses Windows IME Control messages via LuaJIT FFI
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
  config = true,
}
```

### packer.nvim

```lua
use {
  'hirsaeki/winimectl.nvim',
  config = true,
}
```

## Configuration

No configuration is required.

## License

MIT

## Author

hsaeki
