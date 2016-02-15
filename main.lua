-- LOW RENT SNAKE GAME
-- Really, it's just a test bed for playing with Shaders

function new(class, ...)
  local instance = setmetatable({}, class)
  if class.init then class.init(instance, ...) end
  return instance
end

function class(...)
  local super, body
  if select('#', ...) < 2 then body = ... else super, body = ... end
  local klass = body or {}
  if super then setmetatable(klass, super) end
  klass.__index = klass
  klass.new = new
  return klass
end

function translateDir(d)
  local k = d % 4
  if k == 1 then return 0, -1
  elseif k == 2 then return 1, 0
  elseif k == 3 then return 0, 1
  else return -1, 0 end
end

function clockwiseDir(d) if d == 4 then return 1 else return d + 1 end end
function counterwiseDir(d) if d == 1 then return 4 else return d -1 end end
function reverseDir(d) if d < 3 then return d + 2 else return d -2 end end

function drawArtBlob(drawRect, blob, x, y)
  for sy = 1, 4 do
    for sx = 1, 4 do
      if string.sub(blob[sy], sx, sx) ~= ' ' then
        drawRect(((x-1)*4) + (sx-1), ((y-1)*4) + (sy-1))
      end
    end
  end
end

function drawSquare(x, y)
  love.graphics.rectangle("fill", x + 0.1, y + 0.1, 0.8, 0.8)
end

--------------------------------------------------------------------------------
GameStack = class()
do
  function GameStack:init()
    self.stack = {}
  end
  function GameStack:push(mode)
    table.insert(self.stack, mode)
  end
  function GameStack:pop(mode)
    return table.remove(self.stack)
  end
  function GameStack:call(slot, stackId, ...)
    local mode = self.stack[stackId]
    if mode and type(mode[slot]) == 'function' then mode[slot](mode, ...) end
  end
  function GameStack:downCall(slot, mode, offset, ...)
    local id = 0
    for i = #self.stack, 1, -1 do
      if self.stack[i] == mode then
        id = i
        break
      end
    end
    self:call(slot, id - offset, ...)
  end
  function GameStack:update(...)
    self:call('update', #self.stack, ...)
  end
  function GameStack:draw(...)
    self:call('draw', #self.stack, ...)
  end
  function GameStack:keypressed(...)
    self:call('keypressed', #self.stack, ...)
  end
end

--------------------------------------------------------------------------------
Snake = class()
do
  function Snake:init(x, y, n, d)
    self.x = { x }
    self.y = { y }
    self.d = { d }
    self:append(n)
  end

  function Snake:move(dx, dy)
    local nx, ny = self.x[1] + dx, self.y[1] + dy
    table.remove(self.x)
    table.remove(self.y)
    table.remove(self.d)
    table.insert(self.x, 1, nx)
    table.insert(self.y, 1, ny)
    table.insert(self.d, 1, self.d[1])
    return self
  end

  function Snake:append(n)
    local lx, ly, ld = self.x[#self.x], self.y[#self.y], self.d[#self.d]
    for i = 1, n do
      self.x[#self.x+1] = lx
      self.y[#self.y+1] = ly
      self.d[#self.d+1] = ld
    end
  end

  function Snake:checkSelfCollision(nx, ny)
    for i = 1, #self.x do
      if self.x[i] == nx and self.y[i] == ny then
        return true
      end
    end
    return false
  end

  function Snake:checkOtherCollision(ox, oy)
    return (self.x[1] == ox and self.y[1] == oy)
  end

  function Snake:update()
    local dx, dy = translateDir(self.d[1])
    local hx, hy = self.x[1] + dx, self.y[1] + dy
    if hx < 1 or hx > 40 or hy < 1 or hy > 22 then
      return true
    elseif self:checkSelfCollision(hx, hy) then
      return true
    else
      self:move(dx, dy)
      return false
    end
  end

  local segmentArt = {
    ["00"] = { "    ",
               "### ",
               " ## ",
               "    " },
    ["01"] = { " #  ",
               "### ",
               " #  ",
               "    " },
    ["02"] = { "    ",
               "### ",
               " ###",
               "    " },
    ["03"] = { "    ",
               "##  ",
               " ## ",
               "  # " },
    ["10"] = { " #  ",
               "### ",
               " #  ",
               "    " },
    ["11"] = { " #  ",
               " ## ",
               " ## ",
               "    " },
    ["12"] = { " #  ",
               " ## ",
               "  ##",
               "    " },
    ["13"] = { " #  ",
               " ## ",
               " ## ",
               "  # " },
    ["20"] = { "    ",
               "### ",
               " ###",
               "    " },
    ["21"] = { " #  ",
               " ## ",
               "  ##",
               "    " },
    ["22"] = { "    ",
               " ## ",
               " ###",
               "    " },
    ["23"] = { "    ",
               "  # ",
               " ###",
               "  # " },
    ["30"] = { "    ",
               "##  ",
               " ## ",
               "  # " },
    ["31"] = { " #  ",
               " ## ",
               " ## ",
               "  # " },
    ["32"] = { "    ",
               "  # ",
               " ###",
               "  # " },
    ["33"] = { "    ",
               " ## ",
               " ## ",
               "  # " },
    ["HEAD0"] = { " ## ",
                  "# ##",
                  "####",
                  " ## " },
    ["HEAD1"] = { " ## ",
                  "#  #",
                  "####",
                  " ## " },
    ["HEAD2"] = { " ## ",
                  "## #",
                  "####",
                  " ## " },
    ["HEAD3"] = { " ## ",
                  "####",
                  "#  #",
                  " ## " },
  }

  function Snake:draw(drawRect)
    local N = #self.x
    drawArtBlob(drawRect, segmentArt[string.format("HEAD%i", self.d[1]%4)], self.x[1], self.y[1])
    for i = 2, N do
      local d1 = self.d[i]
      local d2 = reverseDir(self.d[i+1] or d1)
      local blob = segmentArt[string.format("%i", d1%4) .. string.format("%i", d2%4)]
      drawArtBlob(drawRect, blob, self.x[i], self.y[i])
    end
  end

  function Snake:changeDir(dir)
    local dx, dy = translateDir(dir)
    if (self.x[2] ~= (self.x[1] + dx)) or (self.y[2] ~= (self.y[1] + dy)) then
      self.d[1] = dir
    end
  end
end


--------------------------------------------------------------------------------
Food = class()
do
  function Food:init(x, y)
    self:moveTo(x, y)
  end

  function Food:moveTo(x, y)
    self.x = math.floor(x)
    self.y = math.floor(y)
  end

  local foodArt = { "    ", " ## ",  " ## ",  "    " }

  function Food:draw(drawRect)
    drawArtBlob(drawRect, foodArt, self.x, self.y)
  end
end

--------------------------------------------------------------------------------
PlayMode = class()
do
  function PlayMode:init(gameStack)
    self.gameStack = gameStack
    self.player = Snake:new(20, 11, 5, 1)
    self.food = Food:new(0, 0)
    self:placeFood()
    self.clock = 0
  end

  function PlayMode:update(dt)
    self.clock = self.clock + dt
    if self.clock >= 0.16 then
      self.clock = self.clock - 0.16
      local collision = self.player:update()
      if collision then
        self.gameStack:pop()
        self.gameStack:push(GameOverMode:new(self.gameStack))
      elseif self.player:checkOtherCollision(self.food.x, self.food.y) then
        self:placeFood()
        self.player:append(3)
      end
    end
  end

  function PlayMode:placeFood()
    local ny, nx, cc = 0, 0, 0
    for yy = 1, 22 do
      for xx = 1, 40 do
        if not self.player:checkSelfCollision(xx, yy) then
          cc = cc + 1
          if math.random(1, cc) == 1 then
            nx, ny = xx, yy
          end
        end
      end
    end
    self.food:moveTo(nx, ny)
  end

  function PlayMode:draw()
    self.player:draw(drawSquare)
    self.food:draw(drawSquare)
  end

  function PlayMode:keypressed(k)
    if k == "up" then self.player:changeDir(1) end
    if k == "right" then self.player:changeDir(2) end
    if k == "down" then self.player:changeDir(3) end
    if k == "left" then self.player:changeDir(4) end
    if k == "p" then self.gameStack:push(PauseMode:new(self.gameStack)) end
    if k == "f5" then self:placeFood() end
  end
end

--------------------------------------------------------------------------------
GameOverMode = class()
do
  function GameOverMode:init(gameStack)
    self.gameStack = gameStack
  end
  function GameOverMode:draw()
    love.graphics.print("GAMEOVER", 0, 0)
  end
  function GameOverMode:keypressed(k)
    if k == "return" or k == "enter" then
      self.gameStack:pop()
    end
  end
end

--------------------------------------------------------------------------------
TitleMode = class()
do
  function TitleMode:init(gameStack)
    self.gameStack = gameStack
  end
  function TitleMode:draw()
    love.graphics.print("SNAKE", 0, 0)
  end
  function TitleMode:keypressed(k)
    if k == "return" or k == "enter" then
      self.gameStack:push(PlayMode:new(self.gameStack))
    end
  end
end

--------------------------------------------------------------------------------
PauseMode = class()
do
  function PauseMode:init(gameStack)
    self.gameStack = gameStack
  end
  function PauseMode:draw()
    self.gameStack:downCall('draw', self, 1)
    love.graphics.print("PAUSE", 0, 0)
  end
  function PauseMode:keypressed(k)
    if k == "return" or k == "enter" or k == "p" then
      self.gameStack:pop()
    end
  end
end

--------------------------------------------------------------------------------
Shaders = class()
do
  function Shaders:init()
    self.shaders = {}
    self.shaderId = 1
  end

  function Shaders:reset()
    local sw = love.graphics.getWidth()
    local sh = love.graphics.getHeight()
    self.canvas = love.graphics.newCanvas(sw, sh)
    self.quad = love.graphics.newQuad(0, 0, sw, sh, sw, sh)
    self.shaders = {}
    local files = love.filesystem.getDirectoryItems("shaders")
    table.sort(files)
    for i,v in ipairs(files) do
      local filename, filetype = v:match("(.+)%.(.-)$")
      if filetype == "frag" then
        local name = "shaders".."/"..v
        if love.filesystem.isFile(name) then
          local str = love.filesystem.read(name)
          local success, effect = pcall(love.graphics.newShader, str)
          if success then
            print(("loaded shader %s"):format(filename))
            local defs = {}
            for vtype, extern in str:gmatch("extern (%w+) (%w+)") do
              defs[extern] = true
            end
            self.shaders[#self.shaders+1] = {
              shader = effect,
              filename = filename,
              str = str,
              defs = defs
            }
          else
            print(("shader (%s) is fucked up, yo:\n"):format(filename), effect)
          end 
        end
      end
    end
  end

  function Shaders:changeNext()
    self.shaderId = (self.shaderId % #self.shaders) + 1
    if self.shaderId > 0 and self.shaderId <= #self.shaders then
      print(("changing to shader %i (%s)"):format(self.shaderId, self.shaders[self.shaderId].filename))
    end
  end

  function Shaders:preDraw()
    love.graphics.setCanvas(self.canvas)
    love.graphics.clear()
  end

  function Shaders:postDraw()
    if self.shaderId > 0 and self.shaderId <= #self.shaders then
      love.graphics.setCanvas()
      local shaderT = self.shaders[self.shaderId]
      love.graphics.setShader(shaderT.shader)
      if shaderT.defs["size"] then
        local w = love.graphics.getWidth()
        local h = love.graphics.getHeight()
        shaderT.shader:send("size", { w, h })
      end
      love.graphics.setColor(255, 255, 255)
      love.graphics.draw(self.canvas, self.quad, 0, 0)
      love.graphics.setShader()
    end
  end
end


--------------------------------------------------------------------------------
do
  local gameMode, shaders

  function love.load()
    gameMode = GameStack:new()
    gameMode:push(TitleMode:new(gameMode))
    shaders = Shaders:new()
    shaders:reset()
  end

  function love.update(dt)
    gameMode:update(math.min(dt, 0.1))
  end

  function love.draw()
    local w = love.graphics.getWidth()
    local h = love.graphics.getHeight()
    shaders:preDraw()
    love.graphics.setColor(255, 255, 255)
    love.graphics.push()
    love.graphics.scale(w/800*5, h/450*5)
    gameMode:draw()
    love.graphics.pop()
    shaders:postDraw()
  end

  function love.keypressed(k)
    if k == "f10" then love.event.quit() end
    if k == "f3" then shaders:changeNext() end
    gameMode:keypressed(k)
  end

  function love.resize()
    shaders:reset()
  end
end

