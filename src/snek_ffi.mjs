export function documentAddEventListener(type, listener) {
	return document.addEventListener(type, listener)
}

export function eventCode(event) {
	return event.code;
}

let id = undefined;

export function windowSetInterval(interval, cb) {
	windowClearInterval();
	id = window.setInterval(cb, interval);
}

export function windowClearInterval() {
	if (id) {
		window.clearInterval(id);
		id = undefined;
	}
}
