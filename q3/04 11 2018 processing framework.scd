// main initialization
(
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

nil
)

z = Synth(\playBus, [\inBus, ~busses[12]], addAction:\addToTail)
z.free

~busses

(
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
)

x = ~fftAmFunc.value(4, 0).play
x.free

// 4/12: all of this works
// still todo:
// final treatment (need Synthdef) with spectral freeze and send-out
// full list of cues...

// highest bin of FFT
// ring-mod by highest bin can be done later. Send just-highest, ring-mod-to-highest, to two different busses (need to allocate those, or reuse 0--3), pick them up later.


// 4/15: synthdefs
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

// tests of synthdef
{Out.ar(5,SinOsc.ar(Line.kr(200, 1600, 10)))}.play
a.set(\gate, 0)
a = Synth(\playBus, [\inBus, 5], s, \addToTail)
a = Synth(\bitCrushBus, [\inBus, 5], s, \addToTail)
a = Synth(\fftFreezeBus, [\inBus, 3], s, \addToTail)
a.set(\freeze, 1)
a.set(\freeze, 0)

a = {SinOsc.ar}.play
a.free