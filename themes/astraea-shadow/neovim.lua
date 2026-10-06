return {
  {
    "bjarneo/aether.nvim",
    branch = "v3",
    name = "aether",
    priority = 1000,
    opts = {
      colors = {
        bg = "#0A0A12",
        dark_bg = "#05030B",
        darker_bg = "#030208",
        lighter_bg = "#120E24",

        fg = "#E9E6F2",
        dark_fg = "#8F8CAA",
        light_fg = "#F1EEF8",
        bright_fg = "#F8F6FF",
        muted = "#6A6A8C",

        red = "#C0708E",
        yellow = "#E6C666",
        orange = "#94CBED",
        green = "#5CCFA0",
        cyan = "#94CBED",
        blue = "#7F92D0",
        magenta = "#A5A6DE",
        brown = "#6B4A5A",

        bright_red = "#D890AA",
        bright_yellow = "#F4D987",
        bright_green = "#85E8BE",
        bright_cyan = "#B3FEFF",
        bright_blue = "#9BAEE8",
        bright_magenta = "#BABAFF",

        accent = "#7F92D0",
        cursor = "#F8F6FF",
        foreground = "#E9E6F2",
        background = "#0A0A12",
        selection = "#241C48",
        selection_foreground = "#F8F6FF",
        selection_background = "#241C48",
      },
    },
  },
  {
    "LazyVim/LazyVim",
    opts = {
      colorscheme = "aether",
    },
  },
}
