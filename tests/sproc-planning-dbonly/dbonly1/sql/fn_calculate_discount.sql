-- Leaf function #1: calculate discount percentage based on customer tier
-- Has a test script, no production caller
CREATE OR REPLACE FUNCTION fn_calculate_discount(
  p_tier_level IN NUMBER
) RETURN NUMBER
IS
  v_discount NUMBER;
BEGIN
  IF p_tier_level >= 5 THEN
    v_discount := 0.20;
  ELSIF p_tier_level >= 3 THEN
    v_discount := 0.10;
  ELSIF p_tier_level >= 1 THEN
    v_discount := 0.05;
  ELSE
    v_discount := 0;
  END IF;

  RETURN v_discount;
END fn_calculate_discount;
/
