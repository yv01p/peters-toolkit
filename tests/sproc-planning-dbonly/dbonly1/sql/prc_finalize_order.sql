-- Procedure with no app caller (DB-only)
-- Calls helper function fn_calculate_tax (creates DB-internal edge)
-- Writes to shared package variable (GLOBAL_STATE coupling with prc_reset_batch_totals)
-- Should be classified as possibly-dead/presumptive
CREATE OR REPLACE PROCEDURE prc_finalize_order(
  p_order_id IN NUMBER,
  p_amount IN NUMBER,
  p_tax_rate IN NUMBER
) IS
  v_tax_amount NUMBER;
  v_total_amount NUMBER;
BEGIN
  -- Call to helper function (creates DB-internal call edge)
  v_tax_amount := fn_calculate_tax(p_amount, p_tax_rate);
  v_total_amount := p_amount + v_tax_amount;

  -- Write to shared package variable (GLOBAL_STATE coupling)
  pkg_order_state.g_batch_total := pkg_order_state.g_batch_total + v_total_amount;

  -- Simulate order finalization
  NULL; -- Would normally UPDATE orders SET status = 'FINAL', total = v_total_amount...
END prc_finalize_order;
/
