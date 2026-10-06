return {
  {
    "bjarneo/aether.nvim",
    branch = "v3",
    name = "aether",
    priority = 1000,
    opts = {
      colors = {
        bg = "#070A12",
        dark_bg = "#05070E",
        darker_bg = "#03050A",
        lighter_bg = "#111A2A",

        fg = "#F4EBDD",
        dark_fg = "#9A93A0",
        light_fg = "#F8F0E4",
        bright_fg = "#FFF8EE",
        muted = "#6B6A78",

        red = "#FF4D5E",
        yellow = "#F2C14E",
        orange = "#9BDCFF",
        green = "#3FD6A6",
        cyan = "#9BDCFF",
        blue = "#8A8ACD",
        magenta = "#B09CDF",
        brown = "#8A5A3A",

        bright_red = "#FF7A87",
        bright_yellow = "#FFD36A",
        bright_green = "#6AE8C0",
        bright_cyan = "#AEF8FF",
        bright_blue = "#A9AAF0",
        bright_magenta = "#C8AEFF",

        accent = "#8A8ACD",
        cursor = "#FFF8EE",
        foreground = "#F4EBDD",
        background = "#070A12",
        selection = "#1C2236",
        selection_foreground = "#FFF8EE",
        selection_background = "#1C2236",
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
