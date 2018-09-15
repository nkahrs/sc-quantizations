(
/* CMP 412, Fall 2018, Composition Project 1
(based on Lucas/Fibonacci Series)
Noah Kahrs, September 2018
synthdefs are in 0_synthdefs.scd */

// pick a universal fundamental frequency
var f0 = 377; // near G384, and a Fibonacci number
// obviously seconds are relative so it doesn't really matter that it's Fib.
// but it helps with some calculations in Section 3

Routine({
	// generate Fibonacci series
	var this_ = 1;
	var next_ = 2;
	var tmp, rat, thisdur, nextdur, totaldur, flag;
	/* other variables I need later: placeholder, iterations of golden ratio,
	single section duration, total duration elapsed duration,
	cues to exit loop */
	var phi = 514229 / 317811; // a nice approximation of phi, precise enough
	// for mono sounds, left or right? We'll generally just alternate
	var whichspeaker = 0;

	totaldur = 0;

	// ======
	// section 1: present a sequence of Fibonacci Ratio FM synths with increasing durations and indices (in stereo)
	("Section 1" + totaldur).postln;
	// keep in mind total section duration
	totaldur=0;
	while({totaldur < 8}, { // 13-second section
		rat = (next_/this_); // set ratio
		[rat, this_].postln;
		tmp = this_+next_; // calculate next two elements of series
		this_ = next_;
		next_ = tmp;
		Synth(\fm, [\cf, f0, \mc, rat, \ic, this_**(1/rat), \dur, this_, \amp, 0.1*(0.97**this_)]);
		totaldur = totaldur + (this_/5);
		(this_/5).wait;
	});

	("Section 1b; " + totaldur).postln;
	// mark midpoint with a single harmonic timbre at f0 * ratio
	Synth(\fm, [\cf, f0 * rat, \mc, 1, \ic, 1, \dur, 8, \amp, 0.2]);
	totaldur = totaldur + 5;
	5.wait;

	// invert process: go backwards in Fib series and use undertones
	// alternating hard panning
	while({this_ > 0}, { // next section just lasts until it's done
		rat = (this_ / next_);
		[rat, this_].postln;
		tmp = next_ - this_;
		next_ = this_;
		this_ = tmp;

		Synth(\fmmono, [\cf, f0 / rat, \mc, rat, \ic, this_**rat, \dur, this_,
			\amp, 0.1, \outBus, whichspeaker]);
		whichspeaker = 1 - whichspeaker;
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

		// determine synth duration, wait time, and filter intensity from the deviation
		// of "rat" from "oldrat" (ie change in how we're approaching harmonic series
		// measured in absolute difference in cents
		thisdeviation = max((1/phi)/abs((rat / oldrat).ratiomidi), 1);

		[rat, this_, thisdeviation].postln;

		Synth(\fmfiltermono, [\cf, f0, \mc, (1/rat), \ic, this_**(1/rat),
			\dur, thisdeviation**(1/rat), \amp, thisdeviation**(phi/this_),
			\ff, f0 * phi, \fq, thisdeviation**(1/phi), \outBus, whichspeaker]);
		// these values for amplitude and duration are good compromises
		//between mathematical elegance and wanting to temper changes
		whichspeaker = 1 - whichspeaker;
		totaldur = totaldur + (thisdeviation/13);
		thisdur = thisdur + (thisdeviation/13);
		if( (thisdeviation/8 < 13),
			// if it's a really long-duration cue, do things differently
			{(thisdeviation/13).wait;}, // then
			{(thisdeviation/26).wait; // else
				Synth(\fm, [\cf, f0 * rat, \mc, 1, \ic, 1,
					\dur, thisdeviation / 10, \amp, 1/21]);
				flag = false; // long duration cues to end loop early
				(thisdeviation/26).wait
		});
	});

	(nextdur - thisdur).wait;

	("Section 3; " + totaldur).postln;
	/* section 3: combined pulse trains of higher and lower Fibonacci series,
	decreasing over time as in section 1b. Ratios between the two pulse trains
	are various golden sections. Each pulse train is filtered at f0.*/
	this_ = 377;
	next_ = 610;
	thisdur = 0;
	nextdur = totaldur / (1.618);

	11.do{ // 3/2 is too recognizable a polyrhythm, 5/3 is a good place to end
		arg thisiter;
		var minwait, maxwait, synthwait, itersleft;
		itersleft = 13 - thisiter;
		/* how to establish how long it is?
		prolong if difference between values is close to critical band
		want average-ish wait time to be (time left / iters left)
		determine acceptable deviation by number of iterations left */

		synthwait = (nextdur - thisdur) / itersleft;
		maxwait = synthwait*(1+(itersleft/13));
		minwait = synthwait/(1+(itersleft/13));

		tmp = next_ - this_; // used for next Fibonacci duration
		synthwait = min(20/tmp, tmp/20).linexp(0, 1, minwait, maxwait);
		rat = next_/this_;

		[this_, next_].postln;
		Synth(\pitchedpulse, [\pf, next_, \sf, 377, \dur, (phi + 1) * synthwait,
			\ramp, (synthwait/3), \outBus, whichspeaker,
			// determine amplitude in accordance with duration
			\amp, 0.3/synthwait;]
		);
		synthwait.wait;
		thisdur = thisdur + synthwait;
		totaldur = totaldur + synthwait;
		next_ = this_;
		this_ = tmp;
		whichspeaker = 1 - whichspeaker;
	};
	thisdur.postln;
	Synth(\fm, [\cf, 377*377/610, \mc, 1, \ic, 1, \dur, (nextdur - thisdur), \amp, 0.2]);
	totaldur = totaldur + nextdur - thisdur;
	(nextdur-thisdur).wait;
	("end; "+ totaldur).postln;

}).play;
)