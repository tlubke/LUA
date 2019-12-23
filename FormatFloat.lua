function format_float(num, min_places, max_places)
  -- TODO: exception for min > max
  local buffer = {}
  local s = tostring(num)
  local point_index = string.find(s, "%.")
  
  -- find index of '.' in floating point
  -- if an int, just return a string of num
  if point_index == nil then
    return s
  end
  
  digits_after_point = string.sub(s, point_index + 1, point_index + max_places + 1)
  
  if #digits_after_point > max_places then
    -- float has more precision than max_places, ROUND UP if neccessary
    for i = 1, #digits_after_point do
      -- put all trailing zeroes in string buffer
      if string.sub(digits_after_point, i, i) == '0' then
        table.insert(buffer, '0')
      else
        -- first non-zero character at ith index after .
        first_nz = i
        break
      end
    end
    
    round_digit = string.sub(digits_after_point, #digits_after_point, #digits_after_point)
    
    if round_digit >= '5' then
      digits_after_zeroes = string.sub(digits_after_point, first_nz, #digits_after_point) + 5
    else
      digits_after_zeroes = string.sub(digits_after_point, first_nz, #digits_after_point)
    end
    
    -- truncate the rounding digit and floating point if string was converted to a num
    table.insert(buffer, string.sub(digits_after_zeroes, 1, #digits_after_point - first_nz))
  else
    -- float has less than max_places, no rounding neccessary
    after_point = string.sub(s, point_index + 1, point_index + max_places)
    table.insert(buffer, after_point)
    table.insert(buffer, string.rep("0", min_places - string.len(after_point)) )
  end
  
  return (string.sub(s, 0, point_index) .. table.concat(buffer))
end
