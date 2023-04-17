
CREATE DATABASE UniversityDepartment 
GO
USE UniversityDepartment

--Создание таблиц

CREATE TABLE Major
	(MajorID int PRIMARY KEY IDENTITY(1,1) NOT NULL,
	Name nvarchar(max) NOT NULL)
GO

CREATE TABLE Subject
	(SubjectID int PRIMARY KEY IDENTITY(1,1) NOT NULL,
	Name nvarchar(max) NOT NULL,
	ControlForm nvarchar(25) NOT NULL)
GO

CREATE TABLE Room
	(RoomID int PRIMARY KEY IDENTITY(1,1) NOT NULL,
	Number int NOT NULL,
	Building nvarchar(10) NOT NULL)
GO

CREATE TABLE Post
	(PostID int PRIMARY KEY IDENTITY(1,1) NOT NULL,
	Name nvarchar(50) NOT NULL)
GO

CREATE TABLE Staff
	(StaffID int PRIMARY KEY IDENTITY(1,1) NOT NULL,
    FirstName nvarchar(50) NOT NULL,
    LastName nvarchar(50) NOT NULL,
    Pathronymic nvarchar(50) NULL,
	Phone nvarchar(25) NULL,
	Email nvarchar(50) NULL,
	EduDegree nvarchar(max) NOT NULL,
	RoomID int NULL,
	FOREIGN KEY (RoomID) REFERENCES Room (RoomID))
GO

CREATE TABLE StaffPost
	(StaffPostID int PRIMARY KEY IDENTITY(1,1) NOT NULL,
	StaffID int	NOT NULL,
	PostID int NOT NULL,
	FOREIGN KEY (StaffID) REFERENCES Staff (StaffID),
	FOREIGN KEY (PostID) REFERENCES Post (PostID))
GO

CREATE TABLE GradStudent
	(GradStudentID int PRIMARY KEY IDENTITY(1,1) NOT NULL,
    FirstName nvarchar(50) NOT NULL,
    LastName nvarchar(50) NOT NULL,
    Pathronymic nvarchar(50) NULL,
	ScientificAdviserID int NOT NULL,
	ResearchTopic nvarchar(max) NOT NULL,
	FOREIGN KEY (ScientificAdviserID) REFERENCES Staff (StaffID))
GO

CREATE TABLE Groupp
	(GroupID int PRIMARY KEY IDENTITY(1,1) NOT NULL,
	Number nvarchar(25) NOT NULL,
	Course int NOT NULL,
	EducationType nvarchar(50) NOT NULL,
	MajorID int NOT NULL,
	TutorID int NOT NULL,
	FOREIGN KEY (MajorID) REFERENCES Major (MajorID),
	FOREIGN KEY (TutorID) REFERENCES Staff (StaffID))
GO

CREATE TABLE Student
    (StudentID int PRIMARY KEY IDENTITY(1,1) NOT NULL,
    FirstName nvarchar(50) NOT NULL,
    LastName nvarchar(50) NOT NULL,
    Pathronymic nvarchar(50) NULL,
	BirthDate date NOT NULL,
	GroupID int NOT NULL,
	FinancingForm nvarchar(25) NOT NULL,
	Phone nvarchar(25) NULL,
	Email nvarchar(50) NULL,
	FOREIGN KEY (GroupID) REFERENCES Groupp (GroupID))
GO

CREATE TABLE DiplomaStudent
	(DiplomaStudentID int PRIMARY KEY IDENTITY(1,1) NOT NULL,
	StudentID int NOT NULL,
	ScientificAdviserID int NOT NULL,
	ResearchTopic nvarchar(max) NOT NULL,
	FOREIGN KEY (ScientificAdviserID) REFERENCES Staff (StaffID),
	FOREIGN KEY (StudentID) REFERENCES Student (StudentID))
GO

CREATE TABLE Schedule
	(ClassID int PRIMARY KEY IDENTITY(1,1) NOT NULL,
	ClassNumber int NOT NULL,
	ClassDate datetime NOT NULL,
	WeekType nvarchar(25) NOT NULL,
	Semester int NOT NULL,
	ClassType nvarchar(25) NOT NULL,
	SubjectID int NOT NULL,
	GroupID int NOT NULL,
	RoomID int NULL,
	TeacherID int NOT NULL,
	FOREIGN KEY (SubjectID) REFERENCES Subject (SubjectID),
	FOREIGN KEY (GroupID) REFERENCES Groupp (GroupID),
	FOREIGN KEY (RoomID) REFERENCES Room (RoomID),
	FOREIGN KEY (TeacherID) REFERENCES Staff (StaffID))
GO

--Создание представлений

CREATE VIEW StudyPlan AS
SELECT DISTINCT Course AS N'Course', (Course-1)*2+Semester AS N'Semester',  Name AS N'Subject'
FROM Schedule AS sc 
JOIN Groupp AS gr ON sc.GroupID = gr.GroupID 
JOIN Subject as sub ON sc.SubjectID = sub.SubjectID
GO

CREATE VIEW ClassSchedule 
AS
SELECT gr.Number AS 'GroupNumber', CAST(ClassDate AS date) AS 'Date',CAST(ClassDate AS time(0)) AS 'StartTime', 
ClassNumber, Name AS 'Subject', ClassType, CONCAT(st.FirstName,' ',LEFT(st.LastName,1),'.',LEFT(st.Pathronymic,1),'.') AS 'Teacher', 
CONCAT(Building,'-',r.Number) AS N'Room'
FROM Schedule AS sc JOIN Subject AS sub ON sc.SubjectID = sub.SubjectID
JOIN Groupp AS gr ON sc.GroupID = gr.GroupID
LEFT JOIN Room AS r ON sc.RoomID=r.RoomID
LEFT JOIN Staff AS st ON sc.TeacherID = st.StaffID
GO

CREATE VIEW vDiplomaStudentInfo AS
SELECT CONCAT(s.FirstName,' ',s.LastName,' ',s.Pathronymic) AS 'DiplomaStudent', Number AS 'Group', 
CONCAT(st.FirstName,' ',LEFT(st.LastName,1),'.',LEFT(st.Pathronymic,1),'.') AS 'ScientificAdviser', ResearchTopic
FROM DiplomaStudent AS ds
JOIN Student AS s ON ds.StudentID = s.StudentID
JOIN Groupp AS g ON s.GroupID = g.GroupID
JOIN Staff as st ON st.StaffID = ds.ScientificAdviserID
GO

CREATE VIEW vGradStudentInfo AS
SELECT CONCAT(gs.FirstName,' ',gs.LastName,' ',gs.Pathronymic) AS 'GradStudent',
CONCAT(st.FirstName,' ',LEFT(st.LastName,1),'.',LEFT(st.Pathronymic,1),'.') AS 'ScientificAdviser',ResearchTopic
FROM GradStudent AS gs 
JOIN Staff AS st ON st.StaffID = gs.ScientificAdviserID
GO

CREATE OR ALTER VIEW vStaffInfo AS
SELECT CONCAT(FirstName,' ',LastName,' ',Pathronymic) AS 'Name', Phone, Email,CONCAT(Building,'-',Number) AS 'Room', p.Name AS 'Post'
			FROM Staff AS st JOIN StaffPost AS stp ON st.StaffID=stp.StaffID
			JOIN Post AS p ON stp.PostID = p.PostID
			LEFT JOIN Room AS r ON r.RoomID = st.RoomID
GO

CREATE VIEW vScientificFieldsEmployees AS
SELECT DISTINCT s.Name AS 'Subject', CONCAT(FirstName,' ',LastName,' ',Pathronymic) AS Name FROM Schedule 
JOIN Staff ON Schedule.TeacherID = Staff.StaffID
JOIN Subject AS s ON s.SubjectID = Schedule.SubjectID
GO

CREATE OR ALTER VIEW vStudentInfo
AS
SELECT CONCAT(FirstName, ' ', LastName, ' ', Pathronymic) AS 'Name', BirthDate, Number as 'Group', FinancingForm, Phone, Email
FROM Student AS s
JOIN Groupp AS g ON g.GroupID = s.GroupID

--Создание функций

CREATE OR ALTER FUNCTION StudentSchedule(@group nvarchar(25), @day nvarchar(25))
RETURNS TABLE
AS
	RETURN(SELECT ClassNumber,StartTime,Subject,ClassType,Teacher,Room
		FROM ClassSchedule AS cs WHERE GroupNumber = @group AND CONVERT(nvarchar(25), Date, 105) = @day)
GO
CREATE FUNCTION TeacherSchedule(@name nvarchar(55), @day nvarchar(25))
RETURNS TABLE
AS
	RETURN(SELECT ClassNumber,StartTime,Subject,ClassType,GroupNumber,Room FROM ClassSchedule
WHERE Teacher = @name AND @day = CONVERT(nvarchar(25), Date, 105))
GO

CREATE FUNCTION SemesterStudyPlan(@semester int)
RETURNS TABLE
AS
	RETURN(SELECT * FROM StudyPlan WHERE Semester = @semester)
GO

CREATE FUNCTION StudentInfo(@Id int)
RETURNS TABLE
AS
	RETURN(SELECT CONCAT(FirstName,' ',LastName,' ',Pathronymic) AS 'Name', BirthDate, Number, FinancingForm, Phone, Email 
			FROM Student JOIN Groupp ON Student.GroupID = Groupp.GroupID WHERE StudentID = @Id)
GO

CREATE FUNCTION StaffInfo(@Id int)
RETURNS TABLE
AS
	RETURN(SELECT CONCAT(FirstName,' ',LastName,' ',Pathronymic) AS 'Name', Name AS 'Post', Phone, Email, 
			CONCAT(Building,'-',Number) AS 'Room', 
			(SELECT COUNT(1) FROM Groupp WHERE TutorID = @Id GROUP BY TutorID) AS 'TutoringCroupsAmount',
			(SELECT COUNT(1) FROM GradStudent Where ScientificAdviserID = @Id GROUP BY ScientificAdviserID) AS 'GradStudentAmount',
			(SELECT COUNT(3) FROM DiplomaStudent Where ScientificAdviserID = @Id GROUP BY ScientificAdviserID) AS 'DiplomaStudentAmount'
			FROM Staff AS st JOIN StaffPost AS stp ON st.StaffID=stp.StaffID
			JOIN Post AS p ON stp.PostID = p.PostID
			LEFT JOIN Room AS r ON r.RoomID = st.RoomID
			WHERE st.StaffID = @Id)
GO

CREATE FUNCTION ClassAmount (@period_type NVARCHAR(25), @period NVARCHAR(25))
RETURNS TABLE
AS
RETURN
(
	SELECT CONCAT(st.FirstName,' ',LEFT(st.LastName,1),'.',LEFT(st.Pathronymic,1),'.') AS 'Name', COUNT(1) AS 'ClassAmount'
	FROM Schedule AS sc
	JOIN Staff AS st ON sc.TeacherID = st.StaffID
	WHERE @period = CASE @period_type
					WHEN N'день' THEN CONVERT(Nvarchar, CONVERT(DATE, ClassDate))
					WHEN N'месяц' THEN CAST(DATEPART(mm,ClassDate) AS nvarchar)
					WHEN N'семестр' THEN CAST(Semester AS nvarchar)
					WHEN N'год' THEN CAST(DATEPART(yyyy, ClassDate) AS nvarchar)
					END
	GROUP BY CONCAT(st.FirstName,' ',LEFT(st.LastName,1),'.',LEFT(st.Pathronymic,1),'.')
)
GO

CREATE OR ALTER FUNCTION TutorName (@group NVARCHAR(25))
RETURNS NVARCHAR(50)
AS
BEGIN
	DECLARE @res NVARCHAR(50) = 
	(SELECT CONCAT(FirstName, ' ', LastName, ' ', Pathronymic) 
	FROM Groupp AS g 
	JOIN Staff AS s ON g.TutorID = s.StaffID 
	WHERE Number = @group)
	RETURN @res
END
GO

--Создание процедур

CREATE OR ALTER PROCEDURE StaffSearch 
	@name_part NVARCHAR(50) 
AS
	SELECT DISTINCT Name, Phone, Email, Room 
	FROM vStaffInfo 
	WHERE Name LIKE ('%'+@name_part+'%')
GO

CREATE OR ALTER PROCEDURE StudentSearch 
	@name_part NVARCHAR(50) 
AS
	SELECT * FROM vStudentInfo 
	WHERE Name LIKE ('%'+@name_part+'%')
GO

CREATE OR ALTER PROCEDURE TodaySchedule
	@user NVARCHAR(50)
AS
	DECLARE @date date = CONVERT(date, GETDATE())
	IF EXISTS(SELECT GroupNumber, ClassNumber, StartTime, Subject, ClassType, Room, Teacher FROM ClassSchedule WHERE @user IN (GroupNumber, Teacher) AND Date = @date)
		SELECT GroupNumber, ClassNumber, StartTime, Subject, ClassType, Room, Teacher 
		FROM ClassSchedule 
		WHERE @user IN (GroupNumber, Teacher) AND Date = @date
		ORDER BY ClassNumber
	ELSE 
		PRINT 'Schedule is not found'
GO

CREATE OR ALTER PROCEDURE AddStudent
	@fname NVARCHAR(50),
	@lname NVARCHAR(50),
	@pathronymic NVARCHAR(50),
	@birthdate DATE,
	@group INT,
	@finform NVARCHAR(25),
	@phone NVARCHAR(25),
	@email NVARCHAR(50)
AS
	INSERT INTO Student 
	VALUES(@fname, @lname, @pathronymic, @birthdate, @group, @finform, @phone, @email)
GO

CREATE OR ALTER PROCEDURE AddStaff
	@fname NVARCHAR(50),
	@lname NVARCHAR(50),
	@pathronymic NVARCHAR(50),
	@phone NVARCHAR(25),
	@email NVARCHAR(50),
	@edudegree NVARCHAR(max),
	@roomId int
AS
	INSERT INTO Staff
	VALUES(@fname, @lname, @pathronymic, @phone, @email, @edudegree, @roomId)
GO

CREATE OR ALTER PROCEDURE AddClass
	@number INT,
	@date DATETIME,
	@week NVARCHAR(25),
	@sem INT,
	@type NVARCHAR(25),
	@subId INT,
	@groupId INT,
	@roomId INT,
	@teacherId INT
AS
	INSERT INTO Schedule
	VALUES(@number, @date, @week, @sem, @type, @subId, @groupId, @roomId, @teacherId)
GO

--Создание триггеров

CREATE OR ALTER TRIGGER DS_ScientificAdviserCheck
ON DiplomaStudent
AFTER INSERT, UPDATE
AS
BEGIN
	DECLARE @edudegree NVARCHAR(MAX) = (SELECT EduDegree FROM inserted JOIN Staff ON inserted.ScientificAdviserID = Staff.StaffID WHERE StaffID = inserted.ScientificAdviserID)
	IF @edudegree NOT LIKE N'Кандидат % наук' AND @edudegree NOT LIKE N'Доктор % наук'
	BEGIN
		ROLLBACK;
		THROW 50001, N'Ученая степень сотрудника не соответствует требуемой(Кадидат или доктор наук)', 0
	END
END
GO

ALTER TABLE DiplomaStudent ENABLE TRIGGER DS_ScientificAdviserCheck
GO

CREATE OR ALTER TRIGGER GS_ScientificAdviserCheck
ON GradStudent
AFTER INSERT, UPDATE
AS
BEGIN
	DECLARE @edudegree NVARCHAR(MAX) = (SELECT EduDegree FROM inserted JOIN Staff ON inserted.ScientificAdviserID = Staff.StaffID WHERE StaffID = inserted.ScientificAdviserID)
	IF @edudegree NOT LIKE N'Кандидат % наук' AND @edudegree NOT LIKE N'Доктор % наук'
	BEGIN
		ROLLBACK;
		THROW 50001, N'Ученая степень сотрудника не соответствует требуемой(Кадидат или доктор наук)', 0
	END
END
GO


ALTER TABLE GradStudent ENABLE TRIGGER GS_ScientificAdviserCheck
GO

CREATE OR ALTER TRIGGER StaffPostDelete
ON Staff 
AFTER DELETE
AS
BEGIN
	DECLARE @staffId INT = (SELECT StaffID FROM deleted)
	DELETE FROM StaffPost WHERE StaffPost.StaffID = @staffId
END
GO

ALTER TABLE Staff ENABLE TRIGGER staffPostDelete
GO

CREATE OR ALTER TRIGGER ScheduleUpdateTrigger
ON Schedule
AFTER INSERT, UPDATE
AS
	IF EXISTS(SELECT * FROM inserted WHERE SubjectID NOT IN (SELECT SubjectID FROM Subject) 
	OR GroupID NOT IN (SELECT GroupID FROM Groupp) OR RoomID NOT IN (SELECT RoomID FROM Room)
	OR TeacherID NOT IN (SELECT StaffID FROM Staff))
	BEGIN
		ROLLBACK;
		THROW 50001, N'Ошибка: попытка нарушения ссылочной целостности между таблицей Schedule и таблицами Staff, Subject, Groupp, Room. Транзакция отменена.', 0
	END
GO

ALTER TABLE Schedule ENABLE TRIGGER ScheduleUpdateTrigger
GO

CREATE OR ALTER TRIGGER RoomUpdateTrigger
ON Room
AFTER INSERT, UPDATE
AS
	IF (SELECT Building FROM inserted) NOT IN (N'А', N'Б', N'В', N'Г', N'Д', N'К', N'Л')
	BEGIN
		ROLLBACK;
		THROW 50001, N'Ошибка: введены недопустимые данные. Транзакция отменена', 0
	END
GO

ALTER TABLE Room ENABLE TRIGGER RoomUpdateTrigger
GO

CREATE OR ALTER TRIGGER MajorSafety
ON Major
INSTEAD OF DELETE, INSERT, UPDATE
AS
	PRINT N'Транзакция отменена. Чтобы совершить изменения отключите триггер MajorSafety.'
	ROLLBACK;
GO

ALTER TABLE Major ENABLE TRIGGER MajorSafety
GO

--Демонстрация работы БД
--1
SELECT * FROM SemesterStudyPlan(5)
--2
SELECT * FROM StudentSchedule(N'БИВТ-20-2','28-11-2022')
ORDER BY ClassNumber

SELECT * FROM TeacherSchedule(N'Микитенко И.И.','28-11-2022')
ORDER BY ClassNumber
--3
SELECT * FROM StudentInfo(5)
SELECT * FROM StaffInfo(4)
--4
EXEC AddStudent N'Горченко', N'Тимур', N'Рудольфович', '2002-12-03', 3, N'Коммерция', '+79890506745', 'm2153248@edu.misis.ru'
--5
EXEC TodaySchedule N'БИВТ-21-6'
EXEC TodaySchedule N'Валова А.А.'
--6
EXECUTE StaffSearch N'Сергей Эдуардович'
EXECUTE StudentSearch N'Само'
--7
SELECT * FROM ClassAmount(N'день','2022-11-28')
SELECT * FROM ClassAmount(N'месяц','11')
SELECT * FROM ClassAmount(N'год','2022')



--Тестирование
--SELECT * FROM ClassSchedule ORDER BY GroupNumber, Date
--SELECT * FROM StudyPlan
--SELECT * FROM TeacherClassAmount
--SELECT * FROM vDiplomaStudentInfo
--SELECT * FROM vGradStudentInfo
--SELECT * FROM vScientificFieldsEmployees
--SELECT * FROM SemesterStudyPlan(1)
--SELECT * FROM StaffInfo(10)
--SELECT * FROM StudentInfo(4)
--SELECT * FROM ClassAmount(N'семестр','2')
----
--DECLARE @res NVARCHAR(50)
--EXEC @res = TutorName N'БИВТ-21-8'
--PRINT @res
----
--EXECUTE StaffSearch N'Сергей'
--EXECUTE StudentSearch N'Ан'
--EXEC TodaySchedule N'БИВТ-21-6'
--EXEC AddStudent N'Рычков', N'Борис', N'Анатольевич', '2004-01-19', 1, N'Бюджет', '+79154343544', 'm2133876@edu.misis.ru'
--EXEC AddStaff N'Рзазаде', N'Ульви', N'Азар оглы', '+74992302434', 'rzazade.u@misis.ru', N'Высшее образование - магистратура', NULL
--EXEC AddClass 3, '2022-12-19 12:40:00', N'Нечетная', 1, N'Практическое занятие', 49, 1, NULL, NULL