pico-8 cartridge // http://www.pico-8.com
version 21
__lua__
-- bloom eternal
-- by sam b, josh s
-- slay slugs and keep your flowers alive

--sprite rotation by jihem
function rspr(sx,sy,x,y,w, sa,ca)
  --local ca,sa=cos(a),sin(a)
  local srcx,srcy,addr,pixel_pair
  local ddx0,ddy0=ca,sa
  local mask=shl(0xfff8,(w-1))
  w*=4
  ca*=w-0.5
  sa*=w-0.5
  local dx0,dy0=sa-ca+w,-ca-sa+w
  w=2*w-1
  for ix=0,w do
      srcx,srcy=dx0,dy0
      for iy=0,w do
          if band(bor(srcx,srcy),mask)==0 then
              local c=sget(sx+srcx,sy+srcy)
              if(c!=0)pset(x+ix,y+iy,c)
          end
          srcx-=ddy0
          srcy+=ddx0
      end
      dx0+=ddx0
      dy0+=ddy0
  end
end

-- PICO-tween https://github.com/JoebRogers/PICO-Tween
function outCubic(t, b, c, d)
  a=t / d-1
  return c * (a*a*a+1)+b
end

-- Particle System by fililou
particles={}
emitters={}
function update_particles() --used to be update60
 foreach(particles, update_particle)
 foreach(emitters, update_emitter)
end
function draw_particles() --used to be _draw
 foreach(particles, draw_particle)
end

function make_particle(_x, _y, _c, _r, _maxl)
 p={
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
 local _l=p.l / p.maxl
 _r=get_axis(p.r, _l)
 update_axis(p.x)
 update_axis(p.y)
 update_axis(p.c)
 update_axis(p.r)
 if(p.l>=p.maxl) del(particles, p)
 p.l += 1
end
function draw_particle(p)
 local _l=p.l / p.maxl
 pset(flr(get_axis(p.x, _l) * 127+0.5), flr(get_axis(p.y, _l) * 127+0.5), get_axis(p.c, p.l))
end
function make_emitter(_f, _l, _r)
 add(emitters, {f=_f, l=_l, r=_r or 1})
end
function update_emitter(e)
 if(e.l % e.r==0) e.f()
 e.l -= 1
 if(e.l<=0) del(emitters, e)
end

function update_axis(a, m, o)
 if not is_texture_axis(a) then
  a.v += a.a -- Add acceleration
  a.n += a.v * (m or 1)+(o or 0) -- Add velocity
  a.v *= a.i -- Modify by inertia
 end
end
function get_axis(a, l)
 if is_texture_axis(a) then
  return sget(l%8+a[1], a[2]+l\8) -- Get value at addr
 else
  return a.n
 end
end
function is_texture_axis(a)
 return a.n==nil
end

function emitter_can()
  local _r=0.12+rnd(0.3)
  if not isweaponleft then _r=-_r end
  local _vx=0.004 * sin(_r)
  local _vy=cos(_r) * -0.004
  make_particle(axis((weapontipx-screenx)/127, _vx), axis((weapontipy-screeny)/127, _vy, 0.0003), {0, 24}, axis(), 10+rnd(5))
 end

--p={count,sprite,gravity,lifetime}
function oneshot_splash(x, y, p)
  for i=0, p.count do
    local _r=rnd(1)-0.5
    local _vx=0.008 * (sin(_r)+rnd(1)-0.5)
    local _vy=(cos(_r)+rnd(1)-0.5) * -0.008
    make_particle(axis((x-screenx)/127, _vx), axis((y-screeny)/127, _vy, p.gravity), {(p.sprite%16)*8, (p.sprite\16)*8}, axis(), p.lifetime+rnd(3))
  end
 end

--doomfire by fernandojsg (slightly altered)
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
  for df_x=0,df_d do
    xx=df_x%df_w
    yy=flr(df_x/df_w)
    rectfill(2*xx,2*yy,2*xx+2,2*yy+2,df_p[df_f[df_x]])
  end
end
function kill_doomfire()
  for df_i=0,df_d do
    if(df_i>df_d-df_w) df_f[df_i]=0
  end
end
function reset_doomfire()
  df_f={}
  for df_i=0,df_d do df_f[df_i]=df_i>df_d-df_w and 8 or 0 end
end

--UTILITIES

dither_patterns={
  0b1111111111111111.1,
  0b0111111111111111.1,
  0b0111111111011111.1,
  0b0101111111011111.1,
  0b0101111101011111.1,
  0b0101101101011111.1,
  0b0101101101011110.1,
  0b0101101001011110.1,
  0b0101101001011010.1,
  0b0001101001011010.1,
  0b0001101001001010.1,
  0b0000101001001010.1,
  0b0000101000001010.1,
  0b0000001000001010.1,
  0b0000001000001000.1,
  0b0000000000000000.1
}

function dither_rect(x1, y1, x2, y2, color, pattern)
  fillp(dither_patterns[pattern])
  rectfill(x1, y1, x2, y2, color)
  fillp()
end

function magnitude(x,y)
  return sqrt(x*x+y*y)
end

function get_dir8(dx,dy)
  local ratio=abs(dx)/abs(dy)
  if ratio>2 then --much more sideways
    return dx>0 and 0 or 2
  elseif ratio<0.5 then --much more vertical
    return dy>0 and 3 or 1
  else --diagonal
    if dx>0 then
      return dy>0 and 7 or 4
    else
      return dy>0 and 6 or 5
    end
  end
end

function lerp(a,b,t)
  return (1-t) * a+t * b;
end

function print_outline(s, x,y, col, colout)
  colout=colout or 0
  for i=x-1,x+1 do
    for j=y-1,y+1 do
      print(s,i,j,colout)
    end
  end
  print(s,x,y,col)
end

function distance_basic(o1, o2) --axis-aligned distance between objects
  return max(abs(o1.x-o2.x), abs(o1.y-o2.y))
end

function distance(o1, o2)
  dx=o1.x-o2.x
  dy=o1.y-o2.y
  if(abs(dx)>128 or abs(dy)>128) return 30000.0
  return magnitude(dx,dy)
end

function check_collisions(x, y, dx, dy, in_x) -- assume width=height=8
  if in_x then
    checkx=x+dx+((dx>0) and 8 or 0)
    tilex=checkx / 8
    return (checkx>worldsizex or checkx<0 or fget(mget(tilex, y / 8), 0) or fget(mget(tilex, (y+7.9) / 8), 0))
  else
    checky=y+dy+((dy>0) and 8 or 0)
    tiley=checky / 8
    return (checky>worldsizey or checky<0 or fget(mget(x / 8, tiley), 0) or fget(mget((x+7.9) / 8, tiley), 0))
  end
end


-->8
--
-- START

--SETUP
pal(13,139,1) --palette recolouring
pal(2,131,1)
cls() -- clear screen

--CONSTANTS/CONFIG
maxval=32767
screenborder=40 -- how close guy can get before moving screen
bulletspeed=0.5
bulletlife=40 -- life of bullet in frames
worldsizex=384 --size of arena in pixels
worldsizey=256
killscorescaler=0.2 --%age of enemy max health converted to points
canscorescaler=0.2 --%age of watering can healing converted to points
powerup_chance=0.2 --chance a killed enemy will drop a powerup
screen_shake_decay=1
playerstartx=188
playerstarty=104
screenstartx=128
screenstarty=30
can_healperframe=2
retarget_time=150 -- number of frames after which enemy switches targets
gunnerstunduration=20  --num. frames for stun to occur
gunershootspeed=36

wave_downtime=6 --time between waves (s)
wave_spawnduration=5 --time for enemies to spawn (s)
wave_enemycountbase=3 --base #enemies per wave
wave_enemycountdelta=1
wave_originsizebase=48 --dist from 'wave origin' (px)
wave_originsizedelta=8
wave_originrubberband=256 --max distance of enemy origin from camera

player={
  dx=0,
  dy=0,
  x=playerstartx,
  y=playerstarty,
  accel=0.6,
  maxspd=2.4,
  sprite=64,
  default_weapon={
    sprite=64,
    damage=50,
    cooldown=15,
    shake=3,
    bullet_sprite=42,
    bullet_animated=false,
    lifetime=nil,
    splash_radius=0,
  },
  weapon=nil,
  weapon_cooldown=0
}
player_original_stats={}
for k,v in pairs(player) do
  player_original_stats[k]=v
end

p_weapon=player.default_weapon

--VARIABLES
lmbdown=false
clickl=false
oldlmb=false
oldrmb=false
screenx=screenstartx --camera position
screeny=screenstarty
screen_shake=0
weapontipx=0
weapontipy=0
isweaponleft=false
isfacingdown=true
oldenemycount=-1
isintro=true
stunnedframes=0
stuncooldown = 10
desiredmusic=0 --loop id to schedule

bullets={}
--(x,y,dx,dy,sprite,life,dead)

flowers={}
--(x,y,sprite)

enemies={}

powerups={}
active_powerups={}
available_powerups={
  {
    sprite=69,
    type="weapon",
    contents={
      name="machine gun",
      sprite=69,
      damage=20,
      cooldown=4,
      bullet_sprite=36,
      lifetime=240,
      shake=3,
      splash_radius=0,
    }
  },
  {
    sprites=2,
    sprite=70,
    type="weapon",
    contents={
      name="beeg boy",
      sprites=2,
      sprite=70,
      damage=200,
      cooldown=40,
      bullet_sprite=38,
      lifetime=240,
      shake=15,
      particles={
        sprite=49,
        count=40,
        gravity=0.0003,
        lifetime=15,
      },
      splash_radius=32,
    }
  },
  {
    sprites=2,
    sprite=74,
    type="weapon",
    contents={
      name="chainsaw", --chainsaw
      sprites=2,
      sprite=74,
      melee=true,
      damage=5,
      range=14,
      lifetime=240,
    }
  },
  {
    sprite=72,
    type="stat",
    contents={
      name="speed juice",
      key="maxspd",
      value=4.8,
      lifetime=240
    }
  },
  {
    sprite=73,
    type="instant",
    effect="water",
    contents={
      name="raincloud",
      lifetime=30
    }
  },
  {
    sprites=2,
    sprite=77,
    type="weapon",
    contents={
      name="elite x", --sniper
      sprites=2,
      sprite=77,
      damage=200,
      lifetime=240,
      shake=2,
      cooldown=20,
      splash_radius=0,
      sniper=true,
      tipx=-7
    }
  },
  {
    sprite=76,
    type="weapon",
    contents={
      name="shotgun", --shotgun
      sprite=76,
      damage=35,
      lifetime=240,
      bullet_sprite=36,
      shake=5,
      cooldown=20,
      splash_radius=0,
      bulletspershot=3
    }
  },
  {
    sprite=65,
    type="weapon",
    contents={
      name="satanic soaker", --water gun
      sprite=65,
      damage=5,
      lifetime=240,
      shake=1,
      cooldown=2,
      splash_radius=0,
      bullet_sprite=32,
      bullet_animated=true,
      particles={
        sprite=48,
        count=3,
        gravity=0.001,
        lifetime=5,
      },
    }
  },
  {
    sprites=4,
    sprite=155,
    type="weapon",
    contents={
      name="the crucible", --crucible
      sprites=4,
      sprite=155,
      melee=true,
      damage=100,
      range=9,
      lifetime=240,
    }
  },
}

tumbleweeds={}
--x, y, sprite, progress, direction

score=0
kills=0
health=100
wave=0 --#waves survived (lags behind)

playerstill=true --for idle animation
can_t=0 --frames remaining of watering can anim
watersuccess=false --did the watering get a flower
weakest_flower=nil --ref to weakest flower obj
t=0 --frame count, for anims (not to be trusted!)
time=0 --game timer in s
gamerunning=false
gameover=false
controlsscreen=false
startcountdown=nil --countdown for animations
startcountdownframes=45
startcountdown2=nil --countdown for fade in

wave_nextwavestarttime=-1
wave_enemycount=0
wave_originsize=0
wave_originx=0
wave_originy=0
wave_spawned=0
wave_spawnwait=0
wave_nextspawntime=0

--UPDATE FUNCTIONS


function start_can()
  watersuccess=false
  can_t=30
  sfx(7)
  make_emitter(emitter_can, 35, 1)
end

function update_can()
  water={
    x=player.x+(isweaponleft and -4 or 12),
    y=player.y+4
  }

  for f in all(flowers) do
    if distance(water, f)<14 then
      watersuccess=true
      f.health=min(f.health+can_healperframe, f.maxhealth)
      score += can_healperframe * canscorescaler
    end
  end

  can_t -= 1
  if(can_t==0 and watersuccess) then
    random_effect_text(water_texts)
  end
end

function apply_powerup(powerup)
  contents={}
  for k,v in pairs(powerup.contents) do
    contents[k]=v
  end
  if powerup.type=="weapon" then
    p_weapon=contents
    sfx(10)
  elseif powerup.type=="stat" then
    sfx(18)
    player[contents.key]=contents.value
  elseif powerup.type=="instant" then
    sfx(24)
    if powerup.effect=="water" then
      for f in all(flowers) do
        f.health=min(f.health+50, f.maxhealth)
      end
    else
      show_effect_text("fix apply_powerup instant")
    end
  else
    show_effect_text("fix apply_powerup")
  end
  contents.type=powerup.type
  contents.life=contents.lifetime
  add(active_powerups, contents)
end

function cooldown_powerups()
  if(gameover) return
  done_powerup=nil
  weapon_cooled=false
  for p in all(active_powerups) do
    if((not weapon_cooled) or p.type != "weapon") then
      p.life=max(p.life-1, 0)
      if(p.life==0) done_powerup=p
      if(p.type=="weapon") weapon_cooled=true
    end
  end
  if done_powerup != nil then
    if(done_powerup.type=="weapon" or done_powerup.type=="instant") then
    elseif done_powerup.type=="stat" then
      player[done_powerup.key]=player_original_stats[done_powerup.key]
    else
      show_effect_text"fix cooldown_powerups"
    end
    del(active_powerups, done_powerup)

    if(done_powerup.type != "instant") sfx(19)
  end
end

inputx=0
inputy=0

function control_player()
  x=0
  y=0

  if stunnedframes<=stuncooldown then
    if gamerunning and not(isintro and run_timer) then
      if (btn(4) or btn(5,1) or rmbdown) and can_t==0 then
        start_can()
      end

      inputx=0
      inputy=0
      if(btn(0,0) or btn(0,1)) inputx -= 1
      if(btn(1,0) or btn(1,1)) inputx += 1
      if(btn(2,0) or btn(2,1)) inputy -= 1
      if(btn(3,0) or btn(3,1)) inputy += 1

      if can_t==0 then
        x=inputx
        y=inputy
      end
    end
  end

  if(stunnedframes!=0)stunnedframes -=1

  playerstill=x==0 and y==0

  if x==0 then
    if abs(player.dx)<player.accel then
      player.dx=0
    else
      sign=player.dx / abs(player.dx)
      player.dx -= sign * player.accel
    end
  else
    player.dx += x * player.accel
  end
  if y==0 then
    if abs(player.dy)<player.accel then
      player.dy=0
    else
      sign=player.dy / abs(player.dy)
      player.dy -= sign * player.accel
    end
  else
    player.dy += y * player.accel
  end
  -- clamp
  spd=sqrt(player.dx*player.dx+player.dy*player.dy) / player.maxspd
  if spd>1 then
    player.dx /= spd
    player.dy /= spd
  end

  if(abs(player.dx)>0 and check_collisions(player.x, player.y, player.dx, player.dy, true)) then
    player.x += player.dx
    player.x=((player.x\8) * 8)+((player.dx<0) and 8 or 0)
  else
    player.x += player.dx
  end
  if(abs(player.dy)>0 and check_collisions(player.x, player.y, player.dx, player.dy, false)) then
    player.y += player.dy
    player.y=((player.y\8) * 8)+((player.dy<0) and 8 or 0)
  else
    player.y += player.dy
  end

  -- powerups
  collected_powerup=nil
  for p in all(powerups) do
    for i=0,(p.sprites==nil and 0 or p.sprites-1) do
      if(collected_powerup==nil and distance_basic(player,{x=p.x+i*8,y=p.y})<8) collected_powerup=p
    end
  end
  if collected_powerup != nil then
    apply_powerup(collected_powerup)
    del(powerups, collected_powerup)
  end

  -- current weapon
  p_weapon=nil
  for p in all(active_powerups) do
    if(p_weapon==nil and p.type=="weapon") p_weapon=p
  end
  p_weapon=p_weapon or player.default_weapon

  player.weapon_cooldown=max(player.weapon_cooldown-1, 0)
  local melee=p_weapon.melee or false
  if(not melee and stunnedframes<=stuncooldown and not isintro and lmbdown and player.weapon_cooldown==0 and can_t==0) then
    shoot_bullet()
    player.weapon_cooldown=p_weapon.cooldown
  end

  if(p_weapon.name=="chainsaw") screen_shake=max(screen_shake, 1)

  --enemy collisions
  range=p_weapon.range or 8
  for e in all(enemies) do
    if p_weapon.name == "the crucible" then
      xx,yy=world_to_screen(player.x-4, player.y-4)
      dx=mousex-xx
      dy=mousey-yy
      mag=magnitude(dx,dy)
      centre={
        x=4+player.x+(14*dx/mag),
        y=4+player.y+(14*dy/mag)
      }
    else centre=player end
    if distance_basic(centre, e)<range then
      if melee then
        hurt_enemy(e, p_weapon.damage)
        if(p_weapon.name=="chainsaw") screen_shake=min(screen_shake+2, 20)
      else --knockback
        player.dx=(player.x-e.x)*2
        player.dy=(player.y-e.y)*2
      end
    end
  end
end

function update_mouse()
  mousex=stat(32)
  mousey=stat(33)
  lmbdown=(stat(34)&1) and gamerunning
  rmbdown=(stat(34)&2==2) and gamerunning
  clickl=lmbdown and oldlmb != lmbdown
  --clickr=rmbdown and oldrmb != rmbdown
  oldlmb=lmbdown
  oldrmb=rmbdown
end

function add_flower_patch(x, y, num, radius, health)
  radius=radius or 12
  health=health or 100
  sprites={}
  mainflower=flr(rnd(4))+2
  for i=1,num do
    sprite=(rnd(1)<0.2) and flr(rnd(4))+2 or mainflower
    local xx, yy=get_random_point_around(x,y, radius)
    add(sprites, {
      x=flr(xx-4),
      y=flr(yy-4),
      alivesprite=sprite,
      sprite=sprite,
      flip_x=(rnd(1)<0.5)
    })
  end
  add(flowers, {
    x=x,
    y=y,
    health=health,
    maxhealth=health,
    sprites=sprites,
    maincolor=mainflower,
    grass=flr(rnd(5)),
  })
end

function add_enemy(x, y)
  local class=(wave>=2 and rnd(1)<0.3) and "gun" or "eat" --from wave 3 onwards
  --local class=(rnd(1)<0.5) and "gun" or "eat" --debug

  e={
    x=x,
    y=y,
    maxspd=(class=="gun" and 0.8 or 0.5),
    attackdist=(class=="gun" and 32 or 8),
    damage=0.3,
    sprite=45,
    health=100,
    dead=false,
    maxhealth=100,
    base_sprite=(class=="gun" and 88 or 104),
    class=class,
    phase=flr(rnd(30)),
    retarget=retarget_time
  }
  if class=="gun" then
    e.target=player
  else
    target=nil
    targetdist=maxval
    for f in all(flowers) do
      dist=distance_basic(e, f)
      if dist<targetdist then
        target=f
        targetdist=dist
      end
    end
    e.target=target
  end

  target_enemy(e)

  add(enemies, e)
end

function target_enemy(e)
  if(e.class=="gun" or rnd(1)<0.3) then
    e.target=player
  else
    target=nil
    targetdist=maxval
    for f in all(flowers) do
      dist=distance_basic(e, f)
      if dist<targetdist then
        target=f
        targetdist=dist
      end
    end
    e.target=target
  end
end

function add_random_powerup(x, y)
  add_powerup(x, y, available_powerups[flr(rnd(#available_powerups))+1])
end

function add_powerup(x, y, powerup)
  p={
    x=x,
    y=y
  }
  for k,v in pairs(powerup) do
    p[k]=v
  end
  add(powerups, p)
end

function add_tumbleweed()
  x,y=get_random_point(true)
  add(tumbleweeds, {
    x=x,
    y=y,
    sprite=151,
    progress=0,
    direction=(rnd(1)<0.5) and 1 or (-1)
  })
end

function update_tumbleweeds()
  dead_tumbleweed=nil
  for t in all(tumbleweeds) do
    if(t.x<0 or t.x>worldsizex) dead_tumbleweed=t
    t.x += t.direction * 2
    t.progress=(t.progress+t.direction) % 8
    t.sprite=151+(t.progress\2)
  end
  if(dead_tumbleweed != nil) del(tumbleweeds, dead_tumbleweed)
end

function is_onground(x,y)
  return x>0 and y>0 and x<worldsizex and y<worldsizey and not fget(mget(x\8,y\8),0)
end

function get_random_point(offscreen, onground)
  offscreen=offscreen or true
  onground=onground or false
  local x,y=0,0
  repeat
    x=flr(rnd(worldsizex-32))+16
    y=flr(rnd(worldsizey-32))+16
    allowed=true
    if(offscreen) allowed=allowed and (x<screenx or x>screenx+128 or y<screeny or y>screeny+128)
    if(onground) allowed=allowed and is_onground(x,y)
  until(allowed)
  return x,y
end

function get_random_point_around(cx,cy,maxradius, minradius)
  minradius=minradius or 0
  local x,y=0,0
  repeat
    local dist=rnd(maxradius-minradius)+ minradius
    local angle=rnd(1)
    x, y=cx+dist*cos(angle), cy+dist*sin(angle)
  until(is_onground(x,y))
  return x,y
end

function open_menu()
  gameover=false
  gamerunning=false
  controlsscreen=false
  music(40)
  reset_doomfire()
end

function _init()
  open_menu()
end

function start_game(frommenu)
  player.x=playerstartx
  player.y=playerstarty
  p_weapon=player.default_weapon
  screenx=screenstartx
  screeny=screenstarty
  isintro=frommenu


  flowers={}
  enemies={}
  powerups={}
  active_powerups={}
  for k,v in pairs(player_original_stats) do
    player[k]=v
  end
  t=0
  time=0
  score=0
  kills=0
  wave=-1
  wave_nextwavestarttime=-1
  wave_spawntimeend=-1

  --place flowers
  add_flower_patch(192, 128, flr(rnd(5))+20, 25, 200) --place patch in center

  for i=1,9 do
    local centerx, centery=get_random_point(false, true)
    add_flower_patch(centerx, centery, flr(rnd(5))+6)
  end

  if isintro then
    --choose 3 random patches to damage
    flowers[1].health=150+rnd(25)
    local i=0
    repeat
      local f=flowers[flr(rnd(#flowers)+1)]
      if f.health==f.maxhealth then
        f.health=50+rnd(25)
        i+=1
      end
    until i==2

    music(8,500)
    run_timer=false
  else
    music(0,0,1)
    run_timer=true
  end

  --TEMP
  -- for i=1,#available_powerups do
  --   add_powerup(114+17*i, 115, available_powerups[i])
  -- end

  gamerunning=true
  gameover=false
  screen_shake=10 --yaas
end

function shoot_bullet()
  dx=mousex+screenx-weapontipx
  dy=mousey+screeny-weapontipy
  mag=magnitude(dx,dy)

  if p_weapon.sniper then
    for e in all(enemies) do
      --|(e-tip) X dir|/|dir|, cross cancels to a1b2-a2b1
      vx=e.x-weapontipx
      vy=e.y-weapontipy
      dist=(vx*dy-vy*dx)/mag
      dot=vx*dx+vy*dy
      if(dist<3 and dot>0) hurt_enemy(e, p_weapon.damage)
    end
  else
    dx /= mag * bulletspeed
    dy /= mag * bulletspeed
    local n=p_weapon.bulletspershot or 1
    if(abs(player.dx)>0 or abs(player.dy)>0) then
      pmag=magnitude(player.dx, player.dy)
      dot=dx*(player.dx/pmag)+dy*(player.dy/pmag)
      if(dx*player.dx<0) dot=0
      if(dy*player.dy<0) dot=0
      dx += dx*0.5*dot
      dy += dy*0.5*dot
    end
    flip_x=false
    flip_y=false
    if p_weapon.bullet_sprite==nil then
      sprite_base=player.default_weapon.bullet_sprite
      animated=player.default_weapon.bullet_animated
    else
      sprite_base=p_weapon.bullet_sprite
      animated=p_weapon.bullet_animated or false
    end

    if abs(dx)>abs(dy) then
      if dx<0 then
        flip_x=true
      end
    else
      sprite_base += (animated and 2 or 1)
      if dy>0 then
        flip_y=true
        --sprite_base += 2--(animated and 2 or 1)
      end
    end
    for i=1,n do
      local b={
        x=weapontipx-4, --for sprite centering
        y=weapontipy-4,
        dx=dx * (n>1 and 1+rnd(1)/4 or 1),--for scattering
        dy=dy * (n>1 and 1+rnd(1)/4 or 1),
        sprite_base=sprite_base,
        sprite=sprite_base,
        animated=animated,
        flip_x=flip_x,
        flip_y=flip_y,
        damage=p_weapon.damage,
        life=bulletlife,
        dead=false,
        particles=p_weapon.particles,
        splash_radius=p_weapon.splash_radius,
        shake=p_weapon.shake
      }
      add(bullets, b)
    end
  end

  sfx(0, -1)
  random_effect_text(shoot_texts, 0.05)
  screen_shake=p_weapon.shake
  if(p_weapon.particles) oneshot_splash(weapontipx-4,weapontipy-4, p_weapon.particles)
end

kill_sfx_this_frame=false

function hurt_enemy(e, damage)
  e.health -= damage
  if e.health<=0 then
    if(rnd(1)<powerup_chance) add_random_powerup(e.x, e.y)
    del(enemies, e)
    kills += 1
    if not kill_sfx_this_frame then sfx(8) kill_sfx_this_frame=true end
    oneshot_splash(e.x,e.y, {count=10,sprite=50,gravity=0.001,lifetime=10})
    score += e.maxhealth * killscorescaler
    random_effect_text(kill_texts, 0.1)
  end
end

function do_splash_damage(b)
  for e in all(enemies) do
    if distance_basic(b,e)<b.splash_radius then
      hurt_enemy(e, b.damage)
    end
  end
end

function update_bullets()
  deadbullet=nil
  for b in all(bullets) do
    if not b.dead then
      b.x += b.dx
      b.y += b.dy
      b.life -= 1
      if(b.animated) b.sprite=b.sprite_base+(t%2) --32+(b.sprite-28) %8 --cycle sprite
      if b.life<0 then
        b.dead=true
        if(b.particles) oneshot_splash(b.x,b.y, b.particles)
        if(b.splash_radius>0) do_splash_damage(b)
      else
          if b.evil then
            if distance_basic(b,player)<8 and stunnedframes==0 then
              stunnedframes=gunnerstunduration+stuncooldown
              b.dead=true
            end
          else
            hit_enemy=nil
            for e in all(enemies) do
              if distance_basic(b,e)<8 then
                hit_enemy=e
              end
            end
            if hit_enemy != nil then
              b.dead=true
              if(b.particles) oneshot_splash(b.x,b.y, b.particles)
              sfx(6)
              screen_shake=b.shake
              if b.splash_radius>0 then do_splash_damage(b)
              else hurt_enemy(hit_enemy, b.damage) end
            end
          end
      end
    else
      deadbullet=b
    end
  end
  if(deadbullet != nil) del(bullets, deadbullet)
end

function is_powerup_on(n)
  for p in all(active_powerups) do
    if(p.name==n) return true
  end
  return false
end

function add_enemy_bullet(e)
  local bx=e.x+(e.flip_x and -4 or 6)
  local by=e.y+2
  local dx=player.x-bx
  local dy=player.y-by
  mag=magnitude(dx,dy) * bulletspeed

  flip_x=false
  flip_y=false
  sprite_base=40
  if abs(dx)>abs(dy) then
    if dx<0 then
      flip_x=true
    end
  else
    sprite_base += 1
    if dy>0 then
      flip_y=true
    end
  end

  local b={
    evil=true,
    x=bx, --for sprite centering
    y=by,
    dx=dx/mag,
    dy=dy/mag,
    sprite_base=sprite_base,
    sprite=sprite_base,
    animated=false,
    flip_x=flip_x,
    flip_y=flip_y,
    life=bulletlife,
    dead=false,
    splash_radius=0 --prevents crash
  }
  add(bullets, b)
  sfx(0)
  oneshot_splash(bx, by, {count=5,sprite=50,gravity=0.001,lifetime=6})
end

function update_enemies()
  deadenemy=nil
  for e in all(enemies) do
    if(not gameover) then
      e.retarget -= 1
      if e.retarget==0 then
        target_enemy(e)
        e.retarget=retarget_time
      end
    end
    if(not e.dead and e.target != nil) then
      targetdist=distance(e, e.target)
      e.moving=(targetdist>e.attackdist)
      e.flip_x=e.target.x<e.x
      if e.moving then
        --show_effect_text(""..targetdist)
        e.x += (e.maxspd / targetdist) * (e.target.x-e.x)
        e.y += (e.maxspd / targetdist) * (e.target.y-e.y)
      else --doing action
        if e.class=="eat" then
          if(e.target.health != nil) e.target.health=max(e.target.health-e.damage, 0)

          if(not gameover and e.target.health != nil and t%15==9) oneshot_splash(e.x, e.y, {count=4,sprite=52+e.target.maincolor,gravity=0.001,lifetime=10})
        else
          if(e.phase+t)%gunershootspeed==0 then
            add_enemy_bullet(e)
          end
        end
      end
      e.dead=false
    else
      deadenemy=e
    end
  end
  if(deadenemy != nil) del(enemies, deadenemy)
end

function update_health()
  health=1
  weakest_flower=nil --makes the compiler happy

  for f in all(flowers) do
    frac = f.health/f.maxhealth
    if frac<health then
      weakest_flower=f
      health=frac
    end
  end
  health*=100

  if isintro and not run_timer and weakest_flower==nil then --END INTRO
    music(-1)
    --isintro=false
    run_timer=true
    wave_nextwavestarttime=time+4.1
    wave_originx, wave_originy=get_random_point_around(player.x, player.y, wave_originrubberband, 128) --enforce rubberbanding for first enemy
    increment_wave()
    wave_spawn_enemy()
    oldscreenx=screenx
    oldscreeny=screeny
    enemyscreenx=enemies[1].x -64
    enemyscreeny=enemies[1].y -64
  end
end

function increment_wave()
  wave+=1
  wave_enemycount=wave_enemycountbase+wave_enemycountdelta * wave
  wave_spawned=0
  wave_spawnwait=wave_spawnduration/wave_enemycount
  wave_originsize=wave_originsizebase+wave_originsizedelta * wave
  wave_nextspawntime=wave_spawnwait
  desiredmusic=min(2*(wave\2), 6)
end

function wave_spawn_enemy()
  local x,y=get_random_point_around(wave_originx, wave_originy, wave_originsize)
  add_enemy(x, y)
  wave_spawned+=1
end

function update_wave()
  if wave_nextwavestarttime != -1 then --downtime
    if time>=wave_nextwavestarttime then
      --start wave
      show_effect_text("wave "..(wave+1))

      wave_nextwavestarttime=-1
      wave_originx, wave_originy=get_random_point_around(player.x, player.y, wave_originrubberband, 128)
    end
  else --mid-wave time
    if wave_spawned != wave_enemycount then --mid-spawn

      wave_nextspawntime -= 0.0333333333
      if wave_nextspawntime<=0 then
        wave_spawn_enemy()
        wave_nextspawntime=wave_spawnwait
      end

    else --cleanup time
      if not isintro and #enemies==0 then --all enemies cleared, begin downtime
        --show_effect_text("start of downtime")
        increment_wave()
        wave_nextwavestarttime=time+wave_downtime-(wave==0 and 3 or 0)
      end
    end

  end
end

function _update()
  if(rnd(1)<0.005) add_tumbleweed()
  kill_sfx_this_frame=false

  update_tumbleweeds()
  update_mouse()
  cooldown_powerups()
  control_player()
  update_bullets()

  if(not isintro) update_enemies()

  isweaponleft=mousex<=player.x-screenx
  isfacingdown=mousey>=player.y-screeny

  if can_t>0 then
    update_can()
    if(inputx!=0) isweaponleft=inputx<=0
    if(inputy!=0) isfacingdown=inputy>=0
  end

  if gamerunning then

    if(run_timer) time += 0.0333333333

    if(isintro and t==60) show_effect_text("water plants", true)

    if run_timer and isintro then
      if(time>1 and time<1.04) show_effect_text("protect the garden", true)
      if time<1 then
        screenx=outCubic(time, oldscreenx, enemyscreenx-oldscreenx, 1)
        screeny=outCubic(time, oldscreeny, enemyscreeny-oldscreeny, 1)
      elseif time>3 and time<4 then
        oldscreenx=player.x-64
        oldscreeny=player.y-64
        screenx=outCubic(time-3, enemyscreenx, oldscreenx-enemyscreenx, 1)
        screeny=outCubic(time-3, enemyscreeny, oldscreeny-enemyscreeny, 1)
      elseif time>4 then
        isintro=false
        music(0,0,1)
      end
    else
      --move screen
      pxs=player.x-screenx
      pys=player.y-screeny
      screenx=screenx+max(pxs-128+screenborder,0)-max(screenborder-pxs,0)
      screeny=screeny+max(pys-128+screenborder,0)-max(screenborder-pys,0)
    end

    if not isintro then
      score += 0.2
       if((stat(24)%2==0 and stat(26)==0) or stat(24)==-1) music(desiredmusic,0,1) --if current music id is even numbered and we're at step 0, or no music is playing,
    end

    update_health()
    update_wave()
    --critical health sfx
    if(health<30 and t%16==0) sfx(4)

    if health==0 then
      --end the game
      music(51)
      gamerunning=false
      gameover=true --must come after show text effect
      t_die=0
      oldscreenx=screenx
      oldscreeny=screeny
      dstscreenx=weakest_flower.x-screenx-64
      dstscreeny=weakest_flower.y-screeny-64
    end

  else
    if gameover then
      if t_die>50 then
        if(btnp(5)) start_game(false)
        if(btnp(4)) open_menu() --go to title screen
      end
    else --main menu
      if btnp(5) then
        if(controlsscreen and startcountdown==nil) then
          startcountdown=startcountdownframes
          music(-1)
          sfx(22)
          sfx(23)
          kill_doomfire()
        else controlsscreen=true end
      end
    end
  end

  if startcountdown != nil then
    startcountdown -= 1
    if startcountdown==0 then
      startcountdown=nil
      startcountdown2=30
      poke(0x5F2D, 1) --enable mouse
      start_game(true)
    end
  end
  if(startcountdown2 != nil) startcountdown2 -= 1
  if(startcountdown2==0) startcountdown2=nil

  --update effects
  screen_shake_x=rnd(screen_shake*2)-screen_shake
  screen_shake_y=rnd(screen_shake*2)-screen_shake
  ui_shake_x=(-0.5) * screen_shake_x
  ui_shake_y=(-0.5) * screen_shake_y
  screen_shake=max(screen_shake-screen_shake_decay, 0)
end

--DRAW FUNCTIONS

function world_to_screen(x,y)
  return x-screenx+screen_shake_x, y-screeny+screen_shake_y
end

function draw_sprite(spriteno, x, y, flip_x)
  flip_x=flip_x or false
  x,y=world_to_screen(x,y)
  spr(spriteno, x, y, 1, 1, flip_x)
end

function draw_object(obj, draw_shadow)
  x,y=world_to_screen(obj.x,obj.y)
  if(draw_shadow) spr(66, x,y+1)
  sprites=obj.sprites or 1
  for i=1,sprites do
    spr(obj.sprite+i-1, x+8*(i-1), y, 1, 1, obj.flip_x or false, obj.flip_y or false)
  end
end

function draw_arrow(obj, dir)
  spr(112+dir, min(max(((obj.x-screenx)\4)*4, 4), 116), min(max(((obj.y-screeny)\4)*4, 4), 116))
end

function draw_enemies()
  for e in all(enemies) do
    if e.moving or gameover then
      e.sprite=e.base_sprite+(t\8)%2
    else
      e.sprite=e.base_sprite+2+ (t\3)%5
    end
    if(gameover) e.flip_x=(t%26)>=13
    if(not e.dead) draw_object(e, true)
  end
end

function draw_lava()
  rectfill(0,0,127,127,10)
  --map(51,10)
  for i=0,127 do
      for iters=0,10 do
        itersworld=iters+screeny\12.5
        ii=i+screenx-screen_shake_x+itersworld*10-t/10
        local y= sin(t/53+itersworld/7)*sin(ii/32)*4+i%2*0.4
        w=5
        local offset=12.5*iters+(screen_shake_y-screeny)%12.5
        rectfill(i,offset-w+y,i,offset+w+y, 9)
      end
  end
end

ghosts={{maxval,maxval},{maxval,maxval},{maxval,maxval},{maxval,maxval}}
flower_cols={10,12,8,9,14}

function draw_player()
  draw_sprite(66, player.x,player.y+1) --shadow

  oldpos={player.x, player.y}
  if is_powerup_on"speed juice" then
    --draw ghosts
    for i=4,1,-1 do
      draw_sprite(84, ghosts[i][1], ghosts[i][2])
      if i==1 then --update chost
        ghosts[i]=oldpos
      else
        ghosts[i]=ghosts[i-1]
      end
    end
  end

  --bloomguy
  if gameover then --cry
    player.sprite=97+(t\10)%2
    if(t%5==0) make_particle(axis((player.x+(t%10==0 and 2 or 4)-screenx)/127), axis((player.y+3-screeny)/127,0,0.001), {0,24}, axis(), 10+rnd(3))

  else
    if playerstill then
      player.sprite=(isfacingdown and 96 or 100)+max((t\4)%6-2,0)
    else
      player.sprite=(isfacingdown and 80 or 82)+(t\5)%2
      if(isintro and t%5==0)sfx(17)
    end
  end
  draw_object(player, false)

  local tipoffx=p_weapon.tipx or -5
  local tipoffy=p_weapon.tipy or 3
  weapontipx=player.x+(isweaponleft and tipoffx or 8-tipoffx)
  weapontipy=player.y+tipoffy



  --weapon
  if p_weapon.name =="the crucible" then
    xx,yy=world_to_screen(player.x, player.y)
    dx=mousex-xx
    dy=mousey-yy
    mag=magnitude(dx,dy)
    sa=dy/mag
    ca=-dx/mag

    for i=0,3 do
      rspr(112-i*8,72, xx- (8*i-4)*ca-3+3*sa,yy+(8*i)*sa-4+3*ca, 2, sa,ca)
    end
  else
    weaponsprite=(p_weapon.sprites==nil) and p_weapon.sprite or nil
    if(isintro) weaponsprite=-1
    if can_t>0 then
      if can_t>5 and can_t<25 then
        weaponsprite=68
      else weaponsprite=67
      end
    else
      if p_weapon.sniper then
        x0, y0=world_to_screen(weapontipx, weapontipy)
        dx=mousex-x0
        dy=mousey-y0
        line(x0, y0,x0+dx*128, y0+dy*128, 8)
      end
    end

    if weaponsprite != nil then
      draw_sprite(weaponsprite, player.x+(isweaponleft and -8 or 8), player.y, not isweaponleft)
    else
      for i=1,p_weapon.sprites do
        draw_sprite(p_weapon.sprite+i-1, player.x+8*(i-p_weapon.sprites)*(isweaponleft and 1 or -1), player.y, not isweaponleft)
      end
    end
  end

  if(stunnedframes>stuncooldown) draw_sprite(52+(t\2)%2,player.x,player.y-2) --stun stars
end

function _draw()
  if not (gamerunning or gameover) then --MENU
    cls()
    draw_doomfire()
    logo_offset=(startcountdown==nil) and 0 or (startcountdownframes-startcountdown)
    map(112,0,0)
    print("eternal",51,58, 9)
    print("eternal",51,57, 7)
    if controlsscreen then
      controlsstr="controls:\n\x8b\x94\x83\x91/esdf: move\nLMB: shoot gun\nq/RMB: water plants\n\ndon't let the flowers die!"
      print_outline(controlsstr, 18,70,7)
      if(t%40<20) print_outline("press \x97 to begin",31,110, 7) --1s on, 1s off
    else
      if(t%40<20) print_outline("press \x97",48,100, 7) --1s on, 1s off

      print("sam b", 1,116, 0)
      print("@samboyer276", 1,122, 0)
      print("josh s", 104,116, 0)
      print("@smailesyboi", 80,122, 0)
    end
    palt(0) --doomguy silhouette
    palt(14)
    spr(85, 60, 120)
    palt()

    if(startcountdown != nil and startcountdown<34) then
      dither_rect(0,0,128,128,0,(35-startcountdown)\2)
    end
  else
    draw_lava()

    sx=screenx-screen_shake_x
    sy=screeny-screen_shake_y
    ox=sx%8
    oy= sy%8
    cx=min((worldsizex-screenx)\8,17)
    cy=min((worldsizey-screeny)\8,17)

    map((sx-ox)/8,(sy-oy)/8,-ox,-oy, cx, cy)

    --flowers
    for f in all(flowers) do
      x,y = world_to_screen(f.x-f.x%8-8,f.y-f.y%8-8)
      map(70,f.grass*3,x,y,3,3)
      for s in all(f.sprites) do
        s.sprite= f.health<40 and 22 or s.alivesprite
        draw_object(s)
      end
    end

    foreach(powerups, draw_object)
    foreach(tumbleweeds, draw_object)
    draw_enemies()
    draw_player()

    --bullets
    for b in all(bullets) do
      if(not b.dead) draw_object(b)
    end

    update_particles()
    draw_particles()

    --world-space flower healthbars
    for f in all(flowers) do
      if gamerunning and f.health<f.maxhealth then
        x0, y0=world_to_screen(f.x-8,f.y-9)
        x1,y1=world_to_screen(f.x+8,f.y-8)
        --rect(x0,y0,x1,y1, 7) --health bar
        frac=f.health/f.maxhealth
        col=(frac<0.5) and 8 or 9
        rectfill(x0, y0, lerp(x0,x1, frac), y1, col)
      end
    end

    if is_powerup_on"raincloud" then
      for i=1,15 do
        x,y=rnd(128),rnd(128)
        line(x,y,x+1,y+3,12)
      end
    end


    --UI
    if gamerunning then
      if oldlmb then ret=17 else ret=16 end
      spr(ret, mousex-3+ui_shake_x, mousey-3+ui_shake_y)

      -- powerup bar
      if #active_powerups>0 then
        pu=active_powerups[1]
        if pu.type != "instant" then
          rect(20,110, 122,113, 7)
          print(pu.name, 21+ui_shake_x, 104+ui_shake_y)
          col=(pu.type=="weapon") and 9 or 11
          rectfill(21+ui_shake_x,111+ui_shake_y, lerp(21, 121, pu.life/pu.lifetime)+ui_shake_x,112+ui_shake_y, col)
        end
      end

      -- health bar
      spr(46, 2+ui_shake_x,110+ui_shake_y, 2,2)
      rect(20,115, 122,122, 7)
      col=(health>30) and 14 or 8
      rectfill(21+ui_shake_x,116+ui_shake_y, lerp(21, 121, health/100)+ui_shake_x,121+ui_shake_y, col)


      --weakest flower direction
      if weakest_flower != nil then
        local dx=(weakest_flower.x-player.x)/100
        local dy=(weakest_flower.y-player.y)/100
        local mag=magnitude(dx,dy)*0.2

        dir=get_dir8(dx, dy)
        --flash arrow when health v low, or during intro
        if not (isintro and t%8>3 and t<150) then
         if(health>40 or (health>15 and t%8>3) or (health<=15 and t%4>1)) spr(120+dir, 7+dx/mag, 114+dy/mag)
        end
      end
    end
    print("score: "..flr(score), 2+ui_shake_x,2+ui_shake_y, 7)
    spr(45, 105+ui_shake_x,1+ui_shake_y)--kills
    print(kills, 115+ui_shake_x,2+ui_shake_y, 7)

    --draw enemy indicators
    for e in all(enemies) do
      if not e.dead then
        ex=e.x-screenx-64
        ey=e.y-screeny-64
        if abs(ex)>64 or abs(ey)>64 then
          dir=get_dir8(e.x-screenx-64, e.y-screeny-64)
          draw_arrow(e, dir)
        end
      end
    end

    if(effect_text_time>0) draw_effect_text();


    if gameover then
      spr(206, 2+ui_shake_x,110+ui_shake_y, 2,2)

      t_die +=1
      if t_die<=50 then
        screenx=outCubic(t_die, oldscreenx, dstscreenx, 50)
        screeny=outCubic(t_die, oldscreeny, dstscreeny, 50)
        if(t_die==50) random_gameover_text()
      else
        effect_text_time=max(effect_text_time,1) --infinite text effect
        if(t_die%40<20) print("press \x97 to restart\n\n press \x8e for menu",31,100, 7) --1s on, 1s off
      end
    end

    if startcountdown2 != nil then
      dither_rect(0,0,128,128,0,max(startcountdown2\2,1))
    end
  end

  t+=1

  --DEBUG
  --print(flr(stat(1)*100) .. "% CPU",0,16,7)
  --print(stat(7).." fps", 0, 24, 7)

end

-->8
--
-- EFFECTS

fierycolours={5,8,9,14,15,9}

flag_ripandtear=false
flag_saucyboy=false

function random_effect_text(list, chance)
  if(isintro) return

  chance=chance or 0.3
  if not flag_ripandtear and rnd(1)<chance then
    flag_ripandtear=true
    show_effect_text"rip and tear"
  else
    if(rnd(1)<0.3) list=generic_texts
    if(rnd(1)<chance) show_effect_text(list[flr(rnd(#list))+1])
  end
end

function random_gameover_text()
  s=gameover_texts[flr(rnd(#gameover_texts-(flag_saucyboy and 0 or 1)))+1]
  show_effect_text(s, true, false)
end

function show_effect_text(text, override, playsfx)
  if(text==generic_texts[1]) flag_saucyboy=true
  if(gameover and not override) return
  if(playsfx==nil) playsfx=true
  effect_text=text
  effect_text_time=40
  effect_text_effect=flr(rnd(effect_count))
  if(playsfx) sfx(5)
end

effect_text=nil
effect_text_effect=0
effect_text_time=0
effect_text_width=6
effect_count=10
function draw_effect_text()
  if type(effect_text)=="string" then
    draw_text(effect_text, 40)
  else
    text=effect_text[1]
    for i=2,#effect_text+1 do
      draw_text(sub(text, ((i==2) and 0 or effect_text[i-1])+1, (i==#effect_text+1) and #text or effect_text[i]), 35+10*(i-2))
    end
  end
end

function draw_text(text, texty)
  effect_text_time -= 1;

  textx=(128-effect_text_width * #text)\2+(rnd(1)<0.1 and rnd(1)-.5 or 0) + ui_shake_x
  texty+=ui_shake_y

  if effect_text_effect<4 then
    for j=1,#text do
      text_offset=effect_text_width*(j-1)
      for i=0,6 do
        trig_oper=t/30+j/5+i/30
        offset_x=2 * ((effect_text_effect % 2==0) and sin(trig_oper) or cos(trig_oper))+text_offset
        offset_y=5 * sin(trig_oper)
        print(sub(text,j,j), textx+offset_x, texty+offset_y, fierycolours[1+(i-effect_text_time\2)%#fierycolours])
      end
      print(sub(text,j,j), textx+text_offset, texty, (effect_text_effect>1) and (t%2)*7 or 0)
    end
  elseif effect_text_effect<8 then
    for j=1,#text do --per char
      text_offset=effect_text_width*(j-1)
      for i=1,6 do --per copy of char
        col=(effect_text_effect % 2==0) and fierycolours[1+(i-effect_text_time\2)%#fierycolours] or 9 --either rainbow or orange
        if effect_text_time<33+i and effect_text_time>i then
          print(sub(text,j,j), textx-i+text_offset, texty+i, col)
        end
      end
      if effect_text_time<33 then
        print(sub(text,j,j), textx+text_offset, texty, (effect_text_effect>5) and (t%2)*7 or 0)
      end
    end
  elseif effect_text_effect<10 then
    for j=1,#text do
      text_offset=effect_text_width*(j-1)
      offset_x=text_offset
      offset_y=0
      col=fierycolours[1+(t+effect_text_time\2)%#fierycolours]
      print_outline(sub(text,j,j), textx+offset_x+ui_shake_x, texty+offset_y, (effect_text_effect%2==0) and 7 or col, (effect_text_effect%2==0) and col or 7)
    end
  end
end

water_texts={
  "epic water combo",
  {"wow that's a niceflower",17},
  "+10,000 nook miles",
  "flower power",
  "splish splash",
  "hydro homie"
}

kill_texts={
  "combo",
  "super combo",
  "mega combo",
  "ultra combo",
  "wombo combo",
  "kill bill",
  "sluggernaut",
  "you monster",
  "rip and tear",
  {"death comesto us all",11},
  "yaass slayy",
  "slug is kil"
}

shoot_texts={
  "wow bullet",
  "bang bang",
  "pew pew",
  "brrap brrap"
}

generic_texts={
  "you are a saucy boy", --keep first!
  "you legend",
  "amazing",
  "outstanding move",
  "huzzah",
  "exceptional",
  "magnificent",
  "phenomenal",
  "tubular",
  "stonks",
  "far out",
  "wicked",
  "radical",
  "awesome",
  "groovy",
  "glorious",
  "sensational",
  "divine",
  "neato",
  "you did the thing",
  "sample text",
  "hey! listen!",
  "owo what's this",
  "yeet",
  "qpuS aligned",
  "reticulating splines",
}

gameover_texts={
  {"change da worldmy final messagegoodb ye", 15, 31},
  "ded",
  "rip",
  "*pacman death sound*",
  "you died",
  "game over",
  "you lose",
  {"mission failed. we'llget em next time",21},
  "death",
  {"dehydration comesto us all",17},
  "you had two jobs",
  "flower says goodbye",
  "bloom-slain",
  {"omae wa moushindeiru",11},
  {"\"everything not savedwill be lost\"",21},
  {"you lose(the flowers)",8},
  "f",
  {"all your baseare belong to slug",13},
  "sad violin sounds",
  {"you are nota saucy boy",11} --keep last!
}

__gfx__
0000000000ff0ff0000000000000000000000000000000000000000000000000000000000000000000000000d3dddd3d3dddd3dd000000000dd3ddd33ddd3dd0
0700007000ff0ff000000000000000000000000000000000000000000000000000000000000000dddd000000d3dd3d3d0d3dd3d30000000d0003ddd33d3d3dd0
0070070000fffff00000000000000000000000000000000000000000000000000000000000003dd33ddd0000dddd3dd0003dddd30000000300000ddddd3ddd00
0007700000f8ff8000000a0000c00000000008000000090000000e000000000000000000000d3dd33d3dd000dd000000000ddd3d000000d3000003dddddddd00
0007700000fffff00000a7a00c7c000000008780000097900000e7e0000000000000000000dddddddd3d3d003d000000000d3d3d000000dd000003dd3dd3d000
007007000004440000000a0000c00000000008000000090000000e00000000000000000000ddd3dddddd3d003000000000003dd30dd3dddd00000d3d3dd30000
0700007000099900000003000030000000000300000003000000030000000000000000000dd3d3d3d3dddd30d0000000000000d3d3d3dd3d00000d3ddd000000
00000000000f0f0000000b0000b0000000000b0000000b0000000b0000000000000000000dd3ddd3d3dddd30000000000000000dd3dddd3d000000dd00000000
0000000000000000000000000000000000000000000000000000000000000000dd3dddddffffffffffffffffd3dddd3d3dddd3ddfff3dddd0000000000000000
060006000c000c00000000000000000000000000000000000000000000000000dd3dd3ddffffffddddffffffd3dd3d3dfd3dd3d3fdd3d3dd0000000000000000
0060600000c0c000000000000000000000000000000000000000000000000000ddddd3ddffff3dd33dddffffdddd3ddfff3dddd3fdddd3dd0000000000000000
0000000000000000000000000000000000000000000000000000000000000000d3ddddd3fffd3dd33d3ddfffddfffffffffddd3dd3ddddd30000000000000000
0060600000c0c000000000000000000000000000000000000000400000000000d3ddddd3ffdddddddd3d3dff3dfffffffffd3d3dd3ddddd30000000000000000
060006000c000c00000000000000000000000000000000000004740000000000ddd3ddddffddd3dddddd3dff3fffffffffff3dd3ddd3dddd0000000000000000
00000000000000000000000000000000000000000000000000004300000000003dd3dd3dfdd3d3d3d3dddd3fdfffffffffffffd33dd3dd3d0000000000000000
00000000000000000000000000000000000000000000000000000b00000000003ddddd3dfdd3ddd3d3dddd3ffffffffffffffffd3ddddd3d0000000000000000
0000000000000000000c7000000c700000000000000000005555500000055000000000000000000000000000000000000000000070000007000000eeee000000
000000000000000000cc700000cc70000000000000000000555555000055550000000000005050000000000000000000000000000777777000000eeeeee00000
c00cc7700c0c777000ccc00000ccc00000000000000000005565555005555550000050500005400000000000000c0000000000000766766000000eeeeee00000
00ccccc70cccccc700ccc00000ccc00000000000000500005656555555555555004445000004400000000000000c0000000000000766766000000eeeeee0eee0
c700ccc0c0c0ccc000cc000000c0700000055000000500005565555555565655044444000004400000cccc00000c000000000000077777700eee0eeeeeeeeeee
0000000000000000000c0000000cc00000000000000000005656555055656555000000000004400000000000000c00000000000000767600eeeeee9aaaeeeeee
000000000000000000007000000c000000000000000000005555550055565655000000000000400000000000000000000000000000767600eeeee9aa9aaeeeee
000000000000000000c0c0000000c00000000000000000005555500055555555000000000000000000000000000000000000000077777700eeeee9a9a9aeeeee
cc7ccc7caaaa9999444555440000000000a0000000000a00aaaaaaaacccccccc8888888899999999eeeeeeee000000000000000000000000eeeee9aa9aaeeee0
c7cc7cc7999998894444444500000000000000a00a000000aaaaaaaacccccccc8888888899999999eeeeeeee0000000000000000000000000eeee99aaa9eee00
cc7cc7cc8989559545544554000000000a000000000000a0aaaaaaaacccccccc8888888899999999eeeeeeee000000000000000000000000000eee9999eee000
cc7ccccc8898555844444444000000000000a000000a0000aaaaaaaacccccccc8888888899999999eeeeeeee000000000000000000000000000eeeeeeeeeee00
111c11c15858558555544445000000000000000000000000aaaaaaaacccccccc8888888899999999eeeeeeee00000000000000000000000000eeeeeeeeeeeee0
1c1111c15855588555555555000000000000000000000000aaaaaaaacccccccc8888888899999999eeeeeeee00000000000000000000000000eeeeee0eeeeee0
111c1c115558585555555555000000000000000000000000aaaaaaaacccccccc8888888899999999eeeeeeee00000000000000000000000000eeeeee00eeeee0
11c111c15585558555555555000000000000000000000000aaaaaaaacccccccc8888888899999999eeeeeeee000000000000000000000000000eee0000eeee00
00000000000000000000000000000000000000000000000000000000000055000066660000666600000000000000550000000000000000000000000000000000
000000000000bbb000000000000000000000000000000050000000000000655003bb8bb00666666600000000000500500000000000000000000c660000000000
000000000000bbb0000000000000e00000000000050005000000666660060555023888b05666666500505050500555500000006000000000000050000ccc0010
00006555009ccccc000000000e0eeee0000e0000655555550555666658550005023bbbb005665560506666666658888505555555056666c5556c6655cccac666
0000550300000c030000000000eeee03000eeee3000566930555666655555555023b8bb0005500500655555556588585004445430000006666666503c88cc161
000000550000000c00111100000eeee00eeeee0e000599640567666655555555023888b00c000c0c5666666666585583000000040000050305050055ccccc656
00000000000000000111111000000000000eeee0000066600067666660300000023bbbb00c00000c006666666658888500000000000000000050000088888666
00000000000000000011110000000000000000000000000000000000000000000066660000000000050505050505355000000000000000000000000050500505
00333d0000333d0000333d0000333d0000cccc00ee0000ee00000000000000005000000550000005500000055000000559444955500000055000000500000000
031112d0031112d0033333d0033333d00cccccc0e000000e0000000000000000059444900594449005944490594449504a949a00059444900594449000000000
0031130000311300003333000033330000cccc00ee0000ee000000000000000004a949a004a949a004a949a04a949a004ab4ab0004a949a004a949a000000000
035595300355953003555530035555300cccccc0e000000e000000000000000004ab4ab004ab4ab004ab4ab04ab4ab004444440004ab4ab004ab4ab000000000
30333303303333033033330330333303c0cccc0c0e0000e000000000000000000444444004444440044444404444440003444400044444400444444000000000
0053350000533500005335000053350000cccc00ee0000ee00000000000000000034555500344400003555500345555003455550034455550034555500000000
0030050000500300003005000050030000c00c00ee0ee0ee00000000000000000034540000035555003544000345400003454000034450000034540000000000
0000030000300000000003000000000000c00c00ee0ee0ee00000000000000003344440003345440334444003344400033444000334440003344440000000000
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
f0000000000000005fffffff0000000fffffffffffffffffffff44ff044044400004004004004004404004000000000000000000000000000000000000000000
ff00000000000000005ff000000000ffffffffffffff4fffffff4fff044004404044444044404400000440000000990000000000900900900550000000000000
ff0000000000000000000000000000fffff4ffffff4f4ffffff44fff004000404400404004040404044004040009890000000999999999999995000000000000
ff00000000000000000000000000005f4ff4fffff44f4ffff444ff4f040444404004040004400040440040040009889999999888888888888885005000000000
ff00000000000000000000000000000ff4f44f44ff44f44ffff4f4ff040004400004004444044040004040440098888888888888888888899955558500000000
f500000000000050000000000000000ff4f4f44ffff44ffffff444ff404040404440044004000400040400400009889999999888888888888885005000000000
f000000000005ff00000000000000005f44444fffff4fffffff444ff404404444404400000440000404444000009890000000999999999999995000000000000
500000005fffffff0000000000000000ff444ffffff4fffff44ff4ff400400000000040404440400040040000000990000000000900900900550000000000000
00000000000000000000000000000000ffffffffffffffff00000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000fffffffffffff5ff00000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000ffffffffff55ffff00000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000ffff55ffff555f5500000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000f5f555f55fffffff00000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000ffffffffff55ffff00000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000ff55ff5fffffff5500000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000ffffffffffffffff00000000000000000000000000000000000000000000000000000000000000000000000000000000
fffffffff00000000000005ffffffffffffffffffffffffffffffffffff50000000555fffff50ffffff55fff5fffffffffffffffffffffffffffffff00000000
fffffffff50000000000005f55fffffffffff550fffffffffffffffffffff500005fffffffff5ffffff5ffffffffffffffffffffffffffffffff5fff00000000
fffffffff5000000000000ff0055ffffffff50005fffffffffffffffffffff5005fffffffffffffffff5fffffffffffffffff0fffffffffff50f0f5f00000000
ffffffffff500000000005ff00005ffffff500000ffffffffffffff5fffffff05fffffffffffffffffffffff5fffffffffff0000ffffffffff5000ff00000000
fffffffffff5000000005fff000005ffff5000000ffffffffffffff0fffffff05fffffffffffffffffffffff005ffffffff00ff0fffffffffff00fff00000000
ffffffffffff55000005ffff0000005fff50000005ffffffffffff50fffffff5ffffffffffffffffffffffffffffffffffffffffffff5ffffff050ff00000000
ffffffffffffff50555fffff0000005ff5000000005ffffffffff500fffffffffffffffffffffffffffffffffffffffffffffffff5ff05ffff5fff5f00000000
ffffffffffffffffffffffff0000000ff500000000005fffff550000fffffffffffffffffffffffffffffffffffffffffffffffff0f500ffffffffff00000000
67677775066666666666666066666666677777756750000067776775500000006776777777767675676777766666666500066666000000000000000000000000
67676775676767677666767576766666676776757500000006776777750000000677677677767775676767777667675000676677000000000000004444450000
67776765677767777676777576776767667776755000000000677677775000000067776767777750677767677767750006776776000000000000044445500000
67777775677777777776777576777767677767750000000000067776777500000006777566777700677767677677500067776776000000000000044444400440
66777775677777677777767576767777677767500000000000006776677755550000675076767700677767777775000067677776000000000000044444404444
66767775667676777776767577767777767775000000000000000677767677770000050077767750677777777750000067677777000000000444445999444444
67767765677677777676776577777667767750000000000000000067777767770000000067777675667776777500000067767777000000004444459949944444
67677765676777756777776555555555677500000000000000000006767776770000000067777675677776675000000067767775000000004444459494944444
66666666000006666660000066666600677777750000067767776775000000067677677567777775666656666776777500000000000000004444459949944444
77676777000000677500000066777750676777650000006767777750000000677677675067677775777755670677677500000000000000004444455999544405
77676767000000677500000077767775676777750000000677677500000006777767750077677675676775670067776500000000000000005404445555444000
77677767000000065000000076776775677677750000000077675000000067776777500077777675676777560006776500000000000000000504444444444400
77677767000000065000000077777775067776760000000077750000666677670675000076777675776767560000677500000000000000000004444444444400
77777677000000065000000077776775006777670000000077500000766777670050000076767775677767560000067500000000000000000004444404444400
77777677000000065000000077776775000677770000000075000000776776770000000077767750777777560000006500000000000000000000544400544400
67777777000000065000000067777775000067670000000050000000777777760000000055555500776776560000000500000000000000000000055000555000
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
1717171717171717171717911717171717171717911717171717171717171717171717171717911717171717171717171717171717171717171717000000000000000000000009180a00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
17b8b9bab0b0bab0b0b0b0b0b0b0b0b0b0b7b8b0b0b0b0b0b0b0b0b0b0b0b0b1911717b2b0b0b0b0b0b0b0b0b0b0b7171717171717171717171717000000000000000000000018181800000000000000000000000000000000000000000000000000000000000000000000000000000000020300000004000005060000000500
17bbb0b0b0b0b0b0b0b0b0b095b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b095b0babab0b0b0b0b0b0b0b0b095b0b017171717171717171717171700000000000000000000000c180b000000000000000000000000000000000000000000000000000000000000000000000000000000d1d0c3dac2c1c3c2c1c3c2c1d3ccd0d2
93b0b0b0b0b0b0b0b0b0b0a5b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0beb0b0b0b0b0b0b0b0b0b0b0a5b0b0b0b0b0bdb417171717171717171717171700000000000000000000000d0a0000000000000000000000000000000000000000000000000000000000000000000000000000000000c000c0c0c000c0c000c0c0c0c0c000
17b0b0b095b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b094b0b0b0b0b0beb0b0b0b41717171717171717171717171717000000000000000000000018180000000000000000000000000000000000000000000000000000000000000000000000000000000000cac3c9c0c000c0c000c0c0c0c0c000
17b5b0b0b0b0b0beb0b0b0b0b0b0b0b0b0b0b0b0b0a5b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0bc17171717171717171717171717171700000000000000000000000c0f0000000000000000000000000000000000000000000000000000000000000000000000000000000000c006c0c0c6c7c4d4d7d6dbc6d6c000
17b8b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b094b0b0b0b096b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b1b8b7171717171717171717171717000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000cac3d9cacbc8c5d5d803000000db00
17b0b0b0b0b0b0b0b41717b3b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0bab0b0901717011717171717171717000000000000000000000009180a00000000000000000000000000000000000000000000000000000000000000000000000000000000d60000d6e0e1e1e1e1e20000000000
17b0b0b0b0b0b0b017171717b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0a4b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0bc17171717171717171717171700000000000000000000000e180f00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000e3e400000000000000
17b0b0b0b0b0b0b0171717b2b0b095b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0beb0b0b0b0b0b0b096b0beb0b0b017171717171717171717171700000000000000000000000d180a00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
17b0b0b0b0b0b0b0b117b2b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0901717171717171717171717000000000000000000000018181800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
17b0b0a5b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0a4b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0a4b0b0b0b0b0b0b0b017171717171717171717171700000000000000000000000e180f00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
17bbb0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0a4b0b0b0b0b0b0b0b0b0b0b0b0b017171717171717171717171700000000000000000000000d0a0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
17b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0a4a5b0b0b0b0b0b0b0a4b0b0b0b0b0171717171717171717171717000000000000000000000018180000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
17b0b0b094b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b019181818181ab0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b017171717171717171717171700000000000000000000000e0b0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
17b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b01d181818181818b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0bc171717171717171717171717000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
93b0b0b0b0b0b0b0b0b0b0b0b096b0b0b0b0b0b0b018181818181818b0b0b0b0b0b0b0b0b094b0b0b0b0b0b0b0b0b0171717171717171717171717000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
17b0b0b0b0b0b094b0b0b0b0b0b0b0b0b0b0b0b0b01c18181818181bb0b0b0b0b0b0b0b0b0b0b0b0b0beb0b0b095b0171717171717171717171717000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
17b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b01c18181bb0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0171717171717171717171717000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
17b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b094b0b0b0b0b0b0b0b0b0b0b0b0a4b0b0b0b0b0b0b0901717171717171717171717000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
17b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0171717171717171717171717000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
17b5b0b0b0b0b0b0b0b096b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b4171717171717171717171717000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1717bbb0b0b0b0b0b0b0b0b0b0b0b0b0a4b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b7171717171717171717171717000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
17b8b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b41717b3b0b0b0b0b0b0b096b0b0b0b0b0b0171717171717171717171717000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
93b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b4171717b2b0b0b0b0b0b0b0b0b0b0b0b0b0b0171717171717171717171717000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
17b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0a4b0b0b0171717b8b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0171717171717171717171717000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
17b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0beb0b0b0b0b0b0b0b117b2b0b0b0b0b0b0b0b0b0b0b0b0a5b0b0b0171717171717171717171717000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
17b0b096b0b0b0b0b0a5b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0171717171717171717171717000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
17b0b0b0b0b0a4b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0beb0b0b0b0b0b0b095b0b0171717171717171717171717000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
17b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0171717171717171717171717000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
17b5b0b0b0b0b0b0b0bdb0b095b0b0b0b0b0b0b0b0b0b0b6b3b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0bdb0b0b0b6171717171717171717171717000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1717179217171717171717171717171717171717921717171717171717171717179292171717171717171717171717171717171717171717171717000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__sfx__
000400000c6200c0301e620180100d610160100a600300003500027000270002b000290002b000300003300001000010000100001000010000100001000010000100001000010000100001000000000000000000
0105000011653086510b351094520b4520c4320c4220c4220c4220c4220c4220c4220c4220c4220c4220c4220c4220c4220c4220c4220c4220c42200402004020040200400004000040000400004000040000400
00020000006700c0700a0700005000030000300002000020000200001000010000100001000010040000400004000040000400004000040000400000000000000000000000000000100001000010000000000000
000100003c670386603665032650306402b6302b630286202762025620216201f6101d6101c6101b6101b6101a6101a61019610196000f6000b60009600086001d60000600006000060026600006000060000600
010a00002857527500285750050000500005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500
0005000000450034500c45000440034400c44000430034300c43000420034200c42000410034100c4100741500400006030060000000000000000000000000000000000000000000000000000000000000000000
000300001e61022620256201f6200e6200c61011610156101b610176100f6100a61007610076100a6100161000610006000060001600016000060001600006000060000000000000000000000000000000000000
010700000000000000146101f6102461023610256102261024610266102361026610226101c6101e6101861012610086100360000600016000160000600237003b600027002e7003670033600006000000000000
000200000f010260202b020320303604033050340502f05035050300502d0502f0402c040290202c020290202c020290201f62018620126100761003610026100161037600316002e6002a600256001b60007600
011000100ca500ca5039b1339b131bb501bb5034b130da400da5034b101ab501ab501ab5034b100ea5034b1000000000000000000000000000000000000000000000000000000000000000000000000000000000
000200002b610216101962034640306302c620276101f6101a61017610116101860000600006001a600246001f6202f6403c630256201d61017610126100e6100d6100c6100b6000b6000b6000a6000960009600
011800002343023430234301f4301f4301f4301e4301e4301c4301c4301c4301e4301e4301e4301f4301f4302343023430234301f4301f4301f4301e4301e4301c4301c4301c4301e4301e4301e4301f4301f430
011800002343023430234301f4301f4301f43023430234302443024430244301f4301f4301f43024430244302343023430234301f4301f4301f4301e4301e4301c4301c4301c4301c4301c430000000000000000
011800002f7502f7502f7502b7502b7502b7502a7502a7502875028750287502a7502a7502a7502b7502b7502f7502f7502f7502b7502b7502b7502a7502a7502875028750287502a7502a7502a7502b7502b750
011800002f7502f7502f7502b7502b7502b7502f7502f7503075030750307502b7502b7502b75030750307502f7502f7502f7502b7502b7502b7502a7502a7502875028750287502875028750247000070000700
003400182f7542c7542a754287542a7542c7542f7542c7542a754287542a7542c7542f7542c7542f754317542c754317542f7542c7542a7542875428752007000070000700007000070000700007000070000700
0134000023424204241e4241c4241e4242042423424204241e4241c4241e4242042423424204242342425424204242542423424204241e4241c4241c422004000040000400000000000000000000000000000000
00010000136200b610046100161017600006000060000600006000060000600006000060000600006000060000600006000060000600006000060000600006000060000600006000060000600006000060000600
010200001a0702a070300701a0602a060300601a0502a050300501a0402a040300401a0302a030300301a0202a020300201a0102a010300150000000000000000000000000000000000000000000000000000000
01020000240701e0700e070240601e0600e060240501e0500e050240401e0400e040240301e0300e030240201e0200e020240101e0100e0150000400004000040000000000000000000000000000000000000000
010c001009a70000000ba700000018b5318b0009a7318b5309a7318b5309a730000018b5315a7315b3309a0300000000000000000000000000000000000000000000000000000000000000000000000000000000
010c000833b1032b1033b1032b1018b7032b1033b1032b10000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
010a00000c55018550245500c54018540245400c53018530245300c52018520245200c51018510245102451500500005000050000500005000050000500005000050000500005000050000500005000050000500
010800000061101611026110461105611086110b6110f611156111b611236112a6113261136611386113661134611316112d6112961125611216111b611166110f6110b611076110561103611006100061000610
000700001663035630336303d6303a630356202f6202a62024620246202262022620376302c630256302062019620156201361012610116100f6100e6100d6100b6100a600096000000000000000000000000000
011800002743227432274322343223432234322243222432204322043220432224322243222432234322343227432274322743223432234322343222432224322043220432204322243222432224322343223432
011800002743227432274322343223432234322743227432284322843228432254322543225432284322843227432274322743223432234322343222432224322043220432204322043220432000020000200002
010d00081305500000130550000013055000001305500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
010d00000c055000050c055000050c055000050c055000050c055000050c055000050c055000000c055000000e055000000e055000000e055000000e055000001105500000110550000511055000051105500000
000d000016150161551615000000161501615516150000001a1501a1551a150000001a1501a1551a1500000018150181551815000000181501815518150000001d1501d1551d150000001d1501d1551d15000000
010d00001f1501f1101f1501f1101f1501f1101f1501f1101f1421f1121f1421f1121f1321f1121f1321f1121f1221f1221f1221f1221f1121f1121f1121f1151a15000000181500000016150000001515000000
010d00100ca500000024b0036b1024b50000003ab10000000ca5000b00000003ab1024b5000b003ab403ab3000000000000000000000000000000000000000000000000000000000000000000000000000000000
000d0000230501d05119051110510705102051326512c631236311d631166210f621076210262100611006110061100611006110061104111091110f1111a1111a15000000181500000016150000001515000000
000d00001315013150000000000013150131501a15000000181501815000000000001615016150000000000015150151500000000000151501515016150161501815018150000000000016150000001515000000
010d00001315013150000000000013150131502215122150211540000022150000002115000000221500000013150131500000000000131501315022151221502115400000221500000021150000002215000000
010d00001315013150000000000013150131521a1511a150181541815000000000001615016150131411312115150151500000000000151501515016151161501815118150000001800016150161501515115150
011000000c0500000018050000000c0500000018050000000d0500000019050000000d0500000019050000000c0500000018050000000c0500000018050000000d0500000019050000000d050000001905000000
011000001810500005241050000518105000052410500005191050000525105000051910500005251050000518155000052415500005181550000524155000051915500005251550000519155000052515500005
011000000055200552005520055200552005520055200552015520155201552015520155201552015520155200552005520055200552005520055200552005520155201552015520155201552015520155201552
011000001ab501cb001ab001ab001ab5018b001ab001cb001ab501cb001ab001cb001ab501cb001ab001cb001ab501cb001ab001cb001ab501cb001ab001ab001ab5018b001ab001ab001ab50000001ab0000000
011000000c050180500c050180500d050190500d050190500c050180500c050180500d050190500d050190500c050180500d050190500c050180500d050190500c050190500c050190500c050190500c05019050
011000000027500275002750020500275002050027500275002750027500205002750020500275002750027500275002750027500205002750020500275002750027500275002050027500205002750027500275
011000000cb700000000000000000cb700000000000000000cb700000000000000000cb700000000000000000cb700000000000000000cb700000000000000000cb700000000000000000cb70000000000000000
011000000c5710c5710c57107571075710757107571075710f5710f5710f57107571075710757107571075710c5710c5710c5710c5710c5710c5710c5710c5710c5710c5710c5710c5710c5710c5710c5710c571
011000000c5710c5710c57107571075710757107571075710f5710f5710f571195711957119571195711957118571185711857118571185711857118571185711857118571185711857118571185711857118571
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
002700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__music__
01 0b144a41
02 0c144141
01 0b140d41
02 0c140e41
01 0b150d55
02 0c150e55
01 190d1541
02 1a0e1541
01 3f4f410f
02 3f0f1041
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
00 1d414141
00 1e5f4141
00 41414141
00 41414141
00 41414141
00 41414141
00 41414141
00 41414141
00 296a4141
00 292a4141
01 292a2b41
02 292a2c41
00 41414141
00 41414141
00 41414141
00 41414141
00 24252627
00 41414141
00 41414141
00 20414141
00 21414141
00 22414141
00 23414141
00 22414141
01 211f1c41
00 221f1b41
00 231f1c41
00 221f1b41
00 231f1c41
00 221f1b41
00 1d1f1c41
02 1e1f1b41

