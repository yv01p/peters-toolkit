-- AFTER trigger. The drop-guard conditional below is OUT-OF-BODY (it runs
-- before CREATE TRIGGER, guarding a DROP), and is excluded from this
-- trigger's branch count -- only the CREATE TRIGGER body itself counts.
IF OBJECT_ID(N'[dbo].[trg_Orders_StatusSync]', N'TR') IS NOT NULL
    DROP TRIGGER [dbo].[trg_Orders_StatusSync];
GO

CREATE TRIGGER [dbo].[trg_Orders_StatusSync]
    ON [dbo].[Orders]
    AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    IF NOT UPDATE(status)
        RETURN;

    DECLARE @order_id INT, @old_status VARCHAR(20), @new_status VARCHAR(20), @severity VARCHAR(10);

    DECLARE status_cursor CURSOR FOR
        SELECT i.order_id, d.status, i.status
          FROM inserted i
          JOIN deleted d ON d.order_id = i.order_id
         WHERE i.status <> d.status;

    OPEN status_cursor;
    FETCH NEXT FROM status_cursor INTO @order_id, @old_status, @new_status;

    WHILE @@FETCH_STATUS = 0
    BEGIN
        IF @new_status = 'CANCELLED'
            SET @severity = 'HIGH';
        ELSE
            SET @severity = 'NORMAL';

        EXEC dbo.sp_LogOrderStatusChange @order_id, @old_status, @new_status, @severity;

        FETCH NEXT FROM status_cursor INTO @order_id, @old_status, @new_status;
    END

    CLOSE status_cursor;
    DEALLOCATE status_cursor;
END;
GO
