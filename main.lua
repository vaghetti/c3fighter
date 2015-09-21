local socket = require "socket"
local entity -- entity is what we'll be controlling
local updaterate = 0.01 -- how long to wait, in seconds, before requesting an update
local t,fx,fy

graficos = {
		bauru = love.graphics.newImage("gfx/bauru.png"),
		bicho = love.graphics.newImage("gfx/bicho.png"),
		celso = love.graphics.newImage("gfx/celso.png"),
		glauber = love.graphics.newImage("gfx/glauber.png"),
		pedro = love.graphics.newImage("gfx/pedro.png"),
		silvia = love.graphics.newImage("gfx/silvia.png"),
		vagner = love.graphics.newImage("gfx/vagner.png"),
		ze = love.graphics.newImage("gfx/ze.png"),
	}

local function recebeMensagem()
	data, msg = udp:receive()
 
	if data then 
		ent, cmd, parms = data:match("^(%S*) (%S*) (.*)")
		if cmd == 'at' then
			local x, y = parms:match("^(%-?[%d.e]*) (%-?[%d.e]*)$")
			assert(x and y) 
			x, y = tonumber(x), tonumber(y)
			if objects[ent] then
				objects[ent].x = x
				objects[ent].y = y
			else
				objects[ent] = loadPlayer(x,y,graficos["bauru"])
			end
		else
			print("unrecognised command:", cmd)
		end
	elseif msg ~= 'timeout' then 
		error("Network error: "..tostring(msg))
	end

	return data~= nil
end

function love.load(args)
	
	objects = {}
	COEFICIENTEFORCA = 5

	udp = socket.udp()
	udp:settimeout(0)
	if #args ~=3 then
		print("modo de uso: (na pasta do jogo) love . ipservidor professor")
		love.event.quit()
	end
	local ip_servidor = args[2]
	local professor = args[3]
	if graficos[professor]==nil then
		print("professor desconhecido")
		love.event.quit()
	end
	print ("iniciando cliente, servidor =  ",ip_servidor, "professor = ",professor)
	udp:setpeername(ip_servidor, 12345)
	math.randomseed(os.time())
	euMesmo = tostring(math.random(99999))

	local init = string.format("%s %s %s", euMesmo, 'init', professor)
	udp:send(init)
	t = 0 -- (re)set t to 0
	retorno = false
	while not retorno do
		retorno = recebeMensagem() --espera a primeira posição
	end

end



function love.draw()
	love.graphics.setColor(255,0, 0)
	love.graphics.setLineWidth(10.0)
	if( fx and fy ) then 
		love.graphics.print("fx = "..fx.." fy = "..fy,10,10)
	end
    love.graphics.circle("line", love.window.getWidth()/2, love.window.getHeight()/2, 300, 100); -- Draw white circle with 100 segments.
	for i,v in pairs(objects) do
		v.draw()	
	end
end

local function clamp(x,minx,maxx)
	return math.max(minx,math.min(maxx,x))
end

function love.update(dt)
	
	t = t + dt
	local maxForca = 200
	if t > updaterate then
		fx = ((love.mouse.getX()-objects[euMesmo].x))*COEFICIENTEFORCA
		fy = ((love.mouse.getY()-objects[euMesmo].y))*COEFICIENTEFORCA
		fx = clamp(fx,-maxForca,maxForca)
		fy = clamp(fy,-maxForca,maxForca)
		local dg = string.format("%s %s %f %f", euMesmo, 'update', fx, fy)
		udp:send(dg)
		t=t-updaterate -- set t for the next round
	end
	local retorno
	repeat
		retorno = recebeMensagem()
	until not retorno 
end



local function drawCauda(cauda,tamMax,tamanhoCauda)

	for i,v in ipairs(cauda) do

		love.graphics.setColor(255, 255, 255,math.max((i/tamanhoCauda)*255-20,20))
		love.graphics.circle("fill", v.x, v.y, (tamMax-5)*(i/tamanhoCauda)+5)
	end
end

local function geraFuncaoDraw(grafico,raio,player)
	local escala = 2*raio/grafico:getWidth()
	local cauda = {}
	return  function() 
				drawCauda(cauda,grafico:getWidth()*escala/2,20)
				love.graphics.draw(grafico,player.x,player.y,0,escala,escala,grafico:getWidth()/2,grafico:getWidth()/2)
				--TODO: AJUSTAR O ANGULO TAMBEM
				table.insert(cauda,{x=player.x,y=player.y})
				if #cauda==20 then table.remove(cauda,1) end
	end
end	

function loadPlayer(x,y,grafico)     
	local player = {}
	player.x = x
	player.y = y
	player.draw = geraFuncaoDraw(grafico,40,player)     
	return player 
end
