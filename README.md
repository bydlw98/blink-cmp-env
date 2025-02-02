# blink-cmp-env

[blink.cmp](https://github.com/Saghen/blink.cmp) source for environment variables.

Inspired by [cmp-env](https://github.com/bydlw98/cmp-env).

## Installation

### `lazy.nvim`

```lua
{
    "saghen/blink.cmp",
    dependencies = {
        "bydlw98/blink-cmp-env",
    },
    opts = {
        sources = {
            default = { "lsp", "path", "snippets", "buffer", "env" },
            providers = {
                env = {
                    name = "Env",
                    module = "blink-cmp-env",
                    --- @type blink-cmp-env.Options
                    opts = {
                        item_kind = require("blink.cmp.types").CompletionItemKind.Variable,
                        show_braces = false,
                        show_documentation_window = true,
                    },
                }
            }
        }
    }
}
```

## Options

### item_kind (type: number)

_Default:_ `require("blink.cmp.types").CompletionItemKind.Variable,`

[`CompletionItemKind`](https://github.com/Saghen/blink.cmp/blob/main/lua/blink/cmp/types.lua#L21) shown in completion menu.

### show_braces (type: boolean)

_Default:_ `false`

Specify whether to show braces in completion item. For example, `${PATH}` instead of `$PATH`.

### show_documentation_window (type: boolean)

_Default:_ `true`

Specify whether to show documentation window which contains value of environment variable selected.

## Special Thanks

- [@amarz45](https://github.com/amarz45) cmp-env general improvements and implementation for show_braces options
