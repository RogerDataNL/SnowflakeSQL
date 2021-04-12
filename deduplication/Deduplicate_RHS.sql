--test RHS dataset to verify what duplicates will be deleted 
with test_dataset as (
  select
  12345 as CUSTOMER_KEY,666 as JSON_SRC_KEY,'hash_A' as JSON_SRC_MD5,'2021-02-10 13:00:10.690 ' as META_SOURCE_DTS,'2021-02-10 13:00:51.706' as META_LOAD_DTS,'r' as META_CDC_DML_TYPE ,1 as META_UNIQUE_KEY
  union all
  select 12345 as CUSTOMER_KEY,666 as JSON_SRC_KEY,'hash_A' as JSON_SRC_MD5,'2021-03-10 13:06:10.690 ' as META_SOURCE_DTS,'2021-03-10 13:06:51.706' as META_LOAD_DTS,'c' as META_CDC_DML_TYPE ,2 as META_UNIQUE_KEY
  union all
  select 12345 as CUSTOMER_KEY,666 as JSON_SRC_KEY,'hash_B' as JSON_SRC_MD5,'2021-03-11 13:06:10.690 ' as META_SOURCE_DTS,'2021-03-11 13:06:51.706' as META_LOAD_DTS,'u' as META_CDC_DML_TYPE ,3 as META_UNIQUE_KEY
  union all
  select 12345 as CUSTOMER_KEY,666 as JSON_SRC_KEY,'hash_B' as JSON_SRC_MD5,'2021-03-11 13:06:10.690 ' as META_SOURCE_DTS,'2021-03-11 13:06:51.706' as META_LOAD_DTS,'u' as META_CDC_DML_TYPE ,4 as META_UNIQUE_KEY
  union all
  select 12345 as CUSTOMER_KEY,666 as JSON_SRC_KEY,'hash_B' as JSON_SRC_MD5,'2021-03-11 13:07:10.690 ' as META_SOURCE_DTS,'2021-03-11 13:07:51.706' as META_LOAD_DTS,'r' as META_CDC_DML_TYPE ,5 as META_UNIQUE_KEY
  union all
  select 12345 as CUSTOMER_KEY,666 as JSON_SRC_KEY,'hash_B' as JSON_SRC_MD5,'2021-03-11 13:07:10.690 ' as META_SOURCE_DTS,'2021-03-11 13:07:51.706' as META_LOAD_DTS,'d' as META_CDC_DML_TYPE ,6 as META_UNIQUE_KEY
  union all
  select 12345 as CUSTOMER_KEY,666 as JSON_SRC_KEY,'hash_B' as JSON_SRC_MD5,'2021-03-13 13:06:10.690 ' as META_SOURCE_DTS,'2021-03-13 13:06:51.706' as META_LOAD_DTS,'d' as META_CDC_DML_TYPE ,66 as META_UNIQUE_KEY
  union all
  select 12345 as CUSTOMER_KEY,666 as JSON_SRC_KEY,'hash_B' as JSON_SRC_MD5,'2021-03-14 13:06:10.690 ' as META_SOURCE_DTS,'2021-03-14 13:06:51.706' as META_LOAD_DTS,'c' as META_CDC_DML_TYPE ,7 as META_UNIQUE_KEY
  union all
  select 12345 as CUSTOMER_KEY,666 as JSON_SRC_KEY,'hash_B' as JSON_SRC_MD5,'2021-03-14 13:06:10.690 ' as META_SOURCE_DTS,'2021-03-15 13:06:51.706' as META_LOAD_DTS,'c' as META_CDC_DML_TYPE ,8 as META_UNIQUE_KEY
  union all
  select 12345 as CUSTOMER_KEY,666 as JSON_SRC_KEY,'hash_C' as JSON_SRC_MD5,'2021-03-16 13:06:10.690 ' as META_SOURCE_DTS,'2021-03-16 13:06:51.706' as META_LOAD_DTS,'u' as META_CDC_DML_TYPE ,9 as META_UNIQUE_KEY
  union all
  select 12345 as CUSTOMER_KEY,666 as JSON_SRC_KEY,'hash_C' as JSON_SRC_MD5,'2021-03-16 13:06:10.690 ' as META_SOURCE_DTS,'2021-03-16 13:06:51.706' as META_LOAD_DTS,'d' as META_CDC_DML_TYPE ,10 as META_UNIQUE_KEY
  union all
  select 12345 as CUSTOMER_KEY,666 as JSON_SRC_KEY,'hash_C' as JSON_SRC_MD5,'2021-03-16 13:06:10.690 ' as META_SOURCE_DTS,'2021-03-16 13:06:52.706' as META_LOAD_DTS,'d' as META_CDC_DML_TYPE ,11 as META_UNIQUE_KEY
  union all
  select 12345 as CUSTOMER_KEY,666 as JSON_SRC_KEY,'hash_C' as JSON_SRC_MD5,'2021-03-16 13:06:10.690 ' as META_SOURCE_DTS,'2021-03-16 13:06:52.706' as META_LOAD_DTS,'c' as META_CDC_DML_TYPE ,12 as META_UNIQUE_KEY
  union all
  select 12345 as CUSTOMER_KEY,666 as JSON_SRC_KEY,'hash_D' as JSON_SRC_MD5,'2021-03-16 13:06:10.690 ' as META_SOURCE_DTS,'2021-03-16 13:06:52.706' as META_LOAD_DTS,'u' as META_CDC_DML_TYPE ,13 as META_UNIQUE_KEY
  union all
  select 12345 as CUSTOMER_KEY,666 as JSON_SRC_KEY,'hash_D' as JSON_SRC_MD5,'2021-03-16 13:06:10.690 ' as META_SOURCE_DTS,'2021-03-16 13:06:52.706' as META_LOAD_DTS,'u' as META_CDC_DML_TYPE ,14 as META_UNIQUE_KEY
)
--select the next row within an CUSTOMER_KEY / JSON_SRC_KEY / JSON_SRC_MD5 partitioning based on time sorting and META_UNIQUE_KEY
, vw as (
select 
  CUSTOMER_KEY,JSON_SRC_KEY,JSON_SRC_MD5,META_SOURCE_DTS,META_LOAD_DTS, META_CDC_DML_TYPE,META_UNIQUE_KEY
  ,LEAD(META_CDC_DML_TYPE,1) over (partition by CUSTOMER_KEY,JSON_SRC_KEY,JSON_SRC_MD5 order by META_SOURCE_DTS,META_LOAD_DTS,META_UNIQUE_KEY ASC ) as NEXT_DML_DELETE
  ,LEAD(META_UNIQUE_KEY,1) over (partition by CUSTOMER_KEY,JSON_SRC_KEY,JSON_SRC_MD5 order by META_SOURCE_DTS,META_LOAD_DTS ASC,META_UNIQUE_KEY ASC ) as NEXT_META_UNIQUE_KEY_DELETE
  from  test_dataset 
)
--These are the keys to join on with the target table / emits the keys of the rows that need to be deleted
select CUSTOMER_KEY,JSON_SRC_KEY,JSON_SRC_MD5,NEXT_META_UNIQUE_KEY_DELETE as META_UNIQUE_KEY
 from vw
where 1=1
--delete duplicated CDC reads /inserts / updates and duplicated deletes seperately
and ((META_CDC_DML_TYPE in ('c','r','u') and NEXT_DML_DELETE in ('c','r','u')) OR (META_CDC_DML_TYPE ='d' and NEXT_DML_DELETE='d'))
and NEXT_META_UNIQUE_KEY_DELETE is not null
order by CUSTOMER_KEY,JSON_SRC_KEY,META_SOURCE_DTS,META_LOAD_DTS,META_UNIQUE_KEY;
;
