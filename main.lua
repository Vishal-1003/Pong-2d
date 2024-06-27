push = require 'push'
Class = require 'class'

require 'Paddle'
require 'Ball'

WINDOW_WIDTH = 1280
WINDOW_HEIGHT = 720

VIRTUAL_WIDTH = 432
VIRTUAL_HEIGHT = 243

PADDLE_SPEED = 200

MODE = 1

function love.load()
    -- use nearest-neighbor filtering on upscaling and downscaling to prevent blurring of text 
    -- and graphics; try removing this function to see the difference!
    love.graphics.setDefaultFilter('nearest', 'nearest')

    -- "seed" the RNG so that calls to random are always random
    -- use the current time, since that will vary on startup every time
    math.randomseed(os.time())

    -- set a new font 
    smallFont = love.graphics.newFont('font.ttf', 8)

    scoreFont = love.graphics.newFont('font.ttf',32)
    
    winnerfont = love.graphics.newFont('font.ttf',24) 
    -- initialize our virtual resolution, which will be rendered within our
    -- actual window no matter its dimensions; replaces our love.window.setMode call
    -- from the last example
    push:setupScreen(VIRTUAL_WIDTH, VIRTUAL_HEIGHT, WINDOW_WIDTH, WINDOW_HEIGHT, {
        fullscreen = false,
        resizable = false,
        vsync = true
    })

    player1=Paddle(10,30,5,20)
    player2 = Paddle(VIRTUAL_WIDTH - 10, VIRTUAL_HEIGHT - 30, 5, 20)

    player1Score=0
    player2Score = 0

    winnerNumber=0
    ball = Ball(VIRTUAL_WIDTH / 2 - 2, VIRTUAL_HEIGHT / 2 - 2, 4, 4)
    -- we will use this to determine behavior during render and update
    gameState = 'start'
end

function love.update(dt)
    if gameState =='play' then 
        --Player1 movement
        if love.keyboard.isDown('w') then 
            player1.dy = -PADDLE_SPEED
        elseif love.keyboard.isDown('s') then
            player1.dy = PADDLE_SPEED
        else
            player1.dy=0
        end
        --player2 movement
        if MODE==2 then
            if love.keyboard.isDown('up') then 
                player2.dy = -PADDLE_SPEED
            elseif love.keyboard.isDown('down') then
                player2.dy = PADDLE_SPEED
            else
                player2.dy=0
            end
        else
            if player2.y >0 then
                player2.y = math.max(5,ball.y+PADDLE_SPEED*dt)
            elseif player2.y <= VIRTUAL_HEIGHT-20 then
                player2.y = math.min(VIRTUAL_HEIGHT-20 , ball.y + PADDLE_SPEED*dt)
            end
        end
        

        if ball:collides(player1) then
            ball.dx = -ball.dx*1.1
            ball.x = player1.x+5

            -- keep velocity going in the same direction, but randomize it
            if ball.dy < 0 then
                ball.dy = -math.random(10, 150)
            else
                ball.dy = math.random(10, 150)
            end
        end
        if ball:collides(player2) then
            ball.dx = -ball.dx*1.1
            ball.x = player2.x  -5

            -- keep velocity going in the same direction, but randomize it
            if ball.dy < 0 then
                ball.dy = -math.random(10, 150)
            else
                ball.dy = math.random(10, 150)
            end
        end

        -- detect upper and lower screen boundary collision and reverse if collided
        if ball.y <= 0 then
            ball.y = 0
            ball.dy = -ball.dy
        end

        -- -4 to account for the ball's size
        if ball.y >= VIRTUAL_HEIGHT - 4 then
            ball.y = VIRTUAL_HEIGHT - 4
            ball.dy = -ball.dy
        end

        if ball.x<=0 then
            gameState = 'serve'
            player2Score =player2Score+1
            ball:reset()
        end

        if ball.x> VIRTUAL_WIDTH then
            gameState = 'serve'
            player1Score =player1Score+1
            ball:reset()
        end

        if player1Score ==5 then
            gameState= 'end'
            winnerNumber=1
        elseif player2Score ==5 then
            gameState= 'end'
            winnerNumber=2
        end

        ball:update(dt)
        player1:update(dt)
        if MODE==2 then
            player2:update(dt)
        end
        
    end
end


function love.keypressed(key)
    if key == 'escape' then
        -- function LÖVE gives us to terminate application
        love.event.quit()
    -- if we press enter during the start state of the game, we'll go into play mode
    -- during play mode, the ball will move in a random direction
    elseif key == 'enter' or key == 'return' then
        if gameState == 'start' then
            gameState = 'select'
        end

        if gameState=='serve' then
            gameState='play'   
        end
    end

    if key =='2' then
        if gameState == 'select' then
            MODE = 2
            gameState = 'serve'
        end
    end

    if key =='1' then
        if gameState == 'select' then
            MODE = 1
            gameState = 'serve'
        end
    end


end


function love.draw()
    -- begin rendering at virtual resolution
    push:apply('start')

    love.graphics.clear(40/255, 45/255, 52/255, 255/255)

    love.graphics.setFont(smallFont)
    if gameState == 'start' then
        love.graphics.printf('Press Enter to Start!!', 0, 20, VIRTUAL_WIDTH, 'center')
    end
    
    

    if gameState =='select' then
        love.graphics.setFont(smallFont)
        love.graphics.printf('Press 1 for 1p or 2 for 2p', 0, 20, VIRTUAL_WIDTH, 'center')
        
        love.graphics.setFont(scoreFont)
        love.graphics.print('1p', VIRTUAL_WIDTH / 2 - 50, VIRTUAL_HEIGHT / 3)
        
        love.graphics.print('2p', VIRTUAL_WIDTH / 2 + 30,VIRTUAL_HEIGHT / 3)
    end
    love.graphics.setColor(255/255, 255/255, 255/255, 255/255)

    if gameState=='serve' then
        love.graphics.setFont(smallFont)
        love.graphics.printf('Press Enter to Serve!!', 0, 20, VIRTUAL_WIDTH, 'center')
    end
    -- draw score on the left and right center of the screen
    -- need to switch font to draw before actually printing
    love.graphics.setFont(scoreFont)
    if gameState=='play' then
        love.graphics.print(tostring(player1Score), VIRTUAL_WIDTH / 2 - 50, 
        VIRTUAL_HEIGHT / 3)
        love.graphics.print(tostring(player2Score), VIRTUAL_WIDTH / 2 + 30,
            VIRTUAL_HEIGHT / 3)
    end

    -- render first paddle (left side)
    player1:render()

    -- render second paddle (right side)
    player2:render()

    -- render ball (center)
    ball:render()

    displayFPS()

    if gameState=='end' then
    love.graphics.setFont(winnerfont)
    love.graphics.setColor(0, 0, 255/255, 255/255)
        if winnerNumber == 1 then
            love.graphics.printf('Player 1 is winner',0, 20, VIRTUAL_WIDTH, 'center')
        else
            love.graphics.printf('Player 2 is winner',0, 20, VIRTUAL_WIDTH, 'center')
        end
    end
    -- end rendering at virtual resolution
    push:apply('end')
end


function displayFPS()
    -- simple FPS display across all states
    love.graphics.setFont(smallFont)
    love.graphics.setColor(0, 255/255, 0, 255/255)
    love.graphics.print('FPS: ' .. tostring(love.timer.getFPS()), 10, 10)
end