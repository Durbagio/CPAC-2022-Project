//FIRST EXAMPLE: EACH PERSSON REPRESENTS ONE SINGLE SOUND
//FIXED BPM
//ONLY ONE OSC



(
~n_boids = 1;
~current_state = 0;
~markov_matrix = [1];
~prob_vec = [1];
)

//FUNCTION TO TURN VECTOR INTO SQUARE MATRIX (MARKOV MATRIX)
(
m = {
	|in_vector, length|
	//var length = sqrt(in_vector.size);
	var matrix = [];
	for (0, length-1, {
		|i| matrix = matrix.add(in_vector[i*length..(i+1)*length-1]);
	});
	matrix;
}

)


//FUNCTION TO GET NEXT STATE
(
n = {
	|cur_state|
	//we first compute the matrix  from prob_vec
	var probs;
	~markov_matrix = m.value(~prob_vec, ~n_boids);
	probs = ~markov_matrix[cur_state].normalizeSum;
	postln("Probabilities for next state: "+probs);
	(0..~n_boids-1).wchoose(probs);
}
)



( // RECEIVER
OSCdef('OSCreceiver',
	{
		arg msg;

		msg.removeAt(0);
		//msg.postln;
		~prob_vec = msg;
		~n_boids = sqrt(msg.size).asInteger;

		//function for next note based on current one


	},
	"/markov");
)



///////////////


//EX 0: Visualizing states and probabilities in post window
(
//var tempoclock = TempoClock(1);
var initial_state = 0;
var cur_state = initial_state;
var next_state;
a = {
	inf.do {
		postln("Current state: "+ cur_state);
		next_state = n.value(cur_state);
		postln("Next state"+ next_state);
		1.0.wait;
		cur_state = next_state;
	};
}.fork;
)


a.stop;





//EX 1: Changing between notes represented by each boid
(
e = Pbind(
	\degree, Pfunc({
		var next_state;
		postln("Current state: "+ ~current_state);
		next_state = n.value(~current_state);
		postln("Next state"+ next_state);
		~current_state = next_state;
		next_state;
	})
).play
)

e.stop;