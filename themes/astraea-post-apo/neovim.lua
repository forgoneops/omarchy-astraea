return {
  {
    "bjarneo/aether.nvim",
    branch = "v3",
    name = "aether",
    priority = 1000,
    opts = {
      colors = {
        bg = "#12100F",
        dark_bg = "#0D0B0A",
        darker_bg = "#080707",
        lighter_bg = "#241E1A",

        fg = "#F3E6C8",
        dark_fg = "#A09478",
        light_fg = "#F8EFD8",
        bright_fg = "#FFF6E2",
        muted = "#7A746C",

        red = "#E0604E",
        yellow = "#E4BE81",
        orange = "#6FC3D0",
        green = "#8DB36A",
        cyan = "#6FC3D0",
        blue = "#7A8FC4",
        magenta = "#C8789A",
        brown = "#8A5230",

        bright_red = "#EAAB8B",
        bright_yellow = "#FDC95B",
        bright_green = "#A9CE86",
        bright_cyan = "#93D6E0",
        bright_blue = "#94A6DF",
        bright_magenta = "#DE9AB6",

        accent = "#7A8FC4",
        cursor = "#FFF6E2",
        foreground = "#F3E6C8",
        background = "#12100F",
        selection = "#3A2E22",
        selection_foreground = "#FFF6E2",
        selection_background = "#3A2E22",
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
