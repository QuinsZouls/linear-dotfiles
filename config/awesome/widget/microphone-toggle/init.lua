local awful = require('awful')
local wibox = require('wibox')
local gears = require('gears')
local watch = awful.widget.watch
local dpi = require('beautiful').xresources.apply_dpi

local clickable_container = require('widget.clickable-container')

local config_dir = gears.filesystem.get_configuration_dir()

local widget_icon_dir = config_dir .. 'widget/microphone-toggle/icons/'
local widget_script = config_dir .. 'widget/microphone-toggle/scripts/audio_fn.py'

local return_button = function()

    local widget = wibox.widget {
        {
            id = 'icon',
            image = widget_icon_dir .. 'microphone-unused' .. '.svg',
            widget = wibox.widget.imagebox,
            resize = true
        },
        layout = wibox.layout.align.horizontal
    }

    local widget_button = wibox.widget {
        {
            widget,
            margins = dpi(7),
            widget = wibox.container.margin
        },
        widget = clickable_container
    }

    widget_button:buttons(gears.table.join(awful.button({}, 1, nil, function()
        awful.spawn('python3 ' .. widget_script .. ' --toggle', false)
    end)))

    local microphone_tooltip = awful.tooltip {
        objects = {widget_button},
        mode = 'outside',
        align = 'right',
        margin_leftright = dpi(8),
        margin_topbottom = dpi(8),
        preferred_positions = {'right', 'left', 'top', 'bottom'}
    }

    watch('python3 ' .. widget_script .. ' --query', 1, function(_, stdout)
        local widget_icon_name = nil
        if stdout:match('no recording') then
            widget_icon_name = 'microphone-unused'
            microphone_tooltip.markup = 'Microphone is not recording'
        elseif stdout:match('recording and muted') then
            widget_icon_name = 'microphone-muted'
            microphone_tooltip.markup = 'Microphone is muted'
        else
            widget_icon_name = 'microphone-recording'
            microphone_tooltip.markup = 'Microphone is recording'
        end
        widget.icon:set_image(widget_icon_dir .. widget_icon_name .. '.svg')
        collectgarbage('collect')
    end, widget)

    return widget_button

end

return return_button
