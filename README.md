# NeoVim Tron
Run and view tests results inside NeoVim

:warning: This is a personal project, if you are looking for something more serious I recommend [Neotest](https://github.com/nvim-neotest/neotest)


Uses [pantsbuild](https://www.pantsbuild.org) and pytest to run tests.


## Setup

Uses plenary, treesitter, and nvim-notify.

Install using your favorite package manager, mine is:

[packer.nvim](https://github.com/wbthomason/packer.nvim)

```
use {
  "sebhein/nvim-tron",
  requires = {
    "nvim-lua/plenary.nvim",
    "nvim-treesitter/nvim-treesitter",
    "rcarriga/nvim-notify",
  }
}
```

## Usage

- `require("tron").run_test()` or `:TronRun`
- `require("tron").show_output()` or `:TronShow`
- `require("tron").clear_signs_in_current_buffer()` or `:TronClear`

## TODO

- [x] make it work with pants
- [x] find line numbers of tests AFTER the test has finished
- [x] send a notification when test has finished
- [x] use fancy notification
- [x] make a spinner animation while test is running
- [x] don't open scratch again if already open
- [x] fix: placing signs for tests in class
- [ ] dont refresh tree for each test
- [ ] explain usage in ReadMe
- [ ] add some screenshots as example in in ReadMe
- [ ] make it configurable
- [ ] record and show output of test runs using an overlay window
- [ ] handle parametrized tests
- [ ] add cargo test runner
