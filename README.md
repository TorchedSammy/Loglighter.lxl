# Loglighter
> 🚦 Highlight logs in the Lite XL log view based on where they come from.

![](https://safe.kashima.moe/peed15rvdj7p.png)

This is a simple plugin that highlights log entries based on the plugin
they are from. This is detected either by the Lua source file that
is logging from, or by the \[name] at the beginning of the log message.

# Installation
Simply clone this plugin into your Lite XL plugins folder.
Next, you will have colorful logs!

# Config
There is, at the moment, 1 config option which determines what log
is colored: "tagged" ones with the [name] or anyone detected to come
from a plugin source file.

```lua
local config = require 'core.config'

config.plugins.loglighter = {
	taggedOnly = false -- if this is true, only logs that start with something like [name] will be colored
}
```

# License
MIT

The code of this plugin is heavily based on the code for the Lite XL log view since
it just recreates it with color, so credit also goes to the Lite XL authors.
