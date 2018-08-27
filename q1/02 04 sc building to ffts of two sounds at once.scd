// basic initializations

b = Buffer.read(s, "/Volumes/snd/sflib/gamelan/angk.shortroll.af5.wav")
b.numChannels

~fftBuf1 = Buffer.alloc(s,1024)
~fftBuf2 = Buffer.alloc(s,1024)

// just play buffer. success!
{PlayBuf.ar(1,b,loop:1)}.play

// just magnify voice. success!
{SoundIn.ar(0)}.play

// basic AM synthesis. success!
(
{
	var carrier, modulator;
	carrier = PlayBuf.ar(1, b, loop:1);
	modulator = SoundIn.ar(0);

	carrier * modulator;
}.play;
)

// let's try basic FFT manipulation that changes nothing
(
{
	var sound, chain;

	sound = PlayBuf.ar(1, b, loop:1);
	chain = FFT(~fftBuf1, sound);

	chain = chain.pvcalc(1024, {
		arg mags, phases;
		[mags, phases]
	}, 0, 1023, 0);

	IFFT(chain);
}.play;
)


// very basic FFT manipulation, combining these two sources
(
{
	var sound1, sound2, chain1, chain2;

	sound1 = PlayBuf.ar(1, b, loop:1);
	sound2 = SoundIn.ar(0);

	chain1 = FFT(~fftBuf1, sound1);
	chain2 = FFT(~fftBuf2, sound2);

	chain1 = chain1.pvcalc2(chain2, 1024, {
		arg mags1, phases1, mags2, phases2;
		[mags2, phases1]
	});

	IFFT(chain1);
}.play;
)

// another very basic FFT manipulations. Here's a squaring of all the magnitudes, reset all phases to zero..

// first, make sure we know how lists work.
(
var asdf = [1,2,3,4,5];
asdf.size.do{arg i; asdf[i] = asdf[i]**2;};
asdf.postln;
)

(
{
	var sound, chain;

	sound = SoundIn.ar(0);
	chain = FFT(~fftBuf1, sound);

	chain = chain.pvcalc(1024, {
		arg mags, phases;
		mags.size.do{
			arg i;
			mags[i] = mags[i]**2;
		};
		phases.size.do{
			arg i;
			phases[i] = 0;
		};
		[mags, phases]
	});

	IFFT(chain);
}.play;
)

// I have all the basics of the easy stuff. Now, the hard stuff remains---actually implementing the fake AM thing.

// first, let's sandbox the general principles of the code. There'll be 1024 bins to deal with, each gets a list of amplitudes and phases to combine.

~bins = Array.fill(1024, {List.new()});
~bins[289].add([5,2])
~bins[5].add([8,3])
~bins
// all works as expected, but is weirdly objecty. But ok, continue.

// also check mod
17%3
(-16)%3

// part 1: calculate all the sidebands and package them all near their respective bins
(
// fake amplitudes and phases, for testing purposes.
var amps1, phases1, amps2, phases2, sidebands, size;

// assume that all of the above lists have length "size"
size = 2;

// lists of size size (like amps, phases in pvcalc2
amps1 = Array.fill(size, {arg i; i/size;});
phases1 = Array.fill(size, {arg i; i/(2*pi);});
amps2 = Array.fill(size, {arg i; i/size;});
phases2 = Array.fill(size, {arg i; i/(2*pi);});

// for each bin, we have [newamps, newphases], ie an array of two lists
sidebands = Array.fill(size, {[List.new(), List.new()]});

size.do{
	arg i;
	size.do{
		arg j;

		sidebands[(j-i)%size][0].add(amps1[i]*amps2[j]/2); // difference tone amplitude
		sidebands[(j-i)%size][1].add(pi/2 + phases2[j] - phases1[i]); // difference tone phase

		sidebands[(j+i)%size][0].add(amps1[i]*amps2[j]/2); // sum tone amplitude
		sidebands[(j+i)%size][1].add(phases2[j] + phases1[i] - pi/2); // sum tone phase
	};
};

sidebands
)

// part 2: for a single bin with [newamps, newphases], we need a final amp and final phase.

// test operators
sin(pi)
sin(pi/2)
cos(pi/2)
cos(pi)
sqrt(3)
atan(1)/pi

(
~addSines = {
	arg amp1, phase1, amp2, phase2;
	var newAmp, newPhase;
	var newAmpPart1, newAmpPart2, newPhaseNum, newPhaseDenom;

	newAmpPart1 = ((amp1 * cos(phase1)) + (amp2 * sin(phase2)))**2;
	newAmpPart2 = ((amp1 * sin(phase1)) - (amp2 * cos(phase2)))**2;
	newAmp = sqrt(newAmpPart1 + newAmpPart2);

	newPhaseNum = (amp1 * sin(phase1)) - (amp2 * cos(phase2));
	newPhaseDenom = (amp1 * cos(phase1)) + (amp2 * sin(phase2)) + 0.0001;
	newPhase = atan(newPhaseNum / newPhaseDenom) + (pi/2);

	[newAmp, newPhase]
};
)

// all of these should still have amplitude 1 (adding to amplitude 0)
~addSines.value(0,0,1,1)
~addSines.value(1,1,0,0)
~addSines.value(0,1,1,1)
~addSines.value(1,1,0,1)

// should have amplitude 2
~addSines.value(1,0,1,0)
// should have amplitude 0
~addSines.value(1,0,1,pi)

// upon thinking further, the formula given must not be right...
// But, let's pretend it is, so that we can crunch a list.

// sidebands from above example, with size=2
(
var sidebands = [ [
	List[ 0, 0, 0.125, 0.125 ], // amps 1
	List[ 1.5707963267949, -1.5707963267949, 1.5707963267949, -1.411641383703 ] // phases 1
], [
	List[ 0, 0, 0, 0 ], // amps 2
	List[ 1.7299512698868, -1.4912188552489, 1.411641383703, -1.4912188552489 ] // phases 2
]];
)

// for a single sideband, crunch list to determine aggregate amplitude and phase
(
var sideband, amp, phase;

sideband = [
	List[ 0, 0, 0.125, 0.125 ], // amps 1
	List[ 1.5707963267949, -1.5707963267949, 1.5707963267949, -1.411641383703 ] // phases 1
];

amp = 0;
phase = 0;

sideband[0].size.do{
	arg i;
	var tmp;
	tmp = ~addSines.value(amp, phase, sideband[0][i], sideband[1][i]);
	amp = tmp[0];
	phase = tmp[1];
};

[amp, phase]
)

// for an array of sidebands, get lists of amplitudes, phase---like the stuff we need for pvcalc2!!
(
var sidebandsIn, ampsOut, phasesOut;

sidebandsIn = [ [
	List[ 0, 0, 0.125, 0.125 ], // amps 1
	List[ 1.5707963267949, -1.5707963267949, 1.5707963267949, -1.411641383703 ] // phases 1
], [
	List[ 0, 0, 0, 0 ], // amps 2
	List[ 1.7299512698868, -1.4912188552489, 1.411641383703, -1.4912188552489 ] // phases 2
]];

ampsOut = Array.fill(sidebandsIn.size, {0});
phasesOut = Array.fill(sidebandsIn.size, {0});

sidebandsIn.size.do{
	arg whichBin;
	var sideband, amp, phase;
	sideband = sidebandsIn[whichBin];
	amp = 0;
	phase = 0;

	sideband[0].size.do{
		arg i;
		var tmp;
		tmp = ~addSines.value(amp, phase, sideband[0][i], sideband[1][i]);
		amp = tmp[0];
		phase = tmp[1];
	};

	ampsOut[whichBin] = amp;
	phasesOut[whichBin] = phase;
};

[ampsOut, phasesOut]
)


// recap basic two-FFT manipulation
(
{
	var sound1, sound2, chain1, chain2;

	sound1 = PlayBuf.ar(1, b, loop:1);
	sound2 = SoundIn.ar(0);

	chain1 = FFT(~fftBuf1, sound1);
	chain2 = FFT(~fftBuf2, sound2);

	chain1 = chain1.pvcalc2(chain2, 1024, {
		arg mags1, phases1, mags2, phases2;
		[mags2, phases1]
	});

	IFFT(chain1);
}.play;
)

// recap sideband generation
(
// fake amplitudes and phases, for testing purposes.
var amps1, phases1, amps2, phases2, sidebands, size;

// assume that all of the above lists have length "size"
size = 2;

// lists of size size (like amps, phases in pvcalc2
amps1 = Array.fill(size, {arg i; i/size;});
phases1 = Array.fill(size, {arg i; i/(2*pi);});
amps2 = Array.fill(size, {arg i; i/size;});
phases2 = Array.fill(size, {arg i; i/(2*pi);});

// for each bin, we have [newamps, newphases], ie an array of two lists
sidebands = Array.fill(size, {[List.new(), List.new()]});

size.do{
	arg i;
	size.do{
		arg j;

		sidebands[(j-i)%size][0].add(amps1[i]*amps2[j]/2); // difference tone amplitude
		sidebands[(j-i)%size][1].add(pi/2 + phases2[j] - phases1[i]); // difference tone phase

		sidebands[(j+i)%size][0].add(amps1[i]*amps2[j]/2); // sum tone amplitude
		sidebands[(j+i)%size][1].add(phases2[j] + phases1[i] - pi/2); // sum tone phase
	};
};

sidebands
)

// now, put all of this above fanciness into two-FFT manipulation
(
{
	var sound1, sound2, chain1, chain2;

	sound1 = PlayBuf.ar(1, b, loop:1);
	sound2 = SoundIn.ar(0);

	chain1 = FFT(~fftBuf1, sound1);
	chain2 = FFT(~fftBuf2, sound2);

	chain1 = chain1.pvcalc2(chain2, 1024, {
		arg amps1, phases1, amps2, phases2;
		var size, sidebands, ampsOut, phasesOut;

		size = amps1.size;
		sidebands = Array.fill(size, {[List.new(), List.new()]});

		// make big lists of all the amplitude and phase components of each sideband, to be added soon
		size.do{
			arg i;
			size.do{
				arg j;

				sidebands[(j-i)%size][0].add(amps1[i]*amps2[j]/2); // difference tone amplitude
				sidebands[(j-i)%size][1].add(pi/2 + phases2[j] - phases1[i]); // difference tone phase

				sidebands[(j+i)%size][0].add(amps1[i]*amps2[j]/2); // sum tone amplitude
				sidebands[(j+i)%size][1].add(phases2[j] + phases1[i] - pi/2); // sum tone phase
			};
		};

		// add up components
		ampsOut = Array.fill(size, {0});
		phasesOut = Array.fill(size, {0});

		size.do{
			arg whichBin;
			var sideband, amp, phase;
			sideband = sidebands[whichBin];
			amp = 0;
			phase = 0;

			sideband[0].size.do{
				arg i;
				var tmp;
				tmp = ~addSines.value(amp, phase, sideband[0][i], sideband[1][i]);
				amp = tmp[0];
				phase = tmp[1];
			};

			ampsOut[whichBin] = amp;
			phasesOut[whichBin] = phase;
		};

		[ampsOut, phasesOut]
	});

	IFFT(chain1);
}.play;
)
/* and...apparently this crashes SuperCollider. That's a problem.
Actually, it takes a few seconds, then I get an inscrutable "ERROR: Message 'at' not understood."


Well, I'll debug another time. This has been a solid 3 hours and I'm surprised how much I got done.
*/


// as a final thing to test, what if we use shitty FFT quality.

b = Buffer.read(s, "/Volumes/snd/sflib/gamelan/angk.shortroll.af5.wav")
b.numChannels

~fftBuf1 = Buffer.alloc(s,64)
~fftBuf2 = Buffer.alloc(s,64)

(
{
	var sound1, sound2, chain1, chain2;

	sound1 = PlayBuf.ar(1, b, loop:1);
	sound2 = SoundIn.ar(0);

	chain1 = FFT(~fftBuf1, sound1);
	chain2 = FFT(~fftBuf2, sound2);

	chain1 = chain1.pvcalc2(chain2, 1024, {
		arg mags1, phases1, mags2, phases2;
		[mags2, phases1]
	});

	IFFT(chain1);
}.play;
)

(
{
	var sound1, sound2, chain1, chain2;

	sound1 = PlayBuf.ar(1, b, loop:1);
	sound2 = SoundIn.ar(0);

	chain1 = FFT(~fftBuf1, sound1);
	chain2 = FFT(~fftBuf2, sound2);

	chain1 = chain1.pvcalc2(chain2, 1024, {
		arg mags1, phases1, mags2, phases2;
		[mags1, phases1]
	});

	IFFT(chain1);
}.play;
)
