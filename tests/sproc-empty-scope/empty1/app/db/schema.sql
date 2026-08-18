-- PartsTrack inventory schema (SQL Server / T-SQL) — plain storage only.
--
-- This file defines tables and nothing else: no stored procedures, no
-- functions, no triggers, no packages (Oracle-only concept, N/A here), no
-- views, no CHECK constraints, and no logic-bearing DEFAULT clauses. Every
-- DEFAULT-free column below is deliberate — this schema exists to hold the
-- corpus's DB-resident-logic count at exactly zero across every category
-- the x-ray tracks (routines, logic-bearing views, CONSTRAINT_LOGIC).
--
-- Business rules for this system (reorder thresholds, discount rates, order
-- status transitions) live entirely in the C# application layer — see
-- app/src/*.cs — which issues plain parameterized CRUD SQL against these
-- tables via inline string literals (ADO.NET SqlCommand.CommandText).

CREATE TABLE dbo.Products (
    ProductId       INT IDENTITY(1,1) PRIMARY KEY,
    Sku             NVARCHAR(40)   NOT NULL,
    Name            NVARCHAR(200)  NOT NULL,
    UnitPrice       DECIMAL(10,2)  NOT NULL,
    QuantityOnHand  INT            NOT NULL,
    ReorderPoint    INT            NOT NULL,
    CreatedAt       DATETIME2      NOT NULL
);

CREATE TABLE dbo.Customers (
    CustomerId   INT IDENTITY(1,1) PRIMARY KEY,
    CustomerName NVARCHAR(200) NOT NULL,
    Email        NVARCHAR(200) NOT NULL
);

CREATE TABLE dbo.Orders (
    OrderId      INT IDENTITY(1,1) PRIMARY KEY,
    CustomerId   INT NOT NULL REFERENCES dbo.Customers(CustomerId),
    OrderDate    DATETIME2 NOT NULL,
    Status       NVARCHAR(20) NOT NULL
);

CREATE TABLE dbo.OrderLines (
    OrderLineId  INT IDENTITY(1,1) PRIMARY KEY,
    OrderId      INT NOT NULL REFERENCES dbo.Orders(OrderId),
    ProductId    INT NOT NULL REFERENCES dbo.Products(ProductId),
    Quantity     INT NOT NULL,
    LineTotal    DECIMAL(10,2) NOT NULL
);
