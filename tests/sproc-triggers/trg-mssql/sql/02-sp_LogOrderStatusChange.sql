-- Standalone procedure. Called from the AFTER trigger's cursor loop below
-- (the trigger cascade). Zero branches, zero cursor loops -- a plain
-- insert.
CREATE PROCEDURE dbo.sp_LogOrderStatusChange
    @OrderID    INT,
    @OldStatus  VARCHAR(20),
    @NewStatus  VARCHAR(20),
    @Severity   VARCHAR(10)
AS
BEGIN
    SET NOCOUNT ON;

    INSERT INTO dbo.OrderStatusLog (order_id, old_status, new_status, severity, changed_at)
    VALUES (@OrderID, @OldStatus, @NewStatus, @Severity, GETDATE());
END;
GO
