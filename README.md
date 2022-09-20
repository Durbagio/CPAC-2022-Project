# CPAC-2022-Project

[hackaton presentation](https://docs.google.com/presentation/d/1Ks5NzHHrDXpIAf_jLT3ydBJz5u7t9odyt5QjDM_n0lg/edit?usp=sharing)

### keyboard commands for developing
- t (target) cycle throw target visulazation of each boid
- f (fixed) add a fixed boid
- c (clock) start internal clock and one executor (osc messages not sended); also toggle visualization
- e (executor) add a fixed boid as set it as second executor
- k (kill) fade out all present boids
- m (manual) attract the nearest boid

- left click: add bunch of boids
- right click: delete all boids

other commands:
- r randomize boid location
- p (print and pause) print some useful variables
- x (double draw) draw each line two times
- w (and q) increase (decrease) maxspeed
- s (and a) increase (decrease) maxforce


--------------------------------------
example of usage (to manually create two groups of execution):
- open
- right click
- position some fixed boids with f (e.g. on the left of the screen)
- see/start clock with c
- add other boids far away with f
- add a second executor with e near this separate group

- press t two times and m to move boids, and maybe connect those gropus

-------------------------------------
### osc message
/probability
[current_state, prob1, prob2, prob3, .... probN]

current state is the index of the boid selected (by processing) according to the probability distribution, that is anyway forwarded to puredata
note: if useful we could introduce after current_state, the length N of the array that is passed
