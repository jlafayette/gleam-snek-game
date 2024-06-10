export function documentAddEventListener(type, listener) {
	return document.addEventListener(type, listener)
}

export function eventCode(event) {
	return event.code;
}

export function eventKey(event) {
	return event.key;
}

