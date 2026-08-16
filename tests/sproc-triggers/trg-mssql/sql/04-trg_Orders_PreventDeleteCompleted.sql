-- INSTEAD OF trigger, for realism (model shape: PBD-Project's
-- trg_Orders_PreventModifyingCompletedOrders). Guards deletion of
-- completed orders and otherwise re-issues the delete manually, since an
-- INSTEAD OF trigger replaces the triggering statement rather than running
-- alongside it. Same out-of-body drop-guard exclusion as the trigger above.
IF OBJECT_ID(N'[dbo].[trg_Orders_PreventDeleteCompleted]', N'TR') IS NOT NULL
    DROP TRIGGER [dbo].[trg_Orders_PreventDeleteCompleted];
GO

CREATE TRIGGER [dbo].[trg_Orders_PreventDeleteCompleted]
    ON [dbo].[Orders]
    INSTEAD OF DELETE
AS
BEGIN
    SET NOCOUNT ON;

    IF EXISTS (SELECT 1 FROM deleted WHERE status = 'COMPLETED')
    BEGIN
        RAISERROR ('Completed orders cannot be deleted.', 16, 1);
        RETURN;
    END

    DELETE FROM dbo.Orders
     WHERE order_id IN (SELECT order_id FROM deleted);
END;
GO
