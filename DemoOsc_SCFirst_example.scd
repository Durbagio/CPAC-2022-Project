//FIRST EXAMPLE: EACH PERSON REPRESENTS ONE SINGLE SOUND
//ONLY ONE OSCILLATOR


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


~n_boids;

e.stop;


