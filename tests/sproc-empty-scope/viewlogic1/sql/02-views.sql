-- vw_CustomerOrderSummary computes a tier-based discount and an order
-- aging bucket — real logic (CASE expressions producing computed columns),
-- not a passthrough projection over the base tables. This is the corpus's
-- logic-bearing view (there are no stored procedures, functions, or
-- triggers anywhere in this corpus).

CREATE VIEW dbo.vw_CustomerOrderSummary AS
SELECT
    c.CustomerId,
    c.CustomerName,
    c.Tier,
    o.OrderId,
    o.Status,
    o.Subtotal,
    o.Subtotal * CASE c.Tier
        WHEN 'VIP'     THEN 0.85
        WHEN 'PREMIUM' THEN 0.90
        ELSE 1.00
    END AS DiscountedTotal,
    CASE
        WHEN o.Status = 'CANCELLED' THEN 'EXCLUDED'
        WHEN DATEDIFF(DAY, o.OrderDate, SYSUTCDATETIME()) > 30 THEN 'AGED'
        ELSE 'CURRENT'
    END AS AgingBucket
FROM dbo.Orders o
JOIN dbo.Customers c ON c.CustomerId = o.CustomerId;
