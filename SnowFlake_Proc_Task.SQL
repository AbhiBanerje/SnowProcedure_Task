---** REFERENCE DOCUMENT for this ACTIVITY---
--https://medium.com/p/50d2071f59e5
--https://medium.com/snowflake/hey-snowflake-send-me-an-email-243741a0fe3
--https://docs.snowflake.com/en/sql-reference/functions/task_history.html
--https://medium.com/snowflake/how-to-notify-users-in-snowflake-93fa22ea6b9b
--https://alexandersks.medium.com/how-to-schedule-stored-procedure-via-snowflake-task-3209fc267a5e



---**. Check if snowpark is enabled for this Environment
select * from SNOWFLAKE.INFORMATION_SCHEMA.PACKAGES where package_name ilike '%snowflake-snowpark-python%' and language='python';

--- The below code has a simple logic, wherein we are loading a table with snapshot of the data from another table each weekly.
--- Snowflake now provides Procedure and task to enable this functionality.

---**Build the Snapshot Table that holds the historical data
create
or replace TABLE DEMO_DB.PUBLIC.DOT_SELL_THROUGH_DISTRIBUTOR_CODE_SNAPSHOT (
    Snapshot_Date DATE,
    Snapshot_Time TIMESTAMP_NTZ,
    CUSTOMER_NAME VARCHAR(50),
    ACCOUNT_MANAGER VARCHAR(30),
    AFFILIATION VARCHAR(50),
    OVERALL_SCORE NUMBER(4, 0), 
    ACCESS_SCORE NUMBER(1, 0),
    CADENCE_SCORE NUMBER(1, 0),
    AVAILABILITY_SCORE NUMBER(1, 0),
    VOLUME_SCORE NUMBER(1, 0),
    IMPORTANCE_SCORE NUMBER(1, 0),
    VOLUMEMOSTRECENT4WEEKPERIOD NUMBER(38, 3),
    VOLUMEPREVIOUS4WEEKPERIOD NUMBER(38, 3),
    VOLUMELAST6MONTHS NUMBER(38, 3),
    TIERBYVOLUME NUMBER(1, 0),
    UNIQUESKUSBOUGHTLAST8WEEKS NUMBER(18, 0),
    IMPORTANCE VARCHAR(6)
);
---This is the core table that holds the data at point of Time
create
or replace TABLE DEMO_DB.PUBLIC.TBL_DOT_SELL_THROUGH_DISTRIBUTOR_CODE_SNAPSHOT (
    CUSTOMER_NAME VARCHAR(50),
    ACCOUNT_MANAGER VARCHAR(30),
    AFFILIATION VARCHAR(50),
    OVERALL_SCORE NUMBER(4, 0),
    ACCESS_SCORE NUMBER(1, 0),
    CADENCE_SCORE NUMBER(1, 0),
    AVAILABILITY_SCORE NUMBER(1, 0),
    VOLUME_SCORE NUMBER(1, 0),
    IMPORTANCE_SCORE NUMBER(1, 0),
    VOLUMEMOSTRECENT4WEEKPERIOD NUMBER(38, 3),
    VOLUMEPREVIOUS4WEEKPERIOD NUMBER(38, 3),
    VOLUMELAST6MONTHS NUMBER(38, 3),
    TIERBYVOLUME NUMBER(1, 0),
    UNIQUESKUSBOUGHTLAST8WEEKS NUMBER(18, 0),
    IMPORTANCE VARCHAR(6)
);



--**CREATE NOTIFCATION integration
-- snowflake allows multiple types of integration, We are building a notification integration here for the purpose of email notification

Create OR REPLACE notification integration Email_Notification_Integration
type=email
enabled=true
allowed_recipients=('zzzz@gmail.com');

----** Below code Sends email using SYSTEM$SEND_EMAIL function. This code allows snowflake to push email notification to ay verified user in Snowflake after Failure or Success.

--Returns True if email notification is send.
Call SYSTEM$SEND_EMAIL(
    'EMAIL_NOTIFICATION_INTEGRATION',
    'zzzzz@gmail.com' ,
    'Email Alert: Task has finished.',
    'Task has successfully finished on ' || CURRENT_ACCOUNT() || ' account which is deployed on' || CURRENT_REGION() || 'region at' || CURRENT_TIMESTAMP()
);

---**SAMPLE SQL SNAPSHOT is unit tested to validate that Insert sql works properly
select * from DEMO_DB.PUBLIC.TBL_DOT_SELL_THROUGH_DISTRIBUTOR_CODE_SNAPSHOT;

INSERT INTO DEMO_DB.PUBLIC.DOT_SELL_THROUGH_DISTRIBUTOR_CODE_SNAPSHOT
SELECT CURRENT_DATE(),CURRENT_TIMESTAMP,V.* FROM DEMO_DB.PUBLIC.TBL_DOT_SELL_THROUGH_DISTRIBUTOR_CODE_SNAPSHOT V;


--** Build an anonymous procedure
--Snowflake Allows to build Anonymous procedure without even Creating one. 
--This is very useful when testing a Stored Procedure.

INSERT INTO DEMO_DB.PUBLIC.DOT_SELL_THROUGH_DISTRIBUTOR_CODE_SNAPSHOT SELECT CURRENT_DATE(),CURRENT_TIMESTAMP,V.* FROM DEMO_DB.PUBLIC.TBL_DOT_SELL_THROUGH_DISTRIBUTOR_CODE_SNAPSHOT V ;
    
with Load_DOT_SELL_THROUGH_DISTRIBUTOR_CODE_SNAPSHOT as procedure() 
returns string
language python
packages = ('snowflake-snowpark-python')
handler = 'x'
COMMENT='\n-- Stored Procedure to Load V_DOT_SELL_THROUGH_DISTRIBUTOR_CODE_SNAPSHOT to DOT_SELL_THROUGH_DISTRIBUTOR_CODE_SNAPSHOT every Tuesday  \n-- Proc Name : PROC_LD_DOT_SELL_THROUGH_DISTRIBUTOR_CODE_SNAPSHOT\n-- Input Parameters\n\n'
execute as caller
as
$$
def x(session):
    try:
        printed = session.sql("INSERT INTO DEMO_DB.PUBLIC.DOT_SELL_THROUGH_DISTRIBUTOR_CODE_SNAPSHOT SELECT CURRENT_DATE(),CURRENT_TIMESTAMP,V.* FROM DEMO_DB.PUBLIC.TBL_DOT_SELL_THROUGH_DISTRIBUTOR_CODE_SNAPSHOT V ").collect() 
        Inserted_rows = str(printed [0]) 
        #success email notifcation
        session.call('system$send_email',
        'EMAIL_NOTIFICATION_INTEGRATION',
        'zzzzzzzz@gmail.com',
        'Success-Snowflake Task Notifcation: TSK_Load_DOT_SELL_THROUGH_DISTRIBUTOR_CODE_SNAPSHOT load Task',
        Inserted_rows)
    except Exception as e:
        #Exception handle via email
        body = '%s\n%s' % (type(e), e)
        fin_bod='Insert to DOT_SELL_THROUGH_DISTRIBUTOR_CODE_SNAPSHOT failed. Check Task History for more details.\n \n'+ body
        session.call('system$send_email',
        'EMAIL_NOTIFICATION_INTEGRATION',
        'zzzzz@gmail.com',
        'Failure-Snowflake Task Notifcation: TSK_Load_DOT_SELL_THROUGH_DISTRIBUTOR_CODE_SNAPSHOT load Task',
        fin_bod)
$$
call Load_DOT_SELL_THROUGH_DISTRIBUTOR_CODE_SNAPSHOT();




   
----***Finally Create a procedure
----Create the Stored procedure once Anonymous procedure is good.
    --drop procedure Load_DOT_SELL_THROUGH_DISTRIBUTOR_CODE_SNAPSHOT();
create or replace procedure PROC_LD_DOT_SELL_THROUGH_DISTRIBUTOR_CODE_SNAPSHOT()
returns string
language python
runtime_version=3.8
packages = ('snowflake-snowpark-python')
handler = 'x'
COMMENT='\n-- Stored Procedure to Load V_DOT_SELL_THROUGH_DISTRIBUTOR_CODE_SNAPSHOT to DOT_SELL_THROUGH_DISTRIBUTOR_CODE_SNAPSHOT every Tuesday  \n-- Proc Name : PROC_LD_DOT_SELL_THROUGH_DISTRIBUTOR_CODE_SNAPSHOT\n-- Input Parameters\n\n'
execute as caller
as
$$
def x(session):
    try:
        printed = session.sql("INSERT INTO DEMO_DB.PUBLIC.DOT_SELL_THROUGH_DISTRIBUTOR_CODE_SNAPSHOT SELECT CURRENT_DATE(),CURRENT_TIMESTAMP,V.* FROM DEMO_DB.PUBLIC.TBL_DOT_SELL_THROUGH_DISTRIBUTOR_CODE_SNAPSHOT V ").collect() 
        Inserted_rows = str(printed [0]) 
        #success email notifcation
        session.call('system$send_email',
        'EMAIL_NOTIFICATION_INTEGRATION',
        'zzzz@gmail.com',
        'Success-Snowflake Task Notifcation: TSK_Load_DOT_SELL_THROUGH_DISTRIBUTOR_CODE_SNAPSHOT load Task',
        Inserted_rows)
    except Exception as e:
        #Exception handle via email
        body = '%s\n%s' % (type(e), e)
        fin_bod='Insert to DOT_SELL_THROUGH_DISTRIBUTOR_CODE_SNAPSHOT failed. Check Task History for more details.\n \n'+ body
        session.call('system$send_email',
        'EMAIL_NOTIFICATION_INTEGRATION',
        'zzzzz@gmail.com',
        'Failure-Snowflake Task Notifcation: TSK_Load_DOT_SELL_THROUGH_DISTRIBUTOR_CODE_SNAPSHOT load Task',
        fin_bod)
$$;
    
--Calling the procedure manually
call PROC_LD_DOT_SELL_THROUGH_DISTRIBUTOR_CODE_SNAPSHOT();
--drop task TASK_Load_DOT_SELL_THROUGH;
    
    
--****Create a task that calls the stored procedure every hour
--- This task is a single PROC DAG where in we schedule it to run using CRON. We can run the task using Virtual Warehouse or servless compute too.

    CREATE
OR
replace task tsk_load_dot_sell_through_distributor_code_snapshot warehouse = compute_wh schedule = 'USING CRON  0 12 * * 2 America/Los_Angeles' comment = ' This Task is used to invoke PROC TASK_Load_DOT_SELL_THROUGH. Load data into V_DOT_SELL_THROUGH_DISTRIBUTOR_CODE_SNAPSHOT ' AS call proc_ld_dot_sell_through_distributor_code_snapshot();

--- Whenever a task is created it is in suspended state. We need to resume it to kick it off.

ALTER TASK TSK_Load_DOT_SELL_THROUGH_DISTRIBUTOR_CODE_SNAPSHOT RESUME;
    --SUSPEND;  --RESUME ;

--- Check Task Run history to validate when it ran
select
    *
from
    table(information_schema.task_history())
order by
    scheduled_time;