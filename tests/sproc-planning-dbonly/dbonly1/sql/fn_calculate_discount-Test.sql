-- Test script for fn_calculate_discount
DECLARE
  v_result NUMBER;
BEGIN
  v_result := fn_calculate_discount(5);
  DBMS_OUTPUT.PUT_LINE('Tier 5 discount: ' || v_result);

  v_result := fn_calculate_discount(3);
  DBMS_OUTPUT.PUT_LINE('Tier 3 discount: ' || v_result);

  v_result := fn_calculate_discount(0);
  DBMS_OUTPUT.PUT_LINE('Tier 0 discount: ' || v_result);
END;
/
