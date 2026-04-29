create table person (
    person_id       number    ,
    name            varchar2(100)   not null,
    phone_no        varchar2(15)    not null,
    address         varchar2(255)   not null,
    email           varchar2(100)   not null,
    cnic            varchar2(15)    not null,
    dob             date            not null,
    gender          char(1)         not null,   -- 'm' / 'f' / 'o'
    person_type     varchar2(10)    not null,   -- 'client','lawyer','judge'
    created_at      timestamp       default systimestamp,

    constraint pk_person        primary key (person_id),
    constraint uq_person_cnic   unique      (cnic),
    constraint uq_person_email  unique      (email),
    constraint chk_gender       check       (gender in ('m','f','o')),
    constraint chk_person_type  check       (person_type in ('client','lawyer','judge'))
);


-- ============================================================
--  section 5: subtype — client
-- ============================================================

create table client (
    client_id           number          not null,
    person_id           number          not null,
    occupation          varchar2(100),
    emergency_contact   varchar2(15),
    client_status       varchar2(10)    default 'active',  -- active / inactive

    constraint pk_client        primary key (client_id),
    constraint fk_client_person foreign key (person_id)  references person(person_id) on delete cascade,
    constraint uq_client_person unique      (person_id),
    constraint chk_client_status check      (client_status in ('active','inactive'))
);


-- ============================================================
--  section 6: subtype — lawyer
-- ============================================================

create table lawyer (
    lawyer_id           number          not null,
    person_id           number          not null,
    license_no          varchar2(50)    not null,
    specialization      varchar2(100)   not null,
    bar_council_no      varchar2(50),
    years_of_experience number(2)       default 0,
    fee_per_hour        number(10,2)    default 0,
    availability_status varchar2(15)    default 'available',  -- available / busy / on_leave
    rating              number(3,1),    

    constraint pk_lawyer            primary key (lawyer_id),
    constraint fk_lawyer_person     foreign key (person_id)  references person(person_id) on delete cascade,
    constraint uq_lawyer_person     unique      (person_id),
    constraint uq_lawyer_license    unique      (license_no),
    constraint chk_lawyer_status    check       (availability_status in ('available','busy','on_leave')),
    constraint chk_lawyer_rating    check       (rating between 0 and 5),
    constraint chk_lawyer_exp       check       (years_of_experience >= 0),
    constraint chk_lawyer_fee       check       (fee_per_hour >= 0)
);


-- ============================================================
--  section 7: subtype — judge
-- ============================================================

create table judge (
    judge_id            number          not null,
    person_id           number          not null,
    qualification       varchar2(150)   not null,
    exp_year            number(2)       not null,
    department          varchar2(100),
    appointment_date    date,
    judge_status        varchar2(10)    default 'active',  -- active / retired

    constraint pk_judge         primary key (judge_id),
    constraint fk_judge_person  foreign key (person_id)  references person(person_id) on delete cascade,
    constraint uq_judge_person  unique      (person_id),
    constraint chk_judge_status check       (judge_status in ('active','retired')),
    constraint chk_judge_exp    check       (exp_year >= 0)
);


-- ============================================================
--  section 8: court
-- ============================================================

create table court (
    court_id        number  ,
    court_name      varchar2(150)   not null,
    location        varchar2(255)   not null,
    court_type      varchar2(20)    not null,   -- district / high / supreme / family / civil / criminal
    jurisdiction    varchar2(200),
    contact_no      varchar2(15),
    total_judges    number(3)       default 0,

    constraint pk_court         primary key (court_id),
    constraint chk_court_type   check       (court_type in ('district','high','supreme','family','civil','criminal'))
);


-- ============================================================
--  section 9: law_case
-- ============================================================

create table law_case (
    case_id             number ,
    case_title          varchar2(255)   not null,
    case_type           varchar2(20)    not null,   -- civil / criminal / family / corporate / property
    case_status         varchar2(15)    default 'open',  -- open / closed / pending / dismissed / appealed
    filing_date         date            default sysdate,
    close_date          date,
    priority_level      varchar2(10)    default 'normal',  -- low / normal / high / urgent
    court_fee           number(10,2)    default 0,
    description         clob,
    next_hearing_date   date,
    court_id            number          not null,
    client_id           number          not null,
    judge_id            number,

    constraint pk_case          primary key (case_id),
    constraint fk_case_court    foreign key (court_id)   references court(court_id),
    constraint fk_case_client   foreign key (client_id)  references client(client_id),
    constraint fk_case_judge    foreign key (judge_id)   references judge(judge_id),
    constraint chk_case_type    check       (case_type in ('civil','criminal','family','corporate','property')),
    constraint chk_case_status  check       (case_status in ('open','closed','pending','dismissed','appealed')),
    constraint chk_case_priority check      (priority_level in ('low','normal','high','urgent')),
    constraint chk_case_dates   check       (close_date is null or close_date >= filing_date)
);


-- ============================================================
--  section 10: case_lawyer  (many-to-many: case <-> lawyer)
-- ============================================================

create table case_lawyer (
    case_id         number      not null,
    lawyer_id       number      not null,
    role            varchar2(30) default 'defense',   -- defense / prosecution / advisor
    assigned_date   date         default sysdate,

    constraint pk_case_lawyer       primary key (case_id, lawyer_id),
    constraint fk_cl_case           foreign key (case_id)   references law_case(case_id) on delete cascade,
    constraint fk_cl_lawyer         foreign key (lawyer_id) references lawyer(lawyer_id),
    constraint chk_lawyer_role      check       (role in ('defense','prosecution','advisor'))
);


-- ============================================================
--  section 11: hearing
-- ============================================================

create table hearing (
    hearing_id              number  ,
    case_id                 number          not null,
    judge_id                number,
    hearing_date            date            not null,
    hearing_time            varchar2(10)    not null,   -- e.g. '10:30 am'
    hearing_status          varchar2(15)    default 'scheduled',  -- scheduled / completed / postponed / cancelled
    outcome_summary         varchar2(500),
    postponement_reason     varchar2(300),
    next_hearing_id         number,         -- self-reference to linked next hearing

    constraint pk_hearing           primary key (hearing_id),
    constraint fk_hearing_case      foreign key (case_id)   references law_case(case_id) on delete cascade,
    constraint fk_hearing_judge     foreign key (judge_id)  references judge(judge_id),
    constraint fk_hearing_next      foreign key (next_hearing_id) references hearing(hearing_id),
    constraint chk_hearing_status   check       (hearing_status in ('scheduled','completed','postponement','cancelled'))
);


-- ============================================================
--  section 12: evidence
-- ============================================================

create table evidence (
    evidence_id         number  ,
    case_id             number          not null,
    evidence_type       varchar2(50)    not null,   -- document / physical / digital / testimony / forensic
    description         varchar2(500)   not null,
    submission_date     date            default sysdate,
    collected_by        varchar2(100),
    storage_location    varchar2(200),
    admissibility       varchar2(15)    default 'pending',  -- admitted / rejected / pending
    chain_of_custody    varchar2(500),

    constraint pk_evidence          primary key (evidence_id),
    constraint fk_evidence_case     foreign key (case_id) references law_case(case_id) on delete cascade,
    constraint chk_evidence_type    check       (evidence_type in ('document','physical','digital','testimony','forensic')),
    constraint chk_admissibility    check       (admissibility in ('admitted','rejected','pending'))
);


-- ============================================================
--  section 13: verdict
-- ============================================================

create table verdict (
    verdict_id      number  ,
    case_id         number          not null,
    judge_id        number,
    decision        varchar2(20)    not null,   -- guilty / not_guilty / dismissed / settled / acquitted
    remarks         clob,
    issue_date      date            default sysdate,
    sentence        varchar2(300),  -- e.g. "5 years imprisonment" or "fine of 50,000 pkr"
    fine_amount     number(12,2)    default 0,

    constraint pk_verdict           primary key (verdict_id),
    constraint fk_verdict_case      foreign key (case_id)  references law_case(case_id) on delete cascade,
    constraint fk_verdict_judge     foreign key (judge_id) references judge(judge_id),
    constraint chk_verdict_decision check       (decision in ('guilty','not_guilty','dismissed','settled','acquitted')),
    constraint uq_verdict_case      unique      (case_id)   -- one verdict per case
);


-- ============================================================
--  section 14: legal_document
-- ============================================================

create table legal_document (
    doc_id          number  ,
    case_id         number          not null,
    doc_name        varchar2(200)   not null,
    doc_type        varchar2(50)    not null,   -- petition / affidavit / contract / order / notice / other
    issue_date      date            default sysdate,
    submission_by   varchar2(100),
    file_path       varchar2(500),  -- path/url to stored file
    description     varchar2(500),

    constraint pk_document          primary key (doc_id),
    constraint fk_document_case     foreign key (case_id) references law_case(case_id) on delete cascade,
    constraint chk_doc_type         check       (doc_type in ('petition','affidavit','contract','order','notice','other'))
);


-- ============================================================
--  section 15: witness  (new entity)
-- ============================================================

create table witness (
    witness_id      number ,
    case_id         number          not null,
    name            varchar2(100)   not null,
    cnic            varchar2(15),
    contact         varchar2(15),
    witness_type    varchar2(15)    not null,   -- expert / eyewitness / character / alibi
    testimony       clob,
    testimony_date  date,
    credibility     varchar2(10)    default 'unknown',  -- high / medium / low / unknown

    constraint pk_witness           primary key (witness_id),
    constraint fk_witness_case      foreign key (case_id) references law_case(case_id) on delete cascade,
    constraint chk_witness_type     check       (witness_type in ('expert','eyewitness','character','alibi')),
    constraint chk_witness_cred     check       (credibility in ('high','medium','low','unknown'))
);


-- ============================================================
--  section 16: payment  (new entity)
-- ============================================================

create table payment (
    payment_id      number ,
    case_id         number          not null,
    client_id       number          not null,
    lawyer_id       number,
    amount          number(12,2)    not null,
    payment_date    date            default sysdate,
    payment_type    varchar2(20)    not null,   -- court_fee / lawyer_fee / fine / bail / other
    payment_status  varchar2(10)    default 'pending',  -- paid / pending / overdue / waived
    transaction_ref varchar2(100),
    notes           varchar2(300),

    constraint pk_payment           primary key (payment_id),
    constraint fk_payment_case      foreign key (case_id)   references law_case(case_id) on delete cascade,
    constraint fk_payment_client    foreign key (client_id) references client(client_id),
    constraint fk_payment_lawyer    foreign key (lawyer_id) references lawyer(lawyer_id),
    constraint chk_payment_type     check       (payment_type in ('court_fee','lawyer_fee','fine','bail','other')),
    constraint chk_payment_status   check       (payment_status in ('paid','pending','overdue','waived')),
    constraint chk_payment_amount   check       (amount > 0)
);


-- ============================================================
--  section 17: appointment  (new entity)
-- ============================================================

create table appointment (
    appointment_id      number  ,
    lawyer_id           number          not null,
    client_id           number          not null,
    case_id             number,
    appt_date           date            not null,
    appt_time           varchar2(10)    not null,   -- e.g. '02:00 pm'
    purpose             varchar2(300),
    appt_status         varchar2(15)    default 'scheduled',  -- scheduled / completed / cancelled / no_show
    location            varchar2(200),
    notes               varchar2(500),

    constraint pk_appointment       primary key (appointment_id),
    constraint fk_appt_lawyer       foreign key (lawyer_id)  references lawyer(lawyer_id),
    constraint fk_appt_client       foreign key (client_id)  references client(client_id),
    constraint fk_appt_case         foreign key (case_id)    references law_case(case_id),
    constraint chk_appt_status      check       (appt_status in ('scheduled','completed','cancelled','no_show'))
);


-- ============================================================
--  section 18: appeal  (new entity)
-- ============================================================

create table appeal (
    appeal_id           number ,
    case_id             number          not null,
    filed_by_client     number          not null,
    original_verdict_id number          not null,
    appeal_date         date            default sysdate,
    grounds             clob            not null,
    appeal_status       varchar2(15)    default 'filed',  -- filed / under_review / accepted / rejected /withdrawn
    new_verdict_id      number,         -- fk to verdict if appeal leads to new verdict
    resolution_date     date,
    remarks             varchar2(500),

    constraint pk_appeal            primary key (appeal_id),
    constraint fk_appeal_case       foreign key (case_id)           references law_case(case_id),
    constraint fk_appeal_client     foreign key (filed_by_client)   references client(client_id),
    constraint fk_appeal_verdict    foreign key (original_verdict_id) references verdict(verdict_id),
    constraint fk_appeal_new_ver    foreign key (new_verdict_id)    references verdict(verdict_id),
    constraint chk_appeal_status    check       (appeal_status in ('filed','under_review','accepted','rejected','withdrawn'))
);



 ============================================================
--  SECTION 20: INDEXES (Performance)
-- ============================================================
 
-- Case lookups
CREATE INDEX IDX_CASE_CLIENT    ON LAW_CASE(Client_ID);
CREATE INDEX IDX_CASE_JUDGE     ON LAW_CASE(Judge_ID);
CREATE INDEX IDX_CASE_COURT     ON LAW_CASE(Court_ID);
CREATE INDEX IDX_CASE_STATUS    ON LAW_CASE(Case_Status);
CREATE INDEX IDX_CASE_TYPE      ON LAW_CASE(Case_Type);
 
-- Hearing lookups
CREATE INDEX IDX_HEARING_CASE   ON HEARING(Case_ID);
CREATE INDEX IDX_HEARING_DATE   ON HEARING(Hearing_Date);
 
-- Evidence lookups
CREATE INDEX IDX_EVIDENCE_CASE  ON EVIDENCE(Case_ID);
 
-- Payment lookups
CREATE INDEX IDX_PAYMENT_CASE   ON PAYMENT(Case_ID);
CREATE INDEX IDX_PAYMENT_CLIENT ON PAYMENT(Client_ID);
CREATE INDEX IDX_PAYMENT_STATUS ON PAYMENT(Payment_Status);
 
-- Person lookups
CREATE INDEX IDX_PERSON_TYPE    ON PERSON(Person_Type);
CREATE INDEX IDX_PERSON_CNIC    ON PERSON(CNIC);
 
 
-- ============================================================
--  SECTION 21: SAMPLE DATA
-- ============================================================
 
-- Courts
INSERT INTO COURT (Court_ID, Court_Name, Location, Court_Type, Jurisdiction, Contact_No, Total_Judges)
VALUES (1, 'Lahore High Court', 'Lahore, Punjab', 'HIGH', 'Punjab Province', '042-99200482', 25);
 
INSERT INTO COURT (Court_ID, Court_Name, Location, Court_Type, Jurisdiction, Contact_No, Total_Judges)
VALUES (2, 'District Court Faisalabad', 'Faisalabad, Punjab', 'DISTRICT', 'Faisalabad District', '041-9220112', 12);
 
INSERT INTO COURT (Court_ID, Court_Name, Location, Court_Type, Jurisdiction, Contact_No, Total_Judges)
VALUES (3, 'Supreme Court of Pakistan', 'Islamabad', 'SUPREME', 'Nationwide', '051-9213401', 17);
 
-- Persons (Judges)
INSERT INTO PERSON (Person_ID, Name, Phone_No, Address, Email, CNIC, DOB, Gender, Person_Type)
VALUES (1, 'Justice Khalid Mahmood', '0300-1234567', 'Model Town, Lahore', 'j.khalid@courts.pk', '35202-1234567-1', DATE '1965-03-15', 'M', 'JUDGE');
 
INSERT INTO PERSON (Person_ID, Name, Phone_No, Address, Email, CNIC, DOB, Gender, Person_Type)
VALUES (2, 'Justice Amna Saeed', '0321-9876543', 'Gulberg, Lahore', 'j.amna@courts.pk', '35202-9876543-2', DATE '1970-07-22', 'F', 'JUDGE');
 
-- Judges
INSERT INTO JUDGE (Judge_ID, Person_ID, Qualification, Exp_Year, Department, Appointment_Date, Judge_Status)
VALUES (1, 1, 'LLB, LLM, PhD Law', 25, 'Criminal Law', DATE '1999-01-10', 'ACTIVE');
 
INSERT INTO JUDGE (Judge_ID, Person_ID, Qualification, Exp_Year, Department, Appointment_Date, Judge_Status)
VALUES (2, 2, 'LLB, LLM', 18, 'Family Law', DATE '2006-05-20', 'ACTIVE');
 
-- Persons (Lawyers)
INSERT INTO PERSON (Person_ID, Name, Phone_No, Address, Email, CNIC, DOB, Gender, Person_Type)
VALUES (3, 'Adv. Bilal Ahmed', '0333-1112233', 'Johar Town, Lahore', 'bilal.adv@lawfirm.pk', '35201-1112233-3', DATE '1982-11-05', 'M', 'LAWYER');
 
INSERT INTO PERSON (Person_ID, Name, Phone_No, Address, Email, CNIC, DOB, Gender, Person_Type)
VALUES (4, 'Adv. Sara Khan', '0311-4455667', 'Clifton, Karachi', 'sara.adv@lawfirm.pk', '42201-4455667-4', DATE '1988-02-14', 'F', 'LAWYER');
 
-- Lawyers
INSERT INTO LAWYER (Lawyer_ID, Person_ID, License_No, Specialization, Bar_Council_No, Years_of_Experience, Fee_Per_Hour, Availability_Status, Rating)
VALUES (1, 3, 'LHC-2008-4521', 'Criminal Defense', 'PBC-2008-112', 15, 5000, 'AVAILABLE', 4.7);
 
INSERT INTO LAWYER (Lawyer_ID, Person_ID, License_No, Specialization, Bar_Council_No, Years_of_Experience, Fee_Per_Hour, Availability_Status, Rating)
VALUES (2, 4, 'SHC-2012-8834', 'Family Law', 'PBC-2012-334', 11, 4000, 'AVAILABLE', 4.4);
 
-- Persons (Clients)
INSERT INTO PERSON (Person_ID, Name, Phone_No, Address, Email, CNIC, DOB, Gender, Person_Type)
VALUES (5, 'Hassan Raza', '0345-7891234', 'Peoples Colony, Faisalabad', 'hassan.raza@gmail.com', '33100-7891234-5', DATE '1990-06-18', 'M', 'CLIENT');
 
INSERT INTO PERSON (Person_ID, Name, Phone_No, Address, Email, CNIC, DOB, Gender, Person_Type)
VALUES (6, 'Nadia Iqbal', '0300-5556677', 'Samanabad, Lahore', 'nadia.iqbal@yahoo.com', '35202-5556677-6', DATE '1985-09-30', 'F', 'CLIENT');
 
-- Clients
INSERT INTO CLIENT (Client_ID, Person_ID, Occupation, Emergency_Contact, Client_Status)
VALUES (1, 5, 'Businessman', '0300-0001111', 'ACTIVE');
 
INSERT INTO CLIENT (Client_ID, Person_ID, Occupation, Emergency_Contact, Client_Status)
VALUES (2, 6, 'Teacher', '0321-0002222', 'ACTIVE');
 
-- Cases
INSERT INTO LAW_CASE (Case_ID, Case_Title, Case_Type, Case_Status, Filing_Date, Priority_Level, Court_Fee, Description, Court_ID, Client_ID, Judge_ID)
VALUES (1, 'State vs Hassan Raza - Fraud Charges', 'CRIMINAL', 'OPEN', DATE '2025-01-15', 'HIGH', 15000, 'Alleged financial fraud involving property documents', 2, 1, 1);
 
INSERT INTO LAW_CASE (Case_ID, Case_Title, Case_Type, Case_Status, Filing_Date, Priority_Level, Court_Fee, Description, Court_ID, Client_ID, Judge_ID)
VALUES (2, 'Iqbal Family Custody Dispute', 'FAMILY', 'OPEN', DATE '2025-03-10', 'NORMAL', 8000, 'Child custody dispute after divorce proceedings', 2, 2, 2);
 
-- Assign Lawyers to Cases
INSERT INTO CASE_LAWYER (Case_ID, Lawyer_ID, Role, Assigned_Date)
VALUES (1, 1, 'DEFENSE', DATE '2025-01-16');
 
INSERT INTO CASE_LAWYER (Case_ID, Lawyer_ID, Role, Assigned_Date)
VALUES (2, 2, 'DEFENSE', DATE '2025-03-11');
 
-- Hearings
INSERT INTO HEARING (Hearing_ID, Case_ID, Judge_ID, Hearing_Date, Hearing_Time, Hearing_Status, Outcome_Summary)
VALUES (1, 1, 1, DATE '2025-02-10', '10:00 AM', 'COMPLETED', 'Initial arguments presented. Next date set.');
 
INSERT INTO HEARING (Hearing_ID, Case_ID, Judge_ID, Hearing_Date, Hearing_Time, Hearing_Status)
VALUES (2, 1, 1, DATE '2025-04-05', '11:00 AM', 'SCHEDULED');
 
INSERT INTO HEARING (Hearing_ID, Case_ID, Judge_ID, Hearing_Date, Hearing_Time, Hearing_Status)
VALUES (3, 2, 2, DATE '2025-04-20', '02:00 PM', 'SCHEDULED');
 
-- Evidence
INSERT INTO EVIDENCE (Evidence_ID, Case_ID, Evidence_Type, Description, Submission_Date, Collected_By, Admissibility)
VALUES (1, 1, 'DOCUMENT', 'Forged property transfer deed dated Jan 2024', DATE '2025-01-20', 'Investigation Officer Tariq', 'ADMITTED');
 
INSERT INTO EVIDENCE (Evidence_ID, Case_ID, Evidence_Type, Description, Submission_Date, Collected_By, Admissibility)
VALUES (2, 1, 'DIGITAL', 'WhatsApp conversation screenshots showing conspiracy', DATE '2025-01-25', 'Digital Forensics Unit', 'PENDING');
 
-- Legal Documents
INSERT INTO LEGAL_DOCUMENT (Doc_ID, Case_ID, Doc_Name, Doc_Type, Issue_Date, Submission_By)
VALUES (1, 1, 'Criminal Complaint FIR', 'PETITION', DATE '2025-01-15', 'Prosecutor Office');
 
INSERT INTO LEGAL_DOCUMENT (Doc_ID, Case_ID, Doc_Name, Doc_Type, Issue_Date, Submission_By)
VALUES (2, 2, 'Divorce Decree Copy', 'ORDER', DATE '2025-03-10', 'Family Court Faisalabad');
 
-- Witnesses
INSERT INTO WITNESS (Witness_ID, Case_ID, Name, CNIC, Contact, Witness_Type, Testimony, Testimony_Date, Credibility)
VALUES (1, 1, 'Usman Malik', '35202-3334455-7', '0333-9990001', 'EYEWITNESS', 'I witnessed the signing of fraudulent documents at the defendant office in December 2023.', DATE '2025-02-10', 'HIGH');
 
-- Payments
INSERT INTO PAYMENT (Payment_ID, Case_ID, Client_ID, Lawyer_ID, Amount, Payment_Date, Payment_Type, Payment_Status, Transaction_Ref)
VALUES (1, 1, 1, 1, 15000, DATE '2025-01-16', 'COURT_FEE', 'PAID', 'TXN-2025-001');
 
INSERT INTO PAYMENT (Payment_ID, Case_ID, Client_ID, Lawyer_ID, Amount, Payment_Date, Payment_Type, Payment_Status)
VALUES (2, 1, 1, 1, 50000, DATE '2025-01-16', 'LAWYER_FEE', 'PENDING');
 
-- Appointments
INSERT INTO APPOINTMENT (Appointment_ID, Lawyer_ID, Client_ID, Case_ID, Appt_Date, Appt_Time, Purpose, Appt_Status, Location)
VALUES (1, 1, 1, 1, DATE '2025-03-01', '03:00 PM', 'Case strategy discussion before hearing', 'COMPLETED', 'Law Chambers, Johar Town');
 
INSERT INTO APPOINTMENT (Appointment_ID, Lawyer_ID, Client_ID, Case_ID, Appt_Date, Appt_Time, Purpose, Appt_Status, Location)
VALUES (2, 1, 1, 1, DATE '2025-04-01', '04:00 PM', 'Pre-hearing briefing', 'SCHEDULED', 'Law Chambers, Johar Town');