-- Look and feel configuration

hl.config({
    general = {
        gaps_in = 3,
        gaps_out = 8,
        border_size = 2,
        extend_border_grab_area = 10,
        resize_on_border = true,
        col = {
            active_border = {
                colors = { "rgba(b0b0b0ff)", "rgba(707070ff)" },
                angle = 45,
            },
            inactive_border = "rgba(303030ff)",
        },
    },
    group = {
        col = {
            border_active = CACHYLBLUE,
            border_inactive = "rgba(303030ff)",
            border_locked_active = CACHYDBLUE,
            border_locked_inactive = "rgba(303030ff)",
        },
        groupbar = {
            col = {
                active = CACHYLGREEN,
                inactive = "rgba(303030ff)",
                locked_active = CACHYDBLUE,
                locked_inactive = "rgba(303030ff)",
            },
        },
    },
    decoration = {
        dim_special = 0.3,
        rounding = 8,
        active_opacity = 1,
        inactive_opacity = 1,
        fullscreen_opacity = 1,
        blur = {
            enabled = false,
            size = 5,
            passes = 4,
            special = true,
        },
    },
})
