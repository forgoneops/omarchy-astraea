local active_border_color = { colors = { "rgba(FFB62Eee)", "rgba(AEF8FFee)" }, angle = 45 }
local inactive_border_color = "rgba(1C2236aa)"

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
