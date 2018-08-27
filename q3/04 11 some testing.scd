a = Bus.audio(s);

(
SynthDef(\basicSine, {
	arg outBus;
	var sound;
	sound = SinOsc.ar();
	Out.ar(outBus, sound);
}).load(s)
)

Synth(\basicSine, [\outBus, a])

(
SynthDef(\playBus, {
	arg inBus;
	Out.ar(0,In.ar(inBus));
}).load(s)
)

Synth(\playBus, [\inBus, a], addAction:\addToHead)

// but it's hard to do the FFT stuff as a synthdef, so...

{Out.ar(0,In.ar(a))}.play
{Out.ar(a, SinOsc.ar())}.play
// play adds to head, so we have to go from the bottom up!


// or, if only the FFT stuff is isolated like that:
{Out.ar(~busses[0], SinOsc.ar())}.play
z = Synth(\playBus, [\inBus, a], addAction:\addToTail)
// we can add synths to the tail whenever we want, as long as the original ones keep playing where they are


(
SynthDef(\sineLine, {
	arg startFreq, endFreq, time;
	var freq, sine;
	freq = Line.ar(startFreq, endFreq, time);
	sine = SinOsc.ar(freq);
	Out.ar(0, sine);
}).load(s)
)

Synth(\sineLine, [\startFreq, 440, \endFreq, 880, \time, 4])


// decimator: crossfade in or increase bitcrushedness