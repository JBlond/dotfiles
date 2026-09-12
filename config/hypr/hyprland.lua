require("inc.monitor")

-- Set programs that you use
local terminal    = "ghostty"
local fileManager = "dolphin"
local menu        = "hyprlauncher"

require("inc.autostart")

---- ENVIRONMENT VARIABLES ----

-- See https://wiki.hypr.land/Configuring/Advanced-and-Cool/Environment-variables/

hl.env("XCURSOR_SIZE", "24")
hl.env("HYPRCURSOR_SIZE", "24")

require("inc.look")
require("inc.input")
require("inc.keybindings")
require("inc.windows")
