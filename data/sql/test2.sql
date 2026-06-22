​--------------------------------DAILY ACTIVE SUBS--------------------------------------

SELECT id_date, count(distinct msisdn)
FROM TIGIST_KEBEDE.MW_DAILY_ACTIVE_SUBS
    WHERE id_date >= 20260520
      AND id_date <= 20260520
AND service_type <> 'B.VOICE_INC_ONNET'      
group by id_date
      order by id_date
      
      
      

      


--------------------------------30 DAYIS DAILY---------------------------------------------------       

  
      

SELECT /*+ parallel(32)*/  count(distinct msisdn)
    FROM  TIGIST_KEBEDE.MW_DAILY_ACTIVE_SUBS
    WHERE id_date >= to_char(to_date('20260520','YYYYMMDD') - 29,'YYYYMMDD')
      AND id_date <= to_char(to_date('20260520','YYYYMMDD'),'YYYYMMDD')
      AND service_type <> 'B.VOICE_INC_ONNET'      
    
      
      
      
      
      

      
      
      
--------------------------------90 DAY DAILY---------------------------------------------------       

    
SELECT /*+ parallel(32)*/  count(distinct msisdn)
    FROM  TIGIST_KEBEDE.MW_DAILY_ACTIVE_SUBS
    WHERE id_date >= to_char(to_date('20260520','YYYYMMDD') - 89,'YYYYMMDD')
      AND id_date <= to_char(to_date('20260520','YYYYMMDD'),'YYYYMMDD')
      AND service_type <> 'B.VOICE_INC_ONNET'      

      
      
      
  
------------------------------DAILY ACTIVE SUB REGIONAL------------------------------------------ 

SELECT /*+ Parallel(32) */
       id_date,
       CASE
           WHEN EXEC_REGION = 'West Addis' THEN 'A.West Addis'
           WHEN EXEC_REGION = 'East Addis' THEN 'B.East Addis'
           WHEN EXEC_REGION = 'Central' THEN 'C.Central'
           WHEN EXEC_REGION = 'South' THEN 'D.South'
           WHEN EXEC_REGION = 'North West' THEN 'E.North West'
           WHEN EXEC_REGION = 'North East' THEN 'F.North East'
           WHEN EXEC_REGION = 'East 1' THEN 'G.East 1'
           WHEN EXEC_REGION = 'East 2' THEN 'H.East 2'
           WHEN EXEC_REGION = 'West' THEN 'I.West'
           WHEN EXEC_REGION = 'North' THEN 'J.North'
           WHEN EXEC_REGION = 'Afar' THEN 'K.Afar'
           ELSE 'L.Uknown'
       END AS REGION,
       COUNT(DISTINCT MSISDN) AS VLR_ATTCHED
FROM (
    SELECT a.*, EXEC_REGION
    FROM (
        SELECT DISTINCT
               msisdn,
               id_date
        FROM TIGIST_KEBEDE.MW_DAILY_ACTIVE_SUBS
        WHERE id_date >=20260520
          AND id_date <=20260520
          AND service_type <> 'B.VOICE_INC_ONNET'
    ) A
    LEFT JOIN (
        SELECT *
        FROM ACTIVATION_MSISDN
    ) B
    ON a.msisdn = b.msisdn
    WHERE a.msisdn IS NOT NULL
)
GROUP BY
    id_date,
    CASE
        WHEN EXEC_REGION = 'West Addis' THEN 'A.West Addis'
        WHEN EXEC_REGION = 'East Addis' THEN 'B.East Addis'
        WHEN EXEC_REGION = 'Central' THEN 'C.Central'
        WHEN EXEC_REGION = 'South' THEN 'D.South'
        WHEN EXEC_REGION = 'North West' THEN 'E.North West'
        WHEN EXEC_REGION = 'North East' THEN 'F.North East'
        WHEN EXEC_REGION = 'East 1' THEN 'G.East 1'
        WHEN EXEC_REGION = 'East 2' THEN 'H.East 2'
        WHEN EXEC_REGION = 'West' THEN 'I.West'
        WHEN EXEC_REGION = 'North' THEN 'J.North'
        WHEN EXEC_REGION = 'Afar' THEN 'K.Afar'
        ELSE 'L.Uknown'
    END
ORDER BY
    id_date,
    CASE
        WHEN EXEC_REGION = 'West Addis' THEN 'A.West Addis'
        WHEN EXEC_REGION = 'East Addis' THEN 'B.East Addis'
        WHEN EXEC_REGION = 'Central' THEN 'C.Central'
        WHEN EXEC_REGION = 'South' THEN 'D.South'
        WHEN EXEC_REGION = 'North West' THEN 'E.North West'
        WHEN EXEC_REGION = 'North East' THEN 'F.North East'
        WHEN EXEC_REGION = 'East 1' THEN 'G.East 1'
        WHEN EXEC_REGION = 'East 2' THEN 'H.East 2'
        WHEN EXEC_REGION = 'West' THEN 'I.West'
        WHEN EXEC_REGION = 'North' THEN 'J.North'
        WHEN EXEC_REGION = 'Afar' THEN 'K.Afar'
        ELSE 'L.Uknown'
    END






      
--------------------------------RECHARGE DAILY---------------------------------------------------       

  SELECT /*+ parallel */
    RR.ID_DATE,
    COUNT(DISTINCT RR.MSISDN) AS SUBS
FROM BI.FCT_FIN_BLNC_MVMN RR
 
LEFT JOIN BI.REF_SUBSCRIBER RS

    ON RR.ID_SUBSCRIBER = RS.ID_SUBSCRIBER
 
 
WHERE RR.ID_DATE BETWEEN 20260519 AND 20260520

  AND RR.ID_RESULTS = 1
 
  AND (
        (
            RR.ID_TRAFFIC_TYPE = 7

            AND RR.ID_FIN_BLNC_MVMN_TYPE NOT IN (273)

            AND RR.ID_RECHARGE_TYPE = 3

            AND RR.VL_ACCNT_BLNC NOT IN (230000,380000)
        )
        OR (

            RR.ID_TRAFFIC_TYPE = 6

            AND RR.ID_FIN_BLNC_MVMN_TYPE = 4
        )
        OR (

            RR.ID_TRAFFIC_TYPE = 4

            AND (

                RR.ID_ACCOUNT IN (211,212)

                OR RR.X_TRANSACTION_ID LIKE '%PRETUPS%'

                OR RR.X_TRANSACTION_ID LIKE '%CRM%'
            )
            AND NOT (

                RS.X_STAFF_FLAG = 1

                AND RR.X_TRANSACTION_ID LIKE '%CRM%'
            )
        )
  )
 
GROUP BY 
    RR.ID_DATE
ORDER BY RR.ID_DATE;
 



---------------------------------RECHARGE REGIONAL----------------------------------------- 
SELECT /*+ parallel */
 RR.ID_DATE,
    CASE   
WHEN L.DS_EXEC_REGION = 'West Addis' THEN 'A.West Addis'   
        WHEN L.DS_EXEC_REGION = 'East Addis' THEN 'B.East Addis'   
        WHEN L.DS_EXEC_REGION = 'Central' THEN 'C.Central'   
        WHEN L.DS_EXEC_REGION = 'South' THEN 'D.South'   
        WHEN L.DS_EXEC_REGION = 'North West' THEN 'E.North West'   
        WHEN L.DS_EXEC_REGION = 'North East' THEN 'F.North East'   
        WHEN L.DS_EXEC_REGION = 'East 1' THEN 'G.East 1'   
        WHEN L.DS_EXEC_REGION = 'East 2' THEN 'H.East 2'   
        WHEN L.DS_EXEC_REGION = 'West' THEN 'I.West'  
        WHEN L.DS_EXEC_REGION = 'North' THEN 'J.North'   
        WHEN L.DS_EXEC_REGION = 'Afar' THEN 'K.Afar'   
        ELSE 'L.Unknown'

    END AS REGION,
    COUNT(DISTINCT RR.MSISDN) AS SUBS,
    SUM(RR.VL_ACCNT_BLNC/(100))/1.2575 AS TRAFFIC
FROM  BI.FCT_FIN_BLNC_MVMN RR 
LEFT JOIN BI.REF_SUBSCRIBER RS
    ON RR.ID_SUBSCRIBER = RS.ID_SUBSCRIBER 
LEFT JOIN BI.REF_LOCATION L
    ON RR.ID_LOCATION= L.ID_LOCATION 
WHERE RR.ID_DATE BETWEEN 20260519 AND 20260520
  AND RR.ID_RESULTS = 1
  AND (
        (
            RR.ID_TRAFFIC_TYPE = 7
            AND RR.ID_FIN_BLNC_MVMN_TYPE NOT IN (273)
            AND RR.ID_RECHARGE_TYPE = 3
            AND RR.VL_ACCNT_BLNC NOT IN (230000,380000)
        )
        OR (
            RR.ID_TRAFFIC_TYPE = 6

          AND RR.ID_FIN_BLNC_MVMN_TYPE = 4
        )
        OR (
           RR.ID_TRAFFIC_TYPE = 4
            AND (
               RR.ID_ACCOUNT IN (211,212)
                OR RR.X_TRANSACTION_ID LIKE '%PRETUPS%'
                OR RR.X_TRANSACTION_ID LIKE '%CRM%'
            )
            AND NOT (
                RS.X_STAFF_FLAG = 1
                AND RR.X_TRANSACTION_ID LIKE '%CRM%'
            )
        )
  )
GROUP BY 
    RR.ID_DATE,
    CASE   
        WHEN L.DS_EXEC_REGION = 'West Addis' THEN 'A.West Addis'   
        WHEN L.DS_EXEC_REGION = 'East Addis' THEN 'B.East Addis'   
        WHEN L.DS_EXEC_REGION = 'Central' THEN 'C.Central'   
        WHEN L.DS_EXEC_REGION = 'South' THEN 'D.South'   
        WHEN L.DS_EXEC_REGION = 'North West' THEN 'E.North West'   
        WHEN L.DS_EXEC_REGION = 'North East' THEN 'F.North East'   
        WHEN L.DS_EXEC_REGION = 'East 1' THEN 'G.East 1'   
        WHEN L.DS_EXEC_REGION = 'East 2' THEN 'H.East 2'   
        WHEN L.DS_EXEC_REGION = 'West' THEN 'I.West'  
        WHEN L.DS_EXEC_REGION = 'North' THEN 'J.North'   
        WHEN L.DS_EXEC_REGION = 'Afar' THEN 'K.Afar'   
        ELSE 'L.Unknown'
    END
ORDER BY RR.ID_DATE;

 

                            




--------------------------------LOAN DAILY--------------------------------------------------- 

SELECT  /*+ Parallel(132) */    
 
ID_DATE,
 
count(DISTINCT msisdn) AS subs,
count(msisdn) AS qty
 
FROM BI.FCT_FIN_BLNC_MVMN a

LEFT JOIN BI.REF_LOCATION L 

    ON a.ID_LOCATION = L.ID_LOCATION
 
WHERE  ID_DATE>=20260519
 
AND ID_DATE<=20260520
 
AND ID_TRAFFIC_TYPE=6
 
AND ID_FIN_BLNC_MVMN_TYPE=4
 
AND ID_RESULTS =1
 
GROUP BY ID_DATE
ORDER BY ID_DATE
 
-----------------------------------LOAN REGIONAL--------------------------------------------------- 

  
SELECT  /*+ Parallel(132) */    
ID_DATE,
CASE   

        WHEN L.DS_EXEC_REGION='West Addis' THEN 'A.West Addis'   
        WHEN L.DS_EXEC_REGION='East Addis' THEN 'B.East Addis'   
        WHEN L.DS_EXEC_REGION='Central' THEN 'C.Central'   
        WHEN L.DS_EXEC_REGION='South' THEN 'D.South'   
        WHEN L.DS_EXEC_REGION='North West' THEN 'E.North West'   
        WHEN L.DS_EXEC_REGION='North East' THEN 'F.North East'   
        WHEN L.DS_EXEC_REGION='East 1' THEN 'G.East 1'   
        WHEN L.DS_EXEC_REGION='East 2' THEN 'H.East 2'   
        WHEN L.DS_EXEC_REGION='West' THEN 'I.West'  
        WHEN L.DS_EXEC_REGION='North' THEN 'J.North'   
        WHEN L.DS_EXEC_REGION='Afar' THEN 'K.Afar' 
        ELSE 'L.Unknown' 
    END AS Region,
 count(DISTINCT msisdn) AS subs,
 sum(((VL_ACCNT_BLNC)/100) + ((VL_FEE)/100))/1.2575 AS TRAFFIC,
 count(msisdn) AS qty
FROM BI.FCT_FIN_BLNC_MVMN a
LEFT JOIN BI.REF_LOCATION L 
    ON a.ID_LOCATION = L.ID_LOCATION 
WHERE  ID_DATE>=20260519 
AND ID_DATE<=20260520 
AND ID_TRAFFIC_TYPE=6 
AND ID_FIN_BLNC_MVMN_TYPE=4 
AND ID_RESULTS =1
GROUP BY ID_DATE,
CASE   

        WHEN L.DS_EXEC_REGION='West Addis' THEN 'A.West Addis'   
        WHEN L.DS_EXEC_REGION='East Addis' THEN 'B.East Addis'   
        WHEN L.DS_EXEC_REGION='Central' THEN 'C.Central'   
        WHEN L.DS_EXEC_REGION='South' THEN 'D.South'   
        WHEN L.DS_EXEC_REGION='North West' THEN 'E.North West'   
        WHEN L.DS_EXEC_REGION='North East' THEN 'F.North East'   
        WHEN L.DS_EXEC_REGION='East 1' THEN 'G.East 1'   
        WHEN L.DS_EXEC_REGION='East 2' THEN 'H.East 2'   
        WHEN L.DS_EXEC_REGION='West' THEN 'I.West'  
        WHEN L.DS_EXEC_REGION='North' THEN 'J.North'   
        WHEN L.DS_EXEC_REGION='Afar' THEN 'K.Afar'
        ELSE 'L.Unknown'
    END
ORDER BY ID_DATE
 


--------------------------------REPAYMENT DAILY--------------------------------------------------- 
  


SELECT /*+ Parallel(132) */
    ID_DATE,

    COUNT(DISTINCT msisdn) AS usb,
    COUNT(msisdn) AS qty,

    SUM(VL_ACCNT_BLNC) / 100 AS AMOUNT_PAID,

    SUM(
        CASE 
            WHEN VL_ACCNT_BLNC_BEFORE = VL_ACCNT_BLNC 
                 AND VL_FEE IS NULL 
            THEN (VL_ACCNT_BLNC / 100) * 0.9  
            ELSE VL_ACCNT_BLNC / 100 
        END
    ) AS Principal_paid_amount,

    SUM((VL_ACCNT_BLNC_AFTER + VL_FEE) / 100) AS unpaid_Principal_amount,

    SUM(
        CASE 
            WHEN VL_ACCNT_BLNC_BEFORE = VL_ACCNT_BLNC 
                 AND VL_FEE IS NULL 
            THEN (VL_ACCNT_BLNC / 100) * 0.1 
        END
    ) AS Paid_service_fee,

    SUM(VL_FEE / 100) AS unpaid_service_fee

FROM BI.FCT_FIN_BLNC_MVMN

WHERE ID_DATE BETWEEN 20260519 AND 20260520
  AND (
        ID_TRAFFIC_TYPE = 9  -- New repayment filter
        OR (
            ID_TRAFFIC_TYPE = 6 
            AND ID_FIN_BLNC_MVMN_TYPE = 28  -- Old repayment filter
           )
        AND NOT (
            ID_FIN_BLNC_MVMN_TYPE = 274 
            AND ID_TRAFFIC_TYPE = 9
        )
      )
  AND ID_RESULTS = 1

GROUP BY ID_DATE
ORDER BY 1;


--------------------------------------REPAYMENT REGIONAL--------------------------------------------------- 


SELECT /*+ Parallel(132) */
ID_DATE,
CASE   
        WHEN L.DS_EXEC_REGION='West Addis' THEN 'A.West Addis'   
        WHEN L.DS_EXEC_REGION='East Addis' THEN 'B.East Addis'   
        WHEN L.DS_EXEC_REGION='Central' THEN 'C.Central'   
        WHEN L.DS_EXEC_REGION='South' THEN 'D.South'   
        WHEN L.DS_EXEC_REGION='North West' THEN 'E.North West'   
        WHEN L.DS_EXEC_REGION='North East' THEN 'F.North East'   
        WHEN L.DS_EXEC_REGION='East 1' THEN 'G.East 1'   
        WHEN L.DS_EXEC_REGION='East 2' THEN 'H.East 2'   
        WHEN L.DS_EXEC_REGION='West' THEN 'I.West'  
        WHEN L.DS_EXEC_REGION='North' THEN 'J.North'   
        WHEN L.DS_EXEC_REGION='Afar' THEN 'K.Afar'   
        ELSE 'L.Unknown' 
    END AS Region,
    count(DISTINCT msisdn) AS SUBS,
    SUM(VL_ACCNT_BLNC/100)/1.2575 AS TRAFFIC,
count( msisdn) AS qty,
sum( CASE WHEN VL_ACCNT_BLNC_BEFORE=VL_ACCNT_BLNC 
AND VL_FEE IS NULL THEN (VL_ACCNT_BLNC/100)*0.9  
ELSE VL_ACCNT_BLNC/100 end) AS Principal_paid_amount,
Sum((VL_ACCNT_BLNC_AFTER + VL_FEE)/100)/1.2575 AS unpaid_Principal_amount,
sum( CASE WHEN VL_ACCNT_BLNC_BEFORE=VL_ACCNT_BLNC 
AND VL_FEE IS NULL THEN (VL_ACCNT_BLNC/100)*0.1 end) AS Paid_service_fee,  
sum(VL_FEE/100) AS unpaid_service_fee
FROM BI.FCT_FIN_BLNC_MVMN a
LEFT JOIN BI.REF_LOCATION L 
    ON a.ID_LOCATION = L.ID_LOCATION 
WHERE ID_DATE between 20260519 AND 20260520 
AND (ID_TRAFFIC_TYPE = 9 --New repayment filter 
OR (ID_TRAFFIC_TYPE = 6 AND ID_FIN_BLNC_MVMN_TYPE =  28) --Old repayment filter 
AND  NOT (ID_FIN_BLNC_MVMN_TYPE=274 AND  ID_TRAFFIC_TYPE =9) 
)
AND ID_RESULTS = 1
GROUP BY ID_DATE,
CASE   

        WHEN L.DS_EXEC_REGION='West Addis' THEN 'A.West Addis'   
        WHEN L.DS_EXEC_REGION='East Addis' THEN 'B.East Addis'   
        WHEN L.DS_EXEC_REGION='Central' THEN 'C.Central'   
        WHEN L.DS_EXEC_REGION='South' THEN 'D.South'   
        WHEN L.DS_EXEC_REGION='North West' THEN 'E.North West'   
        WHEN L.DS_EXEC_REGION='North East' THEN 'F.North East'   
        WHEN L.DS_EXEC_REGION='East 1' THEN 'G.East 1'   
        WHEN L.DS_EXEC_REGION='East 2' THEN 'H.East 2'   
        WHEN L.DS_EXEC_REGION='West' THEN 'I.West'  
        WHEN L.DS_EXEC_REGION='North' THEN 'J.North'   
        WHEN L.DS_EXEC_REGION='Afar' THEN 'K.Afar'
        ELSE 'L.Unknown'
    END
ORDER BY 1  
 
   
  

-----------------------------Direct Bundle Purchase DAILY-------------------------------------- 
 


SELECT id_date, 
       COUNT(DISTINCT MSISDN) AS subs, 
       NVL(SUM(VL_ACCNT_BLNC/100),0) AS Bundle_value 
FROM BI.FCT_FIN_BLNC_MVMN RR 
LEFT JOIN  BI.REF_SUBSCRIBER RS  
       ON RR.ID_SUBSCRIBER = RS.ID_SUBSCRIBER 
WHERE ID_DATE BETWEEN 20260519 AND 20260520 
AND ID_RESULTS = 1 
AND ID_TRAFFIC_TYPE = 4 
AND ( 
 ID_ACCOUNT IN (211,212)  
 OR X_TRANSACTION_ID LIKE '%PRETUPS%'  
        OR X_TRANSACTION_ID LIKE '%CRM%' 
    ) 
    AND NOT (RS.X_STAFF_FLAG = 1 AND X_TRANSACTION_ID LIKE '%CRM%') 
AND (VL_ACCNT_BLNC > 0 OR VL_FEE > 0) 
GROUP BY ID_DATE 
ORDER BY ID_DATE; 
  

--------------------------------------DIRECT BUNDLE PURCHASE REGIONAL--------------------------------------------------- 

 
SELECT id_date,
 CASE  
        WHEN L.DS_EXEC_REGION='West Addis' THEN 'A.West Addis'  
        WHEN L.DS_EXEC_REGION='East Addis' THEN 'B.East Addis'  
        WHEN L.DS_EXEC_REGION='Central' THEN 'C.Central'  
        WHEN L.DS_EXEC_REGION='South' THEN 'D.South'  
        WHEN L.DS_EXEC_REGION='North West' THEN 'E.North West'  
        WHEN L.DS_EXEC_REGION='North East' THEN 'F.North East'  
        WHEN L.DS_EXEC_REGION='East 1' THEN 'G.East 1'  
        WHEN L.DS_EXEC_REGION='East 2' THEN 'H.East 2'  
        WHEN L.DS_EXEC_REGION='West' THEN 'I.West'  
        WHEN L.DS_EXEC_REGION='North' THEN 'J.North'  
        WHEN L.DS_EXEC_REGION='Afar' THEN 'K.Afar'  
        ELSE 'L.Unknown'
    END AS Region,
       COUNT(DISTINCT MSISDN) AS subs,
       NVL(SUM(VL_ACCNT_BLNC/100),0)/1.2575 AS Bundle_VALUE_TRAFFIC
 FROM BI.FCT_FIN_BLNC_MVMN RR
LEFT JOIN  BI.REF_SUBSCRIBER RS  
       ON RR.ID_SUBSCRIBER = RS.ID_SUBSCRIBER
LEFT JOIN BI.REF_LOCATION L
    ON RR.ID_LOCATION = L.ID_LOCATION
WHERE ID_DATE BETWEEN 20260519 AND 20260520
AND ID_RESULTS = 1
AND ID_TRAFFIC_TYPE = 4
AND (
 ID_ACCOUNT IN (211,212)  
 OR X_TRANSACTION_ID LIKE '%PRETUPS%'  
        OR X_TRANSACTION_ID LIKE '%CRM%'
    )
    AND NOT (RS.X_STAFF_FLAG = 1 AND X_TRANSACTION_ID LIKE '%CRM%')
AND (VL_ACCNT_BLNC > 0 OR VL_FEE > 0)
GROUP BY ID_DATE,
    CASE  
        WHEN L.DS_EXEC_REGION='West Addis' THEN 'A.West Addis'  
        WHEN L.DS_EXEC_REGION='East Addis' THEN 'B.East Addis'  
        WHEN L.DS_EXEC_REGION='Central' THEN 'C.Central'  
        WHEN L.DS_EXEC_REGION='South' THEN 'D.South'  
        WHEN L.DS_EXEC_REGION='North West' THEN 'E.North West'  
        WHEN L.DS_EXEC_REGION='North East' THEN 'F.North East'  
        WHEN L.DS_EXEC_REGION='East 1' THEN 'G.East 1'  
        WHEN L.DS_EXEC_REGION='East 2' THEN 'H.East 2'  
        WHEN L.DS_EXEC_REGION='West' THEN 'I.West'  
        WHEN L.DS_EXEC_REGION='North' THEN 'J.North'  
        WHEN L.DS_EXEC_REGION='Afar' THEN 'K.Afar'
        ELSE 'L.Unknown'
    END
ORDER BY ID_DATE



--------------------------------------GA DAILY--------------------------------------------------- 


SELECT  /*+ PARALLEL(32) */ 
DS_ACTIVATION_DATE as event_date, 
COUNT(DISTINCT DS_MSISDN) AS GA
FROM BI.REF_SUBSCRIBER  
WHERE DS_ACTIVATION_DATE>=20260519  
AND DS_ACTIVATION_DATE<=20260520
GROUP BY DS_ACTIVATION_DATE
ORDER BY DS_ACTIVATION_DATE


--------------------------------------GA REGIONAL--------------------------------------------------- 
 
SELECT  /*+ PARALLEL(32) */ 
DS_ACTIVATION_DATE as EVENT_DATE,
CASE   
        WHEN DS_EXEC_REGION='West Addis' THEN 'A.West Addis'   
        WHEN DS_EXEC_REGION='East Addis' THEN 'B.East Addis'   
        WHEN DS_EXEC_REGION='Central' THEN 'C.Central'   
        WHEN DS_EXEC_REGION='South' THEN 'D.South'   
        WHEN DS_EXEC_REGION='North West' THEN 'E.North West'   
        WHEN DS_EXEC_REGION='North East' THEN 'F.North East'   
        WHEN DS_EXEC_REGION='East 1' THEN 'G.East 1'   
        WHEN DS_EXEC_REGION='East 2' THEN 'H.East 2'   
        WHEN DS_EXEC_REGION='West' THEN 'I.West'  
        WHEN DS_EXEC_REGION='North' THEN 'J.North'   
        WHEN DS_EXEC_REGION='Afar' THEN 'K.Afar'   
        ELSE 'L.Unknown' 
    END AS Region,
count(DISTINCT DS_MSISDN) AS SUBS
FROM BI.REF_SUBSCRIBER b 
LEFT JOIN  bi.FCT_SUBSCRIBER_ACTIVATION a 
  ON a.ID_SUBSCRIBER = b.ID_SUBSCRIBER
LEFT JOIN BI.REF_LOCATION C
ON a.ID_LOCATION_CREATED_USER = c.ID_LOCATION 
WHERE DS_ACTIVATION_DATE>=20260519
AND DS_ACTIVATION_DATE<=20260520
GROUP BY DS_ACTIVATION_DATE,
CASE   
WHEN DS_EXEC_REGION='West Addis' THEN 'A.West Addis'   
        WHEN DS_EXEC_REGION='East Addis' THEN 'B.East Addis'   
        WHEN DS_EXEC_REGION='Central' THEN 'C.Central'   
        WHEN DS_EXEC_REGION='South' THEN 'D.South'   
        WHEN DS_EXEC_REGION='North West' THEN 'E.North West'   
        WHEN DS_EXEC_REGION='North East' THEN 'F.North East'   
        WHEN DS_EXEC_REGION='East 1' THEN 'G.East 1'   
        WHEN DS_EXEC_REGION='East 2' THEN 'H.East 2'   
        WHEN DS_EXEC_REGION='West' THEN 'I.West'  
        WHEN DS_EXEC_REGION='North' THEN 'J.North'   
        WHEN DS_EXEC_REGION='Afar' THEN 'K.Afar'   
        ELSE 'L.Unknown' 
    END 
    ORDER BY DS_ACTIVATION_DATE
 



-----------------------------------VOICE DAILY--------------------------------------------------- 

  


SELECT /*+ Parallel(64) */  

    ID_DATE,  

    COUNT(DISTINCT calling_msisdn) AS total_Subs,

    COUNT(
        DISTINCT CASE 
            WHEN (
                    (RA.DS_ACCOUNT_GROUP LIKE 'Account' 
                     OR (RA.DS_ACCOUNT_GROUP LIKE 'Bucket' 
                         AND RP.X_BUNDLE_TYPE IN ('Inbundle', 'Unlimited Bundles')
                        )
                    )    
                    OR RA.DS_ACCOUNT_ID LIKE 'BalanceAllowanceLimit-LOAN_SECBAL%'  
                    OR (
                        RP.X_BUNDLE_TYPE LIKE 'OOBundle' 
                        AND RA.DS_ACCOUNT_ID NOT LIKE '%FREE%' 
                        AND RA.DS_ACCOUNT_ID NOT LIKE 'BalanceAllowanceLimit-Mpesa%'
                       )   
                 ) 
            THEN charging_msisdn 
        END
    ) AS Paid_Subs,  

    COUNT(
        DISTINCT CASE 
            WHEN NOT (
                    (RA.DS_ACCOUNT_GROUP LIKE 'Account' 
                     OR (RA.DS_ACCOUNT_GROUP LIKE 'Bucket' 
                         AND RP.X_BUNDLE_TYPE IN ('Inbundle', 'Unlimited Bundles')
                        )
                    )    
                    OR RA.DS_ACCOUNT_ID LIKE 'BalanceAllowanceLimit-LOAN_SECBAL%'  
                    OR (
                        RP.X_BUNDLE_TYPE LIKE 'OOBundle' 
                        AND RA.DS_ACCOUNT_ID NOT LIKE '%FREE%' 
                        AND RA.DS_ACCOUNT_ID NOT LIKE 'BalanceAllowanceLimit-Mpesa%'
                       )   
                 ) 
            THEN charging_msisdn 
        END
    ) AS Free_Subs,  

    COUNT(
        DISTINCT CASE 
            WHEN FT.X_ADDITIONAL_INFO LIKE 'J4U_%' 
            THEN charging_msisdn 
        END
    ) AS J4U_paid_logic,    

    COUNT(
        DISTINCT CASE 
            WHEN ID_ROAMING_TYPE = 2 
            THEN charging_msisdn 
        END
    ) AS Outbound_safari  

FROM BI.FCT_TRAFFIC FT  

LEFT JOIN BI.REF_ACCOUNT RA 
    ON FT.ID_ACCOUNT = RA.ID_ACCOUNT   

LEFT JOIN BI.REF_PRODUCT RP 
    ON FT.ID_PRODUCT = RP.ID_PRODUCT   

WHERE ID_DATE BETWEEN 20260519 AND 20260520   
  AND ID_TRAFFIC_TYPE = 1

GROUP BY ID_DATE   

ORDER BY ID_DATE;





--------------------------------------VOICE REGIONAL--------------------------------------------------- 

  
SELECT /*+ Parallel(64) */  
    FT.ID_DATE,
    CASE   
        WHEN L.DS_EXEC_REGION = 'West Addis'  THEN 'A.West Addis'   
        WHEN L.DS_EXEC_REGION = 'East Addis'  THEN 'B.East Addis'   
        WHEN L.DS_EXEC_REGION = 'Central'     THEN 'C.Central'   
        WHEN L.DS_EXEC_REGION = 'South'       THEN 'D.South'   
        WHEN L.DS_EXEC_REGION = 'North West'  THEN 'E.North West'   
        WHEN L.DS_EXEC_REGION = 'North East'  THEN 'F.North East'   
        WHEN L.DS_EXEC_REGION = 'East 1'      THEN 'G.East 1'   
        WHEN L.DS_EXEC_REGION = 'East 2'      THEN 'H.East 2'   
        WHEN L.DS_EXEC_REGION = 'West'        THEN 'I.West'  
        WHEN L.DS_EXEC_REGION = 'North'       THEN 'J.North'   
        WHEN L.DS_EXEC_REGION = 'Afar'        THEN 'K.Afar'   
        ELSE 'L.Unknown' 
    END AS Region,
    COUNT(DISTINCT FT.calling_msisdn) AS total_Subs,  
    SUM(FT.VL_RATE_USAGE)/60 AS TRAFFIC

    /* COUNT(
        DISTINCT CASE 
            WHEN (
                    (RA.DS_ACCOUNT_GROUP LIKE 'Account' 
                     OR (RA.DS_ACCOUNT_GROUP LIKE 'Bucket' 
                         AND RP.X_BUNDLE_TYPE IN ('Inbundle', 'Unlimited Bundles')
                        )
                    )    
                    OR RA.DS_ACCOUNT_ID LIKE 'BalanceAllowanceLimit-LOAN_SECBAL%'  
                    OR (
                        RP.X_BUNDLE_TYPE LIKE 'OOBundle' 
                        AND RA.DS_ACCOUNT_ID NOT LIKE '%FREE%' 
                        AND RA.DS_ACCOUNT_ID NOT LIKE 'BalanceAllowanceLimit-Mpesa%'
                       )   
                 ) 
            THEN FT.calling_msisdn 
        END
    ) AS Paid_Subs,  
    COUNT(
        DISTINCT CASE 
            WHEN NOT (
                    (RA.DS_ACCOUNT_GROUP LIKE 'Account' 
                     OR (RA.DS_ACCOUNT_GROUP LIKE 'Bucket' 
                         AND RP.X_BUNDLE_TYPE IN ('Inbundle', 'Unlimited Bundles')
                        )
                    )    
                    OR RA.DS_ACCOUNT_ID LIKE 'BalanceAllowanceLimit-LOAN_SECBAL%'  
                    OR (
                        RP.X_BUNDLE_TYPE LIKE 'OOBundle' 
                        AND RA.DS_ACCOUNT_ID NOT LIKE '%FREE%' 
                        AND RA.DS_ACCOUNT_ID NOT LIKE 'BalanceAllowanceLimit-Mpesa%'
                       )   
                 ) 
            THEN FT.calling_msisdn 
        END
    ) AS Free_Subs,  

    COUNT(
        DISTINCT CASE 
            WHEN FT.X_ADDITIONAL_INFO LIKE 'J4U_%' 
            THEN FT.calling_msisdn 
        END
    ) AS J4U_paid_logic,    

    COUNT(
        DISTINCT CASE 
            WHEN FT.ID_ROAMING_TYPE = 2 
            THEN FT.calling_msisdn 
        END
    ) AS Outbound_safari */

FROM BI.FCT_TRAFFIC FT  
LEFT JOIN BI.REF_ACCOUNT RA 
    ON FT.ID_ACCOUNT = RA.ID_ACCOUNT   
LEFT JOIN BI.REF_PRODUCT RP 
    ON FT.ID_PRODUCT = RP.ID_PRODUCT  
LEFT JOIN BI.REF_LOCATION L 
    ON FT.ID_LOCATION_CALLING = L.ID_LOCATION
WHERE FT.ID_DATE BETWEEN 20260519 AND 20260520 
  AND FT.ID_TRAFFIC_TYPE = 1
GROUP BY 
    FT.ID_DATE,
    CASE   
        WHEN L.DS_EXEC_REGION = 'West Addis'  THEN 'A.West Addis'   
        WHEN L.DS_EXEC_REGION = 'East Addis'  THEN 'B.East Addis'   
        WHEN L.DS_EXEC_REGION = 'Central'     THEN 'C.Central'   
        WHEN L.DS_EXEC_REGION = 'South'       THEN 'D.South'   
        WHEN L.DS_EXEC_REGION = 'North West'  THEN 'E.North West'   
        WHEN L.DS_EXEC_REGION = 'North East'  THEN 'F.North East'   
        WHEN L.DS_EXEC_REGION = 'East 1'      THEN 'G.East 1'   
        WHEN L.DS_EXEC_REGION = 'East 2'      THEN 'H.East 2'   
        WHEN L.DS_EXEC_REGION = 'West'        THEN 'I.West'  
        WHEN L.DS_EXEC_REGION = 'North'       THEN 'J.North'   
        WHEN L.DS_EXEC_REGION = 'Afar'        THEN 'K.Afar'
        ELSE 'L.Unknown'
    END
ORDER BY FT.ID_DATE;






--------------------------------------DATA DAILY--------------------------------------------------- 

  SELECT /*+ Parallel(64) */  

    ID_DATE,  

    COUNT(DISTINCT CHARGING_msisdn) AS total_Subs

    /*COUNT(
        DISTINCT CASE 
            WHEN (
                    (RA.DS_ACCOUNT_GROUP LIKE 'Account' 
                     OR (RA.DS_ACCOUNT_GROUP LIKE 'Bucket' 
                         AND RP.X_BUNDLE_TYPE IN ('Inbundle', 'Unlimited Bundles')
                        )
                    )    
                    OR RA.DS_ACCOUNT_ID LIKE 'BalanceAllowanceLimit-LOAN_SECBAL%'  
                    OR (
                        RP.X_BUNDLE_TYPE LIKE 'OOBundle' 
                        AND RA.DS_ACCOUNT_ID NOT LIKE '%FREE%' 
                        AND RA.DS_ACCOUNT_ID NOT LIKE 'BalanceAllowanceLimit-Mpesa%'
                       )   
                 ) 
            THEN charging_msisdn 
        END
    ) AS Paid_Subs,  

    COUNT(
        DISTINCT CASE 
            WHEN NOT (
                    (RA.DS_ACCOUNT_GROUP LIKE 'Account' 
                     OR (RA.DS_ACCOUNT_GROUP LIKE 'Bucket' 
                         AND RP.X_BUNDLE_TYPE IN ('Inbundle', 'Unlimited Bundles')
                        )
                    )    
                    OR RA.DS_ACCOUNT_ID LIKE 'BalanceAllowanceLimit-LOAN_SECBAL%'  
                    OR (
                        RP.X_BUNDLE_TYPE LIKE 'OOBundle' 
                        AND RA.DS_ACCOUNT_ID NOT LIKE '%FREE%' 
                        AND RA.DS_ACCOUNT_ID NOT LIKE 'BalanceAllowanceLimit-Mpesa%'
                       )   
                 ) 
            THEN charging_msisdn 
        END
    ) AS Free_Subs,  

    COUNT(
        DISTINCT CASE 
            WHEN FT.X_ADDITIONAL_INFO LIKE 'J4U_%' 
            THEN charging_msisdn 
        END
    ) AS J4U_paid_logic,    

    COUNT(
        DISTINCT CASE 
            WHEN ID_ROAMING_TYPE = 3
            THEN charging_msisdn 
        END
    ) AS Outbound_safari */ 

FROM BI.FCT_TRAFFIC FT  

LEFT JOIN BI.REF_ACCOUNT RA 
    ON FT.ID_ACCOUNT = RA.ID_ACCOUNT   

LEFT JOIN BI.REF_PRODUCT RP 
    ON FT.ID_PRODUCT = RP.ID_PRODUCT   

WHERE ID_DATE BETWEEN 20260519 AND 20260520   
  AND ID_TRAFFIC_TYPE = 3

GROUP BY ID_DATE   
ORDER BY ID_DATE;



--------------------------------------DATA REGIONAL--------------------------------------------------- 




SELECT /*+ Parallel(64) */  
    FT.ID_DATE,
    CASE   
        WHEN L.DS_EXEC_REGION = 'West Addis'  THEN 'A.West Addis'   
        WHEN L.DS_EXEC_REGION = 'East Addis'  THEN 'B.East Addis'   
        WHEN L.DS_EXEC_REGION = 'Central'     THEN 'C.Central'   
        WHEN L.DS_EXEC_REGION = 'South'       THEN 'D.South'   
        WHEN L.DS_EXEC_REGION = 'North West'  THEN 'E.North West'   
        WHEN L.DS_EXEC_REGION = 'North East'  THEN 'F.North East'   
        WHEN L.DS_EXEC_REGION = 'East 1'      THEN 'G.East 1'   
        WHEN L.DS_EXEC_REGION = 'East 2'      THEN 'H.East 2'   
        WHEN L.DS_EXEC_REGION = 'West'        THEN 'I.West'  
        WHEN L.DS_EXEC_REGION = 'North'       THEN 'J.North'   
        WHEN L.DS_EXEC_REGION = 'Afar'        THEN 'K.Afar'   
        ELSE 'L.Unknown' 
    END AS Region,
    COUNT(DISTINCT FT.CHARGING_msisdn) AS total_Subs,
     SUM(FT.VL_RATE_USAGE)/(1024*1024*1024) AS TRAFFIC

    /*,  

    COUNT(
        DISTINCT CASE 
            WHEN (
                    (RA.DS_ACCOUNT_GROUP LIKE 'Account' 
                     OR (RA.DS_ACCOUNT_GROUP LIKE 'Bucket' 
                         AND RP.X_BUNDLE_TYPE IN ('Inbundle', 'Unlimited Bundles')
                        )
                    )    
                    OR RA.DS_ACCOUNT_ID LIKE 'BalanceAllowanceLimit-LOAN_SECBAL%'  
                    OR (
                        RP.X_BUNDLE_TYPE LIKE 'OOBundle' 
                        AND RA.DS_ACCOUNT_ID NOT LIKE '%FREE%' 
                        AND RA.DS_ACCOUNT_ID NOT LIKE 'BalanceAllowanceLimit-Mpesa%'
                       )   
                 ) 
            THEN FT.calling_msisdn 
        END
    ) AS Paid_Subs,  

    COUNT(
        DISTINCT CASE 
            WHEN NOT (
                    (RA.DS_ACCOUNT_GROUP LIKE 'Account' 
                     OR (RA.DS_ACCOUNT_GROUP LIKE 'Bucket' 
                         AND RP.X_BUNDLE_TYPE IN ('Inbundle', 'Unlimited Bundles')
                        )
                    )    
                    OR RA.DS_ACCOUNT_ID LIKE 'BalanceAllowanceLimit-LOAN_SECBAL%'  
                    OR (
                        RP.X_BUNDLE_TYPE LIKE 'OOBundle' 
                        AND RA.DS_ACCOUNT_ID NOT LIKE '%FREE%' 
                        AND RA.DS_ACCOUNT_ID NOT LIKE 'BalanceAllowanceLimit-Mpesa%'
                       )   
                 ) 
            THEN FT.calling_msisdn 
        END
    ) AS Free_Subs,  

    COUNT(
        DISTINCT CASE 
            WHEN FT.X_ADDITIONAL_INFO LIKE 'J4U_%' 
            THEN FT.calling_msisdn 
        END
    ) AS J4U_paid_logic,    

    COUNT(
        DISTINCT CASE 
            WHEN FT.ID_ROAMING_TYPE = 2 
            THEN FT.calling_msisdn 
        END
    ) AS Outbound_safari */
FROM BI.FCT_TRAFFIC FT  
LEFT JOIN BI.REF_ACCOUNT RA 
    ON FT.ID_ACCOUNT = RA.ID_ACCOUNT   
LEFT JOIN BI.REF_PRODUCT RP 
    ON FT.ID_PRODUCT = RP.ID_PRODUCT  
LEFT JOIN BI.REF_LOCATION L 
    ON FT.ID_LOCATION_CALLING = L.ID_LOCATION
WHERE FT.ID_DATE BETWEEN 20260519 AND 20260520 
  AND FT.ID_TRAFFIC_TYPE = 3
GROUP BY 
    FT.ID_DATE,
    CASE   
        WHEN L.DS_EXEC_REGION = 'West Addis'  THEN 'A.West Addis'   
        WHEN L.DS_EXEC_REGION = 'East Addis'  THEN 'B.East Addis'   
        WHEN L.DS_EXEC_REGION = 'Central'     THEN 'C.Central'   
        WHEN L.DS_EXEC_REGION = 'South'       THEN 'D.South'   
        WHEN L.DS_EXEC_REGION = 'North West'  THEN 'E.North West'   
        WHEN L.DS_EXEC_REGION = 'North East'  THEN 'F.North East'   
        WHEN L.DS_EXEC_REGION = 'East 1'      THEN 'G.East 1'   
        WHEN L.DS_EXEC_REGION = 'East 2'      THEN 'H.East 2'   
        WHEN L.DS_EXEC_REGION = 'West'        THEN 'I.West'  
        WHEN L.DS_EXEC_REGION = 'North'       THEN 'J.North'   
        WHEN L.DS_EXEC_REGION = 'Afar'        THEN 'K.Afar'
        ELSE 'L.Unknown'
    END
ORDER BY FT.ID_DATE;




--------------------------------------SMS DAILY--------------------------------------------------- 

  

    

SELECT /*+ Parallel(64) */  

    ID_DATE,  

    COUNT(DISTINCT calling_msisdn) AS total_Subs,

    COUNT(
        DISTINCT CASE 
            WHEN (
                    (RA.DS_ACCOUNT_GROUP LIKE 'Account' 
                     OR (RA.DS_ACCOUNT_GROUP LIKE 'Bucket' 
                         AND RP.X_BUNDLE_TYPE IN ('Inbundle', 'Unlimited Bundles')
                        )
                    )    
                    OR RA.DS_ACCOUNT_ID LIKE 'BalanceAllowanceLimit-LOAN_SECBAL%'  
                    OR (
                        RP.X_BUNDLE_TYPE LIKE 'OOBundle' 
                        AND RA.DS_ACCOUNT_ID NOT LIKE '%FREE%' 
                        AND RA.DS_ACCOUNT_ID NOT LIKE 'BalanceAllowanceLimit-Mpesa%'
                       )   
                 ) 
            THEN charging_msisdn 
        END
    ) AS Paid_Subs,  

    COUNT(
        DISTINCT CASE 
            WHEN NOT (
                    (RA.DS_ACCOUNT_GROUP LIKE 'Account' 
                     OR (RA.DS_ACCOUNT_GROUP LIKE 'Bucket' 
                         AND RP.X_BUNDLE_TYPE IN ('Inbundle', 'Unlimited Bundles')
                        )
                    )    
                    OR RA.DS_ACCOUNT_ID LIKE 'BalanceAllowanceLimit-LOAN_SECBAL%'  
                    OR (
                        RP.X_BUNDLE_TYPE LIKE 'OOBundle' 
                        AND RA.DS_ACCOUNT_ID NOT LIKE '%FREE%' 
                        AND RA.DS_ACCOUNT_ID NOT LIKE 'BalanceAllowanceLimit-Mpesa%'
                       )   
                 ) 
            THEN charging_msisdn 
        END
    ) AS Free_Subs,  

    COUNT(
        DISTINCT CASE 
            WHEN FT.X_ADDITIONAL_INFO LIKE 'J4U_%' 
            THEN charging_msisdn 
        END
    ) AS J4U_paid_logic,    

    COUNT(
        DISTINCT CASE 
            WHEN ID_ROAMING_TYPE = 2 
            THEN charging_msisdn 
        END
    ) AS Outbound_safari  

FROM BI.FCT_TRAFFIC FT  

LEFT JOIN BI.REF_ACCOUNT RA 
    ON FT.ID_ACCOUNT = RA.ID_ACCOUNT   

LEFT JOIN BI.REF_PRODUCT RP 
    ON FT.ID_PRODUCT = RP.ID_PRODUCT   

WHERE ID_DATE BETWEEN 20260519 AND 20260520   
  AND ID_TRAFFIC_TYPE = 2

GROUP BY ID_DATE   

ORDER BY ID_DATE;



--------------------------------------SMS REGIONAL--------------------------------------------------- 

  

SELECT /*+ Parallel(64) */  
    FT.ID_DATE,
    CASE   
        WHEN L.DS_EXEC_REGION = 'West Addis'  THEN 'A.West Addis'   
        WHEN L.DS_EXEC_REGION = 'East Addis'  THEN 'B.East Addis'   
        WHEN L.DS_EXEC_REGION = 'Central'     THEN 'C.Central'   
        WHEN L.DS_EXEC_REGION = 'South'       THEN 'D.South'   
        WHEN L.DS_EXEC_REGION = 'North West'  THEN 'E.North West'   
        WHEN L.DS_EXEC_REGION = 'North East'  THEN 'F.North East'   
        WHEN L.DS_EXEC_REGION = 'East 1'      THEN 'G.East 1'   
        WHEN L.DS_EXEC_REGION = 'East 2'      THEN 'H.East 2'   
        WHEN L.DS_EXEC_REGION = 'West'        THEN 'I.West'  
        WHEN L.DS_EXEC_REGION = 'North'       THEN 'J.North'   
        WHEN L.DS_EXEC_REGION = 'Afar'        THEN 'K.Afar'   
        ELSE 'L.Unknown' 
    END AS Region,
    COUNT(DISTINCT FT.calling_msisdn) AS Subs ,
    SUM(FT.VL_RATE_USAGE) AS TRAFFIC
    /* COUNT(
        DISTINCT CASE 
            WHEN (
                    (RA.DS_ACCOUNT_GROUP LIKE 'Account' 
                     OR (RA.DS_ACCOUNT_GROUP LIKE 'Bucket' 
                         AND RP.X_BUNDLE_TYPE IN ('Inbundle', 'Unlimited Bundles')
                        )
                    )    
                    OR RA.DS_ACCOUNT_ID LIKE 'BalanceAllowanceLimit-LOAN_SECBAL%'  
                    OR (
                        RP.X_BUNDLE_TYPE LIKE 'OOBundle' 
                        AND RA.DS_ACCOUNT_ID NOT LIKE '%FREE%' 
                        AND RA.DS_ACCOUNT_ID NOT LIKE 'BalanceAllowanceLimit-Mpesa%'
                       )   
                 ) 
            THEN FT.calling_msisdn 
        END
    ) AS Paid_Subs,  

    COUNT(
        DISTINCT CASE 
            WHEN NOT (
                    (RA.DS_ACCOUNT_GROUP LIKE 'Account' 
                     OR (RA.DS_ACCOUNT_GROUP LIKE 'Bucket' 
                         AND RP.X_BUNDLE_TYPE IN ('Inbundle', 'Unlimited Bundles')
                        )
                    )    
                    OR RA.DS_ACCOUNT_ID LIKE 'BalanceAllowanceLimit-LOAN_SECBAL%'  
                    OR (
                        RP.X_BUNDLE_TYPE LIKE 'OOBundle' 
                        AND RA.DS_ACCOUNT_ID NOT LIKE '%FREE%' 
                        AND RA.DS_ACCOUNT_ID NOT LIKE 'BalanceAllowanceLimit-Mpesa%'
                       )   
                 ) 
            THEN FT.calling_msisdn 
        END
    ) AS Free_Subs,  

    COUNT(
        DISTINCT CASE 
            WHEN FT.X_ADDITIONAL_INFO LIKE 'J4U_%' 
            THEN FT.calling_msisdn 
        END
    ) AS J4U_paid_logic,    

    COUNT(
        DISTINCT CASE 
            WHEN FT.ID_ROAMING_TYPE = 2 
            THEN FT.calling_msisdn 
        END
    ) AS Outbound_safari */

FROM BI.FCT_TRAFFIC FT  
LEFT JOIN BI.REF_ACCOUNT RA 
    ON FT.ID_ACCOUNT = RA.ID_ACCOUNT   
LEFT JOIN BI.REF_PRODUCT RP 
    ON FT.ID_PRODUCT = RP.ID_PRODUCT  
LEFT JOIN BI.REF_LOCATION L 
    ON FT.ID_LOCATION_CALLING = L.ID_LOCATION
WHERE FT.ID_DATE BETWEEN 20260519 AND 20260520 
  AND FT.ID_TRAFFIC_TYPE = 2

GROUP BY 
    FT.ID_DATE,
    CASE   
        WHEN L.DS_EXEC_REGION = 'West Addis'  THEN 'A.West Addis'   
        WHEN L.DS_EXEC_REGION = 'East Addis'  THEN 'B.East Addis'   
        WHEN L.DS_EXEC_REGION = 'Central'     THEN 'C.Central'   
        WHEN L.DS_EXEC_REGION = 'South'       THEN 'D.South'   
        WHEN L.DS_EXEC_REGION = 'North West'  THEN 'E.North West'   
        WHEN L.DS_EXEC_REGION = 'North East'  THEN 'F.North East'   
        WHEN L.DS_EXEC_REGION = 'East 1'      THEN 'G.East 1'   
        WHEN L.DS_EXEC_REGION = 'East 2'      THEN 'H.East 2'   
        WHEN L.DS_EXEC_REGION = 'West'        THEN 'I.West'  
        WHEN L.DS_EXEC_REGION = 'North'       THEN 'J.North'   
        WHEN L.DS_EXEC_REGION = 'Afar'        THEN 'K.Afar'
        ELSE 'L.Unknown'
    END
ORDER BY FT.ID_DATE;




