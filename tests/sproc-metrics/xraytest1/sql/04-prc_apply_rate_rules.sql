CREATE OR REPLACE PROCEDURE prc_apply_rate_rules (
  p_driver_id  IN  NUMBER,
  p_class_code IN  VARCHAR2,
  p_zone_code  IN  VARCHAR2,
  p_out_rate   OUT NUMBER
) IS
  -- All of the pricing policy for a single trip lives here. There is no loop in
  -- this procedure; it is pure decision logic over one driver and one rate rule.
  v_status     drivers.status%TYPE;
  v_hold_until drivers.hold_until%TYPE;
  v_base_rate  rate_rules.base_rate%TYPE;
  v_surcharge  rate_rules.surcharge_pct%TYPE;
  v_region     VARCHAR2(8);
  v_zone_mult  NUMBER := 1;
  v_tier_adj   NUMBER := 0;
BEGIN
  v_region := SYS_CONTEXT('fleet_ctx', 'region_code');

  SELECT status, hold_until
    INTO v_status, v_hold_until
    FROM drivers
   WHERE driver_id = p_driver_id;

  SELECT base_rate, surcharge_pct
    INTO v_base_rate, v_surcharge
    FROM rate_rules
   WHERE class_code = p_class_code
     AND zone_code  = p_zone_code;

  IF v_status = 'HOLD' THEN
    IF v_hold_until > SYSDATE THEN
      p_out_rate := 0;
      RETURN;
    ELSE
      v_tier_adj := 0.5;
    END IF;
  ELSIF v_status = 'SUSPENDED' THEN
    p_out_rate := 0;
    RETURN;
  ELSIF v_status = 'PENDING' THEN
    v_tier_adj := 0.25;
  ELSE
    v_tier_adj := 0;
  END IF;

  CASE p_zone_code
    WHEN 'URBAN' THEN
      v_zone_mult := 1.35;
    WHEN 'RURAL' THEN
      v_zone_mult := 0.90;
    WHEN 'AIRPORT' THEN
      v_zone_mult := 1.75;
    ELSE
      v_zone_mult := 1.00;
  END CASE;

  IF v_region IS NULL THEN
    v_region := SYS_CONTEXT('userenv', 'client_identifier');
  END IF;

  p_out_rate := v_base_rate * v_zone_mult * (1 + v_surcharge / 100) + v_tier_adj;

  p_out_rate := p_out_rate + CASE
                               WHEN p_out_rate > 5 THEN 1.50
                               WHEN p_out_rate > 2 THEN 0.75
                               ELSE 0
                             END;

  IF p_out_rate < 0 THEN
    p_out_rate := 0;
  END IF;
END prc_apply_rate_rules;
/
