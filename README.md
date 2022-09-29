# SOCIAL CONSTELLATION

<p align="center">
  <img src="https://user-images.githubusercontent.com/64915668/193022043-f95c622a-ce61-4a29-97bb-d543093f3066.png">
</p>

The global pandemic created big issues for everyone, both physically and mentally. We are still struggling against the drawbacks of social distancing that magnifies the digital infrastructure and cultural divide of our society, lowering of empathy levels and leading to creative blocks and mental stress. We developed the concept of our project around this phenomena, trying not to underline difficulties but showing how much digitalization and technology could help by encouraging positive and creative thinking using the power of the collectivity.
We want people to feel the power of being a collective rather than a multitude of singles and showing them the whole is the result of the behaviour of each one.

[**PRESENTATION**](https://docs.google.com/presentation/d/1Ks5NzHHrDXpIAf_jLT3ydBJz5u7t9odyt5QjDM_n0lg/edit?usp=sharing)

## THE EXPERIENCE

- **MINIMAL EVENT SCORE: YOU ARE FREE TO MOVE**
- **AUDIO AND VISUAL ARE AFFECTED BY PEOPLE MOTION**

<p align="center">
  <img src="https://user-images.githubusercontent.com/64915668/193021653-3b00ae53-b760-481d-b123-2643b4616a16.png">
</p>

The way you move and interact with other people will evolve on time, modulating the laser projection on the ceiling which represents a star field. The idea is to represent the effects of the collective behaviour of different clusters of people that move in the field differently. This is both a conceptual art installation and music instrument as everyone is affecting the overall result with his/her motion, encouraging people to cooperate and create unique visual and music pieces.

## TECHNICAL SOLUTION



## HOW TO USE

### Keyboard commands for developing in Processing
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
- r randomize boid location
- p (print and pause) print some useful variables
- x (double draw) draw each line two times
- w (and q) increase (decrease) maxspeed
- s (and a) increase (decrease) maxforce

-------------------------------------
### osc message debug
/probability
[current_state, prob1, prob2, prob3, .... probN]

current state is the index of the boid selected (by processing) according to the probability distribution, that is anyway forwarded to puredata
note: if useful we could introduce after current_state, the length N of the array that is passed

-------------------------------------

### Example of usage (manually create two groups of execution):
- open the Processing script and run it
- right click
- position some fixed boids with f (e.g. on the left of the screen)
- start clock with c
- start Pure Data to start hear sound
- add other boids far away with f
- press t two times and m to move boids
- try to connect those groups

### Example of usage (feed Processing with video stream data):
- open the Python script, select the video source:
```
# video_path = './video examples/MOT20-06-raw.webm'
# video_path = '' # uncomment to activate webcam input
```
- run the Python script
- open the Processing script and run it
- start Pure Data to start hear sound
