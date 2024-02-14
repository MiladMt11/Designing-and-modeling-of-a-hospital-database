
# --> QUERIES <-- #
SELECT Department.Dept_Name as Department, SUM(Service_Provided.Serv_No) as Services_provided
FROM Department 
	JOIN Device ON Department.Dept_ID = Device.Dept_ID 
	JOIN Service ON Device.Dev_ID = Service.Dev_ID 
	JOIN Service_Provided ON Service.Serv_ID = Service_Provided.Serv_ID 
GROUP BY Department.Dept_ID, Department.Dept_Name;

SELECT Pat_ID, Pat_F_Name, Pat_L_Name, Serv_ID, Serv_Name, ROUND(Serv_Price*Serv_No, 2) AS Tot_Serv_Price
FROM (Patient NATURAL JOIN Service_Provided) 
	JOIN Service USING (Serv_ID)
	ORDER BY Tot_Serv_Price ASC;

SELECT Drug_name AS 'Drug name',Drug_Price AS 'Price' FROM Drug WHERE Drug_Type = 'Pain reliever';

SELECT CONCAT(Doc_F_Name, ' ', Doc_L_Name) AS 'Doctor',Speciality,Shift FROM DOCTOR ORDER BY Speciality; 

SELECT CONCAT(Pat_F_Name, ' ', Pat_L_Name) AS 'Patient Name',Bed_ID, End_Date AS 'Has bed until'
	FROM Patient
	JOIN Bed_Occupation ON Patient.Pat_ID = Bed_Occupation.Pat_ID;
    

# --> Functions <-- #
DROP FUNCTION IF EXISTS CurrentShift;
DELIMITER //
CREATE FUNCTION CurrentShift(timeOfDay DATETIME) RETURNS VARCHAR(20)
BEGIN
    IF HOUR(timeOfDay) >= 6 AND HOUR(timeOfDay) < 12 THEN
        RETURN 'Morning';
    ELSEIF HOUR(timeOfDay) >= 12 AND HOUR(timeOfDay) < 18 THEN
        RETURN 'Noon';
    ELSEIF HOUR(timeOfDay) >= 18 AND HOUR(timeOfDay) < 24 THEN
        RETURN 'Evening';
	ELSEIF HOUR(timeOfDay) >= 0 AND HOUR(timeOfDay) < 6 THEN
		RETURN 'Night';
    ELSE
        RETURN 'Undefined';
    END IF;
END//

DELIMITER ;

SELECT NOW() AS 'Current time',CurrentShift(now()) AS 'Current Shift';
SELECT '2020-08-10 11:00:00' AS 'Current time',CurrentShift('2020-08-10 11:00:00') AS 'Current Shift'
	UNION ALL
	SELECT '2021-09-10 15:00:00' AS 'Current time',CurrentShift('2021-09-10 15:00:00') AS 'Current Shift'
	UNION ALL
	SELECT '2020-12-11 19:00:00' AS 'Current time',CurrentShift('2020-12-11 19:00:00') AS 'Current Shift'
	UNION ALL
	SELECT '2022-03-05 01:00:01' AS 'Current time',CurrentShift('2022-03-05 01:00:01') AS 'Current Shift';



DROP FUNCTION IF EXISTS EndOfPregnancy;
CREATE FUNCTION EndOfPregnancy(startOfPregnancy DATE) RETURNS DATE
	return ADDDATE(startOfPregnancy, INTERVAL 9 month);

SELECT DATE(now()) AS 'Start of pregnancy', EndOfPregnancy(DATE(now())) as 'Expected end of term'
	UNION ALL
	SELECT '2020-06-10' AS 'Start of pregnancy', EndOfPregnancy('2020-06-10') as 'Expected end of term'
	UNION ALL
	SELECT '2023-01-02' AS 'Start of pregnancy', EndOfPregnancy('2023-01-02') as 'Expected end of term';


DROP FUNCTION IF EXISTS DoctorsWorkingShift;
DELIMITER //
CREATE FUNCTION DoctorsWorkingShift(vShift VARCHAR(20)) RETURNS int
BEGIN 
	DECLARE vShiftCount INT;
    SELECT COUNT(*) INTO vShiftCount FROM Doctor
    WHERE Shift = vShift;
    RETURN vShiftCount;
end; //
DELIMITER ;

SELECT 	DoctorsWorkingShift('Morning') AS 'Morning shift',
		DoctorsWorkingShift('Noon') AS 'Noon shift',
		DoctorsWorkingShift('Evening') AS 'Evening shift',
		DoctorsWorkingShift('Night') AS 'Night shift';


#--> Triggers <--#
DROP TRIGGER IF EXISTS before_insert_bed_occupation;
DELIMITER //  
Create Trigger before_insert_bed_occupation   
BEFORE INSERT ON bed_occupation FOR EACH ROW  
BEGIN  
IF NEW.Start_Date < CURDATE() THEN SET NEW.Start_Date = CURDATE();
END IF;  
IF NEW.End_Date < CURDATE() THEN SET NEW.End_Date = CURDATE();
End IF;
END // 


DROP TRIGGER IF EXISTS after_insert_doctor;
DELIMITER // 
CREATE TRIGGER after_insert_doctor
AFTER INSERT
ON doctor FOR EACH ROW
IF NEW.Speciality='Pediatrics' THEN 
UPDATE Device 
SET Doc_ID = new.Doc_ID
Where Dev_ID=2;
END IF; 

 

 #--> Procedures <--#

DROP PROCEDURE IF EXISTS Easy_Insert_Patient;
DELIMITER //

CREATE PROCEDURE Easy_Insert_Patient(

IN Par_Pat_F_Name VARCHAR(30),
IN Par_Pat_L_Name VARCHAR(15),
IN Par_Birth_Date Date,
IN Par_Reception_Date Date,
IN Par_Phone_Number VARCHAR(11),
IN Par_Bed_ID int

)
BEGIN
	INSERT INTO Patient(Pat_F_Name, Pat_L_Name, Birth_date, Phone_Number, reception_date, discharge_date)
    Values(Par_Pat_F_Name, Par_Pat_L_Name, Par_Birth_date, Par_Phone_Number, Par_reception_date, NULL);
    
    Select Max(Pat_ID) into @Max_Pat_ID
    From patient;
    
    INSERT INTO bed_occupation(Bed_ID,Pat_ID,Start_Date,End_Date)
    Values(Par_Bed_ID,@Max_Pat_ID,Par_reception_date,NULL)
	;
END //

DELIMITER ;


Call Easy_Insert_Patient(

"Marie",
"Andersen",
"1997-01-01",
"2023-03-14",
"+4528442211",
1
);

DROP PROCEDURE IF EXISTS Available_Patients;
DELIMITER //
CREATE PROCEDURE Available_Patients(IN room_num INT)
BEGIN
    SELECT Patient.Pat_F_Name, Patient.Pat_L_Name, Bed_Occupation.Start_Date, Bed_Occupation.End_Date
    FROM Patient
    JOIN Bed_Occupation ON Patient.Pat_ID = Bed_Occupation.Pat_ID
    JOIN Bed ON Bed_Occupation.Bed_ID = Bed.Bed_ID
    WHERE Bed.Room_Number = room_num AND Bed_Occupation.End_Date IS NULL;
END //
DELIMITER ;


Call Available_Patients(4);

# --> Updates <-- #

-- This statement, changes the 'eye' department name to 'Ophthalmology' 
update department
set dept_name = 'Ophthalmology '
where dept_name = 'eye';

-- This statement, changes shifts of all orthopedics and dermatologists to night shift
update doctor
set shift = 'night'
where speciality = 'orthopedics' or speciality = 'dermatoloy';

-- This statement, increases the price of all the services using "Urine Analyser" device by 10%
update service natural join device
set serv_price = serv_price + (0.1*serv_price)
where dev_name = "Urine Analyser";

# --> Deletions <-- #

-- This statement, removes the patiens with reception date before 2022
delete from patient
where reception_date < "2022-01-01";

-- This statement, removes all the devices belong to "gynaecology" department
delete device
from device natural join department
where dept_name = 'gynaecology';

-- This statement, removes all the specialized beds
delete from bed
where Is_specialised = 1;