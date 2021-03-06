///////////////////////////
////////////////////////////////
///Crackling Data Machines
//////////////////////////
//////beagleMain


//jackd -dalsa -dhw:1,0 -r48000 -p1024 -i2 -o2

(


///////////////////////////////////
////////////////////////////////
//////////////////
///////SETUP


q = ();



(
Tdef(\setup, {
	s.quit;
	0.5.wait;
	s = Server.local;
	0.5.wait;
	s.options.memSize = 65536;
	0.5.wait;
	s.options.blockSize = 512;
	0.5.wait;
	s.boot;
	1.wait;
	Tdef(\boucle).play;
}).play;
);


///////////////////////////////////
//Serial Communication for Arduino


(
q.arduino = ArduinoSMS(
	"/dev/ttyACM0",    //edit to match your port. SerialPort.listDevices
	baudrate: 115200,    //check that baudrate is the same as in arduino sketch
);
);



//////////////////////
//print
////////

////////////////////////
//pixelBuffer

(
q.pxlRes =  [200, 300];
//q.page = [];
q.pxlBuffer = [];
q.pageCount = 0;
q.pageParts = 6;
);



//PixelArrray for one line


q.nextLine = { |q|
	q.currentLine = [];
	q.pxlRes[0].do{
		var pxl = q.pxlBuffer.pop;
		q.currentLine = q.currentLine ++ pxl;
	};
	\nextline;

};


//next Event from the printing process

//q.nextLine;
q.counter = 0;
q.rev = 1;




///////
//EventMapping

q.mapping = (
		rls: [$d, 2],
		srv: [$s, 3],
		led: [$a, 5],
		stp: [$t, 8]
		);


///EventType


q.motorOffset = 0;
q.p5Offset = -10;


(
Event.addEventType(\mechan, {
	var adst = ~adst ? $d;
	var pin = ~pin ? 2;
	var val = ~val ? 0;
	var val1 = ~val1, val2 = ~val2, val3 = ~val3;
	if(pin.isNumber.not) {			// map symbols across dictionary
		pin = q.mapping.at(pin);
		adst = pin[0];
		pin = pin[1];
	};
	//thisThread.clock.sched( ~timingOffset ? 0.0 + q.motorOffset, {
		q.arduino.send($w, adst, pin, val);
	//});
	//thisThread.clock.sched( ~timingOffset ? 0.0 + q.p5Offset, {
		q.oscTX(val1, val2, val3);
		//"val1, val2, val3".postln;
	//});

});
);









//////////////////////////////
//OSC-Send for Processing

(
m = NetAddr("127.0.0.1", 12000);
q.oscTX = { |q, val1, val2, val3|
	m.sendMsg("/sendMe", val1);
};

);



////////////////////////////////
//OSC-Receive from Processing

(
n = NetAddr("127.0.0.1", nil);
q.oscRX = OSCdef(\test, {|msg, time, addr, recvPort|
	msg.postln;
	msg.removeAt(0);
	q.page = q.page ++ msg;
	q.pageCount = q.pageCount + 1;
	if(q.pageCount == q.pageParts,
		{q.pxlBuffer = q.page ++ q.pxlBuffer;
			q.pageCount = 0;
			q.page = [];
	});
}, '/chat', n);
);


//////////////////
///////SON

Ndef.clear;


//////////////////////////////////////
///WiFiInput


(
Ndef(\wifi, { | amp = 1.0|
	var in = SoundIn.ar(0) * 10;
	var son = Limiter.ar(Compander.ar(in, in, 0.7, 		// threshold
		1, 		// below threshold slope
		0.3		// above threshold slope
	), 0.9, 0.01);
	son = BPeakEQ.ar(son, 9000, 2, -6);
	son * amp
});
);




//Ndef(\wifi).play;
//Ndef(\wifi).stop;


(
Ndef(\wifiLoop, { |amp = 2.0, start = 0, bufnum = 1, trig|
	var in = Ndef.ar(\wifi, 1, 0) ;
	var son = PanAz.ar(2, in,
		Duty.kr(1, 0, Drand([-1, -0.5, 0.0, 0.5], inf)),
		amp,
		0.5, 0);
	son
});
);

/*

(
Ndef(\wifiLoop, { |amp = 1.0, start = 0, bufnum = 1, trig|
var in = Ndef.ar(\wifi, 1, 0) ;
var son = PanAz.ar(4, in,
SinOsc.ar(0.05),
amp,
0.5, 0);
son
});
);

*/



(
Ndef(\wifiChan, { |amp = 0.4, start = 0, bufnum = 0, trig|
	var in = Ndef.ar(\wifi, 1, 0) ;
	var son = in ! 2;
	son * amp
});
);



//Ndef(\wifiLoop).play;
//Ndef(\wifiLoop).stop;
//Ndef(\wifiChan).playN(outs: [0, 1, 2, 3]);
//Ndef(\wifiChan).stop;



//////////////////
//droneOndesMod


Ndef(\droneOndes, { |amp = 1|
	var in = Ndef.ar(\wifi, 1, 0) ;
	var analyze = Amplitude.ar(in);
	var son = SinOsc.ar([70, 139, 209, 282, 353, 424, 485] * SinOsc.ar(0.01).range(-0.1, 0.1)).sum * in;
	son = PanAz.ar(2, son,
		SinOsc.kr(0.05),
		amp,
		0.5, 0);

});


//Ndef(\droneOndes).play;
//Ndef(\droneOndes).stop;


//////////////////
//impulse Riddim


(
Ndef(\impulseRid, { |amp = 1|
	var son = PanAz.ar(
		2,                 // numChans
		Impulse.ar(Duty.kr(0.1, 0,
			Drand([0.01, 0.01, 0.01, 0.02, 0.02, 0.02, 0.5, 1, 1.5, 2.0], inf))),     // in
		Duty.kr(0.1, 0, Drand([-1, -0.5, 0.0, 0.5], inf)), // pos
		1.2,            // level
		1.5, 0           // width
	);
	son
});
);



//Ndef(\impulseRid).play;
//Ndef(\impulseRid).stop;


(
Ndef(\blipRid, { |amp = 1|
	var son = PanAz.ar(
		2,                 // numChans
		Blip.ar(0.5, 100 * SinOsc.kr(0.01).range(0.8, 10)),     // in
		LFSaw.kr(0.9), // pos
		amp,            // level
		1.2           // width
	);
	son
});
);



//Ndef(\blipRid).play;
//Ndef(\blipRid).stop;


(
Tdef(\droneSin, {
	loop{
		Ndef(\sin, {
			var son = SinOsc.ar(ExpRand(1500, 50), 0, Rand(0.5, 1));
			son = son * (Ndef.ar(\wifi, 1, 0) * 2);
			Out.ar(0, PanAz.ar(2, son,
				Duty.kr(LFPulse.kr(WhiteNoise.kr().range(0.1, 2.0)).range(3.0, 0.001), 0,
					Drand([-0.5, 0, 0.5, 1], inf)), 0.5, 2)
				* EnvGen.kr(Env.perc(20, 20, 0.5), 0.6, 0.5, doneAction: 2), 0.1);
		}).play;
		8.wait;
	}.tanh;
});
);





//Tdef(\droneSin).play;
//Tdef(\droneSin).stop;


(
Tdef(\dronePulse, {
	loop{
		Ndef(\sin, {
			var son = LFPulse.ar([80, 81, 160, 239, 321, 400, 480, 560].choose, 0, Rand(0.5, 1));
			//son = RLPF.ar(son, 1000, 0.5);
			Out.ar(0, PanAz.ar(2, son,
				Duty.kr(LFPulse.kr(WhiteNoise.kr().range(0.1, 2.0)).range(3.0, 0.001), 0,
					Drand([-0.5, 0, 0.5, 1], inf)), 0.5, 2)
				* EnvGen.kr(Env.perc(20, 20, 0.5), 0.8, 0.3, doneAction: 2), 0.1);
		}).play;
		8.wait;
	}.tanh;
});
);

//Tdef(\dronePulse).play;
//Tdef(\dronePulse).stop;


////////////////////////
///////////DelayClicks


(
Ndef(\delay, {
	var input, delayTime, outDelay;
	// input from sound card
	input = Ndef.ar(\wifi, 1, 0) * 3.8;
	// delay time jumps every 2 seconds
	delayTime = Demand.kr(Impulse.kr(0.2), 0, Dseq([0.4, 0.6, 0.9, 0.3, 0.7], inf));
	// CombC - delay with feedback
	CombC.ar(input ! 2, 16, delayTime, 6) + input;
	input = PanAz.ar(2, input, LFSaw.kr(SinOsc.kr(0.5).range(0.01, 0.05)));
	input = input * 2;
	input
});
);


//Ndef(\delay).play;
//Ndef(\delay).stop;





//////////////////
///////PATTERNS




Tdef(\printPxl, {
	loop{
		q.nextLine;
		0.4.wait;
		q.currentLine.postln;
		q.counter = 0;
		0.4.wait;
		q.arduino.send($w, $s, 1, 550); //DC get Back
		1.5.wait;
		//q.arduino.send($w, $d, 1, 400); //DC to starting Point, Hardware starting Point?
		//1.wait;
		q.arduino.send($w, $t, 10, 7); //Stepper next Line
		1.5.wait;
		//q.arduino.send($w, $o);
		//0.1.wait;
		q.pxlRes[0].do( //For each Line
			{
				var pxl = q.currentLine[q.counter];
				q.counter = q.counter + 1;
				if(pxl == 1, {
					q.arduino.send($w, $o);  //Pen up or down --> black or white
				});
				0.05.wait;
				q.arduino.send($w, $d, 1, 1.0);   				//DC next Pixel
				pxl.postln;
				0.05.wait;

		});
		0.1.wait;
		//q.arduino.send($w, $o);
		//0.1.wait;
	};

});


//Tdef(\printPxl).play;
//Tdef(\printPxl).stop;


/////
//RandomPrint

Tdef(\printRand, {
	loop{
		q.nextLine;
		0.4.wait;
		q.currentLine.postln;
		q.counter = 0;
		0.4.wait;
		q.arduino.send($w, $c, 1, 550); //DC get Back
		rrand(1.5, 2.5).wait;
		//q.arduino.send($w, $d, 1, 400); //DC to starting Point, Hardware starting Point?
		//1.wait;
		q.arduino.send($w, $s, 10, 7); //Stepper next Line
		rrand(1.5, 2.5).wait;
		//q.arduino.send($w, $o);
		//0.1.wait;
		q.pxlRes[0].do( //For each Line
			{
				var pxl = q.currentLine[q.counter];
				q.counter = q.counter + 1;
				if(pxl == 1, {
					q.arduino.send($w, $o);  //Pen up or down --> black or white
				});
				rrand(0.01, 0.2).wait;
				q.arduino.send($w, $d, 1, 1.0);   				//DC next Pixel
				pxl.postln;
				rrand(0.01, 0.2).wait;

		});
		0.1.wait;
		//q.arduino.send($w, $o);
		//0.1.wait;
	};

});


//Tdef(\printRand).play;
//Tdef(\printRand).stop;






//////////////////////////////
///////////////////////////
///////////////////////
/////////KOMPOSITION


Tdef(\boucle, {
	var machine;
	loop{
		/*
		Ndef(\mechaLoop).set(\start, 0, \amp, 0.3, \trig, 0);
		Ndef(\mechaLoopNoise).set(\start, 0, \amp, 1.7, \trig, 0);
		q.arduino.send($w, $d, 2, 0);
		*/
		//Produce Data;
		//RANDOM DICHTE!!!!
		q.oscTX([2, 3, 4].choose);
		2.5.wait;
		//send me some pxlData
		q.oscTX(1);
		2.5.wait;

		q.oscTX(5);
		0.3.wait;


		//Crackling
		"Crackling".postln;
		machine = [[Ndef(\wifiLoop)],
			[Ndef(\droneOndes)],
			[Ndef(\impulseRid), Pdef(\impulseRid)],
			[Ndef(\blipRid), Pdef(\blipRid)],
			[Tdef(\droneSin)],
			[Ndef(\delay)],
			[Tdef(\dronePulse)]].choose;
		machine.postln;
		machine[0].play;
		try{ machine[1].play; };
		try{ machine[2].play; };

		rrand(36, 101).wait;

		Ndef(\wifiLoop).stop(60);
		Ndef(\droneOndes).stop(50);
		Ndef(\impulseRid).stop(60);
		Pdef(\impulseRid).stop;
		Ndef(\blipRid).stop(50);
		Pdef(\blipRid).stop;
		Ndef(\delay).stop(45);
		Tdef(\droneSin).stop;
		Tdef(\dronePulse).stop;
		15.wait;


		//1_Print
		"1_mechaLoop".postln;
		Tdef(\printPxl).play;

		rrand(28, 107).wait;
		Tdef(\printPxl).stop;


		//Crackling
		"Crackling".postln;
		machine = [[Ndef(\wifiLoop)],
			[Ndef(\droneOndes)],
			[Ndef(\impulseRid), Pdef(\impulseRid)],
			[Ndef(\blipRid), Pdef(\blipRid)],
			[Tdef(\droneSin)],
			[Ndef(\delay)],
			[Tdef(\dronePulse)]].choose;
		machine.postln;
		machine[0].play;
		try{ machine[1].play; };
		try{ machine[2].play; };

		rrand(64, 122).wait;

		Ndef(\wifiLoop).stop;
		Ndef(\droneOndes).stop(30);
		Ndef(\impulseRid).stop(20);
		Pdef(\impulseRid).stop;
		Ndef(\blipRid).stop;
		Pdef(\blipRid).stop;
		Ndef(\delay).stop(35);
		Tdef(\droneSin).stop;
		Tdef(\dronePulse).stop;
		15.wait;


		//2_PrintRand
		"2_printRand".postln;
		Tdef(\printRand).play;

		rrand(41, 97).wait;
		Tdef(\printRand).stop;



	};
});





);
