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
