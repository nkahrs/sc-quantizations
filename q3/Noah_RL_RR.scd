// for testing:
{SoundIn.ar(0).dup}.play
s.reboot
ServerOptions.inDevices
s.options.device="Scarlett 6i6 USB"
{SinOsc.ar.dup}.play
MIDIIn.connectAll
MIDIFunc.trace

/* Quantizations 3 (Noah Kahrs)
This file contains two components:

(1) the basic framework (a single Ctrl-enter initializes everything and then you can just press spacebar
(2) SynthDefs (these need to be loaded before everything else, but only once ever)

As of 4/18, it still needs work, but this is the master file that I'll be working with.

*/

// basic framework including GUI
(

// set tempo here
~tempo = 72;

"initializing busses and io".postln;
// global variables used here: ~busses, ~clarinet, ~fftSize
// declare local variables

~busses = Array.fill(14, {Bus.audio(s)});
~fftSize = 1024;
~playGroup = Group.tail(s);
// ~busses[13] is where to send everything out. so, pick it up
// adjust final two busses here (for concert, probably 4 and 6)
~finalPlaySynth = Synth(\finalOut, [\inBus, ~busses[13], \outBus1, 0, \outBus2, 1, \multiplier, 1], s, \addToTail);

// need to put highest-bin stuff first, so that it can receive clarinet sound as internally directed in a following .play added to head
// use ~busses [0,1] for highest bin only, ringmod by highest
~thisFft = {
	Routine({
		var chain, clarSound, fftSound, env;

		clarSound = In.ar(~busses[4]); // *100 to boost signal
		chain = FFT(LocalBuf(~fftSize), clarSound);
		chain = PV_MaxMagN(chain, ~fftSize/2);

		chain = chain.pvcalc(~fftSize/2, {
			arg mags, phases;

			phases = Array.fill(phases.size, {0});

			[mags, phases]
		});

		fftSound = IFFT(chain);
		Out.ar(~busses[0], fftSound);

		// ring modulation
		fftSound = (clarSound * fftSound);
		// keep it from getting too quiet---follow clarinet envelope, not squared envelope
		env = EnvFollow.ar(clarSound);
		fftSound = fftSound / env;
		Out.ar(~busses[1], fftSound);
	}).play;
}.play;

// busses 0--3: 4 FFT fake AMs 1--4
// these will be created/destroyed on the fly

{
	~clarinet = SoundIn.ar(0) ; // *100 to boost signal

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
		sound = SoundIn.ar(0) ; // *100 to boost signal

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

				plus = (i + sineBin) % size;
				minus = (i - sineBin) % size;

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

~beat = 60 / ~tempo; // change tempo here

~cues = [
	{// 00
		00.postln;
		// silence (initial state)

	},
	{// 01
		01.postln;
		// highest bin of FFT passes through
		~current = Synth(\playBus, [\inBus, ~busses[0], \outBus1, ~busses[13], \outBus1, ~busses[13]], ~playGroup);
	},
	{// 02
		02.postln;
		// ring-mod by highest bin of FFT
		~current.set(\gate, 0);
		~current = Synth(\playBus, [\inBus, ~busses[1], \outBus1, ~busses[13]], ~playGroup);
	},
	{// 03
		03.postln;
		// ring-mod by bin 4
		~current.set(\gate, 0);
		~thisFft.free;
		~current = Synth(\fftFreezeBus, [\inBus, ~busses[8], \endDur, ~beat, \outBus1, ~busses[13]], ~playGroup);
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
		~current = Synth(\playBus, [\inBus, ~busses[8], \outBus1, ~busses[13]], ~playGroup);
	},
	{// 07
		07.postln;
		// ring-mod by bin 3
		~current.set(\gate, 0);
		~current = Synth(\fftFreezeBus, [\inBus, ~busses[7], \outBus1, ~busses[13]], ~playGroup);
	},
	{// 08
		08.postln;
		// spectral freeze on
		~current.set(\freeze, 1);
	},
	{// 09
		09.postln;
		// fade to bitcrush of input
		~current.set(\endDur, 2*~beat);
		~current.set(\gate, 0);
		~current = Synth(\bitCrushBus, [\inBus, ~busses[4], \startDur, 2, \outBus1, ~busses[13]], ~playGroup);
		// particularly here, each cue sets up the next
		~thisFft = ~fftAmFunc.value(3, ~busses[2]).play;
	},
	{// 10
		10.postln;
		// FFT am bin 3
		~current.set(\gate, 0);
		~current = Synth(\playBus, [\inBus, ~busses[2], \outBus1, ~busses[13]], ~playGroup);
		~nextFft = ~fftAmFunc.value(2, ~busses[1]).play;
	},
	{// 11
		11.postln;
		// FFT am bin 2
		~current.set(\gate, 0);
		~thisFft.free;
		~thisFft = ~nextFft;
		~current = Synth(\playBus, [\inBus, ~busses[1], \outBus1, ~busses[13]], ~playGroup);
		~nextFft = ~fftAmFunc.value(2, ~busses[1]).play;
	},
	{// 12
		12.postln;
		// FFT am bin 1
		~current.set(\gate, 0);
		~thisFft.free;
		~thisFft = ~nextFft;
		~current = Synth(\playBus, [\inBus, ~busses[1], \outBus1, ~busses[13]], ~playGroup);
	},
	{// 13
		13.postln;
		// ring-mod by bin 1
		~current.set(\endDur, ~beat);
		~current.set(\gate, 0);
		~current = Synth(\playBus, [\inBus, ~busses[5], \startDur, 1, \outBus1, ~busses[13]], ~playGroup);
		Routine({
			1.wait;
			~thisFft.free;
		}).play;
	},
	{// 14
		14.postln;
		// ring-mod by bin 2 and freeze
		~current.set(\gate, 0);
		~current = Synth(\fftFreezeBus, [\inBus, ~busses[6], \endDur, ~beat/2, \outBus1, ~busses[13]], ~playGroup);
		Routine({
			(~beat/2).wait;
			~current.set(\freeze, 1);
		}).play;
	},
	{// 15
		15.postln;
		// fade to bitcrush
		~current.set(\gate, 0);
		~current = Synth(\bitCrushBus, [\inBus, ~busses[4], \startDur, ~beat/2, \endDur, ~beat/16, \outBus1, ~busses[13]], ~playGroup);

	},
	{// 16
		16.postln;
		// bitcrushed am by bins 1,2,3,4 in rhythm
		Routine({
			// play 1, set 2
			~current.set(\gate, 0);
			~current = Synth(\bitCrushBus, [\inBus, ~busses[5], \startDur, ~beat/16, \endDur, ~beat/16, \outBus1, ~busses[13]], ~playGroup);
			~beat.wait;
			// play 2, set 3
			~current.set(\gate, 0);
			~current = Synth(\bitCrushBus, [\inBus, ~busses[6], \startDur, ~beat/16, \endDur, ~beat/16, \outBus1, ~busses[13]], ~playGroup);
			~beat.wait;
			// play 3, set 4
			~current.set(\gate, 0);
			~current = Synth(\bitCrushBus, [\inBus, ~busses[7], \startDur, ~beat/16, \endDur, ~beat/16, \outBus1, ~busses[13]], ~playGroup);
			~beat.wait; // this was missing
			// play 4
			~current.set(\gate, 0);
			~current = Synth(\bitCrushBus, [\inBus, ~busses[8], \startDur, ~beat/16, \endDur, ~beat/2, \outBus1, ~busses[13]], ~playGroup);
		}).play;
	},
	{// 17
		17.postln;
		// ring-mod by bin 4
		~current.set(\gate, 0);
		~current = Synth(\playBus, [\inBus, ~busses[8], \startDur, ~beat/2, \endDur, ~beat/2, \outBus1, ~busses[13]], ~playGroup);
	},
	{// 18
		18.postln;
		// fade to bitcrush
		~current.set(\gate, 0);
		~current = Synth(\bitCrushBus, [\inBus, ~busses[8], \startDur, ~beat/2, \endDur, ~beat/2, \outBus1, ~busses[13]], ~playGroup);
		~thisFft = ~fftAmFunc.value(4, ~busses[3]).play;
	},
	{// 19
		19.postln;
		// FFT am by bin 4
		~current.set(\gate, 0);
		~current = Synth(\playBus, [\inBus, ~busses[3], \startDur, ~beat/2, \endDur, ~beat*4.5, \outBus1, ~busses[13]], ~playGroup);

	},
	{// 20
		20.postln;
		// fade out
		Routine({
			~current.set(\gate, 0);
			4.5.wait;
		}).play;
	},
	{// 21
		21.postln;
		// ring-mod by bin 2
		~current = Synth(\playBus, [\inBus, ~busses[6], \startDur, ~beat/2, \endDur, ~beat/2, \outBus1, ~busses[13]], ~playGroup);
	},
	{// 22
		22.postln;
		// ring-mod by bin 3
		~current.set(\gate, 0);
		~current = Synth(\playBus, [\inBus, ~busses[7], \startDur, ~beat/2, \endDur, ~beat/2, \outBus1, ~busses[13]], ~playGroup);
	},
	{// 23
		23.postln;
		// ring-mod by bin 4
		~current.set(\gate, 0);
		~current = Synth(\playBus, [\inBus, ~busses[8], \startDur, ~beat/2, \endDur, ~beat/2, \outBus1, ~busses[13]], ~playGroup);
	},
	{// 24
		24.postln;
		// ring-mod by bins 5,6,7,8 (in tempo) and freese
		Routine({
			3.do{
				arg i;
				~current.set(\gate, 0);
				~current = Synth(\playBus, [\inBus, ~busses[9+i], \startDur, ~beat/16, \endDur, ~beat/16, \outBus1, ~busses[13]], ~playGroup);
				(~beat*2/3).wait;
			};
			~current.set(\gate, 0);
			~current = Synth(\fftFreezeBus, [\inBus, ~busses[12], \startDur, ~beat/16, \endDur, ~beat/16, \outBus1, ~busses[13]], ~playGroup);
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
				~current = Synth(\playBus, [\inBus, ~busses[5+i], \startDur, ~beat/16, \endDur, ~beat/16, \outBus1, ~busses[13]], ~playGroup);
				(~beat*2/3).wait;
			};
			~current.set(\gate, 0);
			~current = Synth(\fftFreezeBus, [\inBus, ~busses[8], \startDur, ~beat/16, \endDur, ~beat/16, \outBus1, ~busses[13]], ~playGroup);
			(~beat/8).wait;
			~current.set(\freeze, 1);
		}).play;
	},
	{// 26
		26.postln;
		// ring-mod by bin 4 and freeze
		~current.set(\gate, 0);
		~current = Synth(\fftFreezeBus, [\inBus, ~busses[8], \startDur, ~beat/16, \endDur, ~beat/2, \outBus1, ~busses[13]], ~playGroup);
		Routine({
			(~beat/2).wait;
			~current.set(\freeze, 1);
		}).play;
	},
	{// 27
		27.postln;
		// ring-mod by bin 3 and freeze
		~current.set(\gate, 0);
		~current = Synth(\fftFreezeBus, [\inBus, ~busses[7], \startDur, ~beat/16, \endDur, ~beat/2, \outBus1, ~busses[13]], ~playGroup);
		Routine({
			(~beat/2).wait;
			~current.set(\freeze, 1);
		}).play;
	},
	{// 28
		28.postln;
		// ring-mod by bin 2 and freeze
		~current.set(\gate, 0);
		~current = Synth(\fftFreezeBus, [\inBus, ~busses[6], \startDur, ~beat/16, \endDur, ~beat/2, \outBus1, ~busses[13]], ~playGroup);
		Routine({
			(~beat/2).wait;
			~current.set(\freeze, 1);
		}).play;
	},
	{// 29
		29.postln;
		// ring-mod by bin 1 and freeze
		~current.set(\gate, 0);
		~current = Synth(\fftFreezeBus, [\inBus, ~busses[5], \startDur, ~beat/16, \endDur, ~beat/4, \outBus1, ~busses[13]], ~playGroup);
		Routine({
			(~beat/2).wait;
			~current.set(\freeze, 1);
			~thisFft = ~fftAmFunc.value(1, ~busses[0]).play;
		}).play;
	},
	{// 30
		30.postln;
		// FFT am by bin 1
		~current.set(\gate, 0);
		~current = Synth(\playBus, [\inBus, ~busses[0], \startDur, ~beat/4, \endDur, ~beat*4, \outBus1, ~busses[13]], ~playGroup);
	},
	{// 31
		31.postln;
		// end
		~current.set(\gate, 0);
		~thisFft.free;
		"over".postln;
	}
];

"creating gui".postln;
// create window
w = Window.new("Quantizations 3", Rect(0, 0, 800, 400));
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

m = Slider(w, Rect(650, 50, 100, 300));
m.action = {arg foo;
	var newMult;

	newMult = foo.value.linlin(0,1,1,150);

	~finalPlaySynth.set(\multiplier, newMult);
	// newMult.postln;
};
MIDIFunc.cc({arg i; {m.value_(i/127); m.action.value(m)}.defer } );

w.front;
)


// SynthDefs here
// out busses are currently 0 and 1 by default; change them here and reload synthdefs if needed
(
var halfbeat;
~tempo = 72;
~beat = 60 / ~tempo;
halfbeat = ~beat/2;

// just play bus contents
SynthDef(\playBus, {
	arg inBus, outBus1 = 0, outBus2 = 1, startDur = halfbeat, endDur = halfbeat, gate = 1;

	var sound;
	sound = In.ar(inBus) * EnvGen.kr(Env.asr(startDur, 1, endDur, 0), gate, doneAction:2);

	Out.ar(outBus1, sound);
	// Out.ar(outBus2, sound);
}).load(s);

// play bus contents, but bitcrshed
SynthDef(\bitCrushBus, {
	arg inBus, outBus1 = 0, outBus2 = 1, startDur = halfbeat, endDur = halfbeat, gate = 1;

	var sound;
	sound = Decimator.ar(In.ar(inBus), bits:11);
	sound = sound * EnvFollow.ar(In.ar(inBus)) / EnvFollow.ar(sound);
	sound = sound * EnvGen.kr(Env.asr(startDur, 1, endDur, 0), gate, doneAction:2);

	Out.ar(outBus1, sound);
	// Out.ar(outBus2, sound);
}).load(s);

SynthDef(\fftFreezeBus, {
	arg inBus, outBus1 = 0, outBus2 = 1, startDur = halfbeat, endDur = halfbeat, gate = 1, freeze = 0;

	var sound, chain;

	sound = In.ar(inBus);
	chain = FFT(LocalBuf(1024), sound);
	chain = PV_Freeze(chain, freeze);
	sound = IFFT(chain);
	sound = sound * EnvGen.kr(Env.asr(startDur, 1, endDur, 0), gate, doneAction:2);

	Out.ar(outBus1, sound);
	// Out.ar(outBus2, sound);
}).load(s);

SynthDef(\finalOut, {
	arg inBus, outBus1, outBus2, multiplier;

	var sound;
	sound = In.ar(inBus);
	sound = sound * multiplier;
	Out.ar(outBus1, sound);
	Out.ar(outBus2, sound);
}).load(s);
)