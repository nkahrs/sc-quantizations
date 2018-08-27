// synthdefs
(
// synth for triggering buffers
SynthDef(\triggerBuf, {
	arg buf, bus, trigger;
	Out.ar(bus, PlayBuf.ar(1, buf, 1, trigger).dup);
}).load(s);
)

(
// set fft size
~fftSize = 512;

// key to number mapping (use the bottom two rows of the keyboard, to the right means a higher pitch
~dict = IdentityDictionary.with(*[
	'z'->19,
	's'->18,
	'x'->17,
	'd'->16,
	'c'->15,
	'f'->14,
	'v'->13,
	'g'->12,
	'b'->11,
	'h'->10,
	'n'->9,
	'j'->8,
	'm'->7,
	'k'->6,
	','->5,
	'l'->4,
	'.'->3,
	';'->2,
	'/'->1,
	"'".asSymbol->0
]);

// initialize intermediate bus
~intBus = Bus.audio(s);

// initialize FFT thing from EARS project
Routine(
	{{
		var chain, clarSound, fftSound, env;

		//clarSound is sixxen, not clarinet! legacy variable name

		clarSound = In.ar(~intBus); // *100 to boost signal
		chain = FFT(LocalBuf(~fftSize), clarSound);
		chain = PV_MaxMagN(chain, ~fftSize/2);

		chain = chain.pvcalc(~fftSize/2, {
			arg mags, phases;

			phases = Array.fill(phases.size, {0});

			[mags, phases]
		});

		fftSound = IFFT(chain);

		[clarSound, fftSound]
		// I could create more intermediate buses if I wanted, or just change this and restart each time

		/*		// ring modulation
		fftSound = (clarSound * fftSound);
		// keep it from getting too quiet---follow clarinet envelope, not squared envelope
		env = EnvFollow.ar(clarSound);
		fftSound = fftSound / env;
		Out.ar(~busses[1], fftSound);*/
	}.play}
).play;



// player
// need to build 20 synths that I can repeatedly trigger, but them in a container

// load all 20 files

Routine({
	s.sync;
	~bufs = Array.fill(20, nil);
	20.do{
		arg i;
		~bufs[i] = Buffer.read(s, "C:/Users/nkahrs/Box Sync/Noah Kahrs/1c Summer 2018/compositions and recordings/Quantizations 5 sixxen/sm58 note samples/"++(i+1)++".wav");
	};

	// how to play one of the buffers
	// {PlayBuf.ar(1, ~bufs[18]).dup}.play

	// now, create synths

	~synths = Array.fill(20, nil);
	20.do{
		arg i;
		~synths[i] = Synth(\triggerBuf, [\buf, ~bufs[i], \bus, ~intBus,
			\trigger, 0], s, \addToHead);
	};


	// how to use
	// (
	// Routine{a.set(\trigger, 1);
	// 	s.sync;
	// 	a.set(\trigger, 0)
	// }.play;
	// )


}).play;

	// GUI to trigger by key->number mapping

w = Window.new("Quantizations 5?", Rect(0, 0, 800, 400));
// create number box
n = NumberBox(w, Rect(50, 50, 500, 300));
n.font = Font("Arial", 250);
// action: just post the current number (this might change)// set initial value to zero
n.value_(0);
// when pressing spacebar (and only spacebar!), increment
n.keyDownAction_({
	arg i,keyPressed;
	// ~foo.at(keyPressed.asSymbol).postln;
	var whichKey = ~dict.at(keyPressed.asSymbol);
	n.value_(whichKey);
	Routine{
		~synths[whichKey].set(\trigger, 1);
		s.sync;
		~synths[whichKey].set(\trigger, 0);
	}.play;
});
w.front;

)


// still todo: dump these synths into an intermediate bus, add other processing for FFT, add a slider to adjust balance. This should just be copypasta from clarinet, shouldn't be too hard.