CREATE OR REPLACE PROCEDURE prc_settlement_sweep (
  p_region_code  IN  VARCHAR2,
  p_out_batch_id OUT NUMBER
) IS
  -- Walks every vehicle in a region, then every unsettled trip on that vehicle,
  -- prices the trip and stages the result for post_batch_totals to pick up.
  CURSOR c_vehicles (cp_region VARCHAR2) IS
    SELECT vehicle_id, class_code
      FROM vehicles
     WHERE region_code = cp_region;

  CURSOR c_trips (cp_vehicle_id NUMBER) IS
    SELECT trip_id, zone_code, miles
      FROM trips
     WHERE vehicle_id = cp_vehicle_id
       AND settled_flag = 'N';

  v_batch_id NUMBER;
  v_rate     NUMBER;
  v_driver   NUMBER;
BEGIN
  SELECT seq_settlement_batch.NEXTVAL INTO v_batch_id FROM dual;

  INSERT INTO settlement_batches (batch_id, region_code, run_ts, total_amount)
  VALUES (v_batch_id, p_region_code, SYSDATE, 0);

  FOR v IN c_vehicles(p_region_code) LOOP

    SELECT driver_id INTO v_driver FROM vehicles WHERE vehicle_id = v.vehicle_id;

    FOR t IN c_trips(v.vehicle_id) LOOP

      prc_apply_rate_rules(v_driver, v.class_code, t.zone_code, v_rate);

      IF v_rate > 0 THEN
        INSERT INTO tmp_settlement_stage (batch_id, vehicle_id, trip_id, amount)
        VALUES (v_batch_id, v.vehicle_id, t.trip_id, v_rate * t.miles);
      END IF;

    END LOOP;

  END LOOP;

  p_out_batch_id := v_batch_id;
EXCEPTION
  WHEN OTHERS THEN
    NULL;
END prc_settlement_sweep;
/
