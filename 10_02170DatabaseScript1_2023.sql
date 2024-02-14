#-- The Hospital Database creation SQL script for the Database Systems 2023 DTU course 

DROP DATABASE IF EXISTS Hospital;    

CREATE DATABASE Hospital;
USE Hospital;

CREATE TABLE Patient
(Pat_ID	BIGINT AUTO_INCREMENT,
Pat_F_Name	VARCHAR(30),
Pat_L_Name	VARCHAR(15),
Birth_Date	DATE,
Age INT AS (TIMESTAMPDIFF(YEAR, Birth_Date, CURDATE())),		
Phone_Number VARCHAR(11),
Reception_Date DATE,
Discharge_Date DATE, 
PRIMARY KEY(Pat_ID));

CREATE TABLE Doctor
(Doc_ID		INT(4) AUTO_INCREMENT,
Doc_F_Name	VARCHAR(30) NOT NULL,
Doc_L_Name	VARCHAR(15) NOT NULL,
Speciality	VARCHAR(20),	
Shift 		ENUM('Morning','Noon','Night'),
PRIMARY KEY(Doc_ID));

CREATE TABLE Department
(Dept_ID		INT(4) AUTO_INCREMENT,
Dept_Name	VARCHAR(30),
PRIMARY KEY(Dept_ID));

CREATE TABLE Bed
(Bed_ID		INT(4) AUTO_INCREMENT,
Room_Number	INT(4),
Dept_ID 	INT(4),
Is_Specialised 	BOOL,
PRIMARY KEY(Bed_ID),
FOREIGN KEY(Dept_ID) REFERENCES 				
	Department(Dept_ID) ON DELETE SET NULL);
    
CREATE TABLE Device
(Dev_ID 	INT(4) AUTO_INCREMENT,
Dev_name 	VARCHAR(20),
Doc_ID 		INT(4), 
Dept_ID 	INt(4),
PRIMARY KEY(Dev_ID),
FOREIGN KEY(Dept_ID) REFERENCES
	Department(Dept_ID) ON DELETE SET NULL);
    
CREATE TABLE Service
(Serv_ID	BIGINT AUTO_INCREMENT,
Serv_Name 	VARCHAR(25),
Serv_Price 	DECIMAL(10,2),
Serv_Type 	VARCHAR(25),
Dev_ID 		INT(4),
PRIMARY KEY(Serv_ID),
FOREIGN KEY(Dev_ID) REFERENCES 				
	Device(Dev_ID) ON DELETE SET NULL);  


CREATE TABLE Drug
(Drug_ID 			BIGINT AUTO_INCREMENT, 
Drug_Name			VARCHAR(20),
Manufacturer_Name 	VARCHAR(20),
Drug_Price 			DECIMAL(10,2),
Drug_Type 			VARCHAR(20),
PRIMARY KEY(Drug_ID)
);

CREATE TABLE Diagnosis
(Diag_ID 			INT(4) AUTO_INCREMENT, 
Diag_Name			VARCHAR(25),
PRIMARY KEY(Diag_ID)
);

#--RELATIONS

CREATE TABLE Bed_Occupation
(Bed_ID				INT(4) NOT NULL,
Pat_ID 				BIGINT NOT NULL,
Start_Date 			DATE,
End_Date 			DATE,
PRIMARY KEY(Bed_ID,Pat_ID,Start_Date),
FOREIGN KEY(Bed_ID) REFERENCES
	Bed(Bed_ID) ON DELETE CASCADE,
FOREIGN KEY(Pat_ID) REFERENCES
	Patient(Pat_ID) ON DELETE CASCADE
);

CREATE TABLE Service_Provided 
(Serv_ID 			BIGINT,
Pat_ID 				BIGINT,
Doc_ID 				INT(4),
Serv_Date 			DATE,
Serv_No 			INT(4),
PRIMARY KEY(Serv_ID, Pat_ID, Doc_ID, Serv_Date),
FOREIGN KEY(Serv_ID) REFERENCES 				
	Service(Serv_ID) ON DELETE CASCADE,
FOREIGN KEY(Pat_ID) REFERENCES 				
	Patient(Pat_ID) ON DELETE CASCADE,
FOREIGN KEY(Doc_ID) REFERENCES 				
	Doctor(Doc_ID) ON DELETE CASCADE
    );  

CREATE TABLE Taking_Drugs 
(Drug_ID 				BIGINT,
Pat_ID 					BIGINT,
Doc_ID 					INT(4),
Drug_Amount				INT(4),
Drug_Date				DATE,
PRIMARY KEY(Drug_ID,Pat_ID,Doc_ID,Drug_Date),
FOREIGN KEY(Pat_ID) REFERENCES 				
	Patient(Pat_ID) ON DELETE CASCADE,
FOREIGN KEY(Doc_ID) REFERENCES 				
	Doctor(Doc_ID) ON DELETE CASCADE,
FOREIGN KEY(Drug_ID) REFERENCES 				
	Drug(Drug_ID) ON DELETE CASCADE
    );  
    
CREATE TABLE Given_Diagnosis
(Pat_ID					BIGINT,
Doc_ID					INT(4),
Diag_ID					INT(4),
Diag_Date				DATE,
PRIMARY KEY(Pat_ID, Doc_ID, Diag_ID,Diag_Date),
FOREIGN KEY(Pat_ID) REFERENCES
	Patient(Pat_ID) ON DELETE CASCADE,
FOREIGN KEY(Doc_ID) REFERENCES
	Doctor(Doc_ID) ON DELETE CASCADE, 
FOREIGN KEY(Diag_ID) REFERENCES
	Diagnosis(Diag_ID) ON DELETE CASCADE
);

#--> Views <-- #
# PatientView shows patient data without any sensitive patient information
CREATE VIEW PatientView AS SELECT Pat_F_Name, Pat_L_Name, Age FROM Patient;

# Total drug price view
CREATE VIEW TotalPatientDrugPrice AS
SELECT Pat_ID, Pat_F_Name, Pat_L_Name, Drug_ID, Drug_Name, ROUND(Drug_Price*Taking_Drugs.Drug_Amount, 2) AS Tot_Drug_Price 
FROM (Taking_Drugs JOIN Drug USING (Drug_ID))
NATURAL JOIN Patient
GROUP BY Pat_ID;

CREATE VIEW TotalPatientServPrice AS
SELECT Pat_ID, Pat_F_Name, Pat_L_Name, Serv_ID, Serv_Name, ROUND(Serv_Price*Serv_No, 2) AS Tot_Serv_Price
FROM (Patient NATURAL JOIN Service_Provided) 
JOIN Service USING (Serv_ID)
ORDER BY Pat_ID;

# DoctorPatientView shows every doctor with their patient if they have one
CREATE VIEW DoctorPatientView AS
SELECT Doc_ID, Doc_F_Name, Doc_L_Name, Pat_ID, Pat_F_Name, Pat_L_Name 
FROM (Service_Provided RIGHT JOIN Doctor USING (Doc_ID)) LEFT JOIN Patient USING (Pat_ID);

# Show current patients
CREATE VIEW CurrentPatientsView AS
SELECT * FROM Patient WHERE Discharge_Date IS NULL;

# Show past patients
CREATE VIEW PastPatientsView AS
SELECT * FROM Patient WHERE Discharge_Date IS NOT NULL;

# --> Population <-- #

INSERT INTO Patient(Pat_F_Name, Pat_L_Name, Birth_date, Phone_Number, reception_date, discharge_date)
	VALUES
		('Henry', 'Bertstein', '1983-03-21', '+4560878703','2022-12-21','2023-01-05'),
		('Adam', 'Hansen', '1945-05-01', '+4545672005','2022-12-21','2023-01-05'),
		('Sofie-Amalie', 'Tobiasen', '1991-03-07', '+4544802345','2022-06-21',NULL),
		('Nima', 'Andersen', '1997-05-11', '+4547601112','2022-12-21','2023-01-05'),
		('Elisabeth', 'Mikkelsen', '1965-08-28', '+4542343404','2021-12-21','2023-01-05'),
		('Alberto', 'Milano', '1955-12-12', NULL,'2022-12-21',NULL),
		('Mette Berg', 'Hansen', '1962-03-20', '+4589897703','2023-10-24','2023-10-25'),
		('Gertrud', 'Samuelsen', '1938-09-01', '+4544805413','2022-12-21',NULL),
		('Thomas William', 'Helming', '1980-01-30', '+4567838376','2023-11-21',NULL),
		('Niels Gram', 'Petersen', '1959-05-04', '+4557809070','2022-11-21','2023-01-05');


INSERT INTO Doctor(Doc_F_Name,Doc_L_Name,Speciality,Shift)
	VALUES
		('Svend', 'Svendsen', 'Dermatology', 'Morning'),
        ('John', 'Carlson', 'Pediatrics', 'Noon'),
        ('Line', 'Gale', 'Dermatology', 'Noon'),
        ('Eric', 'Milton', 'Psychiatry', 'Morning'),
        ('Bill', 'Svendsen', 'Anesthesiology', 'Morning'),
        ('Joshua', 'Cooper', 'Surgery', 'Night'),
        ('Frank', 'Roam', 'Orthopedics', 'Morning'),
        ('Anders Aaboe', 'Andersen', 'Surgery', 'Night'),
        ('Inger', 'Yale', 'Obstetrics', 'Morning'),
        ('Thomas', 'Nielsen', 'Orthopedics', 'Morning');

INSERT INTO Department (Dept_Name)
	VALUES 
	   ('Medicine'),
	   ('Surgery'),
       ('Gynaecology'),
       ('Obstetrics'),
       ('Paediatrics'),
       ('Ophthalmology'),
       ('Dental'),
       ('Orthopaedics'),
       ('Neurology'),
       ('Cardiology');

   
INSERT INTO Bed(Room_Number,Dept_ID,Is_Specialised)
	VALUES
		(4,1,true),
        (1,3,false),
        (3,3,false),
        (8,1,false),
        (3,2,false),
        (6,4,false),
        (6,4,false),
        (2,1,true),
        (4,1,false),
        (3,5,true);    


INSERT INTO Diagnosis (Diag_Name)
	VALUES 
		('Physical Diseases'),
		('Mental Diseases'),
		('Infectious Diseases'),
		('No-infectious Diseases'),
		('Deficiency Diseases'),
		('Inherited Diseases'),
		('Degenerative Diseases'),
		('Social Diseases'),
		('Degenerative Diseases'),
		('Self-inflicted Diseases');

INSERT INTO Drug(Drug_Name,Manufacturer_Name,Drug_Price,Drug_Type)
	VALUES
		('Acetaminophen','LegitCO',100.5,'Pain reliever'),
		('Xanax','Rotciv',10.0,'Antidepressant'),
		('Metformin','NextImproved',5.7,'Insulin sensitivity'),
		('Brilinta','GETwl',26.1,'Prevents blood clots'),
		('Adderall','EORC',99.9,'ADHD'),
		('Tramadol NextGen','Novo Nordisk',91.2,'Pain reliever'),
		('Ozempic','Enterap',1.0,'Type 2 diabetes'),
		('Lofexidine','DrugCorp',8.1,'Hormone blocker'),
		('Lexapro','New Initiative',3.3,'Antidepressant'),
		('Fentanyl','Strands',89.9,'Pain reliever');
        
INSERT INTO Device (Dev_name,Doc_ID,Dept_ID)
	VALUES
		('MRI scanner',1,5),
		('Ultrasound machine',3,7),
		('Oxygen concentrator',2,8),
		('CT scanner',7,3),
		('Urine analyser',6,4),
		('Hematology analyzer',4,1),
        ('Ultra sound scanner', 9,4),
        ('X-RAY machine',2,1);

INSERT INTO Service (Serv_name, Serv_Price, Serv_Type, Dev_ID)
	VALUES
		('Blood test', 1000, 'Blood Services', 6),
		('X-RAY', 1000, 'Imaging Services', 8),
		('CT-scan', 820,'Imaging Services', 4),
		('Doctor consultation',NULL,'Consultation',NULL),
		('One day bed rest', 500, 'Bed Rest',NULL),
		('Emergency room', 2000, 'Emergency Occupancy',6),
		('Urine sample test', 50.5, 'Urine Test',5),
		('Pregnancy urine test', 25, 'Urine Test', 5),
		('Vitamin levels blood', 200, 'Blood Services', 6),
        ('Ultra sound',NULL,'Pregnancy scan', 7);
		


INSERT INTO Bed_Occupation (Bed_ID, Pat_ID, Start_Date, End_Date)
	VALUES
		(5,1,'2023-01-15','2023-03-15'),
		(5,2,'2023-01-01','2023-01-14'),
		(3,3,'2023-02-01','2023-03-02'),
		(7,4,'2023-01-07','2023-03-08'),
		(2,5,'2023-01-03','2023-03-08'),
		(4,6,'2023-03-04','2023-03-07'),
		(6,7,'2023-01-11','2023-03-12'),
		(8,8,'2023-01-12','2023-03-12'),
		(5,9,'2023-03-08','2023-03-11');


INSERT INTO Service_Provided (Serv_ID, Pat_ID, Doc_ID, Serv_Date, Serv_No)
	VALUES 
		(3, 1, 3, '2023-01-15', 5),
		(1, 2, 5, '2023-03-05', 4),
		(2, 3, 8, '2022-12-21', 10),
		(1, 4, 9, '2023-03-13', 12),
		(3, 5, 2, '2023-01-30', 4),
		(4, 6, 4, '2023-03-28', 7),
		(1, 7, 1, '2022-08-01', 14),
        (2, 3, 2, '2000-01-03',1),
        (10, 3, 2, '2000-01-03',4),
		(3, 8, 8, '2023-01-20', 1);


INSERT INTO Given_Diagnosis (Pat_ID, Doc_ID, Diag_ID, Diag_Date)
	VALUES
			
		(1,3,1,'2023-01-16'),
		(2,1,3,'2023-01-01'),
		(3,7,4,'2023-02-05'),
		(6,5,1,'2023-03-04'),
		(8,3,6,'2023-01-19'),
		(10,3,8,'2023-03-14');

INSERT INTO Taking_Drugs (Drug_ID,Pat_ID, Doc_ID, Drug_Amount, Drug_Date)
	VALUES			
            (1,1,1,2,'2023-01-18'),
            (2,2,3,5,'2023-01-03'),
            (3,2,4,1,'2023-01-05'),
            (5,2,4,1,'2023-02-10'),
            (6,3,4,1,'2023-02-14'),
            (6,5,4,1,'2023-02-08'),
            (7,5,4,1,'2023-02-09'),
            (1,6,4,1,'2023-03-04'),
            (2,7,4,1,'2023-02-12'),
            (9,8,1,2,'2023-03-09'),
            (8,8,6,1,'2023-01-09'),
            (10,8,8,1,'2023-03-01');



