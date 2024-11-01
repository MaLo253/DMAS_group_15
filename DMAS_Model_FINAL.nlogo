; Design of Multi-Agent Systems 2024

; The Impact of ToM on Compliance In a Pandemic Scenario

; Group 15
; Castoldi, Alessandro (s6133800)
; Skoulidis, Georgios (s6050786)
; Hempenius, Sophie (s4721659)
; Looijenga, Maaike (s4812328)

globals [
  I                                   ; Infection rate, % of agents with infected? True
  R                                   ; Regulation strictness
  C                                   ; Initial willingness to comply of all agents
  alpha1 alpha2 alpha3 alpha4 alpha5  ; Alpha parameters
  gamma_1 gamma_2 gamma_3 gamma_4     ; Gamma parameters
]

turtles-own [
  infected?                           ; Whether the agent is infected
  compliant?                          ; Whether the agent is compliant
  theory-of-mind                      ; ToM level 0, 1, or 2
  infection-duration                  ; How long the agent has been infected
  immune?                             ; Whether the agent is immune
  immunity-duration                   ; How long immunity lasts
  social-pressure                     ; Pressure from social surroundings (neighbours) to comply
  health-status                       ; 1 if healthy, 0 if infected, 2 if immune
]

to setup
  clear-all
  reset-ticks

  set I (initial-infected / 100)      ; Percentage of agents with infected? True for the setup (initial-infected is a slider on the interface)
  set R (I * 100)                     ; Same as initial-infected, this is to show that regulation strictness adjusts to the same rate as infection rate
  set C (willingness-to-comply / 100) ; Initial willingness to comply (slider on the interface)

  ; Initialize alpha and gamma values
  ; In the report is discussed how we got to these specific values
  set alpha1 0.8
  set alpha2 0.2
  set alpha3 0.7
  set alpha4 0.7
  set alpha5 0.5

  set gamma_1 0.8
  set gamma_2 0.8
  set gamma_3 0.6
  set gamma_4 0.6

  ; Get number of agents (set on the slider)
  let total-agents number-of-agents

  ; Initialize how many agents are compliant or not
  let compliance-percentage initial-compliance
  let num-compliant int(total-agents * compliance-percentage / 100)
  let num-non-compliant (total-agents - num-compliant)

  ; Initialize how many agents are first order and second order ToM
  ; The rest will be ToM 0
  let num-tom-1 int(total-agents * ToM-1-percentage / 100)
  let num-tom-2 int(total-agents * ToM-2-percentage / 100)
  let num-tom-0 total-agents - num-tom-1 - num-tom-2

  ; Create agents
  ; Some variables will be set outside of this function (infections, immunity, social pressure and ToM)
  create-turtles total-agents [
    set size 4
    set infected? false
    set compliant? (who < num-compliant)
    set infection-duration 0
    set immune? false
    set immunity-duration 0
    set social-pressure 0
    set health-status 1
    set theory-of-mind -1 ; Set to a value that is not 0, 1 or 2 in order to assign to right number of agents
    setxy random-xcor random-ycor
    set heading random 360
    update-appearance
  ]

  ; Assign ToM levels

  ; Ensure that the number of turtles does not exceed available turtles
  let available-turtles count turtles

  ; Assign first order
  ask n-of min(list num-tom-1 available-turtles) turtles [
    set theory-of-mind 1
  ]

  ; Assign second order
  let remaining-turtles count turtles with [theory-of-mind = -1] ; Count those without assigned ToM
  ask n-of min(list num-tom-2 remaining-turtles) turtles with [theory-of-mind = -1] [
    set theory-of-mind 2
  ]

  ; Assign the remaining agents as ToM 0
  ask turtles with [theory-of-mind = -1] [
    set theory-of-mind 0
  ]

  ; Infect the initial percentage of agents and update health-status and appearance
  let num-initial-infected int(number-of-agents * initial-infected / 100)
  ask n-of num-initial-infected turtles [
    set infected? true
    set health-status 0
    update-appearance
  ]
end

; Function that updates the colour and mask of the agents according to their status
to update-appearance
  ifelse immune? [
    set color green ; Immune agents are green

    ; Compliant agents wear a mask
    ifelse compliant? [
        set shape "mask"
      ] [
        set shape "face happy"
      ]
  ] [
    ifelse infected? [
      set color red ; Infected agents are red
      ifelse compliant? [
        set shape "mask"
      ] [
        set shape "face sad"
      ]
    ] [
      set color yellow ; healthy agents are yellow
      ifelse compliant? [
        set shape "mask"
      ] [
        set shape "face happy"
      ]
    ]
  ]
end

; The following computations are used for the infection transmission probability, please see the report for a detailed explanation

; p0 is the risk from a single agent
to-report compute-p0 [compliant dist]
  let mask-factor ifelse-value compliant [1] [0.5]
  let powerfactor 0.75 * mask-factor * (1 - (1 / (dist + 1)))
  let p0 0.60 - powerfactor
  report p0
end

; pmax is the maximum possible risk
to-report compute-pmax [N]
  let pmax 0.90 - 0.4875 * exp (-0.3 * (N - 1))
  report pmax
end

; p is the actual transmission probability for an agent
to-report compute-p [p0 pmax N]
  let p pmax - 0.4125 + p0
  report max (list 0 (min (list p 1)))
end

; This function handles the infection spread
to infect-neighbors
  ask turtles with [infected?] [
    let nearby-turtles turtles in-radius 2 ; neighbours in a radius of 2 are possible of getting infected
    let num-infected-neighbors count turtles with [infected?] in-radius 1

    ; Each neighbour that is neither infected nor immune (e.g. health-status 1) will get a probability for infection
    ask nearby-turtles with [not infected? and not immune?] [
      let dist distance myself
      let p0 compute-p0 compliant? dist
      let pmax compute-pmax num-infected-neighbors
      let p compute-p p0 pmax num-infected-neighbors
      if random-float 1 < p [
        ; Update status and appearance to infected
        set infected? true
        set health-status 0
        update-appearance
      ]
    ]
  ]
end

; This function handles recovery and immunity for infected agents to recover
to recover
  if infected? [
    set infection-duration infection-duration + 1 ; Update duration counter

    ; Agent recovers between 120 and 240 ticks
    if infection-duration > random 120 + 120 [
      set infected? false
      set immune? true
      set immunity-duration 720
      set health-status 2
      update-appearance
      set infection-duration 0
    ]
  ]
end

; This function handles the decay of immunity over time
to handle-immunity
  if immune? [
    set immunity-duration immunity-duration - 1
    if immunity-duration <= 0 [
      set immune? false
      set immunity-duration 0
      set health-status 1  ; Become healthy after immunity ends
    ]
  ]
end

; Strategy zero order ToM
to-report default-strategy [H]
  let p 0 ; Initializing a compliance probability p

  ; p is calculated based on health-status (we use H here for a more clear oversight of the formulas)
  ; H = 1 indicates healthy
  if H = 1 [
    set p (0.34 * I + 0.33 * (R * (100 - willingness-to-comply) / 100) + 0.33 * willingness-to-comply)
  ]
  ; H = 0 indicates infected
  if H = 0 [
    set p (0.34 * (0 - I) + 0.33 * (R * (100 - willingness-to-comply) / 100) + 0.33 * willingness-to-comply)
  ]
  ; H = 2 indicates immune
  if H = 2 [
    set p (0.5 * (R * (100 - willingness-to-comply) / 100) + 0.5 * willingness-to-comply)
  ]

  ; We normalize the probability
  let normalized_p (p + 100) / 200
  report normalized_p
end

; Strategy first order ToM
to-report first-order-strategy [H perceived_compliance_others]
  let D_H ((alpha1 * I) + (alpha2 * (1 - H)))        ; Desire to remain healthy
  let D_E ((alpha3 * (1 - R)) + (alpha4 * (1 - C)))  ; Desire to minimize effort
  let D_S (alpha5 * perceived_compliance_others)     ; Desire to be social

  ; Calculate exponent (used in determine-compliance function)
  let exponent (1 - (0.2 + (1.2 * I) + (1.0 * R) + (0.8 * H) + (0.5 * C) + (gamma_1 * D_H) - (gamma_2 * D_E) + (gamma_3 * D_S)))
  report (1 / (1 + exp exponent))
end

; Strategy second-order ToM
to-report second-order-strategy [H perceived_compliance_others perceived_beliefs_about_self]
  let D_H ((alpha1 * I) + (alpha2 * (1 - H)))        ; Desire to remain healthy
  let D_E ((alpha3 * (1 - R)) + (alpha4 * (1 - C)))  ; Desire to minimize effort
  let D_S ((alpha5 * perceived_compliance_others))   ; Desire to be social
  let D_B ((gamma_4 * perceived_beliefs_about_self)) ; Desire influenced by others' beliefs about self

  ; Calculate exponent (used in determine-compliance function)
  let exponent (1 - (0.2 + (1.2 * I) + (1.0 * R) + (0.8 * H) + (0.5 * C) + (gamma_1 * D_H) - (gamma_2 * D_E) + (gamma_3 * D_S) + D_B))
  report (1 / (1 + exp exponent))
end

; Determines compliance behaviour based on level of ToM
to determine-compliance
  ask turtles [
    let H health-status
    let perceived_compliance_others (count turtles with [compliant?] in-radius 2) / (count turtles in-radius 2) ; Local compliance rate

    ifelse theory-of-mind = 0 [
      ; ToM-0: Default strategy
      let compliance-prob (default-strategy H)
      set compliant? random-float 1 < compliance-prob
    ] [
      ifelse theory-of-mind = 1 [
        ; First order strategy
        let compliance-prob (first-order-strategy H perceived_compliance_others)
        ; Print to check if strategy works as intended
        ;print compliance-prob
        set compliant? random-float 1 < compliance-prob
      ] [
        ; Second order strategy
        let perceived_beliefs_about_self 0.7
        let compliance-prob (second-order-strategy H perceived_compliance_others perceived_beliefs_about_self)
        set compliant? random-float 1 < compliance-prob
      ]
    ]
    update-appearance
  ]
end

; Function that calculates social pressure, based on compliance of all agents
to calculate-social-pressure
  let total-turtles count turtles
  let compliant-turtles count turtles with [compliant?]
  let non-compliant-turtles total-turtles - compliant-turtles

  ; Set a local social pressure for each agent
  ask turtles [
    let local-pressure (compliant-turtles / total-turtles) * 0.5
    set social-pressure local-pressure
  ]
end

; Function to simulate social distancing by moving away from neighbours too close
to maintain-distance
  let nearby-turtles other turtles in-radius 1.5 ; 1.5 to simulate the 1.5 meter rule
  if any? nearby-turtles [
    let closest-turtle min-one-of nearby-turtles [distance myself]
    let angle-to-turn towards closest-turtle
    rt (angle-to-turn + 180)
    fd 1
  ]
end

to go
  ; Simulation stops when no agents are infected
  if not any? turtles with [infected?] [stop]

  ; Update infection rate (I)
  set I (count turtles with [infected?] / count turtles)
  set R (I * 100)

  ; Spread the infection
  infect-neighbors

  ; Handle recovery and immunity
  ask turtles [
    recover
    handle-immunity
  ]

  ; Calculate compliance and social pressure
  calculate-social-pressure
  determine-compliance

  ; Move agents
  ask turtles [
    if compliant? [
      maintain-distance
    ]

    let angle random 45 - random 45
    rt angle
    fd 1
  ]

  tick
end

; For running the experiment, we implemented a grid search
to run-grid-search

  ; Define the parameter values (further explained in report)
  let agents-grid (range 10 101 10)
  let initial-infected-grid  (range 5 61 5)
  let initial-compliance-grid [50]
  let willingness-to-comply-grid (range 20 91 10)

  ; We changed the ToM manually
  let tom-1-percent-grid [100]
  let tom-2-percent-grid [0]

  ; For saving the csv file to computer
  let results-directory "D:/Downloads/results/"
  let filename (word results-directory "new3__tom1_" tom-1-percent-grid "__tom2_" tom-2-percent-grid".csv") ; Filename based on the current ToM combination

  ; Open the csv file
  file-open filename

  ; Set column names
  file-print "SetupID,Tick,InfectionRate,ComplianceRate,ToM0,ToM1,ToM2,NumberOfAgents,InitialInfected,InitialCompliance,WillingnessToComply,RegulationStrictness"

  file-close

  ; Initialize setup-id to track each unique setup configuration
  let setup-id 1

  ; The grid search
  foreach agents-grid [agents ->
    foreach initial-infected-grid [ini-infected ->
      foreach initial-compliance-grid [ini-compliance ->
        foreach willingness-to-comply-grid [will-to-comply ->
          foreach tom-1-percent-grid [tom-1-percent ->
            foreach tom-2-percent-grid [tom-2-percent ->

              ; Adjust the global parameters in the simulation
              set number-of-agents agents
              set initial-infected ini-infected
              set initial-compliance ini-compliance
              set willingness-to-comply will-to-comply
              set ToM-1-percentage tom-1-percent
              set ToM-2-percentage tom-2-percent

              ; Runs the simulation and logs the results for each tick with the current setup-id
              run-simulation-and-log-every-tick filename setup-id

              ; Increment the setup-id for the next configuration
              set setup-id setup-id + 1

            ]
          ]
        ]
      ]
    ]
  ]
end

; Function for doing simulations and write everything to the file
to run-simulation-and-log-every-tick [filename setup-id]
  let num-simulations 1  ; Number of simulations per setup
  let num-ticks 1000     ; Maximum ticks per simulation

  ; Open csv and start simulation
  file-open filename

  repeat num-simulations [
    setup
    ; Loop through the ticks and log data for each tick
    repeat num-ticks [
      go
      let infection-rate (count turtles with [infected?] / count turtles) * 100
      let compliance-rate (count turtles with [compliant?] / count turtles) * 100
      let tom-0 (count turtles with [theory-of-mind = 0])
      let tom-1 (count turtles with [theory-of-mind = 1])
      let tom-2 (count turtles with [theory-of-mind = 2])

      ; Logging current parameters
      file-print (word setup-id "," ticks "," infection-rate "," compliance-rate "," tom-0 "," tom-1 "," tom-2 "," number-of-agents "," initial-infected "," initial-compliance "," willingness-to-comply "," R)

      ; Stop logging if a round ends
      if infection-rate = 0 [
        stop
      ]
    ]
  ]

  file-close
end

; The NetLogo Dictionary (https://ccl.northwestern.edu/netlogo/docs/dictionary.html)
; and course content from Agent Technology Practical (2023) were used as resources and inspiration.
@#$#@#$#@
GRAPHICS-WINDOW
234
12
646
425
-1
-1
4.0
1
10
1
1
1
0
1
1
1
-50
50
-50
50
1
1
1
ticks
1.0

SLIDER
17
229
189
262
initial-compliance
initial-compliance
0
100
50.0
1
1
%
HORIZONTAL

BUTTON
29
13
92
46
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
13
178
46
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
0

SLIDER
17
147
189
180
number-of-agents
number-of-agents
0
200
100.0
1
1
NIL
HORIZONTAL

SLIDER
17
189
189
222
initial-infected
initial-infected
0
100
60.0
1
1
%
HORIZONTAL

MONITOR
24
499
81
544
mask
count turtles with [compliant? = true]
17
1
11

MONITOR
102
499
167
544
no-masks
count turtles with [compliant? = false]
17
1
11

PLOT
236
441
426
582
Compliance rate (%)
NIL
NIL
0.0
10.0
0.0
100.0
true
false
"\n" ""
PENS
"compliance" 1.0 0 -13791810 true "" "if count turtles > 0 [\n  plot (count turtles with [ compliant? = true] / count turtles) * 100\n]"

BUTTON
66
58
141
91
go once
go
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
0

PLOT
435
442
630
582
Infections
NIL
NIL
0.0
20.0
0.0
100.0
true
false
"" ""
PENS
"default" 1.0 0 -2674135 true "" "plot count turtles with [infected? = true]"

SLIDER
17
271
190
304
willingness-to-comply
willingness-to-comply
0
100
90.0
1
1
%
HORIZONTAL

BUTTON
23
106
184
139
NIL
run-grid-search
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

SLIDER
18
356
190
389
ToM-1-percentage
ToM-1-percentage
0
100
40.0
1
1
%
HORIZONTAL

SLIDER
17
398
189
431
ToM-2-percentage
ToM-2-percentage
0
100
40.0
1
1
%
HORIZONTAL

MONITOR
740
107
797
152
ToM 0
count turtles with [theory-of-mind = 0]
17
1
11

MONITOR
739
190
796
235
ToM 1
count turtles with [theory-of-mind = 1]
17
1
11

MONITOR
740
275
797
320
ToM 2
count turtles with [theory-of-mind = 2]
17
1
11

SLIDER
17
313
190
346
regulation-strictness
regulation-strictness
0
100
50.0
1
1
%
HORIZONTAL

@#$#@#$#@
## WHAT IS IT?

(a general understanding of what the model is trying to show or explain)

## HOW IT WORKS

(what rules the agents use to create the overall behavior of the model)

## HOW TO USE IT

(how to use the model, including a description of each of the items in the Interface tab)

## THINGS TO NOTICE

(suggested things for the user to notice while running the model)

## THINGS TO TRY

(suggested things for the user to try to do (move sliders, switches, etc.) with the model)

## EXTENDING THE MODEL

(suggested things to add or change in the Code tab to make the model more complicated, detailed, accurate, etc.)

## NETLOGO FEATURES

(interesting or unusual features of NetLogo that the model uses, particularly in the Code tab; or where workarounds were needed for missing features)

## RELATED MODELS

(models in the NetLogo Models Library and elsewhere which are of related interest)

## CREDITS AND REFERENCES

(a reference to the model's URL on the web if it has one, as well as any other necessary credits, citations, and links)
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

mask
false
4
Circle -1184463 true true 8 7 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Rectangle -16777216 true false 60 195 240 225
Rectangle -1 true false 30 150 270 270

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
NetLogo 6.2.2
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
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
