//FIRST EXAMPLE: EACH PERSON REPRESENTS ONE SINGLE SOUND
//ONLY ONE OSCILLATOR

s.boot;
(
(
~n_boids = 1;
~current_state = 0;
~markov_matrix = [1];
~prob_vec = [1];
);

/*
//FUNCTION TO TURN VECTOR INTO SQUARE MATRIX (MARKOV MATRIX)
(
m = {
	|in_vector, length|
	//var length = sqrt(in_vector.size);
	var matrix = [];
	for (0, length-1, {
		|i| matrix = matrix.add(in_vector[i*length..(i+1)*length-1]);
		//postln(matrix[i]);
	});
	matrix;
}



);
*/


//FUNCTION TO GET NEXT STATE

(
/*
//from Markov Matrix
n = {
	|cur_state|
	//we first compute the matrix  from prob_vec
	var probs;
	~markov_matrix = m.value(~prob_vec, ~n_boids);
	probs = ~markov_matrix[cur_state].normalizeSum;
	postln("Probabilities for next state: "+probs);
	(0..~n_boids-1).wchoose(probs);
}
*/

//from probability array (PROCESSING)
n = {
	|prob_vector|
	~n_boids = prob_vector.size;
	(0..~n_boids-1).wchoose(prob_vector);
}

);

( // RECEIVER
OSCdef('OSCreceiver',
	{
		arg msg;

		msg.removeAt(0);
		("Probabilities: "+ msg).postln;
		~prob_vec = msg;
		~n_boids = msg.size.asInteger;

		//function for next note based on current one


	},
	"/markov");

);


c = NetAddr.new("127.0.0.1", 3000);

)


///////////////




(
SynthDef.new(\PhaseMod, {
	arg f1, f2, f3, fund, sustain, bw;
	var sig, sig1, sig2, sig3, env;

	sig1 = Formant.ar(fund, f1, Rand(1,bw), 0.1, 0.0);
	sig2 = Formant.ar(fund*3, f2, Rand(1,bw), 0.1, 0.0);
	sig3 = Formant.ar(fund*4, f3, Rand(1,bw), 0.1, 0.0);
	sig = sig1 + sig2 + sig3;
	sig =  sig * EnvGen.kr(Env([0, 0.5, 0], [0.01, sustain]),doneAction: 2);

	Out.ar([0,1], sig);
	}).add;

e = Pbind(
	\fund, Pfunc({
		var next_state;
		var fundamental = 100, freq = Array.new(~n_boids);
		~n_boids.do({ arg i; z = freq.add((i+1)*fundamental)};);
		TempoClock.tempo = ~n_boids;
		postln("Initial state: "+ ~current_state);
		next_state = n.value(~prob_vec);
		postln("New state"+ next_state);
		~current_state = next_state;
		c.sendMsg("/clock", ~current_state);
		next_state;
		freq[next_state];
	}),

	\bw, Pfunc({

		var bw = 10*~n_boids;

		bw;
	}),

	\f1, Pfunc({
		var next_state;
		var fundamental = 200, formant1 = Array.new(~n_boids);
		~n_boids.do({ arg i; z = formant1.add(((~current_state+1)*(i+1))*fundamental)};);
		next_state = n.value(~prob_vec);
		~current_state = next_state;
		next_state;
		formant1[next_state];
	}),

	\f2, Pfunc({
		var next_state;
		var fundamental = 200, formant1 = Array.new(~n_boids);
		~n_boids.do({ arg i; z = formant1.add(((~current_state+1)*(i+1))*fundamental)};);
		next_state = n.value(~prob_vec);
		~current_state = next_state;
		next_state;
		formant1[next_state];

	}),

	\f3, Pfunc({
		var next_state;
		var fundamental = 200, formant1 = Array.new(~n_boids);
		~n_boids.do({ arg i; z = formant1.add(((~current_state+1)*(i+1))*fundamental)};);
		next_state = n.value(~prob_vec);
		~current_state = next_state;
		next_state;
		formant1[next_state];

	}),

	\sustain, Pfunc({
		var dur = 1/~n_boids;
		dur;
	}), \instrument, \PhaseMod
).play
)


/*
//EX 1: Changing between notes represented by each boid
(
e = Pbind(
	\degree, Pfunc({
		var next_state;
		TempoClock.tempo = ~n_boids;
		postln("Initial state: "+ ~current_state);
		next_state = n.value(~prob_vec);
		postln("New state"+ next_state);
		~current_state = next_state;
		c.sendMsg("/clock", ~current_state);
		next_state;
	}
	)
).play
)


(
e = Pbind(
	\degree, 0
).play
)

e.stop;

*/

