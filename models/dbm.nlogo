; ============================================================
; Diet Breadth Model — Agent-Based Implementation
; ============================================================
; A spatial agent-based extension of the classic Diet Breadth Model
; (Charnov 1976; Stephens & Krebs 1986; Bettinger 2009).
;
; A single forager moves through a landscape with five prey types
; ranked by post-encounter return rate (kcal / handling time).
; At each encounter, the forager applies the DBM decision rule:
; take the prey only if its rank exceeds the average return rate
; of the currently accepted diet.
;
; Author: Rodrigo Mendoza Sánchez (ArchALife project)
; License: CC BY-SA 4.0
; ============================================================

breed [foragers forager]
breed [preys prey]

preys-own [kcal handling rank-value prey-name]
foragers-own [
  total-kcal
  total-search-time
  total-handling-time
  diet-list           ; list of prey-names accepted
]

globals [
  prey-types          ; list of prey definitions
  encounters-taken
  encounters-skipped
]

; ============================================================
; SETUP
; ============================================================

to setup
  clear-all
  setup-prey-types
  setup-landscape
  setup-forager
  set encounters-taken 0
  set encounters-skipped 0
  reset-ticks
end

to setup-prey-types
  ; Each prey type: [name kcal handling color density]
  ; Density is controlled by sliders (lambda-* values)
  set prey-types (list
    (list "guanaco"  50000 8.0 brown          lambda-guanaco)
    (list "huemul"   30000 6.0 (brown + 1)    lambda-huemul)
    (list "vizcacha"  3000 1.0 orange         lambda-vizcacha)
    (list "coypu"     2500 1.2 (orange + 1)   lambda-coypu)
    (list "lizard"     200 0.3 green          lambda-lizard)
  )
end

to setup-landscape
  ask patches [ set pcolor 38 ]   ; sandy background
  foreach prey-types [ pt ->
    let n round (count patches * (item 4 pt))
    create-preys n [
      set prey-name (item 0 pt)
      set kcal     (item 1 pt)
      set handling (item 2 pt)
      set color    (item 3 pt)
      set rank-value (kcal / handling)
      set shape "circle"
      set size 0.8
      setxy random-xcor random-ycor
    ]
  ]
end

to setup-forager
  create-foragers 1 [
    set color red
    set shape "person"
    set size 2
    setxy 0 0
    set total-kcal 0
    set total-search-time 0
    set total-handling-time 0
    set diet-list []
  ]
end

; ============================================================
; GO — main simulation loop
; ============================================================

to go
  if not any? preys [ stop ]
  ask foragers [
    search-and-encounter
  ]
  tick
end

to search-and-encounter
  ; Search: random walk
  right random 60 - 30
  forward search-speed
  set total-search-time total-search-time + 1

  ; Encounter check: any prey within radius 1?
  let nearby-prey one-of preys in-radius 1
  if nearby-prey != nobody [
    decide-and-act nearby-prey
  ]
end

; ============================================================
; THE DBM DECISION RULE — heart of the model
; ============================================================

to decide-and-act [the-prey]
  let prey-rank [rank-value] of the-prey
  let current-rate average-return-rate

  ; Decision rule: take if post-encounter rate > current average
  ifelse (length diet-list = 0) or (prey-rank > current-rate)
  [
    ; TAKE: consume the prey
    set total-kcal (total-kcal + [kcal] of the-prey)
    set total-handling-time (total-handling-time + [handling] of the-prey)
    set diet-list lput ([prey-name] of the-prey) diet-list
    set encounters-taken encounters-taken + 1
    ask the-prey [ die ]
  ]
  [
    ; SKIP: keep searching
    set encounters-skipped encounters-skipped + 1
  ]
end

to-report average-return-rate
  ; R(D) = total kcal / total time (search + handling)
  let total-time (total-search-time + total-handling-time)
  ifelse total-time = 0
    [ report 0 ]
    [ report (total-kcal / total-time) ]
end

; ============================================================
; REPORTERS for plots and monitors
; ============================================================

to-report current-return-rate
  ifelse any? foragers
    [ report [average-return-rate] of one-of foragers ]
    [ report 0 ]
end

to-report diet-breadth
  ifelse any? foragers
    [ report length remove-duplicates [diet-list] of one-of foragers ]
    [ report 0 ]
end

to-report total-energy
  ifelse any? foragers
    [ report [total-kcal] of one-of foragers ]
    [ report 0 ]
end
@#$#@#$#@
GRAPHICS-WINDOW
500
10
918
429
-1
-1
8.0
1
10
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
30.0

BUTTON
10
10
105
50
NIL
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
10
220
50
NIL
go
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

SLIDER
10
60
220
93
lambda-guanaco
lambda-guanaco
0.001
0.05
0.005
0.001
1
NIL
HORIZONTAL

SLIDER
10
98
220
131
lambda-huemul
lambda-huemul
0.001
0.05
0.008
0.001
1
NIL
HORIZONTAL

SLIDER
10
136
220
169
lambda-vizcacha
lambda-vizcacha
0.01
0.1
0.05
0.01
1
NIL
HORIZONTAL

SLIDER
10
174
220
207
lambda-coypu
lambda-coypu
0.01
0.1
0.04
0.01
1
NIL
HORIZONTAL

SLIDER
10
212
220
245
lambda-lizard
lambda-lizard
0.05
0.5
0.2
0.01
1
NIL
HORIZONTAL

SLIDER
10
250
220
283
search-speed
search-speed
0.5
3.0
1.0
0.1
1
NIL
HORIZONTAL

MONITOR
230
60
355
105
Diet breadth
diet-breadth
3
1
11

MONITOR
365
60
490
105
Encounters taken
encounters-taken
3
1
11

MONITOR
230
115
355
160
Encounters skipped
encounters-skipped
3
1
11

MONITOR
365
115
490
160
Avg return (kcal/h)
current-return-rate
3
1
11

PLOT
230
170
490
295
Cumulative energy
ticks
total-energy
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"energy" 1.0 0 -16777216 true "" "plot total-energy"

PLOT
230
305
490
430
Return rate (kcal/h)
ticks
rate
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"rate" 1.0 0 -2674135 true "" "plot current-return-rate"
@#$#@#$#@
## ¿Qué es?

El **Diet Breadth Model (DBM)** es uno de los modelos fundacionales de la ecología del comportamiento humano (HBE) en arqueología. Predice qué tipos de presa debe incluir un forrajero racional en su dieta para maximizar la tasa de retorno energético a largo plazo.

## Cómo funciona

Un único forrajero recorre un paisaje 2D con cinco tipos de presa: guanaco, huemul, vizcacha, coypu y lagartija. Cada presa tiene un contenido energético (kcal) y un tiempo de manejo (horas). El rango de la presa es e/h.

En cada encuentro, el forrajero aplica la regla del DBM:

> Tomar la presa si y solo si su rango (e/h) supera la tasa de retorno promedio R(D) de la dieta actualmente aceptada.

R(D) = Σ λ_j e_j / (1 + Σ λ_j h_j)

## Cómo usar

1. Ajusta las tasas de encuentro de cada presa con los **sliders** (lambda-*).
2. Pulsa **setup** para crear el paisaje.
3. Pulsa **go** para iniciar la simulación.
4. Observa cómo cambia la **diet breadth** (número de tipos de presa aceptados) en función de la disponibilidad relativa de las presas de alto rango.

## Predicciones

- **Predicción 1**: el rango (e/h) no depende de la abundancia.
- **Predicción 2**: la abundancia de una presa solo importa para tipos rankeados por encima de ella.
- **Predicción 3**: si las presas de alto rango se agotan, la dieta se amplía (firma arqueológica de intensificación).

## Referencias

- Bettinger, R. L. (2009). *Hunter-Gatherer Foraging: Five Simple Models*. Eliot Werner.
- Charnov, E. L. (1976). Optimal foraging: attack strategy of a mantid. *American Naturalist* 110: 141–151.
- Stephens, D. W. & Krebs, J. R. (1986). *Foraging Theory*. Princeton University Press.

Parte del proyecto **ArchALife** (archalife.github.io/archalife). CC BY-SA 4.0.
@#$#@#$#@
default
true
0
Polygon -7500403 true true 150 5 40 250 150 205 260 250

circle
false
0
Circle -7500403 true true 0 0 300

circle 2
false
0
Circle -7500403 true true 16 16 270
Circle -16777216 true false 46 46 210

person
false
0
Circle -7500403 true true 110 5 80
Polygon -7500403 true true 105 90 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 195 90
Rectangle -7500403 true true 127 79 172 94
Polygon -7500403 true true 195 90 240 150 225 180 165 105
Polygon -7500403 true true 105 90 60 150 75 180 135 105

square
false
0
Rectangle -7500403 true true 30 30 270 270
@#$#@#$#@
NetLogo 6.4.0
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
<experiments>
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
0
@#$#@#$#@
