CREATE OR REPLACE FUNCTION fn_trip_surcharge (
  p_trip_id   IN NUMBER,
  p_zone_code IN VARCHAR2
) RETURN NUMBER IS
  -- Flat per-zone surcharge for one trip. Single CASE expression, no loops.
  v_miles trips.miles%TYPE;
BEGIN
  SELECT miles INTO v_miles FROM trips WHERE trip_id = p_trip_id;

  RETURN CASE p_zone_code
           WHEN 'URBAN'   THEN v_miles * 0.10
           WHEN 'AIRPORT' THEN v_miles * 0.20
           ELSE 0
         END;
END fn_trip_surcharge;
/
