
local tiles = {}
local size = 120
local light = {x = 32, y = 32}

function getTile(x, y)
  if tiles[x] and tiles[x][y] then return tiles[x][y] end
end

love.math.setRandomSeed(love.timer.getTime())

function shadowcompare(map, coverage)
  local maxVisibility = coverage.max - coverage.min
  local visibility = maxVisibility
  for i, v in pairs(map) do
    if (v.max <= coverage.max and v.max >= coverage.min) then
      visibility = visibility - v.max + math.max(coverage.min, v.min)
    elseif (v.min >= coverage.min and v.min <= coverage.max) then
      visibility = visibility - (coverage.max - v.min)
    elseif (v.min <= coverage.min and v.max >= coverage.max) then
      visibility = 0
    end
  end
  return visibility / maxVisibility
end

function shadowexpand(map, amount)
  for i, v in pairs(map) do
    v.min = v.min * amount
    v.max = v.max * amount
  end
end

function shadowmerge(map, lastI)
  for i, v in pairs(map) do
    if i ~= lastI then
      if (v.max <= coverage.max and v.max >= coverage.min) then
        v.max = coverage.max
        merged = true
      elseif (v.min >= coverage.min and v.min <= coverage.max) then
        v.min = coverage.min
        merged = true
      elseif (v.min <= coverage.min and v.max >= coverage.max) then
        merged = true
      end
    end
  end
end

function shadowinsert(map, coverage)
  local merged = false
  for i, v in pairs(map) do
    if (v.max <= coverage.max and v.max >= coverage.min) then
      v.max = coverage.max
      merged = true
    elseif (v.min >= coverage.min and v.min <= coverage.max) then
      v.min = coverage.min
      merged = true
    elseif (v.min <= coverage.min and v.max >= coverage.max) then
      merged = true
    end
  end
  if merged then

  else
    table.insert(map, coverage)
  end
end

function shadowprint(map)
  print('map: ')
  for i, v in pairs(map) do
    print(v.min, v.max)
  end
  print('...')
end

function octant(origin, move, grow, range)
  local shadowmap = {}
  for scanForward = 1, range do
    shadowexpand(shadowmap, (scanForward + 1) / scanForward)
    for scanSide = 0, scanForward do
      local tileX = origin.x + move.x * scanForward + grow.x * scanSide
      local tileY = origin.y + move.y * scanForward + grow.y * scanSide
      local tile = getTile(tileX, tileY)
      if tile then
        local coverage = {min = scanSide, max = scanSide + 1}
        local visibility = shadowcompare(shadowmap, coverage)
        visibility = math.max(math.min(visibility, 1), 0)
        if tile.checked > 0 then
          tile.light = tile.light * visibility
        else
          tile.checked = 1
          tile.light = visibility * (1 - math.sqrt(scanForward * scanForward + scanSide * scanSide) / range)
        end
        if (tile.light > 0.25) then
          tile.discovered = 1
        end
        if (tile.wall > 0) then
          shadowinsert(shadowmap, coverage)
        end
      end
    end
  end
end

function lightup(position, range)
  octant(position, {x = 1, y = 0}, {x = 0, y = 1}, range)
  octant(position, {x = 1, y = 0}, {x = 0, y = -1}, range)
  octant(position, {x = -1, y = 0}, {x = 0, y = 1}, range)
  octant(position, {x = -1, y = 0}, {x = 0, y = -1}, range)
  octant(position, {x = 0, y = 1}, {x = 1, y = 0}, range)
  octant(position, {x = 0, y = 1}, {x = -1, y = 0}, range)
  octant(position, {x = 0, y = -1}, {x = 1, y = 0}, range)
  octant(position, {x = 0, y = -1}, {x = -1, y = 0}, range)
end

function renderLights()
  for x = 0, size do
    for y = 0, size do
      tiles[x][y].light = 0
      tiles[x][y].checked = 0
    end
  end
  lightup(light, 16)
end

function digHoles()
  local walkAmount = 400
  local current = {x = light.x, y = light.y}
  for i = 1, walkAmount do
    local tile = getTile(current.x, current.y)
    if tile then
      tile.wall = 0
    end
    if love.math.random() >= 0.5 then
      current.x = current.x + math.floor(love.math.random() * 2) * 2 - 1
    else
      current.y = current.y + math.floor(love.math.random() * 2) * 2 - 1
    end
  end
end

function love.load()
  tiles = {}
  for x = 0, size do
    tiles[x] = {}
    for y = 0, size do
      tiles[x][y] = {light = 0, wall = 1, discovered = 0, checked = 0}
    end
  end
  digHoles()
  renderLights()
end

function love.keypressed(key, scancode, isrepeat)
  if (not isrepeat) then
    if scancode == 'left' then
      light.x = light.x - 1
      renderLights()
    end
    if scancode == 'right' then
      light.x = light.x + 1
      renderLights()
    end
    if scancode == 'up' then
      light.y = light.y - 1
      renderLights()
    end
    if scancode == 'down' then
      light.y = light.y + 1
      renderLights()
    end
  end
end

function love.update(deltaTime)

end

function love.draw()
  for x = 0, size do
    for y = 0, size do
      local tile = tiles[x][y]
      local lit = math.max(tile.light, tile.discovered * 0.25)
      love.graphics.setColor(lit, lit - tile.wall, lit - tile.wall, 1)
      love.graphics.rectangle('fill', x * 8, y * 8, 8, 8)
    end
  end
  love.graphics.setColor(0, 0, 1, 1)
  love.graphics.rectangle('fill', light.x * 8, light.y * 8, 8, 8)
  love.graphics.setColor(1, 1, 1, 1)
  love.graphics.print(love.timer.getFPS(), 0, 0)
end
