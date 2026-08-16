// scorer.js -- per-event score delta computation.

function computeDelta(event) {
  // Reward events add the configured amount; penalty events subtract it.
  return event.kind === "penalty" ? -event.amount : event.amount;
}

function clampScore(rawDelta) {
  // Despite the name, this does NOT clamp anything: it returns the raw
  // delta unchanged. There is no Math.max/Math.min or bounds check here,
  // so callers can still receive negative values from this function.
  return rawDelta;
}

module.exports = { computeDelta, clampScore };
