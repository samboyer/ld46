pico-8 cartridge // http://www.pico-8.com
version 21
__lua__
-- Ludum Dare 46
-- by Josh S and Sam B

-- (^can change later)

-- FLAGS
-- 0x1 COLLIDABLE


-- Particle System by fililou
particles = {}
emitters = {}

-- function _init()
--  -- Demo values
--  demo_i = 1
--  demo_l = {"wind", "sparks", "fireflies", "dome"}
-- end
function update_particles() --used to be update60
 foreach(particles, update_particle)
 foreach(emitters, update_emitter)
end
function draw_particles() --used to be _draw
 foreach(particles, draw_particle)
 --print(#particles, 0, 92, 7)
end
-- Axis are from 0 to 1
-- Axis(x, y, c, r) - axis variable
-- {,} - axis texture [1]: texture y position [2]: texture length
function make_particle(_x, _y, _c, _r, _maxl)
 p = {
 x=_x,
 y=_y,
 c=_c,
 r=_r,
 l=0,
 maxl=_maxl
 }
 add(particles, p)
 return p
end
function axis(_n, _v, _a, _i)
 return {
  n=_n or 0,
  v=_v or 0,
  a=_a or 0,
  i=_i or 1
 }
end
function update_particle(p)
 -- Update all axis
 local _l = p.l / p.maxl
 _r = get_axis(p.r, _l)
 update_axis(p.x, cos(_r), -p.y.v * sin(_r))
 update_axis(p.y, cos(_r), p.x.v * sin(_r))
 update_axis(p.c)
 update_axis(p.r)
 if(p.l >= p.maxl) del(particles, p)
 p.l += 1
end
function draw_particle(p)
 local _l = p.l / p.maxl
 pset(flr(get_axis(p.x, _l) * 127 + 0.5), flr(get_axis(p.y, _l) * 127 + 0.5), get_axis(p.c, p.l))
end
function make_emitter(_f, _l, _r)
 add(emitters, {f=_f, l=_l, r=_r or 1})
end
function update_emitter(e)
 if(e.l % e.r == 0) e.f()
 e.l -= 1
 if(e.l<=0) del(emitters, e)
end

function update_axis(a, m, o)
 if not is_texture_axis(a) then
  a.v += a.a -- Add acceleration
  a.n += a.v * (m or 1) + (o or 0) -- Add velocity
  a.v *= a.i -- Modify by inertia
 end
end
function get_axis(a, l)
 if is_texture_axis(a) then
  return sget(l%8 + a[1], a[2] + l\8) -- Get value at addr
 else
  return a.n
 end
end
function is_texture_axis(a)
 return a.n == nil
end

-- Demo functions
-- function demo_emitter_wind()
--  make_particle(axis(0.5, 0.0076), axis(0.5), axis(0.46), {32, 32}, 50)
-- end
-- function demo_emitter_sparks()
--  local _r = rnd(0.25)-0.125
--  local _vx = 0.008 * sin(_r)
--  local _vy = cos(_r) * -0.008
--  make_particle(axis(0.5, _vx), axis(0.5, _vy, 0.0003), {33, 8}, axis(), 30+rnd(20))
-- end
function demo_emitter_fireflies()
 make_particle(axis(0.4+rnd(0.2)), axis(0.4+rnd(0.2), rnd(0.001)+0.001), {35, 8}, {36+flr(rnd(3.99)), 16}, 600)
end
-- function demo_emitter_dome()
--  make_particle(axis(0.5), axis(0.5, -0.008, 0.00026), {34, 8}, axis(rnd(0.5)-0.25), 60)
-- end

function emitter_wateringcan()
  local _r = 0.12 + rnd(0.3)
  if not isweaponfacingleft then _r = -_r end
  local _vx = 0.004 * sin(_r)
  local _vy = cos(_r) * -0.004
  make_particle(axis((weapontipx - screenx)/127, _vx), axis((weapontipy - screeny)/127, _vy, 0.0003), {0, 24}, axis(), 10+rnd(5))
 end

function oneshot_splash(worldx,worldy, extrafx)
  for i=0,10 do
    local _r = rnd(1)-0.5
    local _vx = 0.008 * sin(_r)
    local _vy = cos(_r) * -0.008
    make_particle(axis((worldx - screenx)/127, _vx), axis((worldy - screeny)/127, _vy, 0.001), {0, 24}, axis(), 5+rnd(3))
  end
  if extrafx then
    sfx(6)
    screen_shake = 7
  end
 end

-- END PARTICLE SYSTEM

--doomfire by fernandojsg (slightly altered)
--for x=0,d do s(x) end
--poke(0x5f2c,3)
df_f={}df_p={0,1,1,4,8,9,10,7}df_w=64
df_d=df_w*df_w
function df_s(df_t)
  df_e=df_f[df_t]
  df_i=flr(rnd(3))
  df_f[df_t-df_i+1-df_w]=df_e-band(df_i,1)
end
for df_i=0,df_d do df_f[df_i]=df_i>df_d-df_w and 8 or 0 end
function draw_doomfire()
  for df_x=0,df_w do for df_y=0,df_w-1 do df_s(df_y*df_w+df_x) end end
  --for x=0,d do pset(x%w,flr(x/w),p[f[x]]) end
  for df_x=0,df_d do
    xx = df_x%df_w
    yy = flr(df_x/df_w)
    --pset(2*xx,2*yy,p[f[x]])
    rectfill(2*xx,2*yy,2*xx+2,2*yy+2,df_p[df_f[df_x]])
  end
end
function reset_doomfire()
  df_f={}
  for df_i=0,df_d do df_f[df_i]=df_i>df_d-df_w and 8 or 0 end
end
--END DOOMFIRE


function magnitude(x,y)
  return sqrt(x*x+y*y)
end

function get_dir8(dx,dy)
  local ratio = abs(dx)/abs(dy)
  if ratio>2 then --much more sideways
    if dx>0 then return 0 else return 2 end
  elseif ratio<0.5 then --much more vertical
    if dy>0 then return 3 else return 1 end
  else --diagonal
    if dx>0 then
      if dy>0 then return 7 else return 4 end
    else
      if dy>0 then return 6 else return 5 end
    end
  end
end

function lerp(a,b,t)
  return (1-t) * a + t * b;
end

function print_outline(s, x,y, col, colout)
  colout = colout or 0
  print(s,x-1,y-1,colout)
  print(s,x-1,y,colout)
  print(s,x-1,y+1,colout)
  print(s,x,y-1,colout)
  print(s,x,y+1,colout)
  print(s,x+1,y-1,colout)
  print(s,x+1,y,colout)
  print(s,x+1,y+1,colout)

  print(s,x,y,col)
end

-->8
--
-- START

--SETUP
pal(13,139,1) --palette recolouring
pal(2,131,1)
poke(0x5F2D, 1) --enable mouse
cls() -- clear screen

--CONSTANTS/CONFIG
screenborder = 32 -- how close guy can get before moving screen
bulletspeed = 0.5
bulletlife = 40 -- life of bullet in frames
worldsizex = 384 --size of arena in pixels
worldsizey = 256
killscorescaler = 0.2 --%age of enemy max health converted to points
screen_shake_decay = 1
playerstartx = 188
playerstarty = 104
screenstartx = 128
screenstarty = 30
wateringcan_healperframe = 2

player = {
  dx = 0,
  dy = 0,
  x = playerstartx,
  y = playerstarty,
  accel = 0.6,
  maxspd = 2.4,
  sprite = 64,
  default_weapon = {
    sprite = 65,
    damage = 50,
    cooldown = 20,
    lifetime = nil
  },
  weapon = nil,
  weapon_cooldown = 0
}

player.weapon = player.default_weapon

--VARIABLES
lmbdown = false
click = false
oldclick = false
screenx = screenstartx --camera position
screeny = screenstarty
screen_shake = 0
weapontipx = 0
isweaponfacingleft = false
isfacingdown = true

bullets = {}
--(x,y,dx,dy,sprite,life,dead)

flowers = {}
--(x,y,sprite)

enemies = {}

powerups = {}

available_powerups = {
  {
    sprite = 69,
    type = "weapon",
    contents = {
      sprite = 69,
      damage = 20,
      cooldown = 4,
      lifetime = 120
    }
  },
  {
    sprites = 2,
    sprite = 70,
    type = "weapon",
    contents = {
      sprites = 2,
      sprite = 70,
      damage = 200,
      cooldown = 40,
      lifetime = 120
    }
  }
}

score = 0
kills = 0
health = 100

playerstill = true --for idle animation
wateranimframes = 0 --frames remaining of watering can anim
watersuccess = false --did the watering get a flower
weakest_flower = nil --ref to weakest flower obj
t = 0 --frame count
gamerunning = false --is gameplay allowed?
gameover = false --discerns between menu and you died screen
controlsshowing = false --discerns between title screen and controls screen

function distance(o1, o2)
  dx = o1.x - o2.x
  dy = o1.y - o2.y
  if (abs(dx) > 128 or abs(dy) > 128) return 30000.0
  return magnitude(dx,dy)
end

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

function start_wateringcan()
  watersuccess = false
  wateranimframes = 30
  sfx(7)
  make_emitter(emitter_wateringcan, 35, 1)
end

function update_wateringcan()
  water = {
    x = player.x + (isweaponfacingleft and (-12) or 20),
    y = player.y + 8
  }

  for f in all(flowers) do
    if (distance(water, f) < 9) then
      watersuccess = true
      f.health = min(f.health + wateringcan_healperframe, f.maxhealth)
    end
  end

  wateranimframes -= 1
  if (wateranimframes==0 and watersuccess) then
    random_effect_text(water_texts)
  end
end

function apply_powerup(powerup)
  contents = {}
  for k,v in pairs(powerup.contents) do
    contents[k] = v
  end
  if (powerup.type == "weapon") then
    player.weapon = contents
  else
    show_effect_text("fix apply_powerup")
  end
end

function control_player()
  x = 0
  y = 0

  if gamerunning then
    if btn(4) and wateranimframes == 0 then
      start_wateringcan()
    end

    if wateranimframes == 0 then
      if (btn(0,0) or btn(0,1)) x -= 1
      if (btn(1,0) or btn(1,1)) x += 1
      if (btn(2,0) or btn(2,1)) y -= 1
      if (btn(3,0) or btn(3,1)) y += 1
    end
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

  -- powerups
  collected_powerup = nil
  for p in all(powerups) do
    if (collected_powerup == nil and abs(player.x - p.x) < 8 and abs(player.y - p.y) < 8) then
      collected_powerup = p
    end
  end
  if (collected_powerup != nil) then
    apply_powerup(collected_powerup)
    del(powerups, collected_powerup)
  end

  -- weapon
  if (player.weapon.lifetime != nil) player.weapon.lifetime -= 1
  if (player.weapon.lifetime == 0) player.weapon = player.default_weapon

  player.weapon_cooldown = max(player.weapon_cooldown - 1, 0)
  if (lmbdown and player.weapon_cooldown == 0) then
    add_bullet()
    player.weapon_cooldown = player.weapon.cooldown
  end

  -- if (pl.t%4) == 0) then
  --  sfx(1)
  -- end
end

function update_mouse()
  mousex=stat(32)
  mousey=stat(33)
  lmbdown = (stat(34)%2==1) and gamerunning
  click = lmbdown and oldclick != lmbdown and gamerunning
  oldclick = lmbdown
end

function add_flower_patch(x, y, num)
  sprites = {}
  mainflower = flr(rnd(4)) + 2
  for i=1,num do
    sprite = (rnd(1) < 0.2) and flr(rnd(4)) + 2 or mainflower
    add(sprites, {
      x = x + flr(rnd(16)) - 12,
      y = y + flr(rnd(16)) - 12,
      alivesprite = sprite,
      sprite = sprite,
      flip_x = (rnd(1) < 0.5)
    })
  end
  add(flowers, {
    x = x,
    y = y,
    health = 100,
    maxhealth = 100,
    sprites = sprites
  })
end

function add_enemy(x, y)
  e = {
    x = x,
    y = y,
    maxspd = 0.5,
    attackdist = 5,
    damage = 0.3,
    sprite = 45,
    health = 100,
    dead = false,
    maxhealth = 100,
  }

  target = nil
  targetdist = 10000
  for f in all(flowers) do
    dist = distance(e, f)
    if (dist < targetdist) then
      target = f
      targetdist = dist
    end
  end
  e.target = target

  add(enemies, e)
end

function add_random_powerup(x, y)
  add_powerup(x, y, available_powerups[flr(rnd(#available_powerups))+1])
end

function add_powerup(x, y, powerup)
  p = {
    x = x,
    y = y
  }
  for k,v in pairs(powerup) do
    p[k] = v
  end
  add(powerups, p)
end

function spawn_enemy_offscreen()
  repeat
    enemyx = flr(rnd(worldsizex-24))+8
    enemyy = flr(rnd(worldsizey-24))+8
  until( enemyx<screenx or enemyx>screenx+128
    or enemyy<screeny or enemyy>screeny+128)
  add_enemy(enemyx, enemyy)
end

function open_menu()
  gameover = false
  gamerunning = false
  controlsshowing = false
  music(-1) --TODO menu music
  reset_doomfire()
end

function start_game()
  player.x = playerstartx
  player.y = playerstarty
  player.weapon = player.default_weapon
  screenx = screenstartx
  screeny = screenstarty

  flowers = {}
  enemies = {}
  t=0
  score=0
  kills=0

  --place flowers
  add_flower_patch(192, 128, flr(rnd(8))+10) --place patch in center TODO make bigger, higher health

  for i=1,9 do
    centerx = flr(rnd(worldsizex-32))+16
    centery = flr(rnd(worldsizey-32))+16
    add_flower_patch(centerx, centery, flr(rnd(5))+6)
  end

  --TEMP
  add_random_powerup(130, 115)
  spawn_enemy_offscreen()

  gamerunning = true
  gameover = false
  music(-1) --TODO start game music
  screen_shake = 10 --yaas
  sfx(6, -1)
end

function add_bullet()
  sfx(0, -1)
  dx = mousex + screenx - player.x
  dy = mousey + screeny - player.y
  mag = magnitude(dx,dy) * bulletspeed
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
    damage = player.weapon.damage,
    life = bulletlife,
    dead = false
  })

  random_effect_text(shoot_texts, 0.05)
  screen_shake = 3
end

function update_bullets()
  deadbullet = nil
  for b in all(bullets) do
    if (not b.dead) then
      b.x += b.dx
      b.y += b.dy
      b.life -= 1
      b.sprite = 32+(b.sprite-28) %8 --cycle sprite
      if b.life < 0 then
        b.dead = true
        oneshot_splash(b.x,b.y, false)
      else
        -- if check_collisions(b.x, b.y, b.dx, b.dy, false) or check_collisions(b.x, b.y, b.dx, b.dy, true) then
        --   b.dead = true
        --   oneshot_splash(b.x,b.y,false)
        -- else
          hit_enemy = nil
          for e in all(enemies) do
            if ((dead_enemy == nil) and abs(b.x - e.x) < 8 and abs(b.y - e.y) < 8) then
              hit_enemy = e
            end
          end
          if hit_enemy != nil then
            b.dead = true
            oneshot_splash(b.x,b.y, true)

            hit_enemy.health -= b.damage
            if hit_enemy.health <= 0 then  --slug is kil
              del(enemies, hit_enemy)
              kills += 1
              score += hit_enemy.maxhealth * killscorescaler
              random_effect_text(kill_texts, 0.1)
            end
          end
        -- end
      end
    else
      deadbullet = b
    end
  end
  if (deadbullet != nil) del(bullets, deadbullet)
end

function update_enemies()
  deadenemy = nil
  for e in all(enemies) do
    if (not e.dead and e.target != nil) then
      targetdist = distance(e, e.target)
      e.moving = (targetdist > e.attackdist)
      e.flip_x = e.target.x < e.x
      if e.moving then
        --show_effect_text(""..targetdist)
        e.x += (e.maxspd / targetdist) * (e.target.x - e.x)
        e.y += (e.maxspd / targetdist) * (e.target.y - e.y)
      else
        e.target.health = max(e.target.health - e.damage, 0)
      end

      e.dead = false -- TODO BULLET CHECK? MAYBE PER BULLET
    else
      deadenemy = e
    end
  end
  if (deadenemy != nil) del(enemies, deadenemy)
end

function update_health()
  health = 100
  weakest_flower = nil

  for f in all(flowers) do
    if f.health<health then
      weakest_flower = f
      health = f.health
    end
  end
end

function _update()
  update_mouse()

  control_player()

  update_bullets()

  update_enemies()

  update_health()

  if wateranimframes > 0 then
    update_wateringcan()
  end

  if gamerunning then
    score += 0.2
    if health==0 then
      --end the game
      music(56)
      gamerunning = false
      show_effect_text(gameover_texts[flr(rnd(#gameover_texts))+1], nil, false) --don't play sound, choose random effect
      gameover = true --must come after show text effect
    end

    --if (t%90==0) spawn_enemy_offscreen()

    --move screen
    pxs = player.x - screenx
    pys = player.y - screeny
    screenx = min(max( screenx + max(pxs-128+screenborder,0) - max(screenborder-pxs,0) ,0), worldsizex-128)
    screeny = min(max( screeny + max(pys-128+screenborder,0) - max(screenborder-pys,0) ,0), worldsizey-128)
  else
    if gameover then
      if(btnp(5)) start_game()
      if(btnp(4)) open_menu() --go to title screen
    else --main menu
      if btnp(5) then
        if controlsshowing then start_game()
        else controlsshowing = true end
      end
    end
  end

  --update effects
  screen_shake_x = rnd(screen_shake*2) - screen_shake
  screen_shake_y = rnd(screen_shake*2) - screen_shake
  ui_shake_x = (-0.5) * screen_shake_x
  ui_shake_y = (-0.5) * screen_shake_y
  screen_shake = max(screen_shake - screen_shake_decay, 0)
end


function world_to_screen_coords(x,y)
  return x - screenx + screen_shake_x, y - screeny + screen_shake_y
end

function draw_sprite(spriteno, x, y, flip_x)
  flip_x = flip_x or false
  spr(spriteno, x - screenx + screen_shake_x, y - screeny + screen_shake_y, 1, 1, flip_x)
end

function draw_object(obj)
  sprites = obj.sprites or 1
  for i=1,sprites do
    spr(obj.sprite + i - 1, obj.x - screenx + screen_shake_x + 8*(i-1), obj.y - screeny + screen_shake_y, 1, 1, obj.flip_x or false)
  end
end

function draw_arrow(obj, dir)
  spr(112 + dir, min(max(((obj.x - screenx)\4)*4, 4), 116), min(max(((obj.y - screeny)\4)*4, 4), 116))
end

function draw_enemies()
  --(Bool and 96 or 100) + max((t \ 4)%6-2,0)
  for e in all(enemies) do
    if e.moving or gameover then
      e.sprite = 104 + (t \ 8)%2
    else
      e.sprite = 106+ (t \ 3)%5
    end
    if(gameover) e.flip_x = (t%26)>=13
    if (not e.dead) draw_object(e)
  end
end

function draw_lava()
  rectfill(0,0,127,127,10)
  --map(51,10)
  for i=0,127 do
      for iters=0,10 do
        itersworld = iters+screeny\12.5
        ii = i+screenx - screen_shake_x + itersworld*10-t/10

        local y= sin(t/53+itersworld/7)*sin(ii/32)*4 + i%2*0.4
        
        --local w=(cos((i+t)/64+iters/4)*0.5+1)*5
        w=5
        local offset = 12.5*iters + (screen_shake_y-screeny)%12.5
        rectfill(i,offset-w+y,i,offset+w+y, 9)
      end
  end
end

function _draw()
  if not (gamerunning or gameover) then --MENU
    cls()
    draw_doomfire()
    map(112,0)
    print("eternal",51,58, 9)
    print("eternal",51,57, 7)
    if controlsshowing then
      controlsstr = "controls:\n\x8b\x94\x91\x83/esdf: move\nlmb: shoot soaker\n\x8e : water plants\n\ndon't let the flowers die!"
      print_outline(controlsstr, 18,70,7)
      if (t%40<20) print_outline("press \x97 to begin",31,110, 7) --1s on, 1s off
    else if (t%40<20) print_outline("press \x97",48,100, 7) --1s on, 1s off
    end

  else
    draw_lava()

    sx = screenx - screen_shake_x
    sy = screeny - screen_shake_y
    ox = sx%8
    oy =  sy%8
    map((sx-ox)/8,(sy-oy)/8,-ox,-oy)

    --flowers
    for f in all(flowers) do
      for s in all(f.sprites) do
        s.sprite = (f.health < 20) and 22 or s.alivesprite
        draw_object(s)
      end
    end

    --powerups
    for p in all(powerups) do
      draw_object(p)
    end

    draw_enemies()

    --bloomguy
    isfacingdown = mousey >= player.y - screeny
    if playerstill then
      player.sprite = (isfacingdown and 96 or 100) + max((t \ 4)%6-2,0)
    else
      player.sprite = (isfacingdown and 80 or 82) + (t \ 5)%2
    end
    draw_object(player)

    --weapon
    weaponsprite = (player.weapon.sprites == nil) and player.weapon.sprite or nil
    if wateranimframes > 0 then
      if wateranimframes > 5 and wateranimframes < 25 then
        weaponsprite = 68
      else weaponsprite = 67
      end
    end
    isweaponfacingleft = mousex <= player.x - screenx
    if isweaponfacingleft then --right hand
      if (weaponsprite != nil) then
        draw_sprite(weaponsprite, player.x - 8, player.y)
      else
        for i=1,player.weapon.sprites do
          draw_sprite(player.weapon.sprite + i - 1, player.x + 8*(i-2), player.y)
        end
      end
      weapontipx = player.x - 5
    else
      if (weaponsprite != nil) then
        draw_sprite(weaponsprite, player.x + 8, player.y, true) --left hand
      else
        for i=1,player.weapon.sprites do
          draw_sprite(player.weapon.sprite + i - 1, player.x - 8*(i-2), player.y, true)
        end
      end
      weapontipx = player.x + 13
    end
    weapontipy = player.y + 4

    --bullets
    for b in all(bullets) do
      if (not b.dead) draw_object(b)
    end

    update_particles()
    draw_particles()

    --world-space flower healthbars
    for f in all(flowers) do
      if gamerunning and f.health < f.maxhealth then
        x0, y0 = world_to_screen_coords(f.x - 8,f.y - 9)
        x1,y1 = world_to_screen_coords(f.x + 8,f.y - 8)
        --rect(x0,y0,x1,y1, 7) --health bar
        frac = f.health/f.maxhealth
        col = (frac<0.5) and 8 or 9
        rectfill(x0, y0, lerp(x0,x1, frac), y1, col)
      end
    end

    --UI
    if gamerunning then
      if oldclick then ret = 17 else ret = 16 end
      spr(ret, mousex-3+ui_shake_x, mousey-3+ui_shake_y)

      print("score: "..flr(score), 2+ui_shake_x,2+ui_shake_y, 7)
      spr(46, 2+ui_shake_x,110+ui_shake_y, 2,2)
      rect(20,115, 122,122, 7) --health bar
      col = (health>30) and 14 or 8
      rectfill(21+ui_shake_x,116+ui_shake_y, lerp(20, 121, health/100)+ui_shake_x,121+ui_shake_y, col)

      spr(45, 105+ui_shake_x,1+ui_shake_y)--kills
      print(kills, 115+ui_shake_x,2+ui_shake_y, 7)

      --weakest flower direction
      if weakest_flower != nil then
        local dx = (weakest_flower.x - player.x)/100
        local dy = (weakest_flower.y - player.y)/100
        local mag = magnitude(dx,dy)*0.2

        dir = get_dir8(dx, dy)
        --flash arrow when health v low
        if(health>40 or (health>15 and t%8>3) or (health<=15 and t%4>1)) spr(120 + dir, 7+dx/mag, 114+dy/mag)
      end
    end

    --draw enemy indicators
    for e in all(enemies) do
      if (not e.dead) then
        ex = e.x - screenx - 64
        ey = e.y - screeny - 64
        if abs(ex)>64 or abs(ey)>64 then
          dir = get_dir8(e.x - screenx - 64, e.y - screeny - 64)
          draw_arrow(e, dir)
        end
      end
    end

    if (effect_text_time > 0) draw_effect_text();


    if gameover then
      effect_text_time = 1 --infinite text effect

      if (t%40<20) print("press \x97 to restart\n\n press \x8e for menu",31,64, 7) --1s on, 1s off
    end

  end

  t+=1

  -- DEBUG
  print(flr(stat(1)*100) .. "% CPU",0,16,7)
  print(stat(7).." fps", 0, 24, 7)

  -- waterx = player.x + (isweaponfacingleft and (-12) or 20)
  -- watery = player.y + 8
  -- circ(waterx-screenx, watery-screeny, 6, 5)
  -- for f in all(flowers) do
    -- circ(f.x-screenx, f.y-screeny, 3, 0)
  -- end
end

-->8
--
-- EFFECTS
-- 0 = wavey
-- 1 = circles
-- 2 = wavey + flashing
-- 3 = circles + flashing
-- 4 and greater = not rainbowtext

fierycolours = {5,8,9,14,15,9}

function random_effect_text(list, chance)
  chance = chance or 0.3
  if (rnd(1) < 0.5) list = generic_texts
  if (rnd(1) < chance) show_effect_text(list[flr(rnd(#list))+1])
end

function show_effect_text(text, effect, playsfx)
  if(gameover) return
  if(playsfx==nil) playsfx = true
  effect_text = text
  effect_text_time = 40
  effect_text_effect = effect or flr(rnd(effect_count))
  if(playsfx) sfx(5)
end

effect_text = nil
effect_text_effect = 0
effect_text_time = 0
effect_text_width = 6
effect_count = 10
function draw_effect_text()
  effect_text_time -= 1;

  textx = (128 - effect_text_width * #effect_text)\2
  texty = 40

  if effect_text_effect < 4 then
    for j=1,#effect_text do
      text_offset = effect_text_width*(j-1)
      for i=0,6 do
        trig_oper = t/30 + j/5 + i/30
        offset_x = 2 * ((effect_text_effect % 2 == 0) and sin(trig_oper) or cos(trig_oper)) + text_offset
        offset_y = 5 * sin(trig_oper)
        print(sub(effect_text,j,j), textx + offset_x + ui_shake_x, texty + offset_y + ui_shake_y, fierycolours[1+(i-effect_text_time\2)%#fierycolours])
      end
      print(sub(effect_text,j,j), textx + text_offset + ui_shake_x, texty + ui_shake_y, (effect_text_effect > 1) and (t%2)*7 or 0)
    end
  elseif effect_text_effect < 8 then
    for j=1,#effect_text do --per char
      text_offset = effect_text_width*(j-1)
      for i=1,6 do --per copy of char
        col = (effect_text_effect % 2 == 0) and fierycolours[1+(i-effect_text_time\2)%#fierycolours] or 9 --either rainbow or orange
        if effect_text_time < 33+i and effect_text_time>i then
          print(sub(effect_text,j,j), textx - i + text_offset + ui_shake_x, texty + i + ui_shake_y, col)
        end
      end
      if effect_text_time < 33 then
        print(sub(effect_text,j,j), textx + text_offset + ui_shake_x, texty + ui_shake_y, (effect_text_effect > 5) and (t%2)*7 or 0)
      end
    end
  elseif effect_text_effect < 10 then
    for j=1,#effect_text do
      text_offset = effect_text_width*(j-1)
      offset_x = text_offset
      offset_y = 0
      col = fierycolours[1+(t+effect_text_time\2)%#fierycolours]
      print_outline(sub(effect_text,j,j), textx + offset_x + ui_shake_x, texty + offset_y + ui_shake_y, (effect_text_effect%2 == 0) and 7 or col, (effect_text_effect%2 == 0) and col or 7)
    end
  end
end

water_texts = {
  "epic water combo",
  "wow that's a nice flower",
  "+10,000 nook miles",
  "titchmarsh would be proud",
  "flower power",
  "splish splash",
  "hydro homie"
}

kill_texts = {
  "combo",
  "super combo",
  "mega combo",
  "ultra combo",
  "wombo combo",
  "kill bill",
  "sluggernaut",
  "you monster",
  "death comes to us all",
  "yaass slayy",
  "slug is kil"
}

shoot_texts = {
  "wow bullet",
  "bang bang",
  "pew pew",
  "brrap brrap"
}

generic_texts = {
  "stonks",
  "you did the thing!",
  "sample text",
  "hey! listen!",
  "owo what's this",
  "you are a saucy boy",
  "yeet"
}

gameover_texts = {
  "game over",
  "mission failed. we'll get em next time",
  "death",
  "dehydration comes to us all",
  "you had two jobs",
  "flower says goodbye",
  "bloom-slain",
  "omae wa mou shindeiru",
  "you are not a saucy boy",
  "\"everything not saved will be lost\"",
  "you lose (the flowers)",
  "omae wa mo shindeiru",
  "f",
  "sam is a poopoo"
}

__gfx__
0000000000ff0ff00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0700007000ff0ff00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0070070000fffff00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0007700000f1ff100000020000000c00000008000000090000000e00000000000000000000000000000000000000000000000000000000000000000000000000
0007700000fffff0000027200000c7c000008780000097900000e7e0000000000000000000000000000000000000000000000000000000000000000000000000
00700700000444000000020000000c00000008000000090000000e00000000000000000000000000000000000000000000000000000000000000000000000000
07000070000999000000030000000300000003000000030000000300000000000000000000000000000000000000000000000000000000000000000000000000
00000000000f0f0000000b0000000b0000000b0000000b0000000b00000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000dd3dddddfffffffdffffffffd3dddd3d3dddd3ddfff3dddd0000000000000000
060006000c000c00000000000000000000000000000000000000000000000000dd3dd3ddffffffddddffffffd3dd3d3dfd3dd3d3fdd3d3dd0000000000000000
0060600000c0c000000000000000000000000000000000000000000000000000ddddd3ddfffffdd33dddffffdddd3ddfff3dddd3fdddd3dd0000000000000000
0000000000000000000000000000000000000000000000000000000000000000d3ddddd3fffffdd33d3ddfffddfffffffffddd3dd3ddddd30000000000000000
0060600000c0c000000000000000000000000000000000000000400000000000d3ddddd3ffffdddddd3d3dff3dfffffffffd3d3dd3ddddd30000000000000000
060006000c000c00000000000000000000000000000000000004740000000000ddd3ddddfffdd3dddddd3dff3fffffffffff3dd3ddd3dddd0000000000000000
00000000000000000000000000000000000000000000000000004300000000003dd3dd3dffd3d3d3d3dddd3fdfffffffffffffd33dd3dd3d0000000000000000
00000000000000000000000000000000000000000000000000000b00000000003ddddd3d3dd3ddd3d3dddd3ffffffffffffffffd3ddddd3d0000000000000000
00000000000c70000000000000c0c00000000000000c70000000000000c0c000000000000000000000000000000000000000000070000007000000eeee000000
0000000000cc7000000000000000c0000000000000cc70000000000000cc000000000000000000000000000000000000000000000777777000000eeeeee00000
c00cc77000ccc0000cc770c0000c00000c0c777000ccc0000cc77007000cc00000000000000000000000000000000000000000000766766000000eeeeee00000
00ccccc700ccc000cccccc0000ccc0000cccccc700ccc000ccccccc000ccc00000000000000000000000000000000000000000000766766000000eeeeee0eee0
c700ccc000cc0000cccc00c700cc7000c0c0ccc000c07000cccc0ccc00cc70000000000000000000000000000000000000000000077777700eee0eeeeeeeeeee
00000000000c00000000000000cc700000000000000cc0000000000000cc7000000000000000000000000000000000000000000000767600eeeeee9aaaeeeeee
000000000000700000000000007cc00000000000000c000000000000007cc000000000000000000000000000000000000000000000767600eeeee9aa9aaeeeee
0000000000c0c00000000000000c0000000000000000c00000000000000c0000000000000000000000000000000000000000000077777700eeeee9a9a9aeeeee
cc7ccc7c00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000eeeee9aa9aaeeee0
c7cc7cc7000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000eeee99aaa9eee00
cc7cc7cc00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000eee9999eee000
cc7ccccc00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000eeeeeeeeeee00
111c11c10000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000eeeeeeeeeeeee0
1c1111c10000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000eeeeee0eeeeee0
111c1c110000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000eeeeee00eeeee0
11c111c100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000eee0000eeee00
0000000000000000eeeeeeee00000000000000000000000000000000000055000000000000000000000000000000000000000000000000000000000000000000
000000000000bbb0eeeeeeee00000000000000000000000000000000000055500000000000000000000000000000000000000000000000000000000000000000
000000000000bbb0eeeeeeee00006000000000000000000000006666600005550000000000000000000000000000000000000000000000000000000000000000
00000000009ccccceeeeeeee06066660000600000006555505556666585500050000000000000000000000000000000000000000000000000000000000000000
0000000000000c03eeeeeeee00666603000666630000050505556666555555550000000000000000000000000000000000000000000000000000000000000000
000000000000000cee0000ee00066660066666060000050505676666555555550000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000666600000000500676666600000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000ee0000ee00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00333d0000333d0000333d0000333d00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
031112d0031112d0033333d0033333d0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00311300003113000033330000333300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
03559530035595300355553003555530000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
30333303303333033033330330333303000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00533500005335000053350000533500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00300500005003000030050000500300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000300003000000000030000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00333d0000333d00000000000000000000333d0000333d0000000000000000005000000550000005559444955594449550000005500000055000000500000000
031112d0031112d000333d0000333d00033333d0033333d000333d0000333d00059444900594449004a949a004a949a005500005050000500594449000000000
0031130000311300031112d0031112d00033330000333300033333d0033333d004a949a004a949a004a84a8004a84a80044944490494449004a949a000000000
035595300033330000311300035115300355553000333300003333000353353004a84a8004a84a800444444004440040044a949a04a949a004a84a8000000000
303333030355953003559530303593033033330303555530035555303035530304444440044444400444404004440000044a84a804a84a800444444000000000
00533500303333033033330300533500005335003033330330333303005335000034440000344400003444000034000004444444044444400034440000000000
00500500005335000053350000500500005005000053350000533500005005000034440000034440003444000034440000344400003444000034440000000000
00300300003003000030030000300300003003000030030000300300003003003344440003344440334444003344440033444400334444003344440000000000
00000000000880000000000000000000000888888888800000000000000000000000000000077000000000000000000000077777777770000000000000000000
00008800008888000088000000000000000088888888000000000000000000000000770000777700007700000000000000007777777700000000000000000000
00008880088888800888000000000000000008888880000000000000000000000000777007777770077700000000000000000777777000000000000000000000
00008888088888808888000000000000000000888800000080000000000000080000777707777770777700000000000000000077770000007000000000000007
00008888000000008888000008888880000000088000000088000000000000880000777700000000777700000777777000000007700000007700000000000077
00008880000000000888000008888880000000000000000088800000000008880000777000000000077700000777777000000000000000007770000000000777
00008800000000000088000000888800000000000000000088880000000088880000770000000000007700000077770000000000000000007777000000007777
00000000000000000000000000088000000000000000000088888000000888880000000000000000000000000007700000000000000000007777700000077777
71717171717171717171717171717171717171717171717171717171717171717171717171717171717171717171717171717171717171717171710000000000
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
fffffffff00000000000005ffffffffffffffffffffffffffffffffffff50000000555fffff50ffffff55fff5fffffffffffffffffffffff0000000000000000
fffffffff50000000000005f55fffffffffff550fffffffffffffffffffff500005fffffffff5ffffff5ffffffffffffffffffffffffffff0000000000000000
fffffffff5000000000000ff0055ffffffff50005fffffffffffffffffffff5005fffffffffffffffff5fffffffffffffffff0ffffffffff0000000000000000
ffffffffff500000000005ff00005ffffff500000ffffffffffffff5fffffff05fffffffffffffffffffffff5fffffffffff0000ffffffff0000000000000000
fffffffffff5000000005fff000005ffff5000000ffffffffffffff0fffffff05fffffffffffffffffffffff005ffffffff00ff0ffffffff0000000000000000
ffffffffffff55000005ffff0000005fff50000005ffffffffffff50fffffff5ffffffffffffffffffffffffffffffffffffffffffff5fff0000000000000000
ffffffffffffff50555fffff0000005ff5000000005ffffffffff500fffffffffffffffffffffffffffffffffffffffffffffffff5ff05ff0000000000000000
ffffffffffffffffffffffff0000000ff500000000005fffff550000fffffffffffffffffffffffffffffffffffffffffffffffff0f500ff0000000000000000
67677775066666666666666066666666677777756750000067776775500000006776777777767675676777766666666500066666000000000000000000000000
67676775676767677666767576766666676776757500000006776777750000000677677677767775676767777667675000676677000000000000000000000000
67776765677767777676777576776767667776755000000000677677775000000067776767777750677767677767750006776776000000000000000000000000
67777775677777777776777576777767677767750000000000067776777500000006777566777700677767677677500067776776000000000000000000000000
66777775677777677777767576767777677767500000000000006776677755550000675076767700677767777775000067677776000000000000000000000000
66767775667676777776767577767777767775000000000000000677767677770000050077767750677777777750000067677777000000000000000000000000
67767765677677777676776577777667767750000000000000000067777767770000000067777675667776777500000067767777000000000000000000000000
67677765676777756777776555555555677500000000000000000006767776770000000067777675677776675000000067767775000000000000000000000000
66666666000006666660000066666600677777750000067767776775000000067677677567777775666656666776777500000000000000000000000000000000
77676777000000677500000066777750676777650000006767777750000000677677675067677775777755670677677500000000000000000000000000000000
77676767000000677500000077767775676777750000000677677500000006777767750077677675676775670067776500000000000000000000000000000000
77677767000000065000000076776775677677750000000077675000000067776777500077777675676777560006776500000000000000000000000000000000
77677767000000065000000077777775067776760000000077750000666677670675000076777675776767560000677500000000000000000000000000000000
77777677000000065000000077776775006777670000000077500000766777670050000076767775677767560000067500000000000000000000000000000000
77777677000000065000000077776775000677770000000075000000776776770000000077767750777777560000006500000000000000000000000000000000
67777777000000065000000067777775000067670000000050000000777777760000000055555500776776560000000500000000000000000000000000000000
00088888888888888888800088888888888888880000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00898888888888888888980000900898898009000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
08888888888888888888888000000008800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
89888888888888888888889800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
89888888888888888888889800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
08888888888888888888888000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00898888888888888888980000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00088888888888888888800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__gff__
0000000000000000000000000000000000000000000000010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001010101000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__map__
1717171717171717171717171717171717171717171717171717171717171717171717171717171717171717171717171717171717171717171717000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
17b8b9bab0b0bab0b0b0b0b0b0b0b0b0b0b7b8b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b7171717171717171717171717000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
17bbb0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b01717171717171717171717170000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000d1d0c3dac2c1c3c2c1c3c2c1d3ccd0d2
17b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0171717171717171717171717000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000c000c0c0c000c0c000c0c0c0c0c000
17b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0171717171717171717171717000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000cac3c9c0c000c0c000c0c0c0c0c000
17b5b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0bc171717171717171717171717000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000c000c0c0c6c7c4d4d7d6dbc6d6c000
17b8b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0171717171717171717171717000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000cac3d9cacbc8c5d5d800000000db00
17b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0171717171717171717171717000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000d60000d6e0e1e1e1e1e20000000000
17b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0171717171717171717171717000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000e3e400000000000000
17b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0171717171717171717171717000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
17b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0171717171717171717171717000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
17b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0191ab0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0171717171717171717171717000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
17bbb0b0b0b0b0b0b0b0b0b0b0b0b0b01818b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0171717171717171717171717000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
17b0b0b0b0b0b0b0b0b0b0b0b0b0b0b01c1bb0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0171717171717171717171717000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
17b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b019181818181ab0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0171717171717171717171717000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
17b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b01d181818181818b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0bc171717171717171717171717000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
17b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b018181818181818b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0171717171717171717171717000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
17b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b01c18181818181bb0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0171717171717171717171717000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
17b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b01c18181bb0b0b0b0b0b019181ab0b0b0b0b0b0b0b0b0b0b0b0171717171717171717171717000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
17b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b01c181bb0b0b0b0b0b0b0b0b0b0b0b0171717171717171717171717000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
17b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0171717171717171717171717000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
17b5b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b4171717171717171717171717000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1717bbb0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b7171717171717171717171717000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
17b8b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b41717b3b0b0b0b0b0b0b0b0b0b0b0b0b0b0171717171717171717171717000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
17b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b4171717b2b0b0b0b0b0b0b0b0b0b0b0b0b0b0171717171717171717171717000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
17b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0171717b8b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0171717171717171717171717000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
17b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b117b2b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0171717171717171717171717000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
17b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0171717171717171717171717000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
17b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0171717171717171717171717000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
17b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0171717171717171717171717000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
17b5b0b0b0b0b0b0b0bdb0b0b0b0b0b0b0b0b0b0b0b0b0b6b3b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0bdb0b0b0b6171717171717171717171717000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1717171717171717171717171717171717171717171717171717171717171717171717171717171717171717171717171717171717171717171717000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__sfx__
000400002c620280301e620180100d610160100a600300003500027000270002b000290002b000300003300001000010000100001000010000100001000010000100001000010000100001000000000000000000
0105000011653086510b351094520b4520c4320c4220c4220c4220c4220c4220c4220c4220c4220c4220c4220c4220c4220c4220c4220c4220c42200402004020040200400004000040000400004000040000400
000500000b26004050000400003000020000200001000010000100000006000000000500000000040000400004000040000400004000040000400000000000000000000000000000100001000010000000000000
000100003c670386603665032650306402b6302b630286202762025620216201f6101d6101c6101b6101b6101a6101a61019610196000f6000b60009600086001d60000600006000060026600006000060000600
01100000290700000000000000002d0700000000000000002b0700000029070000002607000000240700000022070000001c0701d070000000000000000000000000000000000000000000000000000000000000
0005000000450034500c45000440034400c44000430034300c43000420034200c42000410034100c4100741500400006030060000000000000000000000000000000000000000000000000000000000000000000
000300001e61022620256201f6200e6200c61011610156101b610176100f6100a61007610076100a6100161000610006000060001600016000060001600006000060000000000000000000000000000000000000
010700000000000000146101f6102461023610256102261024610266102361026610226101c6101e6101861012610086100360000600016000160000600237003b600027002e7003670033600006000000000000
01100000189501895018950189521895200000000001a9501a9501a9521b9501b9501b9521b9521b95200000189501895018950189501895000000000001b9501b9501b9501a9501a9501a9501a9501a95000000
011000100ca500ca5039b1339b131bb501bb5034b130da400da5034b101ab501ab501ab5034b100ea5034b1000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000001d73025730277301d73025730277301d73025730277301d73025730277301d73025730277301d7301f73025730277301f73025730277301f73025730277301f73025730277301f73025730277301f730
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
010d00100cb500000024b000000024b500000000b00000000cb5000b000000000b0024b5000b000000000b0000000000000000000000000000000000000000000000000000000000000000000000000000000000
010300001a1501a1501a1501c10000000001000000000100181501815018150000000010000100001000010016150161501615000000001000010000100001001515015150151500010000100001000010000100
000d00001315013150000000000013150131501a15000000181501815000000000001615016150000000000015150151500000000000151501515016150161501815018150000000000016150000001515000000
010d00001315013150000000000013150131502215122150211540000022150000002115000000221500000013150131500000000000131501315022151221502115400000221500000021150000002215000000
010d00001315013150000000000013150131521a1511a150181541815000000000001615016150131411312115150151500000000000151541515016151161501815118150000001800016154161501515115150
011000000c0500000018050000000c0500000018050000000d0500000019050000000d0500000019050000000c0500000018050000000c0500000018050000000d0500000019050000000d050000001905000000
011000001810500005241050000518105000052410500005191050000525105000051910500005251050000518155000052415500005181550000524155000051915500005251550000519155000052515500005
011000000055200552005520055200552005520055200552015520155201552015520155201552015520155200552005520055200552005520055200552005520155201552015520155201552015520155201552
011000001ab501cb001ab001ab001ab5018b001ab001cb001ab501cb001ab001cb001ab501cb001ab001cb001ab501cb001ab001cb001ab501cb001ab001ab001ab5018b001ab001ab001ab50000001ab0000000
011000000c050180500c050180500d050190500d050190500c050180500c050180500d050190500d050190500c050180500d050190500c050180500d050190500c050190500c050190500c050190500c05019050
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
00 24252627
00 41414141
00 41414141
00 41414141
00 41414141
00 41414141
00 41414141
00 41414141
00 20414141
01 211f4141
00 221f4141
00 41231f41
02 221f4141
00 41414141
00 41414141
00 41414141

