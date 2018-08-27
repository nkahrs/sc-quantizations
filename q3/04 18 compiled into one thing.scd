/* Quantizations 3 (Noah Kahrs)
This file contains two components:

(1) the basic framework (a single Ctrl-enter initializes everything and then you can just press spacebar
(2) SynthDefs (these need to be loaded before everything else, but only once ever)

As of 4/18, it still needs work, but this is the master file that I'll be working with.

*/

// basic framework including GUI
(
"initializing busses and io".postln;
// global variables used here: ~busses, ~clarinet, ~fftSize
// declare local variables

~busses = Array.fill(13, {Bus.audio(s)});
~fftSize = 1024;

// busses 0--3: 4 FFT fake AMs 1--4
// these will be created/destroyed on the fly

{
	~clarinet = SoundIn.ar(0);

	// bus 4: pass-through
	Out.ar(~busses[4], ~clarinet);

	// busses 5--8: actual AM 1--4
	// busses 9--12: actual AM 5--8
	8.do{
		arg i;
		var sineFreq, sound;

		sineFreq = (i+1) * s.sampleRate / ~fftSize;

		sound = ~clarinet * SinOsc.ar(sineFreq);
		Out.ar(~busses[i+5], sound);

	};
}.play;

"initializing FFT AM generator".postln;
// define a general function for the FFT AM stuff
// syntax to use it: ~fftAmFunc.value(sineBin, outBus).play;
~fftAmFunc = {arg sineBin, outBus;

	{
		var sound, chain, numBins, sineFreq, sine;

		numBins = ~fftSize;
		sound = SoundIn.ar(0);

		chain = FFT(LocalBuf(~fftSize), sound);

		chain = chain.pvcalc(numBins, {
			arg magsIn, phasesIn;
			var magsOut, phasesOut, size;

			size = magsIn.size;

			magsOut = Array.fill(size, 0);
			phasesOut = Array.fill(size, 0);

			size.do{
				arg i;
				// for each bin, calculate what it will be the sum and difference tone of, find the amps and phases for those, and add appropriately
				var plus, minus; // indices to look in
				var aP, aM, pP, pM; // values to store: amp/phase Plus/Minus
				var aOutLeft, aOutRight, pOutNum, pOutDenom; // subcalculations for outputs
				var aOut, pOut; // output values

				plus = (i + ~sineBin) % size;
				minus = (i - ~sineBin) % size;

				aP = magsIn[plus];
				aM = magsIn[minus];
				pP = phasesIn[plus];
				pM = phasesIn[minus];

				aOutLeft = ((aM * sin(pM)) - (aP * sin(pP)))**2;
				aOutRight = ((aP * cos(pP)) - (aM * cos(pM)))**2;
				aOut = sqrt(aOutLeft + aOutRight);
				magsOut[i] = aOut;

				pOutNum = (aP * cos(pP)) - (aM * cos(pM));
				pOutDenom = (aM * sin(pM)) - (aP * sin(pP));
				pOut = atan(pOutNum / pOutDenom);
				phasesOut[i] = pOut;
			};

			[magsOut, phasesOut]
		});

		sound = IFFT(chain);//.dup;

		Out.ar(outBus, sound);
	};
};

"defining cues".postln;

~beat = 60 / 72; // change tempo here

~cues = [
	{// 00
		00.postln;
		// silence
	},
	{// 01
		01.postln;
		// highest bin of FFT passes through
	},
	{// 02
		02.postln;
		// ring-mod by highest bin of FFT
	},
	{// 03
		03.postln;
		// ring-mod by bin 4
		~current = Synth(\fftFreezeBus, [\inBus, ~busses[8]], s, \addToTail);
	},
	{// 04
		04.postln;
		// spectral freeze on
		~current.set(\freeze, 1);
	},
	{// 05
		05.postln;
		// silent
		~current.set(\gate, 0);
	},
	{// 06
		06.postln;
		// ring-mod by bin 4
		~current = Synth(\playBus, [\inBus, ~busses[8]], s, \addToTail);
	},
	{// 07
		07.postln;
		// ring-mod by bin 3
		~current.set(\gate, 0);
		~current = Synth(\fftFreezeBus, [\inBus, ~busses[7]], s, \addToTail);
	},
	{// 08
		08.postln;
		// spectral freeze on
		~current.set(\freeze, 1);
	},
	{// 09
		09.postln;
		// fade to bitcrush of input
		~current.set(\endDur, 2);
		~current.set(\gate, 0);
		~current = Synth(\bitCrushBus, [\inBus, ~busses[4], \startDur, 2], s, \addToTail);
		// particularly here, each cue sets up the next
		~thisFft = ~fftAmFunc.value(3, 2).play;
	},
	{// 10
		10.postln;
		// FFT am bin 3
		~current.set(\gate, 0);
		~current = Synth(\playBus, [\inBus, ~busses[2]], s, \addToTail);
		~nextFft = ~fftAmFunc.value(2, ~busses[1]).play;
	},
	{// 11
		11.postln;
		// FFT am bin 2
		~current.set(\gate, 0);
		~thisFft.free;
		~thisFft = ~nextFft;
		~current = Synth(\playBus, [\inBus, ~busses[1]], s, \addToTail);
		~nextFft = ~fftAmFunc.value(2, ~busses[1]).play;
	},
	{// 12
		12.postln;
		// FFT am bin 1
		~current.set(\gate, 0);
		~thisFft.free;
		~thisFft = ~nextFft;
		~current = Synth(\playBus, [\inBus, ~busses[1]], s, \addToTail);
	},
	{// 13
		13.postln;
		// ring-mod by bin 1
		~current.set(\endDur, 1);
		~current.set(\gate, 0);
		~current = Synth(\playBus, [\inBus, ~busses[5], \startDur, 1], s, \addToTail);
		Routine({
			1.wait;
			~thisFft.free;
		}).play;
	},
	{// 14
		14.postln;
		// ring-mod by bin 2 and freeze
		~current = Synth(\fftFreezeBus, [\inBus, ~busses[6], \endDur, ~beat/2], s, \addToTail);
		Routine({
			(~beat/2).wait;
			~current.set(\freeze, 1);
		}).play;
	},
	{// 15
		15.postln;
		// fade to bitcrush
		~current.set(\gate, 0);
		~current = Synth(\bitCrushBus, [\inBus, ~busses[4], \startDur, ~beat/2, \endDur, ~beat/16], s, \addToTail);

		// initialize am bin 1
		~nextFft = ~fftAmFunc.value(1, ~busses[0]).play;
	},
	{// 16
		16.postln;
		// FFT am by bins 1,2,3,4 in rhythm
		Routine({
			// play 1, set 2
			~current.set(\gate, 0);
			~current = Synth(\playBus, [\inBus, ~busses[0], \startDur, ~beat/16, \endDur, ~beat/16], s, \addToTail);
			~thisFft = ~nextFft;
			~nextFft = ~fftAmFunc.value(2, ~busses[1]).play;
			~beat.wait;
			// play 2, set 3
			~thisFft.free;
			~thisFft = ~nextFft;
			~current.set(\gate, 0);
			~current = Synth(\playBus, [\inBus, ~busses[1], \startDur, ~beat/16, \endDur, ~beat/16], s, \addToTail);
			~nextFft = ~fftAmFunc.value(3, ~busses[2]).play;
			~beat.wait;
			// play 3, set 4
			~thisFft.free;
			~thisFft = ~nextFft;
			~current.set(\gate, 0);
			~current = Synth(\playBus, [\inBus, ~busses[2], \startDur, ~beat/16, \endDur, ~beat/16], s, \addToTail);
			~nextFft = ~fftAmFunc.value(4, ~busses[3]).play;
			~beat.wait;
			// play 4
			~thisFft.free;
			~thisFft = ~nextFft;
			~current.set(\gate, 0);
			~current = Synth(\playBus, [\inBus, ~busses[3], \startDur, ~beat/16, \endDur, ~beat/16], s, \addToTail);
		}).play;
	},
	{// 17
		17.postln;
		// ring-mod by bin 4
		~thisFft.free;
		~current.set(\gate, 0);
		~current = Synth(\playBus, [\inBus, ~busses[8], \startDur, ~beat/16, \endDur, ~beat/2], s, \addToTail);
	},
	{// 18
		18.postln;
		// fade to bitcrush
		~current.set(\gate, 0);
		~current = Synth(\bitCrushBus, [\inBus, ~busses[8], \startDur, ~beat/2, \endDur, ~beat/2], s, \addToTail);
		~thisFft = ~fftAmFunc.value(4, ~busses[3]).play;
	},
	{// 19
		19.postln;
		// FFT am by bin 4
		~current.set(\gate, 0);
		~current = Synth(\playBus, [\inBus, ~busses[3], \startDur, ~beat/2, \endDur, ~beat*4.5], s, \addToTail);

	},
	{// 20
		20.postln;
		// fade out
		Routine({
			~current.set(\gate, 0);
			4.5.wait;
			~thisFft.free;
		});
	},
	{// 21
		21.postln;
		// ring-mod by bin 2
		~current = Synth(\playBus, [\inBus, ~busses[6], \startDur, ~beat/16, \endDur, ~beat/16], s, \addToTail);
	},
	{// 22
		22.postln;
		// ring-mod by bin 3
		~current.set(\gate, 0);
		~current = Synth(\playBus, [\inBus, ~busses[7], \startDur, ~beat/16, \endDur, ~beat/16], s, \addToTail);
	},
	{// 23
		23.postln;
		// ring-mod by bin 4
		~current.set(\gate, 0);
		~current = Synth(\playBus, [\inBus, ~busses[8], \startDur, ~beat/16, \endDur, ~beat/16], s, \addToTail);
	},
	{// 24
		24.postln;
		// ring-mod by bins 5,6,7,8 (in tempo) and freese
		Routine({
			3.do{
				arg i;
				~current.set(\gate, 0);
				~current = Synth(\playBus, [\inBus, ~busses[9+i], \startDur, ~beat/16, \endDur, ~beat/16], s, \addToTail);
				(~beat*2/3).wait;
			};
			~current.set(\gate, 0);
			~current = Synth(\fftFreezeBus, [\inBus, ~busses[12], \startDur, ~beat/16, \endDur, ~beat/16], s, \addToTail);
			(~beat/8).wait;
			~current.set(\freeze, 1);
		}).play;
	},
	{// 25
		25.postln;
		// ring-mod by bins 1,2,3,4 (in tempo) and freeze
		~current.set(\gate, 0);
		Routine({
			3.do{
				arg i;
				~current.set(\gate, 0);
				~current = Synth(\playBus, [\inBus, ~busses[5+i], \startDur, ~beat/16, \endDur, ~beat/16], s, \addToTail);
				(~beat*2/3).wait;
			};
			~current.set(\gate, 0);
			~current = Synth(\fftFreezeBus, [\inBus, ~busses[8], \startDur, ~beat/16, \endDur, ~beat/16], s, \addToTail);
			(~beat/8).wait;
			~current.set(\freeze, 1);
		}).play;
	},
	{// 26
		26.postln;
		// ring-mod by bin 4 and freeze
		~current.set(\gate, 0);
		~current = Synth(\fftFreezeBus, [\inBus, ~busses[8], \startDur, ~beat/16, \endDur, ~beat/16], s, \addToTail);
	},
	{// 27
		27.postln;
		// ring-mod by bin 3 and freeze
		~current.set(\gate, 0);
		~current = Synth(\fftFreezeBus, [\inBus, ~busses[7], \startDur, ~beat/16, \endDur, ~beat/16], s, \addToTail);
	},
	{// 28
		28.postln;
		// ring-mod by bin 2 and freeze
		~current.set(\gate, 0);
		~current = Synth(\fftFreezeBus, [\inBus, ~busses[6], \startDur, ~beat/16, \endDur, ~beat/16], s, \addToTail);
	},
	{// 29
		29.postln;
		// ring-mod by bin 1 and freeze
		~current.set(\gate, 0);
		~current = Synth(\fftFreezeBus, [\inBus, ~busses[5], \startDur, ~beat/16, \endDur, ~beat/16], s, \addToTail);
		~thisFft = ~fftAmFunc.value(1, ~busses[0]).play;
	},
	{// 30
		30.postln;
		// FFT am by bin 1
		~current.set(\gate, 0);
		~current = Synth(\playBus, [\inBus, ~busses[0], \startDur, ~beat/4, \endDur, ~beat], s, \addToTail);
	},
	{// 31
		31.postln;
		// end
		~current.set(\gate, 0);
		"over".postln;
	}
];

"creating gui".postln;
// create window
w = Window.new("Quantizations 3", Rect(0, 0, 600, 400));
// create number box
n = NumberBox(w, Rect(50, 50, 500, 300));
n.font = Font("Arial", 250);
// action: just post the current number (this might change)
n.action = {arg foo; ~cues[foo.value].value;}; //foo.value.postln;};
// set initial value to zero
n.value_(0);
// when pressing spacebar (and only spacebar!), increment
n.keyDownAction_({arg i,j; if (j.asString==" ") {n.value_(n.value + 1); n.action.value(n)}});
// push window to the front.
w.front;
)


// SynthDefs here

(
// just play bus contents
SynthDef(\playBus, {
	arg inBus, outBus1 = 0, outBus2 = 1, startDur = 0.01, endDur = 0.01, gate = 1;

	var sound;
	sound = In.ar(inBus) * EnvGen.kr(Env.asr(startDur, 1, endDur, 0), gate, doneAction:2);

	Out.ar(outBus1, sound);
	Out.ar(outBus2, sound);
}).load(s);

// play bus contents, but bitcrshed
SynthDef(\bitCrushBus, {
	arg inBus, outBus1 = 0, outBus2 = 1, startDur = 0.01, endDur = 0.01, gate = 1;

	var sound;
	sound = Decimator.ar(In.ar(inBus), bits:8);
	sound = sound * EnvGen.kr(Env.asr(startDur, 1, endDur, 0), gate, doneAction:2);

	Out.ar(outBus1, sound);
	Out.ar(outBus2, sound);
}).load(s);

SynthDef(\fftFreezeBus, {
	arg inBus, outBus1 = 0, outBus2 = 1, startDur = 0.01, endDur = 0.01, gate = 1, freeze = 0;

	var sound, chain;

	sound = In.ar(inBus);
	chain = FFT(LocalBuf(1024), sound);
	chain = PV_Freeze(chain, freeze);
	sound = IFFT(chain);
	sound = sound * EnvGen.kr(Env.asr(startDur, 1, endDur, 0), gate, doneAction:2);

	Out.ar(outBus1, sound);
	Out.ar(outBus2, sound);
}).load(s);

// still need highest bin, ring-mod by highest bin
)