-- base-4 numbering system
-- vertically compact (7x3)   
-- 
-- example below
--
-- ___   ___   ___   ___
-- 1      2     3      4 
-- ,__,__,__,__,__,__,__,
-- 4  8  12 16 20 24 28
-- ___   ___   ___   ___
-- 32    64    128    256

engine.name = "TestSine"

function init()
  engine.amp(0)
  b = 4                                         -- base. in this case, base-4
  val = 3                                       -- value to be interpretted
  x = 0                                         -- x for screen values
  y = 0                                         -- y for screen values
end

function redraw()
  screen.clear()
  screen.level(7)
  screen.aa(0)
  screen.move(64,32)
  screen.text_center(val)
  screen.move(0,0)
  mod()
  screen.stroke()
  screen.update()
end

function mod()
  if val / b <= 1 and val % b > 0 then        -- val = 1,2,3...(b-1)
    for n=0,(val % b-1) do                    -- row 1
      screen.pixel(x+n*2,y)
    end
  elseif val / b == 1 and val % b == 0 then   -- val = b
    for n=0,b-1 do                            -- row 1
      screen.pixel(x+n*2,y)
    end
  elseif val / b >= 1 and val % b > 0 then    -- val = more than b, but not a multiple of b
    for n=0,(val % b-1) do                    -- row 1
      screen.pixel(x+n*2,y)
      print("n:"..n*2+x)
    end
    screen.pixel(x,y+1)                       -- row 2
    screen.move(x,y+1)
    screen.line_rel(val/b-1,0)
  elseif val / b > 1 and val % b == 0 then    -- val = multiples of b
    for n=0,b-1 do
      screen.pixel(x+n*2,y)
      print("n:"..n*2+x)
    end
    screen.pixel(x,y+1)                       -- row 2
    screen.move(x,y+1)
    screen.line_rel(round(val/b-2,0),0)
  end
end

function round(num, numDecimalPlaces)
  local mult = 10^(numDecimalPlaces or 0)
  return math.floor(num * mult + 0.5) / mult
end

function enc(n,d)
  if n == 2 then
    val = val + d
    print("val:"..val)
  elseif n == 3 then
    y = y + d
    print("y:"..y)
  end
  redraw()
end

function key(n,z)
  if n == 3 and z == 1 then
    x = x + z
    print("x:"..x)
  elseif n == 2 and z == 1 then
    x = x + (z * -1)
  end
  redraw()
end
