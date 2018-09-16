-- polyrhythmic sampler
--
-- 4, two-channel tracks
-- 
-- trackA: sets the length 
-- of the tuplet
--
-- trackB: sets length of the 
-- 'measure' in quarter notes
--
-- tapping gridkeys toggles the
-- tuplet subdivisions and 
-- quarter notes on/off

engine.name = 'Ack'

local ack = require 'jah/ack'

local g = grid.connect()

--[[current issues:
                  -still can't get quarter notes to works
                  -a track of length two is backwards,
                  so the offbeat plays on the first column instead of
                  the second where it should be happening.
                  

--]]



------------
-- variables
------------



-- clocking variables
position = 0
bpm = 60
counter = nil
ppq =  480 -- pulse per quarter

-- grid variables (until I get this working with a grid)
g_row = {}
for i = 1, 8 do
  g_row[i] = {}
end

  -- for holding one gridkey and pressing another further right
held = {}
heldmax = {}
done = {}
first = {}
second = {}
for i = 1,8 do
  held[i] = 0
  heldmax[i] = 0
  done[i] = 0
  first[i] = 0
  second[i] = 0
end

-- 4, two-channel tracks (TrackA is evens, TrackB is odds)
track = {}
for i=1,8 do
  track[i] = {}
  track[i][1] = {}
  track[i][1][1] = {sub=0, on=false}  -- subdivisions have to be indexed by 0
end



----------------
-- initilization
----------------



function init()
  
  params:add_number("bpm",15,400,60)
  
  -- metronome setup
  counter = metro.alloc()
  counter.time = 60 / (params:get("bpm") * ppq)
  counter.count = -1
  counter.callback = count
  counter:start()
  
  ack.add_effects_params()
  
  for i=1,4 do
    ack.add_channel_params(i)
  end
  
  params:read("gittifer/polygrid.pset")
  params:bang()

  -- supposed to show basic functionality/layout of grid
  g.all(0)
  for i=1, 4 do
    for n=1, math.random(16) do
      g.led(n, i*2 -1, 8)
    end
    for n=1, math.random(8) do
      g.led(n, i*2, 4)
    end
  end
  g.refresh()
  
  redraw()
end



-------------------------
-- grid control functions
-------------------------



function g.event(x, y, z)
  --print("got event from grid: row: " .. y .. ", col: " .. x .. ", state: " .. z)
  gridkeyhold(x,y,z)
  gridkey(x,y,z)
end

function gridkey(x,y,z)
  if z == 1 then
    if tab.count(g_row[y]) == 0 or tab.count(g_row[y]) == nil then
      if x > 1 then
        return
      elseif x == 1 then
          g_row[y][x] = x
          retrack(y)
        gridredraw()
      end
      return
    else
      if x == 16 then
        g_row[y] = {}
        retrack(y)
        return
      elseif y % 2 == 1 then
        if track[y][tab.count(track[y])][x].on == true then
          track[y][tab.count(track[y])][x].on = false
        else
          track[y][tab.count(track[y])][x].on = true
        end
      elseif y % 2 == 0 then
        if track[y][tab.count(track[y])][x].on == true then
          track[y][tab.count(track[y])][x].on = false
        else
          track[y][tab.count(track[y])][x].on = true
        end
      end
    end
  end
  gridredraw()
end



function gridkeyhold(x, y, z)
  if z==1 and held[y] then heldmax[y] = 0 end
  held[y] = held[y] + (z*2-1)
  
  if held[y] > heldmax[y] then heldmax[y] = held[y] end

  if y > 8 and held[y]==1 then
  -- checks against track boundaries
    first[y] = x
    print("pos > "..cut)
  elseif y<=8 and held[y]==2 then
    -- checks for holding
    second[y] = x
  elseif z==0 then
    if y<=8 and held[y] == 1 and heldmax[y]==2 then
      g_row[y] = {}
      for i = 1, math.max(first[y],second[y]) do
        g_row[y][i] = i
      end
      print(second[y])
      retrack(y)
      gridredraw()
    end
  end
end



------------------
-- active functions
-------------------

--[[
    this is the heart of polyrhythm generating, each track is checked to see which note divisions are on or off,
    first, the B track is checked (the 'quarter' note, before the tuplet division) then if the note is on, we check
    each of the subdivisions, and if those turn out to be on, the nth subdivision of the tuple of the track is triggered.
    The complicated divisons and multiplations of each of the track sets and subsets is to find the exact position value,
    that when % by that value returns 1, the track triggers.
]]--


function count(c)
  position = (position + 1) % (ppq + 1) 
  counter.time = 60 / (params:get("bpm") * ppq)
  if position == 0 then gridredraw() end -- for a pretty pulsing effect
  
  for i=1, 7, 2 do 
    for n=1, tab.count(track[i]) do
      cnt = tab.count(track[i])
      if cnt == 0 or nil then return
      else
      -- check each note in sub length for on/off
        if position / ( ppq // (tab.count(track[i][cnt]))) == n then
          g.led(n,i,15)
          g.refresh()
          if track[i][cnt][n].on == true then
            -- for downbeat, makes it toggle-able
            engine.trig(i//2) -- samples are only 0-3
            g.led(n,i,8)
            g.refresh()
          else
            g.led(n,i,4)
            g.refresh()
          end
        end
      end
    end
  end
end



---------------------------
-- refresh/redraw functions
---------------------------



function retrack(y)
  track[y] = {}
  for i = 1, tab.count(g_row[y]) do 
    track[y][i] = {}
    for n=1, i do
      track[y][i][n] = {sub=n-1, on=true}  -- subdivisions have to be indexed by 0
    end
  end
end

function redraw()
  screen.clear()
  screen.update()
end

function gridredraw()
  g.all(0)

  -- draw channels with sub divisions on/off
  for i=1, 8 do
    for n=1, tab.count(track[i]) do
      ct = tab.count(track[i])
      if ct == 0 or nil then return
      else
        if i % 2 == 1 then
          if track[i][ct][n].on == true then
            g.led(n,i,12)
          else
            g.led(n,i,4)
          end
          
        elseif i % 2 == 0 then
          if track[i][ct][n].on == true then
            g.led(n,i,10)
          else
            g.led(n,i,4)
          end
        end
      end
    end
  end
  
g.refresh()
end
