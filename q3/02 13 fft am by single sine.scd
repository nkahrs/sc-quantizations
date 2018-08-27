~fftBuf = Buffer.alloc(s,1024)

~fftBuf.numFrames
s.sampleRate
s.sampleRate/~fftBuf.numFrames

~sineBin = 10; // set however you want, 10 will be a bit under 440

(
x={
	var sound, chain, numBins, sineFreq, sine;

	numBins = 1024;
	sound = SoundIn.ar(0);

	chain = FFT(~fftBuf, sound);

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

	// 4/12: add gate for shutoff
	//sound = sound * EnvGen.kr(Env.asr(1,1,1), ~gate, doneAction:2);
	// Out.ar(a, sound);
}.play;
)

x.free

// for comparison, actual AM
(
{
	var sound, numBins, sineFreq, sine;

	numBins = 1024; //~fftBuf.numFrames.postln;
	sineFreq = (~sineBin / numBins) * s.sampleRate;

	sine = SinOsc.ar(sineFreq);
	sound = SoundIn.ar(0);
	sound = sound * sine;
}.play;
)