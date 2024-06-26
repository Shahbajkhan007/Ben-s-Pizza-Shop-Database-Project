-- Create the database and use it
CREATE DATABASE pizza_db;
USE pizza_db;

-- Create customers table
CREATE TABLE customers (
    cust_id INT PRIMARY KEY,
    cust_firstname VARCHAR(50),
    cust_lastname VARCHAR(50)
);

-- Create address table
CREATE TABLE address (
    add_id INT PRIMARY KEY,
    delivery_address1 VARCHAR(200),
    delivery_address2 VARCHAR(200) NULL,
    delivery_city VARCHAR(50),
    delivery_zipcode VARCHAR(20)
);

-- Create item table
CREATE TABLE item (
    item_id VARCHAR(10) PRIMARY KEY,
    sku VARCHAR(20),
    item_name VARCHAR(100),
    item_cat VARCHAR(100),
    item_size VARCHAR(20),
    item_price DECIMAL(10,2),
    INDEX (sku)
);

-- Create ingredient table
CREATE TABLE ingredient (
    ing_id VARCHAR(10) PRIMARY KEY,
    ing_name VARCHAR(200),
    ing_weight INT,
    ing_meas VARCHAR(20),
    ing_price DECIMAL(5,2)
);

-- Create inventory table
CREATE TABLE inventory (
    inv_id INT PRIMARY KEY,
    item_id VARCHAR(10),
    quantity INT,
    FOREIGN KEY (item_id) REFERENCES item(item_id)
);

-- Create staff table
CREATE TABLE staff (
    staff_id VARCHAR(20) PRIMARY KEY,
    first_name VARCHAR(50),
    last_name VARCHAR(50),
    position VARCHAR(100),
    hourly_rate DECIMAL(5,2)
);

-- Create shift table
CREATE TABLE shift (
    shift_id VARCHAR(20) PRIMARY KEY,
    day_of_week VARCHAR(10),
    start_time TIME,
    end_time TIME
);

-- Create rota table
CREATE TABLE rota (
    row_id INT PRIMARY KEY,
    rota_id VARCHAR(20),
    date DATETIME,
    shift_id VARCHAR(20),
    staff_id VARCHAR(20),
    FOREIGN KEY (shift_id) REFERENCES shift(shift_id),
    FOREIGN KEY (staff_id) REFERENCES staff(staff_id),
    INDEX (date)
);

-- Create orders table
CREATE TABLE orders (
    row_id INT PRIMARY KEY,
    order_id VARCHAR(10),
    created_at DATETIME,
    item_id VARCHAR(10),
    quantity INT,
    cust_id INT,
    delivery BOOLEAN,
    add_id INT,
    FOREIGN KEY (created_at) REFERENCES rota(date),
    FOREIGN KEY (item_id) REFERENCES item(item_id),
    FOREIGN KEY (cust_id) REFERENCES customers(cust_id),
    FOREIGN KEY (add_id) REFERENCES address(add_id)
);

-- Create recipe table
CREATE TABLE recipe (
    row_id INT PRIMARY KEY,
    recipe_id VARCHAR(20),
    ing_id VARCHAR(10),
    quantity INT,
    FOREIGN KEY (recipe_id) REFERENCES item(sku),
    FOREIGN KEY (ing_id) REFERENCES ingredient(ing_id)
);
-- Verify data in customers table
SELECT * FROM customers;

-- Verify data in address table
SELECT * FROM address;

-- Verify data in item table
SELECT * FROM item;

-- Verify data in ingredient table
SELECT * FROM ingredient;

-- Verify data in inventory table
SELECT * FROM inventory;

-- Verify data in staff table
SELECT * FROM staff;

-- Verify data in shift table
SELECT * FROM shift;

-- Verify data in rota table
SELECT * FROM rota;

-- Verify data in orders table
SELECT * FROM orders;

-- Verify data in recipe table
SELECT * FROM recipe;

-- These are the visualizations customer wants in dashboard 1

-- Total order
-- Total sales
-- Total Items
-- Average Order value
-- Sales by category
-- top selling item
-- orders by hour
-- sales by hour
-- orders by address
-- orders by delivery/pickup

-- To get the required table for all these visualizations, this below query is used:

SELECT
	o.order_id,
	i.item_price,
	o.quantity,
	i.item_cat,
	i.item_name,
	o.created_at,
	a.delivery_address1,
	a.delivery_address2,
	a.delivery_city,
	a.delivery_zipcode,
	o.delivery 
FROM
	orders o
	LEFT JOIN item i ON o.item_id = i.item_id
	LEFT JOIN address a ON o.add_id = a.add_id

-- These are the visualizations customer wants in dashboard 2

-- Total quantity by ingredient
-- Total cost by ingredient
-- Calculated cost of pizza
-- Percentage cost remaining by ingredient
-- List of ingredients to reorder based on remaining inventory

-- To get the required table for all these visualizations, this below query is used:

SELECT
	s1.item_name AS item_name,
	s1.ing_name AS ing_name,
	s1.ing_id AS ing_id,
	s1.ing_weight AS ing_weight,
	s1.ing_price AS ing_price,
	s1.order_quantity AS order_quantity,
	s1.recipe_quantity AS recipe_quantity,(
		s1.order_quantity * s1.recipe_quantity 
		) AS ordered_weight,(
		s1.ing_price / s1.ing_weight 
		) AS unit_cost,((
			s1.order_quantity * s1.recipe_quantity 
		) * ( s1.ing_price / s1.ing_weight )) AS ingredient_cost 
FROM
	(
	SELECT
		o.item_id AS item_id,
		i.sku AS sku,
		i.item_name AS item_name,
		r.ing_id AS ing_id,
		ing.ing_name AS ing_name,
		ing.ing_weight AS ing_weight,
		ing.ing_price AS ing_price,
		sum( o.quantity ) AS order_quantity,
		r.quantity AS recipe_quantity 
	FROM
		(((
					orders o
					LEFT JOIN item i ON ((
							o.item_id = i.item_id 
						)))
				LEFT JOIN recipe r ON ((
						i.sku = r.recipe_id 
					)))
			LEFT JOIN ingredient ing ON ((
					ing.ing_id = r.ing_id 
				))) 
	GROUP BY
		o.item_id,
		i.sku,
		i.item_name,
		r.ing_id,
		r.quantity,
		ing.ing_weight,
	ing.ing_price 
	) s1

-- Then this query is saved as a view in sql and used it to get the required table for next 2 points.
-- Below is the query used for the next 2 points

select
s2.ing_name,
s2.ordered_weight,
ing.ing_weight,
inv.quantity,
ing.ing_weight * inv.quantity AS total_inv_weight 
FROM
	( SELECT ing_id, ing_name, sum( ordered_weight ) AS ordered_weight FROM stock1 GROUP BY ing_name, ing_id ) s2
	LEFT JOIN inventory inv ON inv.item_id = s2.ing_id
	LEFT JOIN ingredient ing ON ing.ing_id = s2.ing_id

-- These are the visualizations customer wants in dashboard 3

-- Total staff cost
-- Total hours worked
-- Hours worked by staff members
-- Cost per staff member

-- To get the required table for all these visualizations, this below query is used:

SELECT
	r.date,
	s.first_name,
	s.last_name,
	s.hourly_rate,
	sh.start_time,
	sh.end_time,
	((
			HOUR (
			timediff( sh.end_time, sh.start_time ))* 60 
			)+(
			MINUTE (
			timediff( sh.end_time, sh.start_time ))))/ 60 AS hours_in_shift,
	((
			HOUR (
			timediff( sh.end_time, sh.start_time ))* 60 
			)+(
			MINUTE (
			timediff( sh.end_time, sh.start_time ))))/ 60 * s.hourly_rate AS staff_cost 
FROM
	rota r
	LEFT JOIN staff s ON r.staff_id = s.staff_id
	LEFT JOIN shift sh ON r.shift_id = sh.shift_id


