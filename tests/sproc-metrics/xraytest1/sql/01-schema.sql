-- fleetbill : core storage
--
-- Tables, one global temporary table, one sequence and one collection type.
-- No business logic lives in this file; it is here so the routines under this
-- directory have real definitions to resolve against.

CREATE TABLE drivers (
  driver_id     NUMBER(10)   NOT NULL,
  region_code   VARCHAR2(8)  NOT NULL,
  status        VARCHAR2(12) DEFAULT 'ACTIVE' NOT NULL,
  hold_until    DATE,
  CONSTRAINT pk_drivers PRIMARY KEY (driver_id)
);

CREATE TABLE vehicles (
  vehicle_id    NUMBER(10)   NOT NULL,
  driver_id     NUMBER(10)   NOT NULL,
  class_code    VARCHAR2(8)  NOT NULL,
  region_code   VARCHAR2(8)  NOT NULL,
  CONSTRAINT pk_vehicles PRIMARY KEY (vehicle_id),
  CONSTRAINT fk_vehicles_driver FOREIGN KEY (driver_id) REFERENCES drivers (driver_id)
);

CREATE TABLE trips (
  trip_id       NUMBER(12)   NOT NULL,
  vehicle_id    NUMBER(10)   NOT NULL,
  zone_code     VARCHAR2(8)  NOT NULL,
  miles         NUMBER(9,2)  DEFAULT 0 NOT NULL,
  trip_date     DATE         DEFAULT SYSDATE NOT NULL,
  settled_flag  VARCHAR2(1)  DEFAULT 'N' NOT NULL,
  CONSTRAINT pk_trips PRIMARY KEY (trip_id),
  CONSTRAINT fk_trips_vehicle FOREIGN KEY (vehicle_id) REFERENCES vehicles (vehicle_id)
);

CREATE TABLE rate_rules (
  class_code    VARCHAR2(8)  NOT NULL,
  zone_code     VARCHAR2(8)  NOT NULL,
  base_rate     NUMBER(9,4)  NOT NULL,
  surcharge_pct NUMBER(5,2)  DEFAULT 0 NOT NULL,
  CONSTRAINT pk_rate_rules PRIMARY KEY (class_code, zone_code)
);

CREATE TABLE charges (
  charge_id     NUMBER(12)   NOT NULL,
  driver_id     NUMBER(10)   NOT NULL,
  charge_code   VARCHAR2(12) NOT NULL,
  amount        NUMBER(11,2) DEFAULT 0 NOT NULL,
  batch_id      NUMBER(10),
  CONSTRAINT pk_charges PRIMARY KEY (charge_id)
);

CREATE TABLE settlement_batches (
  batch_id      NUMBER(10)   NOT NULL,
  region_code   VARCHAR2(8)  NOT NULL,
  run_ts        DATE         DEFAULT SYSDATE NOT NULL,
  total_amount  NUMBER(13,2) DEFAULT 0 NOT NULL,
  CONSTRAINT pk_settlement_batches PRIMARY KEY (batch_id)
);

CREATE TABLE driver_holds (
  hold_id       NUMBER(12)   NOT NULL,
  driver_id     NUMBER(10)   NOT NULL,
  created_ts    DATE         DEFAULT SYSDATE NOT NULL,
  CONSTRAINT pk_driver_holds PRIMARY KEY (hold_id)
);

-- Session-scoped staging area for a settlement run.
CREATE GLOBAL TEMPORARY TABLE tmp_settlement_stage (
  batch_id      NUMBER(10)   NOT NULL,
  vehicle_id    NUMBER(10)   NOT NULL,
  trip_id       NUMBER(12)   NOT NULL,
  amount        NUMBER(11,2) NOT NULL
) ON COMMIT PRESERVE ROWS;

CREATE SEQUENCE seq_settlement_batch START WITH 1000 INCREMENT BY 1 NOCACHE;

CREATE OR REPLACE TYPE t_charge_code_list IS VARRAY(20) OF VARCHAR2(12);
/
