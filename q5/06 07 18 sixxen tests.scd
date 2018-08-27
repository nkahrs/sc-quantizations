// for testing:
{SoundIn.ar(0).dup}.play
{SoundIn.ar(0).dup * SinOsc.ar()}.play
s.reboot
ServerOptions.inDevices
s.options.device="Scarlett 6i6 USB"
{SinOsc.ar.dup}.play
MIDIIn.connectAll
MIDIFunc.trace
~fftSize = 1024;

// highest bin of FFT with phase zero
({
	var chain, sound, env;

	sound = SoundIn.ar(0);
	chain = FFT(LocalBuf(~fftSize), sound);
	chain = PV_MaxMagN(chain, ~fftSize);
	chain = chain.pvcalc(~fftSize/2, {
		arg mags, phases;
		phases = Array.fill(phases.size, {0});
		[mags, phases]
	});

	sound = IFFT(chain);

	sound.dup
}.play;)


// ring-modulated
({
	var chain, sound, env;

	sound = SoundIn.ar(0);
	chain = FFT(LocalBuf(~fftSize), sound);
	chain = PV_MaxMagN(chain, ~fftSize);
	chain = chain.pvcalc(~fftSize, {
		arg mags, phases;
		phases = Array.fill(phases.size, {0});
		[mags, phases]
	});

	env = EnvFollow.ar(sound);

	sound = sound * IFFT(chain) / env;

	sound.dup
}.play;)



// code from Quantizations 3
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