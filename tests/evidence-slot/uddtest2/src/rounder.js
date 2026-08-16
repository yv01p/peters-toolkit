// rounder.js -- round a number to N decimal places for invoice display.

function roundTo(x, decimals) {
  const factor = 10 ** decimals;
  return Math.round(x * factor) / factor;
}

module.exports = { roundTo };
