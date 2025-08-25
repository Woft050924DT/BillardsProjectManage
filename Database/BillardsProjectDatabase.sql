-- Create database
CREATE DATABASE BillardsProject;
GO

USE BillardsProject;
GO

-- Table for billiard tables (renamed from TableCoffee)
CREATE TABLE BilliardTable
(
    ID INT IDENTITY PRIMARY KEY,
    Name NVARCHAR(100) NOT NULL DEFAULT N'Chưa đặt tên',
    Status NVARCHAR(100) NOT NULL DEFAULT N'Trống', -- Consider using INT (0: Empty, 1: Occupied)
    PricePerHour INT NOT NULL DEFAULT 30000 -- Default rental price per hour
);
GO

-- Modified Bill table to include play time
CREATE TABLE Bill
(
    ID INT IDENTITY PRIMARY KEY,
    CheckIn DATETIME NOT NULL DEFAULT GETDATE(),
    CheckOut DATETIME,
    TableID INT NOT NULL,
    PlayTime INT DEFAULT 0, -- Duration in minutes
    Discount INT NOT NULL DEFAULT 0,
    TotalPrice INT DEFAULT 0,
    Status INT NOT NULL DEFAULT 0, -- 1: Paid, 0: Unpaid
    FOREIGN KEY (TableID) REFERENCES BilliardTable(ID)
);
GO

-- Other tables (AccountType, Account, CategoryFood, Food, BillInfo) remain unchanged
-- Example: AccountType
CREATE TABLE AccountType
(
    ID INT IDENTITY PRIMARY KEY,
    TypeName NVARCHAR(50) NOT NULL
);
GO

-- Account table (with hashed password recommendation)
CREATE TABLE Account
(
    UserName VARCHAR(100) PRIMARY KEY,
    DisplayName NVARCHAR(100) NOT NULL DEFAULT N'Name',
    Password VARCHAR(500) NOT NULL, -- Should store hashed passwords
    TypeID INT NOT NULL,
    FOREIGN KEY (TypeID) REFERENCES AccountType(ID)
);
GO

-- CategoryFood, Food, and BillInfo tables remain as in the original code
CREATE TABLE CategoryFood
(
    ID INT IDENTITY NOT NULL PRIMARY KEY,
    Name NVARCHAR(100) NOT NULL DEFAULT N'Chưa đặt tên'
);
GO

CREATE TABLE Food
(
    ID INT IDENTITY PRIMARY KEY,
    Name NVARCHAR(100) NOT NULL DEFAULT N'Chưa đặt tên',
    CategoryID INT NOT NULL,
    Price INT NOT NULL DEFAULT 0,
    FOREIGN KEY (CategoryID) REFERENCES CategoryFood(ID)
);
GO

CREATE TABLE BillInfo
(
    ID INT IDENTITY PRIMARY KEY,
    BillID INT NOT NULL,
    FoodID INT NOT NULL,
    Amount INT NOT NULL DEFAULT 0,
    FOREIGN KEY (BillID) REFERENCES Bill(ID),
    FOREIGN KEY (FoodID) REFERENCES Food(ID)
);
GO

-- Insert sample data for BilliardTable
DECLARE @i INT = 1;
WHILE @i <= 30
BEGIN
    INSERT INTO BilliardTable (Name, PricePerHour)
    VALUES (N'Bàn ' + CAST(@i AS NVARCHAR(100)), 30000);
    SET @i = @i + 1;
END;
GO

-- Insert sample data for AccountType, Account, CategoryFood, Food, Bill, and BillInfo as in the original code

INSERT INTO AccountType (TypeName) VALUES (N'Quản trị viên');
INSERT INTO AccountType (TypeName) VALUES (N'Nhân viên');
INSERT INTO AccountType (TypeName) VALUES (N'Nhân viên bán thời gian');

-- Chỉ insert account một lần, tránh bị trùng UserName PRIMARY KEY
INSERT INTO Account (UserName, DisplayName, Password, TypeID)
VALUES
('admin', N'Quản trị viên', 'admin', 1),
('nhanvien1', N'Nguyễn Văn A', '123', 2),
('nhanvien2', N'Lê Thị B', '123', 2),
('parttime1', N'Phạm Văn C', '123', 3),
('parttime2', N'Hoàng Thị D', '123', 3);

INSERT INTO CategoryFood (Name)
VALUES 
(N'Nước uống'), 
(N'Đồ ăn vặt'), 
(N'Trái cây');

-- Nước uống
INSERT INTO Food (Name, CategoryID, Price)
VALUES 
(N'Coca Cola', 1, 15000),
(N'Trà Đào', 1, 18000),
(N'Nước suối', 1, 10000);

-- Đồ ăn vặt
INSERT INTO Food (Name, CategoryID, Price)
VALUES 
(N'Khoai tây chiên', 2, 25000),
(N'Xúc xích', 2, 20000),
(N'Bắp rang', 2, 22000);

-- Trái cây
INSERT INTO Food (Name, CategoryID, Price)
VALUES 
(N'Dưa hấu', 3, 30000),
(N'Ổi', 3, 25000);

-- Chỉ tạo BillID 1-4 để BillInfo khớp BillID
INSERT INTO Bill (TableID, Status)
VALUES 
(1, 0), -- Bàn 1 chưa thanh toán
(2, 0), -- Bàn 2 chưa thanh toán
(3, 1), -- Bàn 3 đã thanh toán
(4, 1); -- Bàn 4 đã thanh toán

select * from Bill;

-- Hóa đơn 1 (Bàn 1) gọi 2 Coca, 1 khoai tây chiên
INSERT INTO BillInfo (BillID, FoodID, Amount) VALUES (1, 1, 2);
INSERT INTO BillInfo (BillID, FoodID, Amount) VALUES (1, 4, 1);

-- Hóa đơn 2 (Bàn 2) gọi 1 trà đào, 2 xúc xích, 1 dưa hấu
INSERT INTO BillInfo (BillID, FoodID, Amount) VALUES (2, 2, 1);
INSERT INTO BillInfo (BillID, FoodID, Amount) VALUES (2, 5, 2);
INSERT INTO BillInfo (BillID, FoodID, Amount) VALUES (2, 7, 1);

-- Hóa đơn 3 (Bàn 3) gọi 3 nước suối, 1 bắp rang
INSERT INTO BillInfo (BillID, FoodID, Amount) VALUES (3, 3, 3);
INSERT INTO BillInfo (BillID, FoodID, Amount) VALUES (3, 6, 1);

-- Hóa đơn 4 (Bàn 4) gọi 2 coca, 1 ổi
INSERT INTO BillInfo (BillID, FoodID, Amount) VALUES (4, 1, 2);
INSERT INTO BillInfo (BillID, FoodID, Amount) VALUES (4, 8, 1);

CREATE PROC dbo.USP_Login
@UserName NVARCHAR(100), @Password NVARCHAR(100)
AS
    SELECT *
    FROM dbo.Account
    WHERE UserName = @UserName AND Password = @Password
GO

CREATE PROC USP_GetAccountByUserName
@UserName VARCHAR(100)
AS
    SELECT *
    FROM dbo.Account
    WHERE UserName = @UserName
GO

EXEC USP_GetAccountByUserName 'admin';

CREATE PROC USP_GetAllAccount
AS
    SELECT UserName, DisplayName, TypeID FROM dbo.Account
GO

CREATE PROC USP_InsertAccount
@UserName VARCHAR(100), @DisplayName NVARCHAR(100), @TypeID INT
AS
    INSERT dbo.Account ( UserName, DisplayName, TypeID, Password )
    VALUES  ( @UserName, @DisplayName, @TypeID, '123' )
GO

CREATE PROC USP_ResetPassword
@UserName VARCHAR(100)
AS
    UPDATE dbo.Account SET Password = '0' WHERE UserName = @UserName
GO

CREATE PROC USP_UpdateAccount
@UserName VARCHAR(100), @DisplayName NVARCHAR(100), @Password VARCHAR(100), @NewPassword VARCHAR(100)
AS
BEGIN
    DECLARE @isRightPass INT = 0
    SELECT @isRightPass = COUNT(*) FROM Account WHERE UserName = @UserName and Password = @Password
    IF (@isRightPass = 1)
    BEGIN
        IF (@NewPassword IS NULL or @NewPassword = '')
            UPDATE Account SET DisplayName = @DisplayName WHERE UserName = @UserName
        ELSE
            UPDATE Account SET DisplayName = @DisplayName, Password = @NewPassword WHERE UserName = @UserName
    END
END
GO

CREATE PROC USP_DeleteAccount
@UserName VARCHAR(100)
AS
    DELETE dbo.Account WHERE UserName = @UserName
GO

CREATE PROC USP_SearchAccountByUserName
@UserName VARCHAR(100)
AS
    SELECT * FROM dbo.Account WHERE dbo.fuConvertToUnsign1(UserName) LIKE N'%' + dbo.fuConvertToUnsign1(@UserName) + '%'
GO
-- end Account's procedure
-- Food's procedure
CREATE PROC USP_GetAllFood
AS
    SELECT * FROM dbo.Food
GO

CREATE PROC USP_GetListFoodByCategoryID
@CategoryID INT
AS
    SELECT ID, Name, Price FROM dbo.Food WHERE CategoryID = @CategoryID
GO

CREATE PROC USP_InsertFood
@Name NVARCHAR(100), @CategoryID INT, @Price INT
AS
    INSERT dbo.Food( Name, CategoryID, Price )
    VALUES  ( @Name, @CategoryID, @Price )
GO

CREATE PROC USP_UpdateFood
@ID INT, @Name NVARCHAR(100), @CategoryID INT, @Price INT
AS
    DECLARE @BillIDCount INT = 0
    SELECT @BillIDCount = COUNT(*) FROM Bill AS b, BillInfo AS bi WHERE FoodID = @ID AND b.ID = bi.BillID AND b.Status = 0
    IF (@BillIDCount = 0)
        UPDATE dbo.Food SET Name = @Name, CategoryID = @CategoryID, Price = @Price WHERE ID = @ID
GO

CREATE PROC USP_DeleteFood
@FoodID INT
AS
BEGIN
    DECLARE @BillIDCount INT = 0
    SELECT @BillIDCount = COUNT(*) FROM Bill AS b, BillInfo AS bi WHERE FoodID = @FoodID AND b.ID = bi.BillID AND b.Status = 0
    IF (@BillIDCount = 0)
    BEGIN
        DELETE BillInfo WHERE FoodID = @FoodID
        DELETE Food WHERE ID = @FoodID
    END
END
GO

CREATE PROC USP_SearchFoodByName
@Name NVARCHAR(100)
AS
    SELECT * FROM dbo.Food WHERE dbo.fuConvertToUnsign1(Name) LIKE N'%' + dbo.fuConvertToUnsign1(@Name) + '%'
GO
-- end Food's procedure
-- Bill's procedure

CREATE PROC USP_InsertBill
@TableID INT
AS
    INSERT dbo.Bill (CheckIn, TableID, Status, Discount) VALUES (GETDATE(), @TableID, 0, 0)
GO

CREATE PROC GetUnCheckBillIDByTableID
@TableID INT
AS
    SELECT * FROM dbo.Bill WHERE TableID = @TableID AND Status = 0
GO

CREATE PROC USP_GetListBillByDay
@FromDate DATE, @ToDate DATE
AS
BEGIN
    SELECT b.ID, t.Name, CheckIn, discount, TotalPrice
    FROM Bill AS b, BilliardTable AS t
    WHERE CheckIn >= @FromDate AND CheckIn <= @ToDate AND b.status = 1 AND t.ID = b.TableID
END
GO

CREATE PROC USP_DeleteBill
@ID INT
AS
    DELETE dbo.Bill WHERE ID = @ID
GO

CREATE PROC USP_GetMaxBillID
AS
    SELECT MAX(ID) FROM dbo.Bill
GO
-- end Bill's procedure
-- Bill Info's procedure
CREATE PROC USP_InsertBillInfo
@BillID int, @FoodID int, @Amount int
as
begin
    declare @isExistBillInfo int
    declare @foodAmount int = 1
    select @isExistBillInfo = ID, @foodAmount = Amount
    from BillInfo
    where BillID = @BillID and FoodID = @FoodID
    if (@isExistBillInfo > 0)
    begin
        declare @newAmount int = @foodAmount + @Amount
        if (@newAmount > 0)
            update BillInfo set Amount = @newAmount where FoodID = @FoodID and BillID = @BillID
        ELSE IF (@newAmount <= 0)
            delete BillInfo where BillID = @BillID and FoodID = @FoodID
    end
    else
        IF (@Amount > 0)
            INSERT into BillInfo (BillID, FoodID, Amount) values (@BillID, @FoodID, @Amount)
end
GO

CREATE PROC USP_DeleteBillInfoByBillID
@BillID INT
AS
    DELETE dbo.BillInfo WHERE BillID = @BillID
GO
-- end Bill's procedure

-- Trigger cập nhật trạng thái bàn khi thêm BillInfo
create trigger UTG_UpdateBillInfo
on BillInfo for insert
as
begin
    declare @billID int
    select @billID = BillID from inserted
    declare @tableID int
    select @tableID = TableID from Bill where ID = @billID and status = 0
    declare @count int
    select @count = COUNT(*) from BillInfo where BillID = @billID
    if (@count > 0)
        update BilliardTable set Status = N'Có người' where ID = @tableID
    else
        update BilliardTable set Status = N'Trống' where ID = @tableID
end
go

CREATE TRIGGER UTG_UpdateBill
on Bill for update
as
begin
    declare @billID int
    select @billID = ID from inserted
    declare @tableID int
    select @tableID = TableID from Bill where ID = @billID
    declare @amount int = 0
    select @amount = COUNT(*) from Bill where TableID = @tableID and Status = 0
    if (@amount = 0)
        update BilliardTable set Status = N'Trống' where ID = @tableID
end
GO

create trigger UTG_DeleteBillInfo
on BillInfo for delete
as
begin
    declare @IDBillInfo int
    declare @BillID int
    select @IDBillInfo = id, @BillID = BillID from deleted
    declare @TableID int
    select @TableID = TableID from Bill where ID = @BillID
    declare @count int = 0
    select @count = COUNT(*) from BillInfo as bi, Bill as b where b.ID = bi.BillID and b.ID = @BillID and b.status = 0
    if (@count = 0)
        update BilliardTable set Status = N'Trống' where ID = @TableID
end
go

CREATE FUNCTION [dbo].[fuConvertToUnsign1] ( @strInput NVARCHAR(4000) ) RETURNS NVARCHAR(4000)
AS
BEGIN
    IF @strInput IS NULL RETURN @strInput
    IF @strInput = '' RETURN @strInput
    DECLARE @RT NVARCHAR(4000)
    DECLARE @SIGN_CHARS NCHAR(136)
    DECLARE @UNSIGN_CHARS NCHAR (136)
    SET @SIGN_CHARS = N'ăâđêôơưàảãạáằẳẵặắầẩẫậấèẻẽẹéềểễệế ìỉĩịíòỏõọóồổỗộốờởỡợớùủũụúừửữựứỳỷỹỵý ĂÂĐÊÔƠƯÀẢÃẠÁẰẲẴẶẮẦẨẪẬẤÈẺẼẸÉỀỂỄỆẾÌỈĨỊÍ ÒỎÕỌÓỒỔỖỘỐỜỞỠỢỚÙỦŨỤÚỪỬỮỰỨỲỶỸỴÝ' + NCHAR(272)+ NCHAR(208)
    SET @UNSIGN_CHARS = N'aadeoouaaaaaaaaaaaaaaaeeeeeeeeee iiiiiooooooooooooooouuuuuuuuuuyyyyy AADEOOUAAAAAAAAAAAAAAAEEEEEEEEEEIIIII OOOOOOOOOOOOOOOUUUUUUUUUUYYYYYDD'
    DECLARE @COUNTER int
    DECLARE @COUNTER1 int
    SET @COUNTER = 1
    WHILE (@COUNTER <= LEN(@strInput))
    BEGIN
        SET @COUNTER1 = 1
        WHILE (@COUNTER1 <= LEN(@SIGN_CHARS) + 1)
            BEGIN
                IF UNICODE(SUBSTRING(@SIGN_CHARS, @COUNTER1,1)) = UNICODE(SUBSTRING(@strInput,@COUNTER ,1) )
                BEGIN
                    IF @COUNTER=1
                        SET @strInput = SUBSTRING(@UNSIGN_CHARS, @COUNTER1,1) + SUBSTRING(@strInput, @COUNTER+1,LEN(@strInput)-1)
                    ELSE
                        SET @strInput = SUBSTRING(@strInput, 1, @COUNTER-1) +SUBSTRING(@UNSIGN_CHARS, @COUNTER1,1) + SUBSTRING(@strInput, @COUNTER+1,LEN(@strInput)- @COUNTER)
                    BREAK
                END
                    SET @COUNTER1 = @COUNTER1 +1
            END
            SET @COUNTER = @COUNTER +1
    END
    SET @strInput = replace(@strInput,' ','-')
    RETURN @strInput
END
GO

create proc USP_GetListBillByDayForReport
@FromDate Date, @ToDate Date
as
begin
    select t.Name, CheckIn, Discount, TotalPrice
    from Bill as b, BilliardTable as t
    where CheckIn >= @FromDate and CheckIn <= @ToDate and b.status = 1 and t.ID = b.TableID
end
go

create proc USP_DeleteCategory
@ID int
as
begin
    declare @FoodCount int = 0
    select @FoodCount = COUNT(*) from Food where CategoryID = @ID
    if (@FoodCount = 0)
        delete CategoryFood where ID = @ID
end
go

create proc USP_DeleteTableFood
@ID int
as begin
    declare @count int = 0
    select @count = COUNT(*) from BilliardTable where ID = @ID and Status = N'Trống'
    if (@count <> 0)
    begin
        declare @BillID int
        select @BillID = b.ID from Bill as b, BilliardTable as t where b.TableID = t.ID
        delete BillInfo where BillID = @BillID
        delete Bill where ID = @BillID
        delete BilliardTable where ID = @ID
    end
end
GO

CREATE PROC USP_SwitchTable
@TableID1 INT, @TableID2 INT
AS
BEGIN
    DECLARE @isTable1Null INT = 0
    DECLARE @isTable2Null INT = 0
    SELECT @isTable1Null = ID FROM dbo.Bill WHERE TableID = @TableID1 AND Status = 0
    SELECT @isTable2Null = ID FROM dbo.Bill WHERE TableID = @TableID2 AND Status = 0
    IF (@isTable1Null = 0 AND @isTable2Null > 0)
        BEGIN
            UPDATE dbo.Bill SET TableID = @TableID1 WHERE ID = @isTable2Null
            UPDATE dbo.BilliardTable SET Status = N'Có người' WHERE ID = @TableID1
            UPDATE dbo.BilliardTable SET Status = N'Trống' WHERE ID = @TableID2
        END
    ELSE IF (@isTable1Null > 0 AND @isTable2Null = 0)
        BEGIN
            UPDATE dbo.Bill SET TableID = @TableID2 WHERE Status = 0 AND ID = @isTable1Null
            UPDATE dbo.BilliardTable SET Status = N'Có người' WHERE ID = @TableID2
            UPDATE dbo.BilliardTable SET Status = N'Trống' WHERE ID = @TableID1
        END
    ELSE IF (@isTable1Null > 0 AND @isTable2Null > 0)
        BEGIN
            UPDATE dbo.Bill SET TableID = @TableID2 WHERE ID = @isTable1Null
            UPDATE dbo.Bill SET TableID = @TableID1 WHERE ID = @isTable2Null
        END
END
GO

CREATE PROC USP_GetAllTable
AS
    SELECT ID, Name FROM dbo.BilliardTable
GO

CREATE PROC USP_GetListTable
AS
    SELECT * FROM dbo.BilliardTable
GO

CREATE PROC USP_InsertTable
@Name NVARCHAR(100)
AS
    INSERT dbo.BilliardTable ( Name )
    VALUES  ( @Name )
GO

CREATE PROC USP_UpdateTable
@ID INT, @Name NVARCHAR(100)
AS
    UPDATE dbo.BilliardTable SET Name = @Name WHERE ID = @ID
GO

CREATE PROC USP_GetListTempBillByTableID
@TableID INT
AS
    SELECT f.Name, bi.Amount, f.Price, f.Price * bi.Amount AS totalPrice
    FROM dbo.BillInfo bi, dbo.Bill b, dbo.Food f
    WHERE b.ID = bi.BillID AND bi.FoodID = f.ID AND b.Status = 0 AND b.TableID = @TableID
GO

CREATE PROC USP_MergeTable
@TableID1 INT, @TableID2 INT
AS
    BEGIN
        DECLARE @UnCheckBillID1 INT = -1
        DECLARE @UnCheckBillID2 INT = -1
        SELECT @UnCheckBillID1 = ID FROM dbo.Bill WHERE TableID = @TableID1 AND Status = 0
        SELECT @UnCheckBillID2 = ID FROM dbo.Bill WHERE TableID = @TableID2 AND Status = 0
        IF (@UnCheckBillID1 != -1 AND @UnCheckBillID2 != -1)
            BEGIN
                DECLARE @BillInfoID INT
                SELECT @BillInfoID = ID FROM dbo.BillInfo WHERE BillID = @UnCheckBillID1
                UPDATE dbo.BillInfo SET BillID = @UnCheckBillID2 WHERE ID = @BillInfoID
                DELETE dbo.Bill WHERE ID = @UnCheckBillID1
                UPDATE dbo.BilliardTable SET STATUS = N'Trống' WHERE ID = @TableID1
            END
    END
GO
