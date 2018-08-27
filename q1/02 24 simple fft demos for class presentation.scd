// more basic FFT demos
b = Buffer.read(s, "/Volumes/snd/sflib/gamelan/angk.shortroll.af5.wav")
b.numChannels

~fftBuf = Buffer.alloc(s,1024)

// let's try basic FFT manipulation that changes nothing
(
{
	var sound, chain;
	sound = SoundIn.ar(0);
	chain = FFT(~fftBuf, sound);
	chain = chain.pvcalc(1024, {
		arg mags, phases;
		[mags, phases]
	}, 0, 1023, 0);
	IFFT(chain);
}.play;
)

// set all phases to zero
(
{
	var sound, chain;
	sound = SoundIn.ar(0);
	chain = FFT(~fftBuf, sound);
	chain = chain.pvcalc(1024, {
		arg mags, phases;
		phases.size.do{
			arg i;
			phases[i] = 0;
		};
		[mags, phases]
	}, 0, 1023, 0);
	IFFT(chain);
}.play;
)

// reverse magnitudes, keep phases as they are
(
{
	var sound, chain;
	sound = SoundIn.ar(0);
	chain = FFT(~fftBuf, sound);
	chain = chain.pvcalc(1024, {
		arg mags, phases;
		mags = mags.reverse;
		[mags, phases]
	}, 0, 1023, 0);
	IFFT(chain);
}.play;
)

// reverse phases, leave magnitudes as they are
(
{
	var sound, chain;
	sound = SoundIn.ar(0);
	chain = FFT(~fftBuf, sound);
	chain = chain.pvcalc(1024, {
		arg mags, phases;
		phases = phases.reverse;
		[mags, phases]
	}, 0, 1023, 0);
	IFFT(chain);
}.play;
)

// handwrite magnitude at bin "binNum" (channel 1), straight-up SinOsc in channel 2.
// options: vary phase and amplitude based on input (un)comment lines to do so
(
{
	var sound, chain, binNum;
	binNum = 10;
	// get from bus?
	sound = SoundIn.ar(0);
	chain = FFT(~fftBuf, sound);
	chain = chain.pvcalc(1024, {
		arg mags, phases;
		var finalMag = 256;
		// uncomment to vary magnitudes according to input
		finalMag = mags.sum;
		mags = {arg i; i*0}.value(mags); // all zeros
		mags[binNum] = finalMag;
		// uncomment to set all phases to zero
		//phases = {arg i; i*0}.value(phases);
		[mags, phases]
	}, 0, 1023, 0);

	[
		IFFT(chain),
		SinOsc.ar(s.sampleRate*binNum/1024)
	]
}.play;
)
