// note that many cues also lay groundwork for the next!
(
~beat = 60 / 72;

~cues = [
	{// 00
		00.postln;
		// silence
	},
	{// 01
		01.postln;
		// highest bin of FFT passes through
	},
	{// 02
		02.postln;
		// ring-mod by highest bin of FFT
	},
	{// 03
		03.postln;
		// ring-mod by bin 4
		~current = Synth(\fftFreezeBus, [\inBus, ~busses[8]], s, \addToTail);
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
		~current = Synth(\playBus, [\inBus, ~busses[8]], s, \addToTail);
	},
	{// 07
		07.postln;
		// ring-mod by bin 3
		~current.set(\gate, 0);
		~current = Synth(\fftFreezeBus, [\inBus, ~busses[7]], s, \addToTail);
	},
	{// 08
		08.postln;
		// spectral freeze on
		~current.set(\freeze, 1);
	},
	{// 09
		09.postln;
		// fade to bitcrush of input
		~current.set(\endDur, 2);
		~current.set(\gate, 0);
		~current = Synth(\bitCrushBus, [\inBus, ~busses[4], \startDur, 2], s, \addToTail);
		// particularly here, each cue sets up the next
		~thisFft = ~fftAmFunc.value(3, 2).play;
	},
	{// 10
		10.postln;
		// FFT am bin 3
		~current.set(\gate, 0);
		~current = Synth(\playBus, [\inBus, ~busses[2]], s, \addToTail);
		~nextFft = ~fftAmFunc.value(2, ~busses[1]).play;
	},
	{// 11
		11.postln;
		// FFT am bin 2
		~current.set(\gate, 0);
		~thisFft.free;
		~thisFft = ~nextFft;
		~current = Synth(\playBus, [\inBus, ~busses[1]], s, \addToTail);
		~nextFft = ~fftAmFunc.value(2, ~busses[1]).play;
	},
	{// 12
		12.postln;
		// FFT am bin 1
		~current.set(\gate, 0);
		~thisFft.free;
		~thisFft = ~nextFft;
		~current = Synth(\playBus, [\inBus, ~busses[1]], s, \addToTail);
	},
	{// 13
		13.postln;
		// ring-mod by bin 1
		~current.set(\endDur, 1);
		~current.set(\gate, 0);
		~current = Synth(\playBus, [\inBus, ~busses[5], \startDur, 1], s, \addToTail);
		Routine({
			1.wait;
			~thisFft.free;
		}).play;
	},
	{// 14
		14.postln;
		// ring-mod by bin 2 and freeze
		~current = Synth(\fftFreezeBus, [\inBus, ~busses[6], \endDur, ~beat/2], s, \addToTail);
		Routine({
			(~beat/2).wait;
			~current.set(\freeze, 1);
		}).play;
	},
	{// 15
		15.postln;
		// fade to bitcrush
		~current.set(\gate, 0);
		~current = Synth(\bitCrushBus, [\inBus, ~busses[4], \startDur, ~beat/2, \endDur, ~beat/16], s, \addToTail);

		// initialize am bin 1
		~nextFft = ~fftAmFunc.value(1, ~busses[0]).play;
	},
	{// 16
		16.postln;
		// FFT am by bins 1,2,3,4 in rhythm
		Routine({
			// play 1, set 2
			~current.set(\gate, 0);
			~current = Synth(\playBus, [\inBus, ~busses[0], \startDur, ~beat/16, \endDur, ~beat/16], s, \addToTail);
			~thisFft = ~nextFft;
			~nextFft = ~fftAmFunc.value(2, ~busses[1]).play;
			~beat.wait;
			// play 2, set 3
			~thisFft.free;
			~thisFft = ~nextFft;
			~current.set(\gate, 0);
			~current = Synth(\playBus, [\inBus, ~busses[1], \startDur, ~beat/16, \endDur, ~beat/16], s, \addToTail);
			~nextFft = ~fftAmFunc.value(3, ~busses[2]).play;
			~beat.wait;
			// play 3, set 4
			~thisFft.free;
			~thisFft = ~nextFft;
			~current.set(\gate, 0);
			~current = Synth(\playBus, [\inBus, ~busses[2], \startDur, ~beat/16, \endDur, ~beat/16], s, \addToTail);
			~nextFft = ~fftAmFunc.value(4, ~busses[3]).play;
			~beat.wait;
			// play 4
			~thisFft.free;
			~thisFft = ~nextFft;
			~current.set(\gate, 0);
			~current = Synth(\playBus, [\inBus, ~busses[3], \startDur, ~beat/16, \endDur, ~beat/16], s, \addToTail);
		}).play;
	},
	{// 17
		17.postln;
		// ring-mod by bin 4
		~thisFft.free;
		~current.set(\gate, 0);
		~current = Synth(\playBus, [\inBus, ~busses[8], \startDur, ~beat/16, \endDur, ~beat/2], s, \addToTail);
	},
	{// 18
		18.postln;
		// fade to bitcrush
		~current.set(\gate, 0);
		~current = Synth(\bitCrushBus, [\inBus, ~busses[8], \startDur, ~beat/2, \endDur, ~beat/2], s, \addToTail);
		~thisFft = ~fftAmFunc.value(4, ~busses[3]).play;
	},
	{// 19
		19.postln;
		// FFT am by bin 4
		~current.set(\gate, 0);
		~current = Synth(\playBus, [\inBus, ~busses[3], \startDur, ~beat/2, \endDur, ~beat*4.5], s, \addToTail);

	},
	{// 20
		20.postln;
		// fade out
		Routine({
			~current.set(\gate, 0);
			4.5.wait;
			~thisFft.free;
		});
	},
	{// 21
		21.postln;
		// ring-mod by bin 2
		~current = Synth(\playBus, [\inBus, ~busses[6], \startDur, ~beat/16, \endDur, ~beat/16], s, \addToTail);
	},
	{// 22
		22.postln;
		// ring-mod by bin 3
		~current.set(\gate, 0);
		~current = Synth(\playBus, [\inBus, ~busses[7], \startDur, ~beat/16, \endDur, ~beat/16], s, \addToTail);
	},
	{// 23
		23.postln;
		// ring-mod by bin 4
		~current.set(\gate, 0);
		~current = Synth(\playBus, [\inBus, ~busses[8], \startDur, ~beat/16, \endDur, ~beat/16], s, \addToTail);
	},
	{// 24
		24.postln;
		// ring-mod by bins 5,6,7,8 (in tempo) and freese
		Routine({
			3.do{
				arg i;
				~current.set(\gate, 0);
				~current = Synth(\playBus, [\inBus, ~busses[9+i], \startDur, ~beat/16, \endDur, ~beat/16], s, \addToTail);
				(~beat*2/3).wait;
			};
			~current.set(\gate, 0);
			~current = Synth(\fftFreezeBus, [\inBus, ~busses[12], \startDur, ~beat/16, \endDur, ~beat/16], s, \addToTail);
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
				~current = Synth(\playBus, [\inBus, ~busses[5+i], \startDur, ~beat/16, \endDur, ~beat/16], s, \addToTail);
				(~beat*2/3).wait;
			};
			~current.set(\gate, 0);
			~current = Synth(\fftFreezeBus, [\inBus, ~busses[8], \startDur, ~beat/16, \endDur, ~beat/16], s, \addToTail);
			(~beat/8).wait;
			~current.set(\freeze, 1);
		}).play;
	},
	{// 26
		26.postln;
		// ring-mod by bin 4 and freeze
		~current.set(\gate, 0);
		~current = Synth(\fftFreezeBus, [\inBus, ~busses[8], \startDur, ~beat/16, \endDur, ~beat/16], s, \addToTail);
	},
	{// 27
		27.postln;
		// ring-mod by bin 3 and freeze
		~current.set(\gate, 0);
		~current = Synth(\fftFreezeBus, [\inBus, ~busses[7], \startDur, ~beat/16, \endDur, ~beat/16], s, \addToTail);
	},
	{// 28
		28.postln;
		// ring-mod by bin 2 and freeze
		~current.set(\gate, 0);
		~current = Synth(\fftFreezeBus, [\inBus, ~busses[6], \startDur, ~beat/16, \endDur, ~beat/16], s, \addToTail);
	},
	{// 29
		29.postln;
		// ring-mod by bin 1 and freeze
		~current.set(\gate, 0);
		~current = Synth(\fftFreezeBus, [\inBus, ~busses[5], \startDur, ~beat/16, \endDur, ~beat/16], s, \addToTail);
		~thisFft = ~fftAmFunc.value(1, ~busses[0]).play;
	},
	{// 30
		30.postln;
		// FFT am by bin 1
		~current.set(\gate, 0);
		~current = Synth(\playBus, [\inBus, ~busses[0], \startDur, ~beat/4, \endDur, ~beat], s, \addToTail);
	},
	{// 31
		31.postln;
		// end
		~current.set(\gate, 0);
		"over".postln;
	}
];
)

~cues.size

~cues[16].value