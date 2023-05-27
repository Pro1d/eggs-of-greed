UI:
- resources:
  - chicken count / max chicken supply (=area * density)
  - eggs count (=money)

action, cost, effect, CD:
- feed, 10 eggs, produce +1 egg, CD 30 sec
- buy chicken, 10 eggs, produce 1 egg
- buy white chicken, 15 eggs  (2 eggs)
- buy chick, 5 eggs, grow in 30 sec with random color
- buy area, 50/100/150/250/500, unlock area+supply
- search density, 300/600, +1/+2 supply per cell
- feed with gold nugget, 300, produce golden egg (worth 10 eggs), CD 30 sec
- buy trophee, 5000

start: 5 chickens
drop eggs (10 sec)
auto collect eggs

react:
- feed -> eat and more noise
- high density -> unhappy=eggs delay * 1.5, density >

TODO
x sound fx: buy / remove/spawn stuffs
x visual fx: particles on spawn /destryo
x unlock upgrade with supply condition
x drawing cup:
x game intro
goto eat
eat on feed