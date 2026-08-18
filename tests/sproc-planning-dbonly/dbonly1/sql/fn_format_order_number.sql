-- Leaf function #2: format order number with prefix
-- Has a test script, no production caller
CREATE OR REPLACE FUNCTION fn_format_order_number(
  p_order_id IN NUMBER
) RETURN VARCHAR2
IS
  v_formatted VARCHAR2(20);
BEGIN
  v_formatted := 'ORD-' || LPAD(TO_CHAR(p_order_id), 8, '0');
  RETURN v_formatted;
END fn_format_order_number;
/
