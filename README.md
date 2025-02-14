# winimectl.vim

A Neovim plugin for controlling Windows IME state using denops.vim.

## Requirements

- Neovim
- [denops.vim](https://github.com/vim-denops/denops.vim)
- Windows OS (uses IMM32 API)

## Installation

Using your preferred plugin manager:

```lua
-- Using packer.nvim
use {
  'your-username/winimectl',
  requires = 'vim-denops/denops.vim'
}
```

## Setup

Add to your init.lua:

```lua
require('winimectl').setup()
```

## Features

- Automatically manages IME state when entering/leaving insert mode
- Preserves IME state between mode switches
- Uses Windows IMM32 API through Deno FFI

## License

MIT

