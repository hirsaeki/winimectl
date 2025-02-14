# winimectl.vim

A Neovim plugin for controlling Windows IME state using denops.vim.

## Requirements

- Neovim
- [denops.vim](https://github.com/vim-denops/denops.vim)
- Windows OS (uses IMM32 API)

## Installation

Using your preferred plugin manager:

### packer

```lua
-- Using packer.nvim
use {
  'hirsaeki/winimectl',
  requires = 'vim-denops/denops.vim'
}
```

Add to your init.lua:

```lua
require('winimectl').setup()
```

### lazy

```lua
-- Using lazy.nvim
{
  "hirsaeki/winimectl",
  dependencies = {
    "vim-denops/denops.vim",
  },
  event = "VeryLazy",
  config = function()
    require("winimectl").setup()
  end,
}
```

## Features

- Automatically manages IME state when entering/leaving insert mode
- Preserves IME state between mode switches
- Uses Windows IMM32 API through Deno FFI

## License

MIT
