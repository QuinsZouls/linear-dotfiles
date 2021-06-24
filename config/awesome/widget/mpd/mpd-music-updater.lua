local awful = require('awful')
local gears = require('gears')
local config_dir = gears.filesystem.get_configuration_dir()
local widget_icon_dir = config_dir .. 'widget/mpd/icons/'
local ui_content = require('widget.mpd.content')
local album_cover = ui_content.album_cover
local song_info = ui_content.song_info
local vol_slider = ui_content.volume_slider
local media_buttons = ui_content.media_buttons
-- TODO update cover
local update_cover = function()

    local extract_script = [[
			playerctl metadata -f "{{mpris:artUrl}}"
		]]

    awful.spawn.easy_async_with_shell(extract_script, function(stdout)
        local album_icon = widget_icon_dir .. 'vinyl' .. '.svg'
        if not (stdout == nil or stdout == '') then
            album_icon = stdout:gsub('%\n', '')
        end
        album_cover.cover:set_image(album_icon)
        album_cover:emit_signal('widget::redraw_needed')
        album_cover:emit_signal('widget::layout_changed')
        collectgarbage('collect')
    end)
end

local update_title = function()
    awful.spawn.easy_async_with_shell([[
			playerctl metadata --format "{{ title }}"
		]], function(stdout)
        -- Remove new lines
        local title = stdout:gsub('%\n', '')
        local title_widget = song_info.music_title
        local title_text = song_info.music_title:get_children_by_id('title')[1]
        -- Make sure it's not null
        if not (title == nil or title == '') then
            title_text:set_text(title)
        else
            awful.spawn.easy_async_with_shell([[
					mpc -f %file% current
					]], function(stdout)
                if not (stdout == nil or stdout == '') then
                    file_name = stdout:gsub('%\n', '')
                    file_name = file_name:sub(1, title:len() - 5) .. ''
                    title_text:set_text(file_name)
                else
                    -- Set title
                    title_text:set_text('Play some music!')
                end
                title_widget:emit_signal('widget::redraw_needed')
                title_widget:emit_signal('widget::layout_changed')
            end)
        end

        title_widget:emit_signal('widget::redraw_needed')
        title_widget:emit_signal('widget::layout_changed')
        collectgarbage('collect')
    end)
end

local update_artist = function()
    awful.spawn.easy_async_with_shell([[
			playerctl metadata --format "{{ artist }}"
		]], function(stdout)

        -- Remove new lines
        local artist = stdout:gsub('%\n', '')
        local artist_widget = song_info.music_artist
        local artist_text = artist_widget:get_children_by_id('artist')[1]
        if not (artist == nil or artist == '') then
            artist_text:set_text(artist)
        else
            awful.spawn.easy_async_with_shell([[
					mpc -f %file% current
					]], function(stdout)
                if not (stdout == nil or stdout == '') then

                    artist_text:set_text('unknown artist')

                else
                    artist_text:set_text('or play some porn?')
                end
                artist_widget:emit_signal('widget::redraw_needed')
                artist_widget:emit_signal('widget::layout_changed')
            end)
        end

        artist_widget:emit_signal('widget::redraw_needed')
        artist_widget:emit_signal('widget::layout_changed')
        collectgarbage('collect')
    end)
end

local check_if_playing = function()
    awful.spawn.easy_async_with_shell([[
			playerctl status
		]], function(stdout)
        local play_button_img = media_buttons.play_button_image.play
        local status = stdout:gsub('%\n', '')
        if (status == 'Playing') then
            play_button_img:set_image(widget_icon_dir .. 'pause.svg')
        else
            play_button_img:set_image(widget_icon_dir .. 'play.svg')
        end
    end)
end

local update_all_content = function()
    check_if_playing()
    update_title()
    update_artist()
    update_cover()
end

media_buttons.play_button:buttons(gears.table.join(awful.button({}, 1, nil, function()
    awful.spawn.with_shell('playerctl play-pause')
end)))

media_buttons.next_button:buttons(gears.table.join(awful.button({}, 1, nil, function()
    awful.spawn.with_shell('playerctl next')
end)))

media_buttons.prev_button:buttons(gears.table.join(awful.button({}, 1, nil, function()
    awful.spawn.with_shell('playerctl previous')
end)))

gears.timer {
    timeout = 1,
    call_now = true,
    autostart = true,
    callback = function()
        update_all_content()
        collectgarbage('collect')
    end
}
