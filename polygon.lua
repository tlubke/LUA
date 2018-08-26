-- extracted straight from my script
function polygon(cx, cy, radius, angle, sides)
	local x[sides+1] = {}
	local y[sides+1] = {}
		  x[1] = cx
		  y[1] = cy
	
	for i = 1, sides+1 do
		x[i+1] = x[1] + (r * math.cos(angle + (i+i-1)*math.pi / sides ))
		y[i+1] = y[1] + (r * math.sin(angle + (i+i-1)*math.pi / sides ))
	end
	
	screen.move(x[2],y[2])
		for i = 3, p + 1 do
			screen.line(x[i],y[i])
		end
	screen.line(x[2],y[2])
	screen.close()
	-- screen.pixel(x[1],y[1]) -- comment this out to get rid of the center point
end


-- based on what I could extract from screen.lua
screen.polygon = function(x, y, r, a, sides) s_polygon(cx, cy, r, a, sides) end

s_polygon = function(cx, cy, r, a, sides)
	local x[sides+1] = {}
	local y[sides+1] = {}
		  x[1] = cx
		  y[1] = cy
	
	for i = 1, sides+1 do
		x[i+1] = x[1] + (r * math.cos(a + (i+i-1)*math.pi / sides ))
		y[i+1] = y[1] + (r * math.sin(a + (i+i-1)*math.pi / sides ))
	end
	
	s_move(x[2],y[2])
		for i = 3, p + 1 do
			s_line(x[i],y[i])
		end
	s_line(x[2],y[2])
	s_close()
	-- screen.pixel(x[1],y[1]) -- center point
end
