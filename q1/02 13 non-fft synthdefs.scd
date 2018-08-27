(
SynthDef(\bitCrush, {
	arg inBus, outBus, ratio;
	// assumes that "ratio" is relative to 24-bit
	var sound, bits;
	bits = 24/ratio;
	sound = In.ar(inBus);
	sound = Decimator.ar(sound, 44100, bits);
	Out.ar(outBus, sound);
}).load(s);

SynthDef(\bitCrushError, {
	arg inBus, outBus, ratio;
	// assumes that "ratio" is relative to 24-bit
	var sound, worseSound, error, bits;
	bits = 24/ratio;
	sound = In.ar(inBus);
	worseSound = Decimator.ar(sound, 44100, bits);
	error = sound - worseSound;
	Out.ar(outBus, error);
}).load(s);

SynthDef(\downSample, {
	arg inBus, outBus, ratio;
	// assumes ratio relative to 44.1kHz
	var sound, fs;
	fs = 44100/ratio;
	sound = In.ar(inBus);
	sound = Decimator.ar(sound, fs);
	Out.ar(outBus, sound);
}).load(s);

SynthDef(\downSampleError, {
	arg inBus, outBus, ratio;
	// assumes ratio relative to 44.1kHz
	var sound, worseSound, error, fs;
	fs = 44100/ratio;
	sound = In.ar(inBus);
	worseSound = Decimator.ar(sound, fs);
	error = sound - worseSound;
	Out.ar(outBus, error);
}).load(s);

SynthDef(\ampMod, {
	arg inBus1, inBus2, outBus;
	var sound1, sound2;
	sound1 = In.ar(inBus1);
	sound2 = In.ar(inBus2);
	Out.ar(outBus, (sound1 * sound2));
}).load(s);

SynthDef(\ampModSine, {
	arg inBus, freq, outBus;
	var sound;
	sound = SinOsc.ar(freq);
	sound = sound * In.ar(inBus);
	Out.ar(outBus, sound);
}).load(s);

SynthDef(\moveBus, {
	arg inBus, outBus;
	var sound;
	sound = In.ar(inBus);
	Out.ar(outBus, sound);
}).load(s);
)

~bus

(
Synth(\moveBus, [\inBus, ~bus, \outBus, 0]);
Synth(\moveBus, [\inBus, ~bus, \outBus, 1])
)

a = Synth(\bitCrush, [\inBus, 2, \outBus, ~bus, \ratio, 10])
a = Synth(\ampModSine, [\inBus, 2, \freq, 440, \outBus, ~bus])
a = Synth(\downSampleError, [\inBus, 2, \outBus, ~bus, \ratio, 10])
a.set(\freq, 1000)
a.set(\ratio, 100)
a.free


