local M = {}
local SPINNER = { '⣾', '⣽', '⣻', '⢿', '⡿', '⣟', '⣯', '⣷' }

function M.split_string(to_split, seperator)
  local result={}
  for chunk in string.gmatch(to_split, "([^"..seperator.."]+)") do
    table.insert(result, chunk)
  end
  return result
end


-- TODO: encapsulate these notifications somehow
-- not super happy with it having to know about TestFile
-- and having someone else stop the loading_timer
M.wrapped_notify = vim.schedule_wrap(function(tf, msg, level, opts)
  local opts = {
    title='Tron Test Runner',
    replace=tf.notification_record,
    hide_from_history=true,
    keep=function() return true end,
  }
  if msg:find('✗') then
    opts['hide_from_history'] = false
    opts['timeout'] = 1000
    opts['keep'] = function() return false end
    opts['on_close'] = function()
      vim.schedule(function() tf:open_scratch() end)
    end
  elseif msg:find('✓') then
    opts['keep'] = function() return false end
    opts['hide_from_history'] = false
    opts['timeout'] = 5000
  end
  tf.notification_record = vim.notify(msg, level, opts)
end)

function M.setup_notification(tf)
  tf:reset_notification()
  local spinner_idx = 1
  local loading_timer = vim.loop.new_timer()
  loading_timer:start(0, 300, vim.schedule_wrap(function()
    spinner_idx = spinner_idx + 1
    if spinner_idx > #SPINNER then spinner_idx = 1 end
    M.wrapped_notify(tf, SPINNER[spinner_idx] .. ' Running tests...', vim.log.levels.INFO)
  end))
  return loading_timer
end

return M
