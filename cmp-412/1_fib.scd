// CMP 412, Fall 2018, Composition Project 1
// (based on Lucas/Fibonacci Series)
// Noah Kahrs, September 2018

// synthdefs are in 0_synthdefs.scd

// introduction: a series of FM synths whose m/c ratios and durations approximate the golden section.
(
// pick a universal fundamental frequency
var f0 = 377; // near G384, and a Fibonacci number
// obviously seconds are relative so it doesn't really matter that it's Fib., but it helps with some calculations in Section 3

Routine({
	// generate Fibonacci series
	var this_ = 1;
	var next_ = 2;
	var tmp, rat, thisdur, nextdur, totaldur, flag; // placeholder, iterations of golden ratio, single section duration, total duration elapsed duration, cues to exit loop
	var phi = 514229 / 317811; // a nice approximation of phi, precise enough

	totaldur = 0;

	// ======
	// section 1: present a sequence of Fibonacci Ratio FM synths with increasing durations and indices
	("Section 1" + totaldur).postln;
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

	("Section 1b; " + totaldur).postln;
	// mark midpoint with a single harmonic timbre at f0 * ratio
	Synth(\fm, [\cf, f0 * rat, \mc, 1, \ic, 1, \dur, 8, \amp, 0.2]);
	totaldur = totaldur + 5;
	5.wait;

	// invert process: go backwards in Fib series and use undertones
	while({this_ > 0}, { // next section just lasts until it's done
		rat = (this_ / next_);
		[rat, this_].postln;
		tmp = next_ - this_;
		next_ = this_;
		this_ = tmp;

		Synth(\fm, [\cf, f0 / rat, \mc, rat, \ic, this_**rat, \dur, this_, \amp, 0.1]);
		totaldur = totaldur + (this_/5);
		(this_/5).wait;
	});
	Synth(\fm, [\cf, f0 / phi, \mc, 1, \ic, 1, \dur, 8, \amp, 0.2]);
	totaldur = totaldur + 3;
	3.wait;
	// Synth(\fm, [\cf, f0 * phi, \mc, 1, \ic, 1, \dur, 8, \amp, 0.2]);

	("Section 2; " + totaldur).postln;
	// section 1: section 2 should be a GS
	nextdur = totaldur / phi;
	thisdur = 0;
	this_ = 8; // set up Fibonacci series again, later in series
	next_ = 13;
	rat = 5/8;
	flag = true; // alternately, exit as soon as a really long one's happened
	while({(thisdur < nextdur) && flag}, { // condition to make sure GS hold (sort of---it only checks at ends of loops to see if it's exceeded it!)
		// this section kinda rehashes the opening, but starting later
		// in the Fibonacci series, and applying filters at freq ratio phi
		var thisdeviation, oldrat;
		oldrat = rat;
		rat = (next_/this_); // set ratio
		tmp = this_+next_; // calculate next two elements of series
		this_ = next_;
		next_ = tmp;

		// determine synth duration, wait time, and filter intensity from the deviation of "rat" from "phi" (ie how far this Fib ratio deviates from golden section)
		// measured in absolute difference in cents
		thisdeviation = max((1/phi)/abs((rat / oldrat).ratiomidi), 1);

		[rat, this_, thisdeviation].postln;

		Synth(\fmfilter, [\cf, f0, \mc, rat, \ic, this_**(1/rat), \dur, thisdeviation,
			\amp, sqrt(thisdeviation), \ff, f0 * phi, \fq, thisdeviation]);
		totaldur = totaldur + (thisdeviation/13);
		thisdur = thisdur + (thisdeviation/13);
		["durs", thisdur, nextdur].postln;
		if( (thisdeviation/8 < 13),
			{(thisdeviation/13).wait;}, // then
			{(thisdeviation/26).wait; // else
				Synth(\fm, [\cf, f0 * rat, \mc, 1, \ic, 1, \dur, thisdeviation / 10, \amp, (1/(abs((rat/oldrat).ratiomidi).midiratio))**thisdeviation]);
				flag = false; // long duration cues to end loop early
				(thisdeviation/26).wait
		});

	});

	(nextdur - thisdur).wait;

	("Section 3; " + totaldur).postln;


}).play;
)


// part 2: FM with filters
// part 3: pulse train ratios/filters

// part 1: part 2 is GS
// (parts 1+2): part 3 is GS

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