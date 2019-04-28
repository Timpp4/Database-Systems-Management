-- TASK 02:
-- Let's start with creating sequences and tables first
create sequence custid_seq
start with 10000
increment by 1
cache 20
nominvalue 
nomaxvalue 
nocycle
noorder;
/

create sequence accnumber_seq
start with 20000
increment by 1
cache 20
nominvalue 
nomaxvalue 
nocycle
noorder;
/

create sequence txnm_seq
start with 1
increment by 1
cache 20
nominvalue 
nomaxvalue 
nocycle
noorder;
/

create table CUSM ( 
    custname varchar2(32) NOT NULL, 
    address varchar2(64), 
    custid number(5) NOT NULL, 
    bday date, 
    sex varchar2(6) check (sex = 'Male' or sex = 'Female' or sex = 'Other'), 
    phone varchar2(13), 
    email varchar2(32) NOT NULL UNIQUE, 
    status varchar2(16) check (status = 'Active' or status = 'Dormant' or status = 'Deceased'), 
    constraint pk_CUSM primary key (custid) 
    );

create table ACTM (
    accnumber number(5) NOT NULL UNIQUE,
    intrate number(4,2),
    opendate date,
    status varchar2(16) check (status = 'Active' or status = 'Hold' or status = 'Closed'),
    balance number(6) check (balance = 0 or balance > 0) NOT NULL,
    acctype varchar2(3),
    custid number(5) NOT NULL,
    constraint pk_ACTM primary key (accnumber, custid),
    constraint fk_custid foreign key (custid) references CUSM (custid)
    );
    
create table TXNM (
    txnm_identifier number(5) NOT NULL UNIQUE,
    transdate date,
    transtype varchar2(2) check (transtype = 'Cr' or transtype = 'Dr'),
    amount number(5,2),
    accnumber number(5) NOT NULL,
    constraint pk_TXNM primary key (txnm_identifier, accnumber),
    constraint fk_accnumber foreign key (accnumber) references ACTM (accnumber)
    );
	
insert into CUSM values ('Tuomas Ikonen', 'Kotikuja 1 Lappeenranta', custid_seq.nextval, to_date('29-03-1996', 'dd-mm-yyyy'), 'Male', '+358401234567', 'tuomas.ikonen@student.lut.fi', 'Active');
insert into CUSM values ('Brin Kottarainen', 'Yliopistonkatu 1 Lappeenranta', custid_seq.nextval, to_date('1111-1992', 'dd-mm-yyyy'), 'Male', '+358500550052', 'brian.kottarainen@student.lut.fi', 'Active');
insert into CUSM (custname, custid, email, sex) values ('Matti Meikalainen', custid_seq.nextval, 'matti.meikalainen@gmail.com', 'Male');
insert into CUSM (custname, custid, email, sex) values ('Meiju Makarainen', custid_seq.nextval, 'meiju.makarainen@outlook.fi', 'Female');
insert into CUSM (custname, custid, address, sex, email) values ('Xiu Lia', custid_seq.nextval, 'Downstreet 2 apt. 23, LA USA', 'Other', 'xiu.lia@cn.com');

insert into ACTM values (accnumber_seq.nextval, 10.22, to_date('01-01-2019', 'dd-mm-yyyy'), 'Active', 10.00, 'NOD', 10000);
insert into ACTM values (accnumber_seq.nextval, 0, to_date('31-12-2018', 'dd-mm-yyyy'), 'Closed', 0, 'NOD', 10000);
insert into ACTM values (accnumber_seq.nextval, 5.11, to_date('22-06-2006', 'dd-mm-yyyy'), 'Active', 2, 'OD', 10003);
insert into ACTM values (accnumber_seq.nextval, 0.22, to_date('30-01-1996', 'dd-mm-yyyy'), 'Active', 3, 'OD', 10004);
insert into ACTM values (accnumber_seq.nextval, 0, to_date('01-10-2009', 'dd-mm-yyyy'), 'Closed', 0, 'NOD', 10002);

insert into TXNM values (txnm_seq.nextval, to_date('25-03-1999', 'dd-mm-yyyy'), 'Dr', 99.59, 20003);
insert into TXNM values (txnm_seq.nextval, to_date('28-02-2019', 'dd-mm-yyyy'), 'Cr', 29.99, 20000);
insert into TXNM values (txnm_seq.nextval, to_date('25-10-2009', 'dd-mm-yyyy'), 'Dr', 47.56, 20004);
insert into TXNM values (txnm_seq.nextval, to_date('30-09-2016', 'dd-mm-yyyy'), 'Dr', 9.98, 20002);
insert into TXNM values (txnm_seq.nextval, to_date('24-03-2019', 'dd-mm-yyyy'), 'Cr', 15.99, 20000);
   
-- After this we want to create error log tables for each table we have
begin
    dbms_errlog.create_error_log(dml_table_name => 'CUSM');
    dbms_errlog.create_error_log(dml_table_name => 'ACTM');
    dbms_errlog.create_error_log(dml_table_name => 'TXNM');
end;

-- Try out and insert some invalid data
insert into CUSM values ('Tuomas Ikonen', 'Kotikuja 1 Lappeenranta', custid_seq.nextval, to_date('29-03-1996', 'dd-mm-yyyy'), 'Male', '+358401234567', NULL, 'Active')
    LOG errors into err$_cusm reject LIMIT unlimited;
insert into ACTM values (accnumber_seq.nextval, 10.22, to_date('01-01-2019', 'dd-mm-yyyy'), 'nothing', 10.00, 'NOD', 10000)
    LOG errors into err$_actm reject LIMIT unlimited;
insert into TXNM values (txnm_seq.nextval, to_date('25-03-1999', 'dd-mm-yyyy'), 'Dr', 99.59, 99999)
    LOG errors into err$_txnm reject LIMIT unlimited;

-- Print out the error messages
select * from err$_cusm;
select * from err$_actm;
select * from err$_txnm;

-- TASK 03
-- Create logging table ACTM and trigger for it
-- This table will log balance information, both old and new values,
-- with related customer ID and access date
create table actm_log (
    cust_id integer,
    access_date date,
    old_balance number(6),
    new_balance number(6)
    );
    
create or replace trigger log_access_actm
after update on actm
for each row
begin
    insert into actm_log (cust_id, access_date, old_balance, new_balance)
    values (:old.custid, SYSDATE, :old.balance, :new.balance);
end;

-- Update custid = 10000
select * from actm
	where custid = 10000;

update actm
    set balance = 509
    where custid = 10000 and status = 'Active';
	
-- Show log changes
select * from actm_log;

-- Verify the changes
select * from actm
	where custid = 10000;
