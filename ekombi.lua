-- Ekombi
--
--  polyrhythmic sampler
--
-- 
-- 4, two-track channels
-- ------------------------------------------
-- trackA: sets the length
-- of the tuplet
--
-- trackB: sets length of the
-- 'measure' in quarter notes
-- -------------------------------------------
--
-- grid controls
-- ---------------------------------
-- hold a key and press another
-- key in the same row to set
-- the length of the track
--
-- tapping gridkeys toggles the
-- tuplet subdivisions and
-- quarter notes on/off
-- -------------------------------------------
--
-- norns controls
-- -------------------------------------------
-- enc1: bpm
-- enc2: select pattern
-- enc3: filter cutoff
--
-- key1: save pattern
-- key2: load patter
-- key3: stop clock
-- ---------------------------------------------

engine.name = 'Ack'

local ack = require 'jah/ack'

local g = grid.connect()

--[[whats next?:
                - pattern saving/loading and view on norns in the works
                  currently works with parameter presets
                - continue optimizing
                - beatclock integration for midi sync
]]--

--[[current issues:
                  - are rhythms totally accurate?
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
ppq =  480 -- pulses per quarter

-- param variables
pattern_select = 1
pattern_display = "default"

-- grid variables
-- for holding one gridkey and pressing another further right
held = {}
heldmax = {}
done = {}
first = {}
second = {}
for row = 1,8 do
  held[row] = 0
  heldmax[row] = 0
  done[row] = 0
  first[row] = 0
  second[row] = 0
end

-- 4, two-track channels (A is even rows, TrackB is odd rows)
track = {}
for i=1,8 do
  if i % 2 == 1 then
    track[i] = {}
    track[i][1] = {}
    track[i][1][1] = false
  else
    track[i] = {}
    for n=1, 16 do
      track[i][n] = {}
      for j=1, 16 do
        track[i][n][j] = true
      end
    end
  end
end



----------------
-- initilization
----------------



function init()

  -- parameters
  params:add_number("bpm",15,400,60)

  ack.add_effects_params()

  for channel=1,4 do
    ack.add_channel_params(channel)
  end

  params:read("gittifer/ekombi.pset")

  -- metronome setup
  counter = metro.alloc()
  counter.time = 60 / (params:get("bpm") * ppq)
  counter.count = -1
  counter.callback = count
  -- counter:start()

  gridredraw()
  redraw()
end



-------------------------
-- grid control functions
-------------------------



function g.event(x, y, z)
  -- sending data to two separate functions
  gridkeyhold(x,y,z)
  gridkey(x,y,z)
end

function gridkey(x,y,z)
  if z == 1 then
  cnt = tab.count(track[y])

    -- error control
    if cnt == 0 or cnt == nil then
      if x > 1 then
        return
      elseif x == 1 then
          track[y] = {}
          track[y][x] = {}
          track[y][x][x] = true
        gridredraw()
      end
      return

    else
      -- track-B un-reset-able
      if x == 16 and y % 2 == 1 then
        track[y] = {}
        track[y][1] = {}
        track[y][1][1] = false
        return
      end

      -- note toggle on/off
      if x > cnt then
        return
      else
        if track[y][cnt][x] == true then
          track[y][cnt][x] = false
        else
          track[y][cnt][x] = true
        end
      end

      -- automatic clock startup
      if running == false then
        counter:start()
        running = true
      end

    end
  end
  gridredraw()
end



function gridkeyhold(x, y, z)
  if z == 1 and held[y] then heldmax[y] = 0 end
  held[y] = held[y] + (z*2-1)

  if held[y] > heldmax[y] then heldmax[y] = held[y] end

  if y > 8 and held[y]==1 then
      first[y] = x
  elseif y <= 8 and held[y] == 2 then
    second[y] = x
  elseif z == 0 then
    if y <= 8 and held[y] == 1 and heldmax[y]==2 then
      track[y] = {}
      for i = 1, second[y] do
        track[y][i] = {}
        for n=1, i do
          track[y][i][n] = true
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
  end
  
  if n == 2 then
    pattern_select = util.clamp(pattern_select + d, 1, 16)
    print("pattern"..pattern_select)
  end
  
  if n == 3 then
    for i=1, 4 do
      params:delta(i..": filter cutoff", d)
    end
  end
  
redraw()
end

function key(n,z)
local pset_str = ""

  if z == 1 then
    
    if n == 2 then
      if pattern_select < 10 then
        pset_str = ("gittifer/ekombi-0"..pattern_select..".pset")
      else
        pset_str = ("gittifer/ekombi-"..pattern_select..".pset")
      end
      params:read(pset_str)
      
      pattern_display = pattern_select
      
    end
    
    if n == 3 then
      if running then
        counter:stop()
        running = false
      else
        position = 0
        counter:start()
        running = true
      end
    end
    
  end

redraw()
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
  position = (position + 1) % (ppq)
  counter.time = 60 / (params:get("bpm") * ppq)
  if position == 0 then
    q_position = q_position + 1
    fast_gridredraw()
  end

  for i=2, 8, 2 do
    cnt = tab.count(track[i])
    if cnt == 0 or cnt == nil then
      return
    else
      if track[i][cnt][(q_position%cnt)+1] == true then
        cnt = tab.count(track[i-1])
          if cnt == 0 or cnt == nil then
            return
          else
            for n=1, cnt do
            if position / ( ppq // (tab.count(track[i-1][cnt]))) == n-1 then
              if track[i-1][cnt][n] == true then
                engine.trig(i//2 -1) -- samples are only 0-3
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
  
  screen.level(15)
    screen.move(0,5)
    screen.text("bpm:"..params:get("bpm"))
    screen.move(0,32)
    screen.level(15)
    screen.text("pattern:"..pattern_select)
    
    if not running then
      screen.rect(123,58,2,6)
      screen.rect(126,58,2,6)
      screen.fill()
    end
  
  screen.level(1)
    screen.move(128,5)
    screen.text_right(pattern_display)
  
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
          if track[i][ct][n] == true then
            g.led(n, i, 12)
          else
            g.led(n, i, 4)
          end

        elseif i % 2 == 0 then
          if track[i][ct][n] == true then
            g.led(n, i, 8)
          else
            g.led(n, i, 2)
          end
          g.led((q_position % ct) + 1, i, 15)
        end
      end
    end
  end

g.refresh()
end

function fast_gridredraw()

  for i=1, 8 do
    for n=1, tab.count(track[i]) do
      ct = tab.count(track[i])
      if ct == 0 or nil then return
      else
        if i % 2 == 0 then
          if track[i][ct][n] == true then
            g.led(n, i, 8)
          else
            g.led(n, i, 2)
          end
          g.led((q_position % ct) + 1, i, 15)
        end
      end
    end
  end

g.refresh()
end
