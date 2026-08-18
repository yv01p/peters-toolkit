-- Billing schema for a small subscription service (SQL Server / T-SQL).
--
-- Zero stored procedures, functions, triggers, or packages anywhere in this
-- corpus. But the tables below carry real DB-resident business logic in
-- their DDL: CHECK constraints (tier/status/amount validation) and a
-- logic-bearing DEFAULT (DEFAULT SUSER_SNAME() — captures the calling
-- principal at insert time, not a static literal). See 02-views.sql for the
-- corpus's other logic-bearing object, a view with CASE-driven computed
-- columns.

CREATE TABLE dbo.Customers (
    CustomerId   INT IDENTITY(1,1) PRIMARY KEY,
    CustomerName NVARCHAR(200) NOT NULL,
    Tier         NVARCHAR(20)  NOT NULL
        CONSTRAINT CK_Customers_Tier CHECK (Tier IN ('STANDARD', 'PREMIUM', 'VIP')),
    CreatedBy    NVARCHAR(128) NOT NULL
        CONSTRAINT DF_Customers_CreatedBy DEFAULT SUSER_SNAME(),
    CreatedAt    DATETIME2     NOT NULL
        CONSTRAINT DF_Customers_CreatedAt DEFAULT SYSUTCDATETIME()
);

CREATE TABLE dbo.Orders (
    OrderId    INT IDENTITY(1,1) PRIMARY KEY,
    CustomerId INT NOT NULL REFERENCES dbo.Customers(CustomerId),
    OrderDate  DATETIME2      NOT NULL,
    Subtotal   DECIMAL(10,2)  NOT NULL
        CONSTRAINT CK_Orders_Subtotal CHECK (Subtotal >= 0),
    Status     NVARCHAR(20)   NOT NULL
        CONSTRAINT CK_Orders_Status CHECK (Status IN ('OPEN', 'SHIPPED', 'CANCELLED'))
);
