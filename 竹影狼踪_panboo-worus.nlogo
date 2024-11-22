;; 定义全局变量
globals [ max-panda ]  ; 不让熊猫群数量增长过大

;; 定义熊猫和狼两种生物
breed [ panda a-panda ]  ; 熊猫是自己的复数形式，所以使用"a-panda"作为单数
breed [ wolves wolf ]

turtles-own [ energy 病毒 ]       ; 狼和熊猫都有能量

patches-own [ countdown ]    ; 这是为了熊猫-狼-竹子模型版本

;; 初始化模型
to setup
  clear-all
  ifelse netlogo-web? [ set max-panda 10000 ] [ set max-panda 30000 ]  ; 根据NetLogo版本设置最大熊猫数量

  ;; 检查模型版本开关
  ;; 如果不模拟竹子，则熊猫不需要吃东西来生存
  ;; 否则每个竹子的状态和生长逻辑需要设置
  ifelse 模型版本 = "熊猫-狼-竹子" [
    ask patches [
      set pcolor one-of [ green brown ]
      ifelse pcolor = green
        [ set countdown 竹子的生长时间 ]
      [ set countdown random 竹子的生长时间 ] ; 为棕色斑块随机初始化竹子再生计时器
    ]
  ]
  [
    ask patches [ set pcolor green ]
  ]

  ; 初始化温度 在0-40之间
  set 温度 random 40

  create-panda 熊猫的初始个数  ; 创建熊猫，并初始化它们的变量
  [
    set shape "panda"
    set color white
    set size 1.5  ; 更容易看到
    set label-color blue - 2
    set energy random (2 * 熊猫从食物中获益)
    ; set 病毒 random 5
    set 病毒 环境病毒数
    setxy random-xcor random-ycor
  ]

  create-wolves 狼的初始个数  ; 创建狼，并初始化它们的变量
  [
    set shape "wolf"
    set color black
    set size 2  ; 更容易看到
    set energy random (2 * 狼从食物中获益)
    setxy random-xcor random-ycor
  ]
  display-labels
  reset-ticks
end

;; 主循环
to go
  ;; 如果没有狼和熊猫，停止模型
  if not any? turtles [ stop ]
  ;; 如果没有狼且熊猫的数量变得非常大，停止模型
  if not any? wolves and count panda > max-panda [ user-message "熊猫占领了整个地球" stop ]

  ;; 每10个时间步长改变温度
  if ticks mod 10 = 0 [
    set 温度 温度 + ifelse-value (random 2 = 0) [-1] [1]
  ]

  ask panda [
    move

    ;; 在这个版本中，熊猫吃竹子，竹子生长，熊猫移动会消耗能量
    if 模型版本 = "熊猫-狼-竹子" [
      set energy energy - 1  ; 只有在运行熊猫-狼-竹子模型版本时扣除熊猫的能量
      eat-bamboo  ; 只有在运行熊猫-狼-竹子模型版本时熊猫才吃竹子
      death ; 只有在运行熊猫-狼-竹子模型版本时熊猫才会因饥饿而死
    ]

    reproduce-panda  ; 熊猫以受滑动条控制的随机速率繁殖

    if 温度 > 50 or 温度 < 10 [
      ; 温度过高或过低 50%可能导致死亡
      if random 10 > 5 [
        die ; 温度过高过低导致熊猫死亡
      ]
    ]

    ; 每次移动有50%概率 获得一点病毒或者失去一点病毒
    if ticks mod 10 = 0 [
        set 病毒 病毒 + ifelse-value (random 2 = 0) [-1] [1]
    ]

    ; shape 暂时没法调色
    ; if 病毒 > 50 and 病毒 < 100 [
    ;     ask panda [set color black]
    ; ]

    if 病毒 > 20 [
      ; 体内病毒过多 50%可能导致死亡
      if random 10 > 5 [
        die ; 病毒导致熊猫死亡
      ]
    ]
  ]
  ask wolves [
    move
    set energy energy - 1  ; 狼移动时失去能量
    eat-panda ; 狼吃掉它们所在斑块上的熊猫
    death ; 狼如果能量耗尽就会死亡
    reproduce-wolves ; 狼以受滑动条控制的随机速率繁殖
  ]

  if 模型版本 = "熊猫-狼-竹子" [ ask patches [ grow-bamboo ] ]

  tick
  display-labels
end

;; 移动过程
to move  ; 生物过程
  rt random 50
  lt random 50
  fd 1
end

;; 吃竹子过程
to eat-bamboo  ; 熊猫过程
  ;; 熊猫吃竹子并将斑块变为棕色
  if pcolor = green [
    set pcolor brown
    set energy energy + 熊猫从食物中获益  ; 熊猫通过吃竹子获得能量
  ]
end

;; 熊猫繁殖过程
to reproduce-panda  ; 熊猫过程
  if random-float 100 < 熊猫繁殖 [  ; 抛“骰子”决定是否繁殖
    set energy (energy / 2)                ; 将能量分配给父母和后代
    hatch 1 [ rt random-float 360 fd 1 ]   ; 孵化一个后代并向前移动一步
  ]
end

;; 狼繁殖过程
to reproduce-wolves  ; 狼过程
  if random-float 100 < 狼繁殖 [  ; 抛“骰子”决定是否繁殖
    set energy (energy / 2)               ; 将能量分配给父母和后代
    hatch 1 [ rt random-float 360 fd 1 ]  ; 孵化一个后代并向前移动一步
  ]
end

;; 吃熊猫过程
to eat-panda  ; 狼过程
  let prey one-of panda-here                    ; 抓取一个随机的熊猫
  if prey != nobody  [                          ; 如果抓到了熊猫，
    ask prey [ die ]                            ; 杀死它，并...
    set energy energy + 狼从食物中获益     ; 从吃熊猫中获得能量
  ]
end

;; 死亡过程
to death  ; 生物过程（即狼和熊猫的过程）
  ;; 当能量低于零时，死亡
  if energy < 0 [ die ]
end

;; 竹子生长过程
to grow-bamboo  ; 斑块过程
  ;; 棕色斑块的倒计时：如果达到0，就长出一些竹子
  if pcolor = brown [
    ifelse countdown <= 0
      [ set pcolor green
        set countdown 竹子的生长时间 ]
      [ set countdown countdown - 1 ]
  ]
end

;; 返回竹子
to-report bamboo
  ifelse 模型版本 = "熊猫-狼-竹子" [
    report patches with [pcolor = green]
  ]
  [ report 0 ]
end

;; 显示标签
to display-labels
  ask turtles [ set label "" ]
  if 显示个体能量? [
    ask wolves [ set label round energy ]
    if 模型版本 = "熊猫-狼-竹子" [ ask panda [ set label round energy ] ]
  ]
  ; 显示个体病毒数量
  ask panda [ set label round 病毒 ]
end
@#$#@#$#@
GRAPHICS-WINDOW
355
10
873
529
-1
-1
10.0
1
14
1
1
1
0
1
1
1
-25
25
-25
25
1
1
1
ticks
60.0

SLIDER
5
60
192
93
熊猫的初始个数
熊猫的初始个数
0
250
100.0
1
1
NIL
HORIZONTAL

SLIDER
5
196
179
229
熊猫从食物中获益
熊猫从食物中获益
0.0
50.0
4.0
1.0
1
NIL
HORIZONTAL

SLIDER
5
231
179
264
熊猫繁殖
熊猫繁殖
1.0
20.0
4.0
1.0
1
%
HORIZONTAL

SLIDER
185
60
357
93
狼的初始个数
狼的初始个数
0
250
50.0
1
1
NIL
HORIZONTAL

SLIDER
183
195
348
228
狼从食物中获益
狼从食物中获益
0.0
100.0
20.0
1.0
1
NIL
HORIZONTAL

SLIDER
183
231
348
264
狼繁殖
狼繁殖
0.0
20.0
5.0
1.0
1
%
HORIZONTAL

SLIDER
5
100
185
133
竹子的生长时间
竹子的生长时间
0
100
30.0
1
1
NIL
HORIZONTAL

BUTTON
30
140
117
173
重置数据
setup
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
115
140
190
173
运行！
go
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
0

PLOT
10
360
350
530
生物数量
时间
数量
0.0
100.0
0.0
100.0
true
true
"" ""
PENS
"熊猫" 1.0 0 -612749 true "" "plot count panda"
"狼" 1.0 0 -16449023 true "" "plot count wolves"
"竹子 / 4" 1.0 0 -10899396 true "" "if 模型版本 = \"羊-狼-草\" [ plot count bamboo / 4 ]"

MONITOR
41
308
118
353
熊猫的数量
count panda
3
1
11

MONITOR
115
308
182
353
狼的数量
count wolves
3
1
11

MONITOR
191
308
293
353
竹子的数量 / 4
count bamboo / 4
0
1
11

TEXTBOX
20
178
160
196
熊猫 属性设置
11
0.0
0

TEXTBOX
198
176
311
194
狼 属性设置
11
0.0
0

SWITCH
105
270
252
303
显示个体能量?
显示个体能量?
1
1
-1000

CHOOSER
5
10
350
55
模型版本
模型版本
"熊猫-狼" "熊猫-狼-竹子"
1

SLIDER
185
100
355
133
温度
温度
0
100
17.0
1
1
NIL
HORIZONTAL

SLIDER
190
145
350
178
环境病毒数
环境病毒数
0
100
10.0
1
1
NIL
HORIZONTAL

@#$#@#$#@
<!--
 * @Author: Amiya mc.amiya@qq.com
 * @Date: 2024-11-16 21:16:54
 * @LastEditors: Amiya mc.amiya@qq.com
 * @LastEditTime: 2024-11-22 23:57:22
 * @FilePath: /Panboo-Worus/README.md
 * @Description: 竹影狼踪的README文件
-->

<h2 align="center" style="font-weight: 600">竹影狼踪 (Panboo Worus)</h2>
<p align="center">
    一个<s>抽象的</s>关于熊猫、竹子、狼在不同的温度以及病毒数量下发展模拟的程序
    <br />
    你可以通过调整不同的初始值来获得多个不同的结局
    <br />
    <br />
    <a href="http://www.netlogoweb.org/launch#https://raw.githubusercontent.com/mcAmiya/Panboo-Worus/master/竹影狼踪_panboo-worus.nlogo" target="blank"><strong>🌎 在线访问</strong></a>  |  
    <a href="https://github.com/mcAmiya/Panboo-Worus/releases" target="blank"><strong>📦️ 下载使用</strong></a>
</p>

[![Stars](https://img.shields.io/github/stars/mcAmiya/Panboo-Worus?label=stars)](https://github.com/mcAmiya/Panboo-Worus)  [![platform](https://img.shields.io/badge/platform-netlogo-blue.svg)](https://ccl.northwestern.edu/netlogo/)  ![Downloads](https://img.shields.io/github/downloads/mcAmiya/Panboo-Worus/total)  [![GitHub Release](https://img.shields.io/github/v/release/mcAmiya/Panboo-Worus)](https://github.com/mcAmiya/Panboo-Worus/releases)  [![GitHub Release Date](https://img.shields.io/github/release-date/mcAmiya/Panboo-Worus)](https://github.com/mcAmiya/Panboo-Worus/releases)

## ✨ 特性

- ✅ 拥有 `熊猫-狼-竹子` 和 `熊猫-狼` 两个模型版本
- 📃 拥有生物数量随时间变化图像
- 🧩 可自由配置各种生物的初始参数
- 💾 基于 [NetLogo](https://ccl.northwestern.edu/netlogo/) 开源可靠
- 🖥️ 拥有 [在线版](http://www.netlogoweb.org/launch#https://raw.githubusercontent.com/mcAmiya/Panboo-Worus/master/竹影狼踪_panboo-worus.nlogo) 和 [客户端版](https://ccl.northwestern.edu/netlogo/download.shtml) 支持不同设备使用

## 🧰 UI介绍

| 界面              | 作用                                                                                                                                   |
| ----------------- | -------------------------------------------------------------------------------------------------------------------------------------- |
| model speed       | 模型模拟速度                                                                                                                           |
| ticks             | 时间步长                                                                                                                               |
| 模型版本          | 拥有 `熊猫-狼-竹子` 和 `熊猫-狼` 两个模型版本                                                                                        |
| 熊猫初始个数      | 模拟开始前熊猫的初始个数                                                                                                               |
| 狼的初始个数      | 模拟开始前狼的初始个数                                                                                                                 |
| 竹子的生长时间    | 类似于冷却时间 越短竹子生长的越快                                                                                                      |
| 温度              | 初始温度默认会在0-40度之间<br />每10个时间步长 温度随机 上升 或 下降 1度<br />温度小于50度 或 温度大于50度时 有50%概率导致熊猫个体死亡 |
| 重置温度          | 用于初始化所有环境（环境病毒数 只可在 `重置数据`时才修改）                                                                           |
| 运行              | 开始根据设定的参数进行模拟                                                                                                             |
| 环境病毒数        | 初始化所有熊猫个体自身携带的病毒数量                                                                                                   |
| 熊猫从食物中获益  | 增加个体自身能量                                                                                                                       |
| 狼从食物中获益    | 增加个体自身能量                                                                                                                       |
| 熊猫繁殖          | 随机0-100之间的一个小数 如果小于 `熊猫繁殖`<br />自身能量消耗一半 且 诞生一个新熊猫个体                                              |
| 狼繁殖            | 随机0-100之间的一个小数 如果小于 `狼繁殖`<br />自身能量消耗一半 且 诞生一个新狼个体                                                  |
| 显示个体能量？    | 熊猫不可用<br />熊猫个体身上的标签已用于显示个体携带的病毒数量                                                                         |
| 熊猫的数量        | 当前模拟环境中熊猫个体数                                                                                                               |
| 狼的数量          | 当前模拟环境中狼个体数                                                                                                                 |
| 竹子的数量 / 4    | 当前模拟环境中草的数量 因过大影响图像观看 所以除四                                                                                     |
| 生物数量-时间图像 | 熊猫、狼、竹子(除以四) 数量随时间变化的图像                                                                                            |

## 💻 运行

1. 可以访问 [在线版](http://www.netlogoweb.org/launch#https://raw.githubusercontent.com/mcAmiya/Panboo-Worus/master/竹影狼踪_panboo-worus.nlogo)**（对网络环境有要求）**
2. 下载 [netlogo](https://ccl.northwestern.edu/netlogo/download.shtml) 和 [nlogo文件](https://github.com/mcAmiya/Panboo-Worus/releases) (需要网络环境) 打开运行

## 📜 开源许可

本项目基于 [NetLogo Wolf Sheep Predation](https://ccl.northwestern.edu/netlogo/models/WolfSheepPredation)

仅供学习研究使用，禁止用于商业及非法用途。

基于 [CC BY-NC-SA 3.0](https://creativecommons.org/licenses/by-nc-sa/3.0/) 许可进行开源。

欢迎提 Issue 和 Pull request。

## 🖼️ 截图

![web](./pic/Screenshot_web.png "网页端")

![client](./pic/Screenshot_client.png "客户端")

## 🏆 致谢

|         贡献         |       贡献者       |
| :------------------: | :----------------: |
| Wolf Sheep Predation | Wilensky & Reisman |
| 整体思路 & 熊猫外观 |     @CHAN LAM     |
@#$#@#$#@
default
true
0
Polygon -7500403 true true 150 5 40 250 150 205 260 250

airplane
true
0
Polygon -7500403 true true 150 0 135 15 120 60 120 105 15 165 15 195 120 180 135 240 105 270 120 285 150 270 180 285 210 270 165 240 180 180 285 195 285 165 180 105 180 60 165 15

arrow
true
0
Polygon -7500403 true true 150 0 0 150 105 150 105 293 195 293 195 150 300 150

box
false
0
Polygon -7500403 true true 150 285 285 225 285 75 150 135
Polygon -7500403 true true 150 135 15 75 150 15 285 75
Polygon -7500403 true true 15 75 15 225 150 285 150 135
Line -16777216 false 150 285 150 135
Line -16777216 false 150 135 15 75
Line -16777216 false 150 135 285 75

bug
true
0
Circle -7500403 true true 96 182 108
Circle -7500403 true true 110 127 80
Circle -7500403 true true 110 75 80
Line -7500403 true 150 100 80 30
Line -7500403 true 150 100 220 30

butterfly
true
0
Polygon -7500403 true true 150 165 209 199 225 225 225 255 195 270 165 255 150 240
Polygon -7500403 true true 150 165 89 198 75 225 75 255 105 270 135 255 150 240
Polygon -7500403 true true 139 148 100 105 55 90 25 90 10 105 10 135 25 180 40 195 85 194 139 163
Polygon -7500403 true true 162 150 200 105 245 90 275 90 290 105 290 135 275 180 260 195 215 195 162 165
Polygon -16777216 true false 150 255 135 225 120 150 135 120 150 105 165 120 180 150 165 225
Circle -16777216 true false 135 90 30
Line -16777216 false 150 105 195 60
Line -16777216 false 150 105 105 60

car
false
0
Polygon -7500403 true true 300 180 279 164 261 144 240 135 226 132 213 106 203 84 185 63 159 50 135 50 75 60 0 150 0 165 0 225 300 225 300 180
Circle -16777216 true false 180 180 90
Circle -16777216 true false 30 180 90
Polygon -16777216 true false 162 80 132 78 134 135 209 135 194 105 189 96 180 89
Circle -7500403 true true 47 195 58
Circle -7500403 true true 195 195 58

circle
false
0
Circle -7500403 true true 0 0 300

circle 2
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240

cow
false
0
Polygon -7500403 true true 200 193 197 249 179 249 177 196 166 187 140 189 93 191 78 179 72 211 49 209 48 181 37 149 25 120 25 89 45 72 103 84 179 75 198 76 252 64 272 81 293 103 285 121 255 121 242 118 224 167
Polygon -7500403 true true 73 210 86 251 62 249 48 208
Polygon -7500403 true true 25 114 16 195 9 204 23 213 25 200 39 123

cylinder
false
0
Circle -7500403 true true 0 0 300

dot
false
0
Circle -7500403 true true 90 90 120

face happy
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 255 90 239 62 213 47 191 67 179 90 203 109 218 150 225 192 218 210 203 227 181 251 194 236 217 212 240

face neutral
false
0
Circle -7500403 true true 8 7 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Rectangle -16777216 true false 60 195 240 225

face sad
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 168 90 184 62 210 47 232 67 244 90 220 109 205 150 198 192 205 210 220 227 242 251 229 236 206 212 183

fish
false
0
Polygon -1 true false 44 131 21 87 15 86 0 120 15 150 0 180 13 214 20 212 45 166
Polygon -1 true false 135 195 119 235 95 218 76 210 46 204 60 165
Polygon -1 true false 75 45 83 77 71 103 86 114 166 78 135 60
Polygon -7500403 true true 30 136 151 77 226 81 280 119 292 146 292 160 287 170 270 195 195 210 151 212 30 166
Circle -16777216 true false 215 106 30

flag
false
0
Rectangle -7500403 true true 60 15 75 300
Polygon -7500403 true true 90 150 270 90 90 30
Line -7500403 true 75 135 90 135
Line -7500403 true 75 45 90 45

flower
false
0
Polygon -10899396 true false 135 120 165 165 180 210 180 240 150 300 165 300 195 240 195 195 165 135
Circle -7500403 true true 85 132 38
Circle -7500403 true true 130 147 38
Circle -7500403 true true 192 85 38
Circle -7500403 true true 85 40 38
Circle -7500403 true true 177 40 38
Circle -7500403 true true 177 132 38
Circle -7500403 true true 70 85 38
Circle -7500403 true true 130 25 38
Circle -7500403 true true 96 51 108
Circle -16777216 true false 113 68 74
Polygon -10899396 true false 189 233 219 188 249 173 279 188 234 218
Polygon -10899396 true false 180 255 150 210 105 210 75 240 135 240

house
false
0
Rectangle -7500403 true true 45 120 255 285
Rectangle -16777216 true false 120 210 180 285
Polygon -7500403 true true 15 120 150 15 285 120
Line -16777216 false 30 120 270 120

leaf
false
0
Polygon -7500403 true true 150 210 135 195 120 210 60 210 30 195 60 180 60 165 15 135 30 120 15 105 40 104 45 90 60 90 90 105 105 120 120 120 105 60 120 60 135 30 150 15 165 30 180 60 195 60 180 120 195 120 210 105 240 90 255 90 263 104 285 105 270 120 285 135 240 165 240 180 270 195 240 210 180 210 165 195
Polygon -7500403 true true 135 195 135 240 120 255 105 255 105 285 135 285 165 240 165 195

line
true
0
Line -7500403 true 150 0 150 300

line half
true
0
Line -7500403 true 150 0 150 150

panda
false
0
Circle -1 true false 165 120 0
Circle -1 true false 69 24 162
Rectangle -1 true false 105 165 195 240
Circle -16777216 true false 45 30 60
Circle -16777216 true false 195 30 60
Circle -16777216 true false 75 75 60
Circle -16777216 true false 165 75 60
Circle -1 true false 105 90 30
Circle -1 true false 195 90 30
Rectangle -16777216 true false 60 165 105 195
Rectangle -16777216 true false 195 165 240 195
Rectangle -16777216 true false 105 225 135 285
Rectangle -16777216 true false 165 225 195 285

pentagon
false
0
Polygon -7500403 true true 150 15 15 120 60 285 240 285 285 120

person
false
0
Circle -7500403 true true 110 5 80
Polygon -7500403 true true 105 90 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 195 90
Rectangle -7500403 true true 127 79 172 94
Polygon -7500403 true true 195 90 240 150 225 180 165 105
Polygon -7500403 true true 105 90 60 150 75 180 135 105

plant
false
0
Rectangle -7500403 true true 135 90 165 300
Polygon -7500403 true true 135 255 90 210 45 195 75 255 135 285
Polygon -7500403 true true 165 255 210 210 255 195 225 255 165 285
Polygon -7500403 true true 135 180 90 135 45 120 75 180 135 210
Polygon -7500403 true true 165 180 165 210 225 180 255 120 210 135
Polygon -7500403 true true 135 105 90 60 45 45 75 105 135 135
Polygon -7500403 true true 165 105 165 135 225 105 255 45 210 60
Polygon -7500403 true true 135 90 120 45 150 15 180 45 165 90

sheep
false
15
Circle -1 true true 203 65 88
Circle -1 true true 70 65 162
Circle -1 true true 150 105 120
Polygon -7500403 true false 218 120 240 165 255 165 278 120
Circle -7500403 true false 214 72 67
Rectangle -1 true true 164 223 179 298
Polygon -1 true true 45 285 30 285 30 240 15 195 45 210
Circle -1 true true 3 83 150
Rectangle -1 true true 65 221 80 296
Polygon -1 true true 195 285 210 285 210 240 240 210 195 210
Polygon -7500403 true false 276 85 285 105 302 99 294 83
Polygon -7500403 true false 219 85 210 105 193 99 201 83

square
false
0
Rectangle -7500403 true true 30 30 270 270

square 2
false
0
Rectangle -7500403 true true 30 30 270 270
Rectangle -16777216 true false 60 60 240 240

star
false
0
Polygon -7500403 true true 151 1 185 108 298 108 207 175 242 282 151 216 59 282 94 175 3 108 116 108

target
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240
Circle -7500403 true true 60 60 180
Circle -16777216 true false 90 90 120
Circle -7500403 true true 120 120 60

tree
false
0
Circle -7500403 true true 118 3 94
Rectangle -6459832 true false 120 195 180 300
Circle -7500403 true true 65 21 108
Circle -7500403 true true 116 41 127
Circle -7500403 true true 45 90 120
Circle -7500403 true true 104 74 152

triangle
false
0
Polygon -7500403 true true 150 30 15 255 285 255

triangle 2
false
0
Polygon -7500403 true true 150 30 15 255 285 255
Polygon -16777216 true false 151 99 225 223 75 224

truck
false
0
Rectangle -7500403 true true 4 45 195 187
Polygon -7500403 true true 296 193 296 150 259 134 244 104 208 104 207 194
Rectangle -1 true false 195 60 195 105
Polygon -16777216 true false 238 112 252 141 219 141 218 112
Circle -16777216 true false 234 174 42
Rectangle -7500403 true true 181 185 214 194
Circle -16777216 true false 144 174 42
Circle -16777216 true false 24 174 42
Circle -7500403 false true 24 174 42
Circle -7500403 false true 144 174 42
Circle -7500403 false true 234 174 42

turtle
true
0
Polygon -10899396 true false 215 204 240 233 246 254 228 266 215 252 193 210
Polygon -10899396 true false 195 90 225 75 245 75 260 89 269 108 261 124 240 105 225 105 210 105
Polygon -10899396 true false 105 90 75 75 55 75 40 89 31 108 39 124 60 105 75 105 90 105
Polygon -10899396 true false 132 85 134 64 107 51 108 17 150 2 192 18 192 52 169 65 172 87
Polygon -10899396 true false 85 204 60 233 54 254 72 266 85 252 107 210
Polygon -7500403 true true 119 75 179 75 209 101 224 135 220 225 175 261 128 261 81 224 74 135 88 99

wheel
false
0
Circle -7500403 true true 3 3 294
Circle -16777216 true false 30 30 240
Line -7500403 true 150 285 150 15
Line -7500403 true 15 150 285 150
Circle -7500403 true true 120 120 60
Line -7500403 true 216 40 79 269
Line -7500403 true 40 84 269 221
Line -7500403 true 40 216 269 79
Line -7500403 true 84 40 221 269

wolf
false
0
Polygon -16777216 true false 253 133 245 131 245 133
Polygon -7500403 true true 2 194 13 197 30 191 38 193 38 205 20 226 20 257 27 265 38 266 40 260 31 253 31 230 60 206 68 198 75 209 66 228 65 243 82 261 84 268 100 267 103 261 77 239 79 231 100 207 98 196 119 201 143 202 160 195 166 210 172 213 173 238 167 251 160 248 154 265 169 264 178 247 186 240 198 260 200 271 217 271 219 262 207 258 195 230 192 198 210 184 227 164 242 144 259 145 284 151 277 141 293 140 299 134 297 127 273 119 270 105
Polygon -7500403 true true -1 195 14 180 36 166 40 153 53 140 82 131 134 133 159 126 188 115 227 108 236 102 238 98 268 86 269 92 281 87 269 103 269 113

x
false
0
Polygon -7500403 true true 270 75 225 30 30 225 75 270
Polygon -7500403 true true 30 75 75 30 270 225 225 270
@#$#@#$#@
NetLogo 6.4.0
@#$#@#$#@
set model-version "sheep-wolves-grass"
set show-energy? false
setup
repeat 75 [ go ]
@#$#@#$#@
@#$#@#$#@
<experiments>
  <experiment name="New BehaviorSpace Features" repetitions="3" runMetricsEveryStep="false">
    <preExperiment>reset-timer</preExperiment>
    <setup>setup</setup>
    <go>go</go>
    <postExperiment>show timer</postExperiment>
    <timeLimit steps="200"/>
    <metric>count sheep</metric>
    <metric>count wolves</metric>
    <metric>[ xcor ] of sheep</metric>
    <metric>[ ycor ] of sheep</metric>
    <metric>[ xcor ] of wolves</metric>
    <metric>[ ycor ] of wolves</metric>
    <runMetricsCondition>ticks mod 2 = 0</runMetricsCondition>
    <subExperiment>
      <steppedValueSet variable="wolf-gain-from-food" first="30" step="5" last="50"/>
    </subExperiment>
  </experiment>
  <experiment name="BehaviorSpace run 3 experiments" repetitions="1" runMetricsEveryStep="false">
    <setup>setup
print (word "sheep-reproduce: " sheep-reproduce ", wolf-reproduce: " wolf-reproduce)
print (word "sheep-gain-from-food: " sheep-gain-from-food ", wolf-gain-from-food: " wolf-gain-from-food)</setup>
    <go>go</go>
    <postRun>print (word "sheep: " count sheep ", wolves: " count wolves)
print ""
wait 1</postRun>
    <timeLimit steps="1500"/>
    <metric>count sheep</metric>
    <metric>count wolves</metric>
    <metric>count grass</metric>
    <runMetricsCondition>ticks mod 10 = 0</runMetricsCondition>
    <enumeratedValueSet variable="model-version">
      <value value="&quot;sheep-wolves-grass&quot;"/>
    </enumeratedValueSet>
    <subExperiment>
      <enumeratedValueSet variable="sheep-reproduce">
        <value value="1"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="sheep-gain-from-food">
        <value value="1"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="wolf-reproduce">
        <value value="2"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="wolf-gain-from-food">
        <value value="10"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="sheep-reproduce">
        <value value="6"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="sheep-gain-from-food">
        <value value="8"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="wolf-reproduce">
        <value value="5"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="wolf-gain-from-food">
        <value value="20"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="sheep-reproduce">
        <value value="20"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="sheep-gain-from-food">
        <value value="15"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="wolf-reproduce">
        <value value="15"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="wolf-gain-from-food">
        <value value="30"/>
      </enumeratedValueSet>
    </subExperiment>
  </experiment>
  <experiment name="BehaviorSpace run 3 variable values per experiments" repetitions="1" runMetricsEveryStep="false">
    <setup>setup
print (word "sheep-reproduce: " sheep-reproduce ", wolf-reproduce: " wolf-reproduce)
print (word "sheep-gain-from-food: " sheep-gain-from-food ", wolf-gain-from-food: " wolf-gain-from-food)</setup>
    <go>go</go>
    <postRun>print (word "sheep: " count sheep ", wolves: " count wolves)
print ""
wait 1</postRun>
    <timeLimit steps="1500"/>
    <metric>count sheep</metric>
    <metric>count wolves</metric>
    <metric>count grass</metric>
    <runMetricsCondition>ticks mod 10 = 0</runMetricsCondition>
    <enumeratedValueSet variable="model-version">
      <value value="&quot;sheep-wolves-grass&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sheep-reproduce">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="wolf-reproduce">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sheep-gain-from-food">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="wolf-gain-from-food">
      <value value="20"/>
    </enumeratedValueSet>
    <subExperiment>
      <enumeratedValueSet variable="sheep-reproduce">
        <value value="1"/>
        <value value="6"/>
        <value value="20"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="wolf-reproduce">
        <value value="2"/>
        <value value="7"/>
        <value value="15"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="sheep-gain-from-food">
        <value value="1"/>
        <value value="8"/>
        <value value="15"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="wolf-gain-from-food">
        <value value="10"/>
        <value value="20"/>
        <value value="30"/>
      </enumeratedValueSet>
    </subExperiment>
  </experiment>
  <experiment name="BehaviorSpace subset" repetitions="1" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <postRun>wait .5</postRun>
    <timeLimit steps="1500"/>
    <metric>count sheep</metric>
    <metric>count wolves</metric>
    <metric>count grass</metric>
    <runMetricsCondition>ticks mod 10 = 0</runMetricsCondition>
    <enumeratedValueSet variable="model-version">
      <value value="&quot;sheep-wolves-grass&quot;"/>
    </enumeratedValueSet>
    <subExperiment>
      <enumeratedValueSet variable="wolf-reproduce">
        <value value="3"/>
        <value value="5"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="wolf-gain-from-food">
        <value value="30"/>
        <value value="40"/>
      </enumeratedValueSet>
    </subExperiment>
    <subExperiment>
      <enumeratedValueSet variable="wolf-reproduce">
        <value value="10"/>
        <value value="15"/>
      </enumeratedValueSet>
      <enumeratedValueSet variable="wolf-gain-from-food">
        <value value="10"/>
        <value value="15"/>
      </enumeratedValueSet>
    </subExperiment>
  </experiment>
  <experiment name="BehaviorSpace combinatorial" repetitions="1" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <postRun>wait .5</postRun>
    <timeLimit steps="1500"/>
    <metric>count sheep</metric>
    <metric>count wolves</metric>
    <metric>count grass</metric>
    <runMetricsCondition>ticks mod 10 = 0</runMetricsCondition>
    <enumeratedValueSet variable="model-version">
      <value value="&quot;sheep-wolves-grass&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="wolf-reproduce">
      <value value="3"/>
      <value value="5"/>
      <value value="10"/>
      <value value="15"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="wolf-gain-from-food">
      <value value="10"/>
      <value value="15"/>
      <value value="30"/>
      <value value="40"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="Wolf Sheep Crossing" repetitions="4" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="1500"/>
    <metric>count sheep</metric>
    <metric>count wolves</metric>
    <runMetricsCondition>count sheep = count wolves</runMetricsCondition>
    <enumeratedValueSet variable="wolf-gain-from-food">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="show-energy?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="wolf-reproduce">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="initial-number-wolves">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="羊的初始个数">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="model-version">
      <value value="&quot;sheep-wolves-grass&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sheep-gain-from-food">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="grass-regrowth-time">
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sheep-reproduce">
      <value value="4"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="New BehaviorSpace Features reproducible" repetitions="3" runMetricsEveryStep="false">
    <preExperiment>reset-timer</preExperiment>
    <setup>random-seed (474 + behaviorspace-run-number)

setup</setup>
    <go>go</go>
    <postExperiment>show timer</postExperiment>
    <timeLimit steps="200"/>
    <metric>count sheep</metric>
    <metric>count wolves</metric>
    <metric>[ xcor ] of sheep</metric>
    <metric>[ ycor ] of sheep</metric>
    <metric>[ xcor ] of wolves</metric>
    <metric>[ ycor ] of wolves</metric>
    <runMetricsCondition>ticks mod 2 = 0</runMetricsCondition>
    <enumeratedValueSet variable="model-version">
      <value value="&quot;sheep-wolves-grass&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="wolf-gain-from-food">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="show-energy?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="wolf-reproduce">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="initial-number-wolves">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="羊的初始个数">
      <value value="100"/>
    </enumeratedValueSet>
    <subExperiment>
      <enumeratedValueSet variable="wolf-gain-from-food">
        <value value="10"/>
        <value value="20"/>
        <value value="30"/>
      </enumeratedValueSet>
    </subExperiment>
  </experiment>
</experiments>
@#$#@#$#@
@#$#@#$#@
default
0.0
-0.2 0 0.0 1.0
0.0 1 1.0 0.0
0.2 0 0.0 1.0
link direction
true
0
Line -7500403 true 150 150 90 180
Line -7500403 true 150 150 210 180
@#$#@#$#@
1
@#$#@#$#@
