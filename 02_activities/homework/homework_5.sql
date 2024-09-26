-- Cross Join
/*1. Suppose every vendor in the `vendor_inventory` table had 5 of each of their products to sell to **every** 
customer on record. How much money would each vendor make per product? 
Show this by vendor_name and product name, rather than using the IDs.

HINT: Be sure you select only relevant columns and rows. 
Remember, CROSS JOIN will explode your table rows, so CROSS JOIN should likely be a subquery. 
Think a bit about the row counts: how many distinct vendors, product names are there (x)?
How many customers are there (y). 
Before your final group by you should have the product of those two queries (x*y).  */

DROP TABLE IF EXISTS product_name_vendor_inventory;
CREATE TEMP TABLE product_name_vendor_inventory AS
SELECT DISTINCT vi.product_id, vendor_id, original_price, product_name
FROM vendor_inventory as vi 
LEFT JOIN product as p 
	ON vi.product_id = p.product_id;

DROP TABLE IF EXISTS new_vendor_inventory;
CREATE TEMP TABLE new_vendor_inventory AS
SELECT product_id, pnvi.vendor_id, original_price, product_name, v.vendor_name
FROM product_name_vendor_inventory as pnvi 
LEFT JOIN vendor as v 
	ON pnvi.vendor_id = v.vendor_id;

SELECT DISTINCT vendor_name, product_name
    ,SUM(original_price)OVER(PARTITION BY vendor_id, product_id)*5 AS total_per_product
FROM
(	
	SELECT * FROM new_vendor_inventory
	CROSS JOIN customer	
)

-- INSERT
/*1.  Create a new table "product_units". 
This table will contain only products where the `product_qty_type = 'unit'`. 
It should use all of the columns from the product table, as well as a new column for the `CURRENT_TIMESTAMP`.  
Name the timestamp column `snapshot_timestamp`. */

CREATE TABLE product_units AS
SELECT product_id, product_name, product_size, product_category_id, product_qty_type, not null AS snapshot_timestamp
FROM product
WHERE product_qty_type='unit';
UPDATE product_units SET snapshot_timestamp = CURRENT_TIMESTAMP;

---- another way
--CREATE TABLE product_units AS
--SELECT * FROM product
--WHERE product_qty_type='unit';
--ALTER TABLE product_units ADD COLUMN snapshot_timestamp DEFAULT NULL;
--UPDATE product_units SET snapshot_timestamp = CURRENT_TIMESTAMP;

/*2. Using `INSERT`, add a new row to the product_units table (with an updated timestamp). 
This can be any product you desire (e.g. add another record for Apple Pie). */

INSERT INTO product_units VALUES(24, 'Banana', '8 oz', 3, 'unit', CURRENT_TIMESTAMP);

-- DELETE
/* 1. Delete the older record for the whatever product you added. 

HINT: If you don't specify a WHERE clause, you are going to have a bad time.*/

DELETE from product_units
WHERE product_id = 24;

-- UPDATE
/* 1.We want to add the current_quantity to the product_units table. 
First, add a new column, current_quantity to the table using the following syntax.

ALTER TABLE product_units
ADD current_quantity INT;

Then, using UPDATE, change the current_quantity equal to the last quantity value from the vendor_inventory details.

HINT: This one is pretty hard. 
First, determine how to get the "last" quantity per product. 
Second, coalesce null values to 0 (if you don't have null values, figure out how to rearrange your query so you do.) 
Third, SET current_quantity = (...your select statement...), remembering that WHERE can only accommodate one column. 
Finally, make sure you have a WHERE statement to update the right row, 
	you'll need to use product_units.product_id to refer to the correct row within the product_units table. 
When you have all of these components, you can run the update statement. */

ALTER TABLE product_units
ADD current_quantity INT;

---1) a CTE with the latest quantity
DROP TABLE IF EXISTS test4;
CREATE TEMP TABLE test4 AS
SELECT product_id, quantity, market_date, date_ranked AS [RANK]
FROM
(
	SELECT *
	,RANK()OVER(PARTITION BY product_id ORDER BY market_date DESC) AS date_ranked
	FROM vendor_inventory
)x 
WHERE date_ranked=1; --SELECT * FROM test4

---2) coalesce null values to 0
UPDATE product_units
SET current_quantity= COALESCE(current_quantity, 0);

---3) Update with the latest quality
UPDATE
    product_units
SET
    current_quantity = (
	SELECT quantity
	FROM test4 AS t
	WHERE t.product_id = product_units.product_id
	);
SELECT * FROM product_units
