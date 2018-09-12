// CMP 412, Fall 2018, Composition Project 1
// (based on Lucas/Fibonacci Series)
// Noah Kahrs, September 2018

// synthdefs are in 0_synthdefs.scd

// introduction: a series of FM synths whose m/c ratios and durations approximate the golden section.
(
// pick a universal fundamental frequency
var f0 = 256*3/2; // 384

Routine({
	// generate Fibonacci series
	var this_ = 1;
	var next_ = 2;
	var tmp;
	var rat;
	8.do{
		rat = (next_/this_); // set ratio
		[rat, this_, this_/rat].postln;
		tmp = this_+next_; // calculate next two elements of series
		this_ = next_;
		next_ = tmp;
		Synth(\fm, [\cf, f0, \mc, rat, \ic, this_**(1/rat), \dur, this_, \amp, 0.1]);
		(this_/5).wait;
	}
}).play;
)