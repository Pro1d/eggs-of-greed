Eggs of Greed
=============

:point_right: :sunflower: [Play Eggs of Greed on itch.io](https://proyd.itch.io/eggs-of-greed) :chicken: :point_left:

Presentation
------------

> Winter has finally ended! It is time to harvest eggs :egg: and make profits :trophy:.

<img src="https://github.com/Pro1d/eggs-of-greed/blob/master/screenshots/intro.png" width=25% height=25%> <img src="https://github.com/Pro1d/eggs-of-greed/blob/master/screenshots/early-game.png" width=25% height=25%> <img src="https://github.com/Pro1d/eggs-of-greed/blob/master/screenshots/late-game.png" width=25% height=25%>

*Eggs of Greed* is a small simulation game made for the [Spring 2D Jam 2023 on itch.io](https://itch.io/jam/spring-2d-jam-2023)
- The theme was **chicken** :chicken: and (obviously) **spring** :sunflower:
- Buy chickens, harvest eggs and buy even more chickens :chicken::chicken::chicken:
- Unlock upgrades, expand your pen and, get the final trophy :trophy:
- The game has a pixel-art style with homemade sprites ([shared on opengameart.org](https://opengameart.org/content/chicken-and-pen)) ✏️
- Made with **Godot 4** <img src="https://github.com/godotengine/godot/blob/master/editor/icons/Godot.svg" width="18px" height="18px">

Dev notes:
----------
Archives of the notes I wrote to myself during development (brainstorming ideas).

**Goal:**
- Management/strategy/clicker chicken farming
- get chickens, harvest eggs, get more chickens, harvest more eggs.
- pixel-art style.

**UI:**
- resources:
  - chicken count / max chicken supply (=area * density)
  - eggs count (=money)

**action, cost, effect, CD:**
- feed, 10 eggs, produce +1 egg, CD=lay period\*1.5 sec
- buy brown chicken, 10 eggs, produce 1 egg (best in end-game)
- buy white chicken, 15 eggs, produce 2 eggs (best in early-game)
- ~buy chick, 5 eggs, grow in 30 sec with random color~
- buy area, 50/100/150/250/500, unlock area+supply
- search density, 300/600, +1/+2 supply per cell
- feed with gold nugget, 300, produce golden egg (worth 10 eggs), CD 30 sec
- buy trophee, 5000

**Start:**
- 5 chickens
- 30 eggs
- drop eggs (8 sec)
- auto collect eggs

**react:**
- [x] feed -> eat and more noise
- [ ] ~high density -> unhappy=eggs delay \* 1.5, density >~

**TODO:**
- [x] sound fx: buy / remove/spawn stuffs
- [x] visual fx: particles on spawn /destryo
- [x] unlock upgrade with supply condition
- [x] drawing cup:
- [x] game intro
- [ ] drop seed on feed, chicken go to eat seed

**[Post jam] Note from submission feedbacks:**
- Chickens get to noisy after 40 chickens. (sound design...)
- Players do not understand the interest of brown chickens.
- People do not really know what kind of game to expect (clicker/idle/simulation/management/startegy...): this is the result of being undecided and also too ambitious, I had to get ride of most of the original ideas when I ran low on time.
