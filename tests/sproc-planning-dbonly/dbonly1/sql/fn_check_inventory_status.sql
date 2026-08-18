-- Defective unreferenced function - CONFIRMED DEAD
-- This function returns an uninitialized variable, making it defective
-- No caller anywhere, no test script
CREATE OR REPLACE FUNCTION fn_check_inventory_status(
  p_product_id IN NUMBER
) RETURN VARCHAR2
IS
  v_status VARCHAR2(20);
  v_unused NUMBER;
BEGIN
  -- Defective: returns v_status which is never assigned
  -- A competent developer would never call this
  v_unused := p_product_id * 2;
  RETURN v_status;
END fn_check_inventory_status;
/
