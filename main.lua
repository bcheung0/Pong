-- Brian Cheung - Pong Project - based off of Pong-v3
push = require 'push'
Class = require "class"
require 'Paddle'
require 'Ball'

WINDOW_WIDTH = 1280
WINDOW_HEIGHT = 720

VIRTUAL_WIDTH = 432
VIRTUAL_HEIGHT = 243

Paddle_Speed = 250

--[[
    Runs when the game first starts up, only once; used to initialize the game.
]]
function love.load()
    love.window.setTitle('Pong - Brians Version')

    math.randomseed(os.time())
    love.graphics.setDefaultFilter('nearest', 'nearest')
    smallFont = love.graphics.newFont('font.ttf', 8)
    love.graphics.setFont(smallFont)
    scoreFont = love.graphics.newFont('font.ttf', 16)
    largeFont = love.graphics.newFont('font.ttf', 16)

    sounds = {
        ['paddle_hit'] = love.audio.newSource('sounds/Powerup2.wav', 'static'),
        ['score'] = love.audio.newSource('sounds/lose.wav', 'static'),
        ['wall_hit'] = love.audio.newSource('sounds/bounce.wav', 'static')
    }

    push:setupScreen(VIRTUAL_WIDTH, VIRTUAL_HEIGHT, WINDOW_WIDTH, WINDOW_HEIGHT, {
        fullscreen = false,
        resizable = true,
        vsync = true
    })
    -- creates Paddle objects 
    player1 = Paddle(10, 30, 5, 20)
    player2 = Paddle(VIRTUAL_WIDTH - 10, VIRTUAL_HEIGHT - 30, 5, 20)
    --move to ball classes
    ball = Ball(VIRTUAL_WIDTH / 2 - 2,VIRTUAL_HEIGHT / 2 - 2,4,4)
    player1Score = 0
    player2Score = 0

    servingPlayer=1
    gameState = 'start'
end

-- updates per delta time
function love.update(dt)
    if gameState == 'serve' then
        ball.dy = math.random(-50, 50)
        if servingPlayer == 1 then
            ball.dx = math.random(150, 200)
        else
            ball.dx = -math.random(150, 200)
        end
    elseif gameState =='play' then

        if ball:collision(player1) then
            ball.dx = -ball.dx * 1.03
            ball.x = player1.x + 5
    
            if ball.dy < 0 then
                ball.dy = -math.random(10, 150)
            else
                ball.dy = math.random(10, 150)
            end
            sounds['paddle_hit']:play()
        end
        if ball:collision(player2) then
            ball.dx = -ball.dx * 1.03
            ball.x = player2.x - 4
    
            if ball.dy < 0 then
                ball.dy = -math.random(10, 150)
            else
                ball.dy = math.random(10, 150)
            end
            sounds['paddle_hit']:play()
        end
        -- windows edge collision detection
        if ball.y <= 0 then
            ball.y = 0
            ball.dy = -ball.dy
            sounds['wall_hit']:play()
        end
    
        if ball.y >= VIRTUAL_HEIGHT - 4 then
            ball.y = VIRTUAL_HEIGHT - 4
            ball.dy = -ball.dy
            sounds['wall_hit']:play()
        end

        -- player 1 movement
        if love.keyboard.isDown('w') then
            player1.dy = -Paddle_Speed
        elseif love.keyboard.isDown('s') then
            player1.dy = Paddle_Speed
        else
            player1.dy = 0    
        end

        -- player 2 movement
        if love.keyboard.isDown('up') then
            player2.dy = -Paddle_Speed
        elseif love.keyboard.isDown('down') then
            player2.dy = Paddle_Speed
        else
            player2.dy = 0
        end


        -- scoring
        if ball.x < 0 then
            servingPlayer = 1
            player2Score = player2Score + 1
            sounds['score']:play()
    
            if player2Score == 5 then
                winningPlayer = 2
                gameState = 'done'
            else
                gameState = 'serve'
                ball:resetGame()
            end
        end
    
        if ball.x > VIRTUAL_WIDTH then
            servingPlayer = 2
            player1Score = player1Score + 1
            sounds['score']:play()
            if player1Score == 5 then
                winningPlayer = 1
                gameState = 'done'
            else
                gameState = 'serve'
                ball:resetGame()
            end
        end

        if gameState == 'play' then
            ball:update(dt)
        end

        player1:update(dt)
        player2:update(dt)
    end
end

function love.keypressed(key)
    -- keys can be accessed by string name
    if key == 'escape' then
        -- function LÖVE gives us to terminate application
        love.event.quit()
    elseif key == 'enter' or key == 'return' then
        if gameState == 'start' then
            gameState = 'serve'
            
        elseif gameState == 'serve' then
            gameState = 'play'

        elseif gameState == 'done' then
            gameState = 'serve'
            ball:resetGame()
  
            player1Score = 0
            player2Score = 0
  
            if winningPlayer == 1 then
                servingPlayer = 2
            else
                servingPlayer = 1
            end    
        end
    end        
end



function love.draw()
    -- begin rendering at virtual resolution
    push:apply('start')

    -- clear the screen with a specific color; in this case, a color similar
    -- to some versions of the original Pong
    love.graphics.clear(40/255, 45/255, 52/255, 255/255)

    if gameState == 'start' then
        love.graphics.printf('Press Enter to Start!', 0, 20, VIRTUAL_WIDTH, 'center')
    elseif gameState == 'serve' then 
        love.graphics.setFont(smallFont)
        love.graphics.printf('Player ' .. tostring(servingPlayer) .. "'s serve!", 
            0, 10, VIRTUAL_WIDTH, 'center')
        love.graphics.printf('Press Enter to serve!', 0, 20, VIRTUAL_WIDTH, 'center')    
    elseif gameState == 'done' then
        love.graphics.setFont(largeFont)
        love.graphics.printf('Player ' .. tostring(winningPlayer) .. ' wins!', 0, 10, VIRTUAL_WIDTH, 'center')
        love.graphics.setFont(smallFont)
        love.graphics.printf('Press Enter to restart!', 0, 30, VIRTUAL_WIDTH, 'center')
    elseif gameState == 'play' then     
    end

    love.graphics.setFont(smallFont)
    -- draws score
    love.graphics.setFont(scoreFont)
    love.graphics.print(tostring(player1Score), VIRTUAL_WIDTH / 2 - 50, VIRTUAL_HEIGHT / 4)
    love.graphics.print(tostring(player2Score), VIRTUAL_WIDTH / 2 + 30, VIRTUAL_HEIGHT / 4)
    
    -- render paddles and balls using methods from class
    player1:render()
    player2:render()

    ball:render()
    displayFPS()

    -- end rendering at virtual resolution
    push:apply('end')
end

-- Green FPS counter
function displayFPS()
    love.graphics.setFont(smallFont)
    love.graphics.setColor(0, 255/255, 0, 255/255)
    love.graphics.print('FPS: ' .. tostring(love.timer.getFPS()), 10, 10)
end

function love.resize(w, h)
    push:resize(w, h)
end
