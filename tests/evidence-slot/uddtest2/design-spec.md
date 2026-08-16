# Design Spec: Invoice Line Item Price Display

## Overview

The invoicing pipeline computes each line item's raw price as a
floating-point value from quantity times unit price, plus any fractional
per-item discount. Before the invoice is printed, raw prices are formatted
to two decimal places (cents) for display.

## Price display handling

`roundTo()` (`src/rounder.js`) takes a raw price and a decimals count and
returns the value rounded to that many decimal places for display. The
raw (unrounded) price is retained internally for accounting reconciliation;
only the display copy passes through `roundTo()`.

## Verified assumptions

| # | Assumption | Evidence |
|---|---|---|
| 1 | `roundTo()` exists in `src/rounder.js` and takes `(x, decimals)` | `src/rounder.js:3` |
