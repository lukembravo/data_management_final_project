DROP TABLE Product_Management;
DROP VIEW orders_view;
DROP VIEW order_details_view;
DROP VIEW MTOWH_PRODUCTS_VIEW;
DROP VIEW WHTOR_PRODUCTS_VIEW;

--CREATING DW-------------------------------------------------------------------------------------------------------------------

CREATE TABLE Product_Management(
  Order_ID NUMBER(7),
  Product_ID NUMBER(7),
  Customer_ID NUMBER(7),
  Order_Detail_ID NUMBER(7),
  Total_Cost_of_Order NUMBER,
  M_ID NUMBER(7),
  M_WH_ID NUMBER(7),
  WH_ID NUMBER(7),
  WH_R_ID NUMBER(7),
  R_ID NUMBER(7)
  --CONSTRAINT pk_product_m PRIMARY KEY (Order_ID,Product_ID)
);

--CREATING VIEWS----------------------------------------------------------------------------------------------------------------

CREATE OR REPLACE VIEW orders_view AS
SELECT 
o.Order_ID,
Customer_ID,
od.Product_ID AS Product_ID
FROM orders o JOIN Order_Details od ON od.Order_ID = o.Order_ID;

CREATE OR REPLACE VIEW order_details_view AS
SELECT 
Order_ID,
od.Product_ID as Product_ID,
Order_Detail_ID,
Quantity * cp.price as Total_Cost_of_Order
FROM Order_Details od JOIN Consumer_Product cp ON cp.Product_ID = od.Product_ID;

CREATE OR REPLACE VIEW mtowh_products_view AS
SELECT 
M_WH_ID,
M_ID,
WH_ID,
Product_ID
FROM MtoWH_Products;

CREATE OR REPLACE VIEW whtor_products_view AS
SELECT 
WH_R_ID,
R_ID,
Product_ID
FROM WHtoR_Products;

--ETL PROCEDURE-----------------------------------------------------------------------------------------------------------------

CREATE OR REPLACE PROCEDURE product_management_etl_proc AS
BEGIN
    INSERT INTO Product_Management
    SELECT ov.Order_ID, ov.Product_ID, ov.Customer_ID, NULL AS Order_Detail_ID, NULL AS Total_Cost_of_Order, NULL AS M_ID,
        NULL AS M_WH_ID, NULL AS WH_ID, NULL AS WH_R_ID, NULL AS R_ID
    FROM orders_view ov LEFT JOIN Product_Management PM
    ON ov.Product_ID = PM.Product_ID
    WHERE PM.Product_ID IS NULL
    UNION
    SELECT odv.order_ID, odv.Product_ID, NULL AS Customer_ID, odv.Order_Detail_ID, odv.Total_Cost_of_Order, NULL AS M_ID,
        NULL AS M_WH_ID, NULL AS WH_ID, NULL AS WH_R_ID, NULL AS R_ID
    FROM order_details_view odv LEFT JOIN Product_Management PM
    ON odv.Product_ID = PM.Product_ID
    WHERE PM.Product_ID IS NULL
    UNION
    SELECT NULL AS Order_ID, mpv.Product_ID, NULL AS Customer_ID, NULL AS Order_Detail_ID, NULL AS Total_Cost_of_Order,
        mpv.M_ID, mpv.M_WH_ID, mpv.WH_ID, NULL AS WH_R_ID, NULL AS R_ID
    FROM mtowh_products_view mpv LEFT JOIN Product_Management PM
    ON mpv.Product_ID = PM.Product_ID
    WHERE PM.Product_ID IS NULL
    UNION
    SELECT NULL AS Order_ID, wpv.Product_ID, NULL AS Customer_ID, NULL AS Order_Detail_ID, NULL AS Total_Cost_of_Order, NULL AS M_ID,
        NULL AS M_WH_ID, NULL AS WH_ID,  wpv.WH_R_ID, wpv.R_ID
    FROM whtor_products_view wpv LEFT JOIN Product_Management PM
    ON wpv.Product_ID = PM.Product_ID
    WHERE PM.Product_ID IS NULL;
    
    DECLARE
        TYPE id_table IS TABLE OF NUMBER;
        product_ids id_table;
        
    BEGIN
        SELECT Product_ID
        BULK COLLECT INTO product_ids
        FROM order_details_view
        ORDER BY Product_ID;
        
        FOR i IN 1..product_ids.COUNT LOOP
            UPDATE Product_Management
            SET 
                Order_ID = (SELECT Order_ID FROM orders_view
                WHERE Product_ID = product_ids(i)),
                Product_ID = (SELECT Product_ID FROM orders_view
                WHERE Product_ID = product_ids(i)),
                Customer_ID = (SELECT Customer_ID FROM orders_view
                WHERE Product_ID = product_ids(i)),
                Order_Detail_ID = (SELECT Order_Detail_ID FROM order_details_view
                WHERE Product_ID = product_ids(i)),
                Total_Cost_of_Order = (SELECT Total_Cost_of_Order FROM order_details_view
                WHERE Product_ID = product_ids(i)),
                M_WH_ID = (SELECT M_WH_ID FROM mtowh_products_view
                WHERE Product_ID = product_ids(i)),
                M_ID = (SELECT M_ID FROM mtowh_products_view
                WHERE Product_ID = product_ids(i)),
                WH_ID = (SELECT WH_ID FROM mtowh_products_view
                WHERE Product_ID = product_ids(i)),
                WH_R_ID = (SELECT WH_R_ID FROM whtor_products_view
                WHERE Product_ID = product_ids(i)),
                R_ID = (SELECT R_ID FROM whtor_products_view
                WHERE Product_ID = product_ids(i))
                WHERE Product_ID = product_ids(i);
        END LOOP;
    END;
END;
/

BEGIN
   product_management_etl_proc();
END;