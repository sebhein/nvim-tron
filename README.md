# NeoVim Tron
Run and view tests results inside NeoVim

:warning: This is a personal project, if you are looking for something more serious I recommend [Neotest](https://github.com/nvim-neotest/neotest)


## Setup

Uses plenary and treesitter.

Install using your favorite package manager, mine is:

[packer.nvim](https://github.com/wbthomason/packer.nvim)

```
use {
  "sebhein/nvim-tron",
  requires = {
    "nvim-lua/plenary.nvim",
    "nvim-treesitter/nvim-treesitter",
  }
}
```

## Usage

- `require("tron").run_test()`
- `require("tron").show_output()` (not implemented)
- `require("tron").run_test_in_split()`

## TODO

- [ ] explain usage in ReadMe
- [ ] add some screenshots as example in in ReadMe
- [ ] make it configurable
- [ ] record and show output of test runs
- [ ] add rust
