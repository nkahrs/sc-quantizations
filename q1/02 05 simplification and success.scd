// from last time, basic shittiness

// as a final thing to test, what if we use shitty FFT quality.

(
b = Buffer.read(s, "/Volumes/snd/Users/nkahrs/3 Spring 2018/sc fft stuff/shortGangsa.wav").postln;
b.numChannels.postln;

~fftSize = 64;
~fftBuf1 = Buffer.alloc(s,~fftSize);
~fftBuf2 = Buffer.alloc(s,~fftSize);
)

// basic FFT tests. This takes mags of mic, phases of recording
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

// just should spit out recording
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

// not FFT, but for comparison: AM Synthesis
(
{
	var carrier, modulator;
	carrier = PlayBuf.ar(1, b, loop:1);
	modulator = SoundIn.ar(0);

	carrier * modulator;
}.play;
)


// now, put all of this above fanciness into two-FFT manipulation
// nb FFT size 1024 just crashes it, FFT size 64 ok
(
{
	var sound1, sound2, chain1, chain2;

	sound1 = PlayBuf.ar(1, b, loop:1);
	sound2 = SoundIn.ar(0);

	chain1 = FFT(~fftBuf1, sound1);
	chain2 = FFT(~fftBuf2, sound2);

	chain1 = chain1.pvcalc2(chain2, ~fftSize, {
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
			var sideband, amp, phase, ampSum, phaseWeightSum;
			sideband = sidebands[whichBin];
			amp = 0;
			ampSum = 0.00001; // prevents division-by-zero error later on, in turn preventing periodic clicking.
			phaseWeightSum = 0;
			phase = 0;

			sideband[0].size.do{
				arg i;
				var phasenum, phasedenom;
				amp = max(amp, sideband[0][i]);

				// commented stuff: from just weighted average of phases
				// below it is more correct: weigh numerators by sines, denoms by cosines, arctan the whole thing
				// can we do phase precisely or is it too slow? too slow.
				// let's try a weighted average of phases. This mostly works, surprisingly...
				ampSum = ampSum + sideband[0][i];
				phaseWeightSum = phaseWeightSum + (sideband[0][i] * sideband[1][i]);

				// ampSum = ampSum + (sideband[0][i] * cos(sideband[1][i]));
				// phaseWeightSum = phaseWeightSum + (sideband[0][i] * sin(sideband[1][i]));

			};

			ampsOut[whichBin] = amp;
			phase = phaseWeightSum / ampSum;
			// phase = atan(phaseWeightSum / ampSum);
			phasesOut[whichBin] = phase;
		};

		[ampsOut, phasesOut]
	});

	IFFT(chain1);
}.play;
)

/*
Now that I have this working, I should write up my intention and what I've been trying to do.

The massive FFT code block is an intentionally degraded simulation of ring modulation. I break apart the FFT stuff, calculate the amplitudes and phases I need to add up for each sideband, and then kinda sorta add them. The best balance I could find between accurate addition of sinusoids of the same frequency and something that can actually be computed decently in real-time was to, for each set of sidebands, take the maximal value of magnitude (this is reasonable since on average when you add two sinusoids of same frequency you'll get the amplitude of the bigger one), and a weighted average of phases (the phase part is way more problematic).

From here, I want to compare to actual ring modulation. I should also compare downsampling/degrading (Decimator plugin) of ring modulation---both of the sources and the result, and see how that compares. There's also grit due to the small FFT size alone, which is another effect to consider adding in.

In any case, from here my task is to build the rest of my toolkit (put this FFT thing into a synthdef, set up synthdefs for the other forms of degradation and ring modulation, and routing in/out).
*/

s.options.memSize = 65536
s.reboot
8192*64