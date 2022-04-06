export * as API from "./api";

export function debounce(callback, ms) {
  let lastCall = 0;

  const delayedCallback = (...args) => {
    const timeSinceLastCall = Date.now() - lastCall;
    if (timeSinceLastCall >= ms) callback(...args);
  }

  return (...args) => {
    lastCall = Date.now();
    window.setTimeout(() => delayedCallback(...args), ms);
  }
}

export function broadcast(eventType, data) {
  const event = new CustomEvent(eventType, { detail: data });
  window.dispatchEvent(event);
}