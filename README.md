# CPAC-2022-Project

[hackaton presentation](https://docs.google.com/presentation/d/1Ks5NzHHrDXpIAf_jLT3ydBJz5u7t9odyt5QjDM_n0lg/edit?usp=sharing)

### keyboard commands for developing
- t (target) cycle throw target visulazation of each boid
- f (fixed) add a fixed boid
- c (clock) start internal clock
- v (visualize) toggle executor visualization
- e (executor) if avaiable add one executor
- k (kill) fade out all present boids
- m (manual) attract the nearest boid
- z kill nearest boid
- i (info) toggle groups info visualization
- g (and h) decrease (and increase) threshold


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
- start clock with c
- add other boids far away with f

- press t two times and m to move boids, and maybe connect those gropus

-------------------------------------
### osc message
/probability
[current_state, prob1, prob2, prob3, .... probN]

current state is the index of the boid selected (by processing) according to the probability distribution, that is anyway forwarded to puredata
note: if useful we could introduce after current_state, the length N of the array that is passed
