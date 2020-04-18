pico-8 cartridge // http://www.pico-8.com
version 21
__lua__
-- Ludum Dare 46
-- by Josh S and Sam B

-- (^can change later)

-- FLAGS
-- 0x1 COLLIDABLE

--SETUP
pal(13,139,1) --palette recolouring
pal(2,131,1)
poke(0x5F2D, 1) --enable mouse
click = false
oldclick = false
screenx = 64
screeny = 64
screenborder = 32 -- how close guy can get before moving screen
worldsizex = 256 --size of arena in pixels
worldsizey = 256
bulletspeed = 0.5
bulletlife = 40 -- life of bullet in frames

--EFFECTS
screen_shake = 0
screen_shake_decay = 1

cls() -- clear screen

player = {
  dx = 0,
  dy = 0,
  x = 128,
  y = 128,
  accel = 0.4,
  maxspd = 1.8,
  sprite = 64
}

bullets={}
--(posx,posy,dx,dy,spritenum)

score = 0
kills = 0

function check_collisions(x, y, dx, dy, in_x) -- assume width=height=8
  if (in_x) then
    checkx = x + dx + ((dx > 0) and 8 or 0)
    tilex = checkx / 8
    return (checkx > worldsizex or checkx < 0 or fget(mget(tilex, y / 8), 0) or fget(mget(tilex, (y+7.9) / 8), 0))
  else
    checky = y + dy + ((dy > 0) and 8 or 0)
    tiley = checky / 8
    return (checky > worldsizey or checky < 0 or fget(mget(x / 8, tiley), 0) or fget(mget((x+7.9) / 8, tiley), 0))
  end
end

playerstill = true

wateranimframes = 0

function control_player()
  x = 0
  y = 0

  if(btn(4)) and wateranimframes == 0 then 
    wateranimframes = 30
    sfx(7)
  end

  if wateranimframes == 0 then 
    if (btn(0)) x -= 1
    if (btn(1)) x += 1
    if (btn(2)) y -= 1
    if (btn(3)) y += 1
  end

  playerstill = x==0 and y==0

  if (x == 0) then
    if abs(player.dx) < player.accel then
      player.dx = 0
    else
      sign = player.dx / abs(player.dx)
      player.dx -= sign * player.accel
    end
  else
    player.dx += x * player.accel
  end
  if (y == 0) then
    if abs(player.dy) < player.accel then
      player.dy = 0
    else
      sign = player.dy / abs(player.dy)
      player.dy -= sign * player.accel
    end
  else
    player.dy += y * player.accel
  end
  -- clamp
  spd = sqrt(player.dx*player.dx + player.dy*player.dy) / player.maxspd
  if (spd > 1) then
    player.dx /= spd
    player.dy /= spd
  end

  if (abs(player.dx) > 0 and check_collisions(player.x, player.y, player.dx, player.dy, true)) then
    player.x += player.dx
    player.x = ((player.x \ 8) * 8) + ((player.dx < 0) and 8 or 0)
  else
    player.x += player.dx
  end
  if (abs(player.dy) > 0 and check_collisions(player.x, player.y, player.dx, player.dy, false)) then
    player.y += player.dy
    player.y = ((player.y \ 8) * 8) + ((player.dy < 0) and 8 or 0)
  else
    player.y += player.dy
  end

  -- if (pl.t%4) == 0) then
  --  sfx(1)
  -- end
end

function update_mouse()
  mousex=stat(32)
  mousey=stat(33)
  lmbdown=(stat(34)%2==1)
  click = lmbdown and oldclick != lmbdown
  oldclick = lmbdown

  if (click) add_bullet()
end

function add_bullet()
  sfx(0, 3)
  dx = mousex + screenx - player.x
  dy = mousey + screeny - player.y
  mag = sqrt(dx*dx + dy*dy) * bulletspeed
  if abs(dx)>abs(dy) 
  then if dx>0 then sprite = 0 else sprite = 2 end
  else if dy>0 then sprite = 3 else sprite = 1 end
  end
  add(bullets, {
    x = player.x,
    y = player.y,
    dx = dx/mag,
    dy = dy/mag,
    sprite = sprite,
    life = bulletlife,
    dead = false
  })

  screen_shake = 10
end

function update_bullets()
  deadbullet = nil
  for b in all(bullets) do
    if (not b.dead) then
      b.x += b.dx
      b.y += b.dy
      b.life -= 1
      b.sprite = 32+(b.sprite-28) %8 --cycle sprite
      b.dead = (b.life < 0) or check_collisions(b.x, b.y, b.dx, b.dy, false) or check_collisions(b.x, b.y, b.dx, b.dy, true)
    else
      deadbullet = b
    end
  end
  if (deadbullet != nil) del(bullets, deadbullet)
end

weaponsprite = 65

function _update()
  control_player()

  update_mouse()

  update_bullets()

  if wateranimframes==0 then
    weaponsprite = 65
  else
    if wateranimframes > 5 and wateranimframes < 25 then
      weaponsprite = 68
      --WATER PARTICLES
    else weaponsprite = 67
    end
    wateranimframes -= 1
  end

  --move screen
  pxs = player.x - screenx
  pys = player.y - screeny
  screenx = min(max( screenx + max(pxs-128+screenborder,0) - max(screenborder-pxs,0) ,0), worldsizex-128)
  screeny = min(max( screeny + max(pys-128+screenborder,0) - max(screenborder-pys,0) ,0), worldsizey-128)

  --update effects
  screen_shake_x = rnd(screen_shake*2) - screen_shake
  screen_shake_y = rnd(screen_shake*2) - screen_shake
  screen_shake = max(screen_shake - screen_shake_decay, 0)
end

function draw_sprite(spriteno, x, y, flip_x)
  flip_x = flip_x or false
  spr(spriteno, x - screenx + screen_shake_x, y - screeny + screen_shake_y, 1, 1, flip_x)
end

t = 0
function draw_object(obj)
  spr(obj.sprite, obj.x - screenx + screen_shake_x, obj.y - screeny + screen_shake_y, 1, 1, obj.flip_x or false)
end

function _draw()
  sx = screenx - screen_shake_x
  sy = screeny - screen_shake_y
  ox = sx%8
  oy =  sy%8
  map((sx-ox)/8,(sy-oy)/8,-ox,-oy)

  --doomguy
  pxs = player.x - screenx
  pys = player.y - screeny
  if playerstill then player.sprite = 96 + (t \ 5)%5
  else player.sprite = 80 + (t \ 5)%2
  end
  draw_object(player)

  --weapon 
  if mousex <= pxs
  then draw_sprite(weaponsprite, player.x - 8, player.y) --right hand
  else draw_sprite(weaponsprite, player.x + 8, player.y, true) --left hand
  end

  for b in all(bullets) do
    if (not b.dead) draw_object(b)
  end

  --UI
  if oldclick then ret = 17 else ret = 16 end
  spr(ret, mousex-3, mousey-3)

  print("score: "..score, 2,2, 7)
  spr(46, 2,110, 2,2)
  rect(20,115, 122,122, 7) --health bar
  rectfill(21,116, 121,121, 14)

  spr(45, 105,1)--kills
  print(kills, 115,2, 7) 

  score=t --TEMP
  kills = 100+t\10
  t+=1
end


__gfx__
0000000000ff0ff044444444bbbbbbbb000000004444444400000000ffffffffffffff3333333333333333333333333333ffffff33ffffffffffffffffffff33
0700007000ff0ff04444444433333333000000004444444400000000ffffffffffffff3333333333333333333333333333ffffff33ffffffffffffffffffff33
0070070000fffff042444444b3b3b3b3000000004444444400000000ffffffffffffff33ffffff33ffffffff33ffffff33ffffff33ffffffffffffffffffff33
0007700000f1ff104444444433333333000000004444424400000e00ffffffffffffff33ffffff33ffffffff33ffffff33ffffff33ffffffffffffffffffff33
0007700000fffff0444444442222222200070000444424240000e7e0ffffffffffffff33ffffff33ffffffff33ffffff33ffffff33ffffffffffffffffffff33
00700700000444004444424444444444007a70004444424400000e00ffffffffffffff33ffffff33ffffffff33ffffff33ffffff33ffffffffffffffffffff33
07000070000999004444444444444444000700004444444400000300ffffffffffffff33ffffff33ffffffff33ffffff33ffffff333333333333333333333333
00000000000f0f004444444444444444000b00004444444400000b00ffffffffffffff33ffffff33ffffffff33ffffff33ffffff333333333333333333333333
00000000000000000000000000000000000000000000000000000000333333330000000000000000000000000000000000000000000000000000000000000000
060006000c000c000000000000000000000000000000000000000000333333330000000000000000000000000000000000000000000000000000000000000000
0060600000c0c0000000000000000000000000000000000000000000333333330000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000333333330000000000000000000000000000000000000000000000000000000000000000
0060600000c0c0000000000000000000000000000000000000000000333333330000000000000000000000000000000000000000000000000000000000000000
060006000c000c000000000000000000000000000000000000000000333333330000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000333333330000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000333333330000000000000000000000000000000000000000000000000000000000000000
00000000000c70000000000000c0c00000000000000c70000000000000c0c000000000000000000000000000000000000000000070000007000000eeee000000
0000000000cc7000000000000000c0000000000000cc70000000000000cc000000000000000000000000000000000000000000000777777000000eeeeee00000
c00cc77000ccc0000cc770c0000c00000c0c777000ccc0000cc77007000cc00000000000000000000000000000000000000000000766766000000eeeeee00000
00ccccc700ccc000cccccc0000ccc0000cccccc700ccc000ccccccc000ccc00000000000000000000000000000000000000000000766766000000eeeeee0eee0
c700ccc000cc0000cccc00c700cc7000c0c0ccc000c07000cccc0ccc00cc70000000000000000000000000000000000000000000077777700eee0eeeeeeeeeee
00000000000c00000000000000cc700000000000000cc0000000000000cc7000000000000000000000000000000000000000000000767600eeeeee9aaaeeeeee
000000000000700000000000007cc00000000000000c000000000000007cc000000000000000000000000000000000000000000000767600eeeee9aa9aaeeeee
0000000000c0c00000000000000c0000000000000000c00000000000000c0000000000000000000000000000000000000000000077777700eeeee9a9a9aeeeee
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000eeeee9aa9aaeeee0
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000eeee99aaa9eee00
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000eee9999eee000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000eeeeeeeeeee00
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000eeeeeeeeeeeee0
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000eeeeee0eeeeee0
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000eeeeee00eeeee0
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000eee0000eeee00
0000000000000000eeeeeeee00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000bbb0eeeeeeee00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000bbb0eeeeeeee00006000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000009ccccceeeeeeee06066660000600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000c03eeeeeeee00666603000666630000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000cee0000ee00066660066666060000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000666600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000ee0000ee00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00333d0000333d0000333d0000333d00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
031112d0031112d0033333d0033333d0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00311300003113000033330000333300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
03559530035595300355553003555530000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
30333303303333033033330330333303000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00533500005335000053350000533500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00300500005003000030050000500300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000300003000000000030000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00333d00000000000000000000333d00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
031112d000333d0000333d00033333d000333d0000333d0000000000000000000000000000000000000000000000000000000000000000000000000000000000
00311300031112d0031112d000333300033333d0033333d000000000000000000000000000000000000000000000000000000000000000000000000000000000
03559530035115300031130003555530035335300033330000000000000000000000000000000000000000000000000000000000000000000000000000000000
30333303303593030355953030333303303553030355553000000000000000000000000000000000000000000000000000000000000000000000000000000000
00533500005335003033330300533500005335003033330300000000000000000000000000000000000000000000000000000000000000000000000000000000
00500500005005000053350000500500005005000053350000000000000000000000000000000000000000000000000000000000000000000000000000000000
00300300003003000030030000300300003003000030030000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
67677775066666666666666066666666777777757750000067777775500000006776777700000000000000000000000000000000000000000000000000000000
67676775676777777776677577777767776776757500000006776777750000000677677600000000000000000000000070000000000000000000000000000000
67776765677767666677767577667777767776755000000000677677775000000067776700000000000000000000000000000000000000000000000000000000
67777775677777777777777577776677777767750000000000067767777500000006777500000000000000000000000000000000000000000000000000000000
66777775676777677767767576677777777777500000000000006777677755550000675000000000000000000000000000000000000000000000000000000000
66767775667676777776767577767777767775000000000000000677767677770000050000000000000000000000000000000000000000000000000000000000
67767765677677777676776577777667777750000000000000000067777767770000000000000000000000000000000000000000000000000000000000000000
67677765676777756777776555555555777500000000000000000006767776770000000000000000000000000000000000000000000000000000000000000000
00000000000006666660000000000000677777770000067767777775000000067777677500000000000000000000000000000000000000000000000000000000
00000000000000677600000000000000676777670000006777767750000000676776775000000000000000000000000000000000000000000000000000000000
00000000000000677600000000000000676777770000000677677500000006777677750000000000000000000000000000000000000000000000000000000000
000000000000000660000000000000006776777700000000767750000000677767775000000000000000000000000000001d2c001c3c2c1c3c2c1c2c1c002d00
00000000000000066000000000000000067776770000000077750000666677760675000000000000000000000000000000000000000000000000000000000000
00000000000000066000000000000000006777670000000077500000777777670050000000000000000000000000000000000c000c000c0c000c0c0c0c0c0000
00000000000000066000000000000000000677770000000075000000777776770000000000000000000000000000000000000000000000000000000000000000
00000000000000066000000000000000000067670000000050000000776777760000000000000000000000000000000000000c000c000c0c000c0c0c0c0c0000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000c006c7c4c4d7d6d000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000c6d008c5c5d8d00000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000006d00000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00001fffff1f000000001fffff1f0000666666666666666633333b3333333b330000144444140000000014444414000055555555555555556666676666666766
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
f0808f8f8f8f80f0f0808f8f8f8f80f0666566666666666665656565656565654090949494949040409094949494904055515555555555555151515151515151
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000e8e8e8e8000000e0e8e8e8e8e000666666666656666666666666666666660000a9a9a9a9000000a0a9a9a9a9a00555555555551555555555555555555555
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00004e00004e000004000000000000046666666666666666666666666666666600008a00008a0000080000000000000855555555555555555555555555555555
__gff__
0000010103010000000000000000000000000000000000010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__map__
1717171717171717171717171717171717171717171717171717171717171717000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1707070707070707070707070707070707070707070707070707070707070717000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1707070707070707070707070707070707070707070707070707070707070717000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1707070707070707070707070707070707070707070707070707070707070717000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1707070707070707070707070707070707070707070707070707070707070717000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1707070707070707070707070707070707070707070707070707070707070717000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1707070707070707070707070707070707070707070707070707070707070717000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1707070707070707010707070707070707070707070707070707070707070717000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1707070707070707070707070707070707070707070707070707070707070717000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1707070707070707070707070707070707070707070707070707070707070717000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1707070707070707070707070707070707070707070707070707070707070717000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1707070707070707070707070707070707070707070707070707070707070717000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1707070707070707070707070707070707070707070707070707070707070717000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1707070707070707070707070707070707070707070707070707070707070717000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1707070707070707070707070707070707070707070707070707070707070717000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1707070707070707070707070707060606070707070707070707070707070717000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1707070707070707070707070707060606070707070707070707070707070717000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1707070707070707070707070707060606070707070707070707070707070717000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1707070707070707070707070707070707070707070707070707070707070717000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1707070707070707070707070707070707070707070707070707070707070717000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1707070707070707070707070707070707070707070707070707070707070717000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1707070707070707070707070707070707070707070707070707070707070717000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1707070707070707070707070707070707070707070707070707070707070717000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1707070707070707070707070707070707070707070707070707070707070717000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1707070707070707070707070707070707070707070707070707070707070717000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1707070707070707070707070707070707070707070707070707070707070717000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1707070707070707070707070707070707070707070707070707070707070717000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1707070707070707070707070707070707070707070707070707070707070717000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1707070707070707070707070707070707070707070707070707070707070717000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1707070707070707070707070707070707070707070707070707070707070717000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1707070707070707070707070707070707070707070707070707070707070717000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1717171717171717171717171717171717171717171717171717171717171717000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__sfx__
000400002c620280301e620180100d610160100a600300003500027000270002b000290002b000300003300001000010000100001000010000100001000010000100001000010000100001000000000000000000
0105000011653086510b351094520b4520c4320c4220c4220c4220c4220c4220c4220c4220c4220c4220c4220c4220c4220c4220c4220c4220c42200402004020040200400004000040000400004000040000400
000500000b26004050000400003000020000200001000010000100000006000000000500000000040000400004000040000400004000040000400000000000000000000000000000100001000010000000000000
000100003c670386603665032650306402b6302b630286202762025620216201f6101d6101c6101b6101b6101a6101a61019610196000f6000b60009600086001d60000600006000060026600006000060000600
01100000290700000000000000002d0700000000000000002b0700000029070000002607000000240700000022070000001c0701d070000000000000000000000000000000000000000000000000000000000000
010500001875021750247501874021740247401873021730247301872021720247201871021710247102471000000000030000000000000000000000000000000000000000000000000000000000000000000000
000300001e64022650256501f6400e6300c63011630156201b620176200f6200a61007610076100a6100161000610006000060001600016000060001600006000060000000000000000000000000000000000000
010700000000000000146101f6102461023610256102261024610266102361026610226101c6101e6101861012610086100360000600016000160000600237003b600027002e7003670033600006000000000000
01100000189501895018950189521895200000000001a9501a9501a9521b9501b9501b9521b9521b95200000189501895018950189501895000000000001b9501b9501b9501a9501a9501a9501a9501a95000000
011000100ca500ca5039b1339b131bb501bb5034b130da400da5034b101ab501ab501ab5034b100ea5034b1000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000001d73025730277301d73025730277301d73025730277301d73025730277301d73025730277301d7301f73025730277301f73025730277301f73025730277301f73025730277301f73025730277301f730
__music__
01 08090a41
02 43444141
00 40414141
03 40414141
00 41414141
00 41414141
00 41414141
00 41414141
00 41414141
00 41414141
00 41414141
00 41414141
00 41414141
00 41414141
00 41414141
00 41414141
00 41414141
00 41414141
00 41414141
00 41414141
00 41414141
00 41414141
00 41414141
00 41414141
00 41414141
00 41414141
00 41414141
00 41414141
00 41414141
00 41414141
00 41414141
00 41414141
00 41414141
00 41414141
00 41414141
00 41414141
00 41414141
00 41414141
00 41414141
00 41414141
00 41414141
00 41414141
00 41414141
00 41414141
00 41414141
00 41414141
00 41414141
00 41414141
00 41414141
00 41414141
00 41414141
00 41414141
00 41414141
00 41414141
00 41414141
00 41414141
00 41414141
00 41414141
00 41414141
00 41414141
00 41414141
00 41414141
00 41414141
00 41414141

