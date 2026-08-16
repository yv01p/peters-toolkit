-- accounts: the base table the trigger fires on
CREATE TABLE accounts (
    account_id  NUMBER PRIMARY KEY,
    balance     NUMBER(12,2) DEFAULT 0,
    status      VARCHAR2(20) NOT NULL,
    risk_flag   CHAR(1) DEFAULT 'N',
    updated_at  DATE DEFAULT SYSDATE
);

-- account_holds: rows the trigger's cursor loop walks and releases
CREATE TABLE account_holds (
    hold_id      NUMBER PRIMARY KEY,
    account_id   NUMBER NOT NULL,
    hold_amount  NUMBER(12,2) NOT NULL,
    released     CHAR(1) DEFAULT 'N'
);

-- account_status_log: written by the standalone procedure the trigger calls
CREATE TABLE account_status_log (
    log_id       NUMBER PRIMARY KEY,
    account_id   NUMBER NOT NULL,
    old_status   VARCHAR2(20),
    new_status   VARCHAR2(20),
    changed_at   DATE DEFAULT SYSDATE
);

CREATE SEQUENCE seq_status_log START WITH 1 INCREMENT BY 1;
