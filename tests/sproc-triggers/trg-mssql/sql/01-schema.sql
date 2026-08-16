CREATE TABLE dbo.Orders (
    order_id    INT IDENTITY PRIMARY KEY,
    status      VARCHAR(20) NOT NULL,
    total       DECIMAL(10,2) NOT NULL DEFAULT 0
);
GO

CREATE TABLE dbo.OrderStatusLog (
    log_id      INT IDENTITY PRIMARY KEY,
    order_id    INT NOT NULL,
    old_status  VARCHAR(20),
    new_status  VARCHAR(20),
    severity    VARCHAR(10),
    changed_at  DATETIME DEFAULT GETDATE()
);
GO
