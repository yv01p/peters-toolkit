-- Leaf function #3: validate US postal code format
-- Has a test script, no production caller
CREATE OR REPLACE FUNCTION fn_validate_postal_code(
  p_postal_code IN VARCHAR2
) RETURN NUMBER
IS
  v_is_valid NUMBER;
BEGIN
  IF REGEXP_LIKE(p_postal_code, '^\d{5}(-\d{4})?$') THEN
    v_is_valid := 1;
  ELSE
    v_is_valid := 0;
  END IF;

  RETURN v_is_valid;
END fn_validate_postal_code;
/
