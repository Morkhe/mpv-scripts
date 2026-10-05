local utils = require 'mp.utils'
local msg = require 'mp.msg'
-- local options = require 'mp.options'

-- Track sub-files we've already rewritten to prevent infinite loops
local config = {
    enabled = true,
}
exclusions = {
    "subtitles",
    "subs",
    "субтитры"
}
-- options.read_options(config, _, function() end)

-- Function to check if the folder matches any excluded keywords
local function is_excluded(folder_name)
    if folder_name == "." or folder_name == ".." then
        return true
    end

    local lower_folder = folder_name:lower()

    for _, pattern in ipairs(exclusions) do
        if string.find(lower_folder, pattern, 1, true) then
            return true
        end
    end
    return false
end


local function rename_tracks(track_list)

    if not track_list then return end

    for _, track in ipairs(track_list) do
        -- Only look at external subtitle files
        if track.type ~= 'sub' or not track.external or not track['external-filename'] then
            goto next_track
        end

        msg.debug("Processing ", track['external-filename'])

        -- Extract the parent folder name (e.g., Crunchyrolls)
        local filepath = track['external-filename']
        local parent_folder = filepath:match("([^/]+)/[^/]+$")

        if parent_folder and not is_excluded(parent_folder) then
            msg.debug("Attempt to rename", track['external-filename'])

            -- Remove the generic unnamed track
            mp.commandv('sub-remove', track.id)
            -- Re-add the subtitle file forcing the parent folder as the title
            flag = (track.selected) ? "selected" : "auto"
            mp.commandv('sub-add', filepath, flag, parent_folder)

            msg.info("Renamed subtitle track from", track.title, "to", parent_folder)
        end

        ::next_track::
    end

end

mp.add_hook('on_preloaded', 55, function()
    if not config.enabled then return end
    rename_tracks(mp.get_property_native("track-list"))
end)
