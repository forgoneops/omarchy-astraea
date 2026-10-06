local active_border_color = { colors = { "rgba(FFC400ee)", "rgba(EB7D6Aee)" }, angle = 45 }
local inactive_border_color = "rgba(3A2216aa)"

hl.config({
  general = {
    col = {
      active_border = active_border_color,
      inactive_border = inactive_border_color,
    },
  },

  group = {
    col = {
      border_active = active_border_color,
      border_inactive = inactive_border_color,
    },
  },
})
