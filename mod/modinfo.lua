name = "BetterNightVision"
description = [[
Version 39

Removes Moggles Black/Red effect and add nightvision with the selected Hotkey	(Default = X)
The nightvision DOESN'T protect you from charlie (Unless you play in a world without caves(and you are host))

Thanks to Fuzzy Waffle and Tony
The snippets of code they've contributed to are shown in the mod's 'modmain.lua' file

]]

author = "Rockou_"
version = "39"
api_version_dst = 10

dst_compatible = true
all_clients_require_mod = false
client_only_mod = true

-- priority = -1

local string = ""
local keys = {
    "A","B","C","D","E","F",
    "G","H","I","J","K","L",
    "M","N","O","P","Q","R",
    "S","T","U","V","W","X",
    "Y","Z",
    "F1","F2","F3","F4","F5",
    "F6","F7","F8","F9","F10",
    "F11","F12",
    "LAlt","RAlt",
    "LCtrl","RCtrl",
    "LShift","RShift",
    "Tab","Capslock","Space",
    "Minus","Equals","Backspace","Insert","Home","Delete","End","Pageup","Pagedown",
    "Print","Scrollock","Pause",
    "Period","Slash","Semicolon","Leftbracket","Rightbracket","Backslash",
    "Up","Down","Left","Right"
}
local keylist = {}
for i = 1, #keys do
    keylist[i] = {description = keys[i], hover = "", data = "KEY_"..string.upper(keys[i])}
end
keylist[#keylist + 1] = {description = "Disabled", hover = "", data = false}

---@param title string
---@return table
local function Title(title)
    return {
        name=title,
        hover = "",
        options={{description = "", hover = "", data = 0}},
        default = 0,
    }
end

configuration_options = {

    Title("Main settings"),

    {
        name = "NIGHTVISION_TOGGLE_KEY",
        label = "Night vision toggle Key",
        hover = "The key that will toggle night vision",
        options = keylist,
        default = "KEY_X",
        is_keybind = true, -- integration with some config mod i dont remember
    },
    
    {
        name = "NIGHTVISION_NOTIFY_ENABLE",
        label = "Notify on toggle",
        hover = "Make the character say the night vision status (Only when changed)",
        options = {
            {
                description = "Enabled",
                hover = "",
                data = true
            },
            {
                description = "Disabled",
                hover = "",
                data = false
            }
        },
        default = true
    },

    {
        name = "NIGHTVISION_DARKNESS_ACTION_ENABLE",
        label = "Allow actions in darkness",
        hover = "Allows you to perform actions as if you really had moggles on, some things will be blocked server side",
        options = {
            {
                description = "Enabled",
                hover = "May require a moggle color cube patch mode other than default to work nicely",
                data = true
            },
            {
                description = "Disabled",
                hover = "",
                data = false
            }
        },
        default = true
    },

    Title("Darkness Alert"),

    {
        name = "NIGHTVISION_DARKNESS_ALERT_ENABLE",
        label = "Darkness Alert Enabled",
        hover = "Shows an indicator when in darkness and the night vision is active",
        options = {
            {
                description = "Enabled",
                hover = "",
                data = true
            },
            {
                description = "Disabled",
                hover = "",
                data = false
            }
        },
        default = true
    },

    {
        name = "NIGHTVISION_DARKNESS_ALERT_TRESHOLD",
        label = "Darkness Alert Treshold",
        hover = "How dark it should be before we start showing the alert",
        options = {
            {
                description = "Leave safety",
                hover = "0.05",
                data = 0.05
            },
            {
                description = "Return to safety",
                hover = "0.075",
                data = 0.075
            },
            {
                description = "Sanity loss",
                hover = "0.1",
                data = 0.1
            },
            {
                description = "0.2",
                hover = "2x Sanity loss",
                data = 0.2
            },
            {
                description = "0.4",
                hover = "4x Sanity loss",
                data = 0.4
            },
        },
        default = 0.1
    },

    {
        name = "NIGHTVISION_DARKNESS_ALERT_FREQUENCY",
        label = "Darkness Alert Frequency",
        hover = "How often should we try to spawn the alert, but might cause lag if too high",
        options = {
            {
                description = "16ms",
                hover = "1/60 of a second, 1 frame",
                data = 1/60
            },
            {
                description = "25ms",
                hover = "1/40 of a second",
                data = 0.025
            },
            {
                description = "33ms",
                hover = "1/30 of a second, 2 frames",
                data = 1/30
            },
            {
                description = "50ms",
                hover = "1/20 of a second, 3 frames",
                data = 0.050
            },
            {
                description = "100ms",
                hover = "1/10 of a second, 6 frames",
                data = 0.1
            },
            {
                description = "141.67ms",
                hover = "time between alarms normally",
                data = (1/60*(8*2+1))/2
            },
            {
                description = "200ms",
                hover = "1/5 of a second, 12 frames",
                data = 0.2
            },
            {
                description = "250ms",
                hover = "1/4 of a second, 15 frames",
                data = 0.25
            },
            {
                description = "300ms",
                hover = "3/10 of a second, 18 frames",
                data = 0.3
            },
            {
                description = "400ms",
                hover = "2/5 of a second, 24 frames",
                data = 0.4
            },
            {
                description = "500ms",
                hover = "",
                data = 0.5
            },
            {
                description = "750ms",
                hover = "",
                data = 0.75
            },
            {
                description = "1000ms",
                hover = "",
                data = 1
            }
        },
        default = 0.1
    },

    {
        name = "NIGHTVISION_DARKNESS_ALERT_ALWAYS",
        label = "Darkness Alert Always",
        hover = "Shows an indicator when in darkness whether the nightvision is active or not",
        options = {
            {
                description = "Enabled",
                hover = "",
                data = true
            },
            {
                description = "Disabled",
                hover = "",
                data = false
            }
        },
        default = true
    },

    Title("Game behavior edits"),

    {
        name = "NIGHTVISION_COLORCUBES_PATCH_MODE",
        label = "Night vision color cubes",
        hover = "Avoid weird interactions with moggle vision, higher is more invasive",
        options = {
            {
                description = "1. Default",
                hover = "Will never try to edit vision",
                data = 0
            },
            {
                description = "2. Override",
                hover = "Listen to events and reset the vision accordingly",
                data = 1
            },
            {
                description = "3. Patch",
                hover = "Work around in playervision component directly",
                data = 2
            },
            {
                description = "4. Delete",
                hover = "Override the value to nil",
                data = 3
            }
        },
        default = 1
    },

    {
        name = "GHOSTVISION_COLORCUBES_PATCH_MODE",
        label = "Ghost vision color cubes",
        hover = "PHOTOSENSITIVITY WARNING, If you want a nice nightvision while dead, higher is more invasive",
        options = {
            {
                description = "1. Default",
                hover = "Will never try to edit vision",
                data = 0
            },
            {
                description = "2. Override",
                hover = "Listen to events and reset the vision accordingly",
                data = 1
            },
            {
                description = "3. Patch",
                hover = "Work around in playervision component directly",
                data = 2
            },
            {
                description = "4. Delete",
                hover = "Override the value to nil",
                data = 3
            }
        },
        default = 1
    },

    {
        label = "Night Vision Strength",
        hover = "How bright should the night vision be",
        name = "NIGHTVISION_STRENGTH",
        options = {
            {
                description = "Disabled",
                hover = "",
                data = false
            },
            {
                description = "0%",
                hover = "",
                data = 0.0
            },
            {
                description = "10%",
                hover = "",
                data = 0.1
            },
            {
                description = "20%",
                hover = "",
                data = 0.2
            },
            {
                description = "25%",
                hover = "",
                data = 0.25
            },
            {
                description = "30%",
                hover = "",
                data = 0.3
            },
            {
                description = "40%",
                hover = "",
                data = 0.4
            },
            {
                description = "50%",
                hover = "",
                data = 0.5
            },
            {
                description = "60%",
                hover = "",
                data = 0.6
            },
            {
                description = "70%",
                hover = "",
                data = 0.7
            },
            {
                description = "75%",
                hover = "",
                data = 0.75
            },
            {
                description = "80%",
                hover = "",
                data = 0.8
            },
            {
                description = "90%",
                hover = "",
                data = 0.9
            },
            {
                description = "100%",
                hover = "",
                data = 1
            }
        },
        default = false,
    }

}
