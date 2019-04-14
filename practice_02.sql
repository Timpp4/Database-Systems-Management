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

-- 1.a)
-- Using range partitioning we can partition the table automatically.

create table CUSM ( 
    custname varchar2(32) NOT NULL, 
    address varchar2(64), 
    custid number(5) NOT NULL, 
    bday date default sysdate, 
    sex varchar2(6) check (sex = 'Male' or sex = 'Female' or sex = 'Other'), 
    phone varchar2(13), 
    email varchar2(32) NOT NULL, 
    status varchar2(16) check (status = 'Active' or status = 'Dormant' or status = 'Deceased'), 
    constraint pk_CUSM primary key (custid) 
    ) partition by range (bday) (
        partition ELDER values less than (to_date('15-04-1959', 'DD-MM-YYYY')),
        partition ADULT values less than (to_date('15-04-2000', 'DD-MM-YYYY')),
        partition YOUNG values less than (MAXVALUE)
    );


-- 1.b)
-- Using list partitioning allows us to create separate partitions.
-- Here we can check the accounts which don't have accnumber set.

create table ACTM (
    accnumber number(5),
    intrate number(4,2),
    opendate date,
    status varchar2(16),
    balance number(6,4),
    acctype varchar2(3),
    custid number(5),
    constraint pk_ACTM primary key (accnumber, custid),
    constraint fk_custid foreign key (custid) references CUSM (custid)
    ) partition by list (accnumber) (
        partition accNULL values (NULL),
        partition accNUM values (default)
    );
	
	
-- Let's insert some values.
insert into CUSM values ('Tuomas Ikonen', 'Kotikuja 1 Lappeenranta', custid_seq.nextval, to_date('29-03-1996', 'dd-mm-yyyy'), 'Male', '+358401234567', 'tuomas.ikonen@student.lut.fi', 'Active');
insert into CUSM values ('Brin Kottarainen', 'Yliopistonkatu 1 Lappeenranta', custid_seq.nextval, to_date('11-11-1992', 'dd-mm-yyyy'), 'Male', '+358500550052', 'brian.kottarainen@student.lut.fi', 'Active');
insert into CUSM (custname, custid, email, sex) values ('Matti Meikalainen', custid_seq.nextval, 'matti.meikalainen@gmail.com', 'Male');
insert into CUSM (custname, custid, email, sex) values ('Meiju Makarainen', custid_seq.nextval, 'meiju.makarainen@outlook.fi', 'Female');
insert into CUSM (custname, custid, address, sex, email) values ('Xiu Lia', custid_seq.nextval, 'Downstreet 2 apt. 23, LA USA', 'Other', 'xiu.lia@cn.com');

insert into ACTM values (accnumber_seq.nextval, 10.22, to_date('01-01-2019', 'dd-mm-yyyy'), 'Active', 10.00, 'NOD', 10000);
insert into ACTM values (accnumber_seq.nextval, 0, to_date('31-12-2018', 'dd-mm-yyyy'), 'Closed', 0, 'NOD', 10000);
insert into ACTM values (accnumber_seq.nextval, 0, to_date('23-11-2013', 'dd-mm-yyyy'), 'Closed', 0, 'NOD', 10001);
insert into ACTM values (accnumber_seq.nextval, 5.11, to_date('22-06-2006', 'dd-mm-yyyy'), 'Active', 2, 'OD', 10003);
insert into ACTM values (accnumber_seq.nextval, 0.22, to_date('30-01-1996', 'dd-mm-yyyy'), 'Active', 3, 'OD', 10004);
insert into ACTM values (accnumber_seq.nextval, 0, to_date('01-10-2009', 'dd-mm-yyyy'), 'Closed', 0, 'NOD', 10002);


-- 1.c)

create view adultcustomer as
    select CUSM.custid, CUSM.custname, CUSM.bday, ACTM.accnumber, ACTM.status
    from CUSM
    inner join ACTM
    on CUSM.custid = ACTM.custid
    where CUSM.bday < (to_date('15-04-2000', 'DD-MM-YYYY'));
    
select * from adultcustomer;
