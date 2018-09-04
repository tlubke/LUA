-- screen.draw functions for Monome's norns

function polygon(cx, cy, radius, angle, points)
	local radius = radius
	local angle = angle
	local points = points
	local x[] = {}
	local y[] = {}
		  x[1] = cx
		  y[1] = cy
	
	for i = 1, points + 1 do
		x[i+1] = x[1] + (radius * math.cos(angle + (i+i-1)*math.pi / points ))
		y[i+1] = y[1] + (radius * math.sin(angle + (i+i-1)*math.pi / points ))
	end
	
	screen.move(x[2],y[2])
		for i = 3, points + 1 do
			screen.line(x[i],y[i])
		end
	screen.line(x[2],y[2])
	screen.close()
end

function gridlay(div,size,shiftx,shifty)
  
	local div = div           -- number of divisions, only multiples of 4 divide cleanly
	local size = (128/div)    -- space between gridlines
	local shiftx = shiftx
	local shifty = shifty
  
 	screen.line_width(1)    -- vertical gridlay
    	for i = 1, div do     
      		screen.move(i * size + shiftx, 0)
      		screen.line_rel(0,64)
      	if i < div/2 then
         	screen.level(i)
        else 
          	screen.level(div-i)
      	end
     	screen.stroke()
	end
    
    	screen.level(7)         -- vertical centerline
    	screen.line_width(1) 
	screen.move(64,0)
	screen.line_rel(0,64)
	screen.stroke()

    	screen.line_width(1)    -- horizontal gridlay
    	for i = 1, div/2 do     
      		screen.move(0, i*size + shifty)
      		screen.line_rel(128,0)
      		if i < div/4 then
          		screen.level(i*2)
        	else
          		screen.level(div-i*2)
      		end
      		screen.stroke()
    	end
      
    	screen.level(15)        -- horizontal centerline
    	screen.line_width(1)
    	screen.move(0,32)
    	screen.line_rel(128,0)
    	screen.stroke()
    
    	screen.level(0)
      	screen.move(0,31)
      	screen.line_rel(128,0)
      	screen.move(0,33)
      	screen.line_rel(128,0)
      	screen.move(63,0)
      	screen.line_rel(0,64)
      	screen.move(65,0)
      	screen.line_rel(0,64)
      	screen.stroke()
    
    	screen.level(10)        -- center square
    	screen.rect(62,30,3,3)
    	screen.fill()
    
end

function baseN(x, y, base, value)
-- base-n numbering system
-- vertically compact: (base * 2 - 1) by (2) pixels.   
-- 
-- example(base-4) below
--
-- ___   ___   ___   ___
-- 1      2     3      4 
-- ,__,__,__,__,__,__,__,
-- 4  8  12 16 20 24 28
-- ___   ___   ___   ___
-- 32    64    128    256

local x = x
local y = y
local base = base                                       -- base only divides cleanly by multiples of 2
local value = util.clamp(value, 0, base^2 * 2)          -- a little impractical over 8.
screen.line_width(0.5)

	if value / base <= 1 and value % base > 0 then        -- val = 1,2,3...(b-1)
  		for i = 0,(value % base - 1) do                    	-- row 1
      			screen.pixel(x + i * 2, y)
    	end
    
	elseif value / base == 1 and value % base == 0 then   -- val = b
    		for i = 0, base - 1 do                              -- row 1
      			screen.pixel(x + i * 2, y)
    		end
    
  	elseif value / base >= 1 and value % base > 0 then    -- val = more than b, but not a multiple of b
    		for i = 0,(value % base - 1) do                     -- row 1
      			screen.pixel(x + i * 2, y)
    		end
    
    		for i = 1, (value // base) do                       -- row 2
      			screen.pixel(x + i - 1, y + 1)                           
    		end
  	elseif value / base > 1 and value % base == 0 then    -- value = multiples of base
    		for i = 0, base - 1 do
      			screen.pixel(x + i * 2, y)
    		end
    
    		for i = 1, (value // base) - 1 do                   -- row 2
      			screen.pixel(x + i - 1, y + 1)                          
    		end
  	end
  
  	if value == 0 then                                    -- create a shadow outline if value is 0
    		screen.level(1)
    		for i = 0, base - 1 do
      			screen.pixel(x + i * 2, y)
    		end
    		for i = 1, base * 2 - 1 do                  
      			screen.pixel(x + i - 1, y + 1)
    		end

    	screen.fill()
    	screen.level(15)
  	end
  
screen.fill()
end
