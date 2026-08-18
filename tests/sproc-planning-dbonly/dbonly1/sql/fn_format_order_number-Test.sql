-- Test script for fn_format_order_number
DECLARE
  v_result VARCHAR2(20);
BEGIN
  v_result := fn_format_order_number(123);
  DBMS_OUTPUT.PUT_LINE('Formatted: ' || v_result);

  v_result := fn_format_order_number(999999);
  DBMS_OUTPUT.PUT_LINE('Formatted: ' || v_result);
END;
/
