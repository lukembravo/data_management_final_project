DROP TABLE Product_Management;
DROP VIEW orders_view;
DROP VIEW order_details_view;
DROP VIEW MTOWH_PRODUCTS_VIEW;
DROP VIEW WHTOR_PRODUCTS_VIEW;

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
  R_ID NUMBER(7),
  CONSTRAINT pk_product_m PRIMARY KEY (Order_ID,Product_ID)
);

CREATE OR REPLACE VIEW orders_view AS
SELECT 
Order_ID,
Customer_ID
FROM orders;

CREATE OR REPLACE VIEW order_details_view AS
SELECT 
Order_ID,
o.Product_ID as Product_ID,
Order_Detail_ID,
Quantity * cp.price as Total_Cost_of_Order
FROM Order_Details o JOIN Consumer_Product cp ON cp.Product_ID = o.Product_ID;

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


CREATE OR REPLACE PROCEDURE pm_etl2 (  
pm_id NUMBER DEFAULT 0)    
IS  
BEGIN  
-- Insert 
INSERT INTO Product_Management
    SELECT *
    FROM (SELECT od.Order_ID,mh.Product_ID,o.Customer_ID,od.Order_Detail_ID,od.Total_Cost_of_Order,mh.M_ID,mh.M_WH_ID,mh.WH_ID,wh.WH_R_ID,wh.R_ID 
    FROM mtowh_products_view mh JOIN order_details_view od ON mh.product_id=od.product_id 
    JOIN whtor_products_view wh ON mh.product_id=wh.product_id JOIN orders_view o ON od.order_id=o.order_id)
    WHERE (Order_ID,Product_ID) NOT IN (SELECT Order_ID,Product_ID FROM Product_Management);  
COMMIT;
--Update 
MERGE INTO Product_Management pm
USING
(
SELECT od.Order_ID,mh.Product_ID,o.Customer_ID,od.Order_Detail_ID,od.Total_Cost_of_Order,mh.M_ID,mh.M_WH_ID,mh.WH_ID,wh.WH_R_ID,wh.R_ID 
FROM mtowh_products_view mh JOIN order_details_view od ON mh.product_id=od.product_id JOIN whtor_products_view wh ON
        mh.product_id=wh.product_id JOIN orders_view o ON od.order_id=o.order_id
)t3
ON(pm.product_id=t3.product_id AND pm.order_id=t3.product_id)
WHEN MATCHED THEN UPDATE SET
pm.Customer_ID=t3.customer_id,
pm.Order_Detail_ID=t3.order_detail_id,
pm.Total_Cost_of_Order=t3.total_cost_of_order,
pm.M_ID=t3.m_id,
pm.M_WH_ID=t3.m_wh_id,
pm.WH_ID=t3.wh_id,
pm.WH_R_ID=t3.wh_r_id,
pm.R_ID=t3.r_id;
END;  

begin 
    pm_etl2;
end;

SELECT * FROM Product_Management;

