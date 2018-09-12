// CMP 412, Fall 2018, Composition Project Common Material
// Noah Kahrs, September 2018
// basic synthdefs: FM, with option for filter
// further projects may introduce new synthdefs, or I might stick with this
(
SynthDef(\fm, {
	// cf = carrier freq, mc = modulator/carrier, ic = index/carrier
	arg cf, mc, ic, dur, amp;
	var modulatorfreq, carrier, modulator, index, sound, env;

	modulatorfreq = mc*cf;
	index = ic*cf;
	modulator = index * SinOsc.ar(modulatorfreq);
	carrier = amp * SinOsc.ar(cf + modulator);
	env = EnvGen.kr(Env([0, 1, 0], [0.1, dur-0.1]), doneAction:2);
	sound = carrier * env;
	sound = sound.dup;
	Out.ar(0, sound);
}).load(s);

SynthDef(\fmfilter, {
	// cf = carrier freq, mc = modulator/carrier, ic = index/carrier
	// ff = filter freq, fq = filter q
	arg cf, mc, ic, dur, amp, ff, fq;
	var modulatorfreq, carrier, modulator, index, sound, env;

	modulatorfreq = mc*cf;
	index = ic*cf;
	modulator = index * SinOsc.ar(modulatorfreq);
	carrier = amp * SinOsc.ar(cf + modulator);
	env = EnvGen.kr(Env([0, 1, 0], [0.1, dur-0.1]), doneAction:2);
	sound = BPF.ar(carrier, ff, 1/fq);
	sound = sound * env;
	sound = sound.dup;
	Out.ar(0, sound);
}).load(s);
)

// tests
Synth(\fm, [\cf, 440, \mc, 1.01, \ic, 0.5, \dur, 2, \amp, 0.5])
Synth(\fmfilter, [\cf, 440, \mc, 1.05, \ic, 5, \dur, 2, \amp, 5, \ff, 2*660, \fq, 50])
