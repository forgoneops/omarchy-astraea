return {
  {
    "bjarneo/aether.nvim",
    branch = "v3",
    name = "aether",
    priority = 1000,
    opts = {
      colors = {
        bg = "#0C0605",
        dark_bg = "#080403",
        darker_bg = "#050202",
        lighter_bg = "#1C100C",

        fg = "#F7EBCB",
        dark_fg = "#A8987A",
        light_fg = "#FBF2DA",
        bright_fg = "#FFF8EA",
        muted = "#7A6B5E",

        red = "#BC5C4E",
        yellow = "#FFC400",
        orange = "#E8883A",
        green = "#9CB85A",
        cyan = "#7FC8B0",
        blue = "#5F79D0",
        magenta = "#D9A066",
        brown = "#7A4A2A",

        bright_red = "#EB7D6A",
        bright_yellow = "#FFD86A",
        bright_green = "#B8D47A",
        bright_cyan = "#A4DFCB",
        bright_blue = "#819AFF",
        bright_magenta = "#E8BC88",

        accent = "#5F79D0",
        cursor = "#FFF8EA",
        foreground = "#F7EBCB",
        background = "#0C0605",
        selection = "#3A2216",
        selection_foreground = "#FFF8EA",
        selection_background = "#3A2216",
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
