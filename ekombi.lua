-- Ekombi
--
-- a polyrhythmic sampler
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

--[[whats next?:
                - continue optimizing
                - beatclock integration for midi sync
]]--

--[[current issues:
                  -a track of length two is backwards,
                  so the offbeat plays on the first column instead of
                  the second where it should be happening.

--]]



------------
-- variables
------------



-- clocking variables
position = 0
q_position = 0
bpm = 60
counter = nil
running = false
ppq =  480 -- pulse per quarter

-- grid variables

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
  if i % 2 == 1 then
    track[i] = {}
    track[i][1] = {}
    track[i][1][1] = {sub=0, on=false}  -- subdivisions have to be indexed by 0
  else
    track[i] = {}
    for n=1, 16 do
      track[i][n] = {}
      for j=1, 16 do
        track[i][n][j] = {sub=0, on=true}
      end
    end
  end
end



----------------
-- initilization
----------------



function init()

  params:add_number("bpm",15,400,60)

  ack.add_effects_params()

  for i=1,4 do
    ack.add_channel_params(i)
  end

  params:read("gittifer/polygrid.pset")

  -- metronome setup
  counter = metro.alloc()
  counter.time = 60 / (params:get("bpm") * ppq)
  counter.count = -1
  counter.callback = count
  --counter:start()

  -- supposed to show basic functionality/layout of grid
  g.all(0)
  for i=1, 4 do
    for n=1, math.random(16) do
      g.led(n, i*2 -1, 10)
    end
    for n=1, 16 do
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
    if tab.count(track[y]) == 0 or tab.count(track[y]) == nil then
      if x > 1 then
        return
      elseif x == 1 then
          track[y] = {}
          track[y][x] = {}
          track[y][x][x] = {sub=0, on=true}
        gridredraw()
      end
      return
    else
      if x == 16 and y % 2 == 1 then
        track[y] = {}
        return
      end
      if x > tab.count(track[y][ tab.count(track[y]) ]) then
        return
      else
        if y % 2 == 1 then
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
      if running == false then
        counter:start()
        running = true
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
      track[y] = {}
      for i = 1, math.max(first[y],second[y]) do
        track[y][i] = {}
        for n=1, i do
          track[y][i][n] = {sub=n-1, on=true}  -- subdivisions have to be indexed by 0
        end
      end
    end
  end

  gridredraw()
end



---------------------------
-- norns control functions
---------------------------



function enc(n,d)
  if n == 1 then
    params:delta("bpm",d)
    redraw()
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
  if position == 0 then -- for a pretty pulsing effect
    gridredraw()
    q_position = (q_position % 16) + 1
  end
  
  for i=2, 8, 2 do
    cnt = tab.count(track[i])
    if cnt == 0 or cnt == nil then
      return
    else
      if track[i][cnt][(q_position%cnt)+1].on == true then
        cnt = tab.count(track[i-1])
        if cnt == 0 or cnt == nil then
          return
        else
          for n=1, cnt do
            if position / ( ppq // (tab.count(track[i-1][cnt]))) == n then
              g.led(n,i-1,15)
              g.refresh()
              if track[i-1][cnt][n].on == true then
                -- for downbeat, makes it toggle-able
                engine.trig(i//2-1) -- samples are only 0-3
                g.led(n,i-1,8)
                g.refresh()
              else
                g.led(n,i-1,4)
                g.refresh()
              end
            end
          end
        end
      else
        -- pass
      end
    end
  end
end



---------------------------
-- refresh/redraw functions
---------------------------


function redraw()
  screen.clear()
  screen.move(0,5)
  screen.text("bpm:"..params:get("bpm"))
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
          g.led((q_position%ct)+1,i,15)
        end
      end
    end
  end

g.refresh()
end
