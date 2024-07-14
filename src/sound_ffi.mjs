import { lookup, lookup_rate, lookup_gain } from "./sound.mjs"

const ctxMap = new Map();

async function loadFile(audioCtx, filePath) {
	// console.log('loadFile ' + filePath);
	const response = await fetch(filePath);
	const arrayBuffer = await response.arrayBuffer();
	// console.log('buffer length: ' + arrayBuffer.byteLength);
	const audioBuffer = await audioCtx.decodeAudioData(arrayBuffer);
	return audioBuffer;
}

function play(audioCtx, gainNode, audioBuffer, rate, gain) {
	const source = audioCtx.createBufferSource();
	source.buffer = audioBuffer;
	source.playbackRate.value = rate;
	gainNode.gain.value = gain;
	source.connect(gainNode);
	source.start(0);
}

export function playSound(sound) {
	// console.log('playSound: <' + typeof (sound) + '>' + sound);
	const file = "./priv/static/sounds/" + lookup(sound);
	let obj = ctxMap.get(file);
	let ctx;
	let gainNode;
	if (obj == undefined) {
		ctx = new AudioContext();
		gainNode = ctx.createGain();
		gainNode.connect(ctx.destination);
		obj = { ctx, gainNode };
		ctxMap.set(file, obj);
	}
	ctx = obj.ctx;
	gainNode = obj.gainNode;
	
	const rate = lookup_rate(sound);
	const gain = lookup_gain(sound);

	loadFile(ctx, file).then((track) => {
		// console.log('track type: ' + typeof (track));
		play(ctx, gainNode, track, rate, gain);
	});
}

