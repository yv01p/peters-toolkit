-- Test script for fn_validate_postal_code
DECLARE
  v_result NUMBER;
BEGIN
  v_result := fn_validate_postal_code('12345');
  DBMS_OUTPUT.PUT_LINE('Valid 5-digit: ' || v_result);

  v_result := fn_validate_postal_code('12345-6789');
  DBMS_OUTPUT.PUT_LINE('Valid 9-digit: ' || v_result);

  v_result := fn_validate_postal_code('ABCDE');
  DBMS_OUTPUT.PUT_LINE('Invalid: ' || v_result);
END;
/
