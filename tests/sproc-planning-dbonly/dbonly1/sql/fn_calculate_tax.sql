-- Helper function - called only by prc_finalize_order (DB-internal)
-- This should be classified as confirmed-live (has DB-internal caller)
CREATE OR REPLACE FUNCTION fn_calculate_tax(
  p_amount IN NUMBER,
  p_tax_rate IN NUMBER
) RETURN NUMBER
IS
  v_tax_amount NUMBER;
BEGIN
  v_tax_amount := ROUND(p_amount * p_tax_rate, 2);
  RETURN v_tax_amount;
END fn_calculate_tax;
/
