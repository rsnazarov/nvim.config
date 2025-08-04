local M = {}
local api = vim.api
local state = require "volt.state"

local buf_i = 1

M.cycle_bufs = function(bufs)
  buf_i = buf_i == #bufs and 1 or buf_i + 1

  local new_buf = bufs[buf_i]
  local a = vim.fn.bufwinid(new_buf)

  api.nvim_set_current_win(a)
end

M.cycle_clickables = function(buf, step)
  local bufstate = state[buf]
  local lines = {}

  for row, val in pairs(bufstate.clickables) do
    if #val > 0 then
      table.insert(lines, row)
    end
  end

  local cur_row = api.nvim_win_get_cursor(0)[1]

  local len = #lines
  local from_loop = step > 0 and 1 or len
  local to_loop = step > 0 and len or 1

  for i = from_loop, to_loop, step do
    if (step > 0 and lines[i] > cur_row) or (step < 0 and lines[i] < cur_row) then
      api.nvim_win_set_cursor(0, { lines[i], 0 })
      return
    end
  end
end

M.close = function(val)
  local event_bufs = require("volt.events").bufs

  for _, buf in ipairs(val.bufs) do
    local valid_buf = api.nvim_buf_is_valid(buf)

    if valid_buf then
      api.nvim_buf_delete(buf, { force = true })
      state[buf] = nil
    end

    --- remove buf from event_bufs table
    for i, bufid in ipairs(event_bufs) do
      if bufid == buf then
        table.remove(event_bufs, i)
      end
    end

    if val.close_func then
      val.close_func(buf)
    end
  end

  if val.after_close then
    val.after_close()
  end

  vim.g.nvmark_hovered = nil
end

M.get_hl = function(name)
  local hexadecimal_to_hex = function(hex)
    return "#" .. ("%06x"):format(hex == nil and 0 or hex)
  end

  local hl = api.nvim_get_hl(0, { name = name })
  local result = {}

  if hl.fg ~= nil then
    result.fg = hexadecimal_to_hex(hl.fg)
  end

  if hl.bg ~= nil then
    result.bg = hexadecimal_to_hex(hl.bg)
  end

  return result
end

return M
