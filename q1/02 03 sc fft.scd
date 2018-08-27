

// test mic in and sound out
{SoundIn.ar(0)}.play
// this is used often later, so run it now
~fftBuf = Buffer.alloc(s,512)

// test of signal chain and magnitude freeze
(
{
	var in, chain, fftOut;

	in = SoundIn.ar(0);

	chain = FFT(~fftBuf, in);
	chain = PV_MagFreeze(chain, MouseX.kr(-1,1));

	IFFT(~fftBuf)
}.play;
)


// stuff from UnpackFFT help file, modified to In.ar/~fftBuf setup above
// This one just drags out various the values and posts them - a little bit pointless!

(
{
    var sig, chain, stream, windowStarts, fftSize;
    fftSize = 1024;

	sig = SoundIn.ar(0);
    chain = FFT(~fftBuf, sig);

    // a window start is indicated by a signal leaving the -1 bottom line
    windowStarts = chain > -1;

    // Using the frombin & tobin args makes it much more efficient, limiting analysis to the bins of interest
    stream = UnpackFFT(chain, fftSize, frombin: 10, tobin: 10);

    // Demand some data from the unpacker.
    // NOTE: At present, Demand.kr is unable to handle more than 32 inputs,
    // so using frombin & tobin to limit the number of bins is compulsory.

    Demand.kr(windowStarts, 0, stream).collect { |anunp, index|
        var label = if(index.even) { "Magnitude" } { "Phase" };
        label = label + (index / 2).floor;
        anunp.poll(windowStarts, label)
    };

    sig
}.play
)

// simple frequency-domain manipulation, square-rooting the magnitudes AND phases.
(
x = {
    var sig, chain, magsphases, b;
	b = ~fftBuf;
	sig = SoundIn.ar(0);
    chain = FFT(~fftBuf, sig);
    magsphases = UnpackFFT(chain, b.numFrames);
    magsphases = magsphases.collect(_.sqrt);
    chain = PackFFT(chain, b.numFrames, magsphases);
    IFFT(chain) * 0.1
}.play
)


// let's try to get to basic resynthesis done manually once a second. Can I do this by modifying the first of the above helpfile examples?

// this resynthesizes once per window start, but only from 16 bins. I can't get Impulse.kr to be a valid (non error-raising) trigger, for whatever reason
(
{
    var sig, chain, stream, windowStarts, fftSize, out, tmp;
    fftSize = 1024;

	sig = SoundIn.ar(0);
    chain = FFT(~fftBuf, sig);
	out = 0;

    // a window start is indicated by a signal leaving the -1 bottom line
	windowStarts = chain > -1;

    // Using the frombin & tobin args makes it much more efficient, limiting analysis to the bins of interest
    stream = UnpackFFT(chain, fftSize, frombin: 50, tobin: 65);

    // Demand some data from the unpacker.
    // NOTE: At present, Demand.kr is unable to handle more than 32 inputs,
    // so using frombin & tobin to limit the number of bins is compulsory.

    Demand.kr(windowStarts, 0, stream).collect { |anunp, index|
        //var label = if(index.even) { "Magnitude" } { "Phase" };
        //label = label + (index / 2).floor;
        //anunp.poll(windowStarts, label)
		index = index + 50;
		if( index.even,
			{tmp = anunp;},
			{out = out + ((1/16)*SinOsc.ar((index/2).floor*22500/1024, anunp, tmp));}
		);
    };

    out
}.play
)

// let's try to do all 1024 bins

// first, a basic synthdef
(SynthDef(\basicSine, {
	arg freq, mag, phase, out;
	Out.ar(out, SinOsc.ar(freq, phase, mag));
}).load(s)
)

a=Synth(\basicSine, [\freq, 440, \mag, 0.5, \phase, 0, \out, 0])
a.set(\mag, 0.1)

// ~fftBuf as usual
~fftBuf.numFrames

// testing other useful things
s.sampleRate
Array.fill(32, {arg i; i})[30]
22050*10/1024


// can I use Unpack1FFT with demand well enough? No, I'm giving up.

// I can create FFT-numbins-many synths with the following. I get an incredibly cryptic error when adding in an UnpackFFT...
(
{
	var numBins, synths, fftBuf, nyquist;
	var sig, chain, stream, windowStarts, fftSize, out, tmp;

	fftBuf = ~fftBuf;
	numBins = fftBuf.numFrames;
	nyquist = s.sampleRate/2;


	// first, initialize all the synths (one per bin)
	~synths = Array.fill(numBins, {arg i; Synth(\basicSine, [
		\freq, nyquist*(i+0.5)/numBins,
		\mag, 0, \phase, 0, \out, 0
	])});

	sig = SoundIn.ar(0);
	chain = FFT(~fftBuf, sig);
	windowStarts = chain > -1;


}.play
)

// let's try to put the UnpackFFT stuff in a separate "program." This seems like it could kinda work, but it takes a really long time for eacho f these synths to initialize.

(
var fftSize = ~fftBuf.numFrames;
fftSize.do{arg i;
	{
    var sig, chain, stream, windowStarts,tmp;

	sig = SoundIn.ar(0);
    chain = FFT(~fftBuf, sig);

    // a window start is indicated by a signal leaving the -1 bottom line
	windowStarts = chain > -1;

    // Using the frombin & tobin args makes it much more efficient, limiting analysis to the bins of interest
	fftSize.do({
		stream = UnpackFFT(chain, fftSize, frombin: i, tobin: i);

		// Demand some data from the unpacker.
		// NOTE: At present, Demand.kr is unable to handle more than 32 inputs,
		// so using frombin & tobin to limit the number of bins is compulsory.

		Demand.kr(windowStarts, 0, stream).collect { |anunp, index|
			//var label = if(index.even) { "Magnitude" } { "Phase" };
			//label = label + (index / 2).floor;
			//anunp.poll(windowStarts, label)
			if( index.even,
				{tmp = anunp;},
				{~synths}
			);
		};
	});
}.play;
};
"done".postln;
)


// upon reading documentation a bit more, I might want to do something simpler. Maybe .pvcalc2?


// Let's try a simple example of that. From the help file, but with mic input.
(
{
    var in, chain, v;
	in = SoundIn.ar(0);
    chain = FFT(LocalBuf(1024), in);

    chain = chain.pvcalc(1024, {|mags, phases|
//////// Try uncommenting each of these lines in turn and re-running the synth:
		//[mags, phases]; // identity
        //[mags * {1.5.rand}.dup(mags.size), phases + {pi.rand}.dup(phases.size)]; // Arbitrary filter, arbitrary phase shift
        [mags.reverse, phases.reverse]; // Upside-down!
        //[mags.differentiate, phases.differentiate]; // Differentiate along frequency axis
        //[mags[30..] ++ mags[..30], phases[30..] ++ phases[..30]]; // ".rotate" doesn't work directly, but this is equivalent
    }, frombin: 0, tobin: 250, zeroothers: 0);

    0.5 * IFFT(chain)
}.play
)