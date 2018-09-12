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
	var tmp, rat, totaldur; // placeholder, iterations of golden ratio, section duration

	// ======
	// section 1: present a sequence of Fibonacci Ratio FM synths with increasing durations and indices
	"Section 1".postln;
	// keep in mind total section duration
	totaldur=0;
	while({totaldur < 8}, { // 13-second section
		rat = (next_/this_); // set ratio
		[rat, this_].postln;
		tmp = this_+next_; // calculate next two elements of series
		this_ = next_;
		next_ = tmp;
		Synth(\fm, [\cf, f0, \mc, rat, \ic, this_**(1/rat), \dur, this_, \amp, 0.1]);
		totaldur = totaldur + (this_/5);
		(this_/5).wait;
	});

	"Section 2".postln;
	// mark midpoint with a single harmonic timbre at f0 * ratio
	Synth(\fm, [\cf, f0 * rat, \mc, 1, \ic, 1, \dur, 8, \amp, 0.2]);
	5.wait;

	// invert process: go backwards in Fib series and use undertones
	while({this_ > 0}, { // next section just lasts until it's done
		rat = (this_ / next_);
		[rat, this_].postln;
		tmp = next_ - this_;
		next_ = this_;
		this_ = tmp;

		Synth(\fm, [\cf, f0 / rat, \mc, rat, \ic, this_**rat, \dur, this_, \amp, 0.1]);
		(this_/5).wait;
	});
	Synth(\fm, [\cf, f0 * rat, \mc, 1, \ic, 1, \dur, 8, \amp, 0.2]);
	5.wait;

}).play;
)


(
var this_ = 34;
var next_ = 55;
var tmp;
var rat;
7.do{
	tmp = next_ - this_;
	next_ = this_;
	this_ = tmp;
	tmp.postln;
	(this_/next_).postln;
}
)