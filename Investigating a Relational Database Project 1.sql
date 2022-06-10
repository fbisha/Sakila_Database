/* Investigating a Relational Database - Project One 

Query 1
Question: */

WITH rental_interval AS (
    SELECT rental_id, rental.return_date::DATE - rental.rental_date::DATE
	AS rental_interval
    FROM rental
    ),

duration AS (
    SELECT rental_interval.rental_id, CASE WHEN rental_interval < 4 THEN 'Quick Return'
    ELSE 'Long Return' END AS Duration
    FROM rental_interval
    )

SELECT film.rating film_rating, 100. * count(*) / sum(count(*)) over () AS percent
FROM rental_interval
JOIN rental
ON rental_interval.rental_id = rental.rental_id
JOIN inventory 
ON rental.inventory_id = inventory.inventory_id
JOIN film 
ON film.film_id = inventory.film_id
JOIN duration
ON rental.rental_id = duration.rental_id
WHERE duration = 'Quick Return'
GROUP BY 1



/*
Query 2
Question: What genres were in the top 25% of movies rented from the year 2005 - 2006?  
*/

SELECT t1.category_name, t1.dates_rented, t1.payment_amount, t2.ranking_genres_now
FROM 
    (SELECT film_category.category_id, category.name category_name, DATE_PART('year', rental.rental_date) AS dates_rented, SUM(payment.amount) AS payment_amount
FROM payment 
JOIN rental 
ON payment.rental_id = rental.rental_id 
JOIN inventory 
ON rental.inventory_id = inventory.inventory_id 
JOIN film 
ON film.film_id = inventory.film_id 
JOIN film_category 
ON film.film_id = film_category.film_id 
JOIN category 
ON category.category_id = film_category.category_id
GROUP BY 1,2,3) t1

JOIN 
    (SELECT film_category.category_id, category.name, NTILE(4) OVER (ORDER BY SUM(payment.amount)) AS ranking_genres_now
FROM payment 
JOIN rental 
ON payment.rental_id = rental.rental_id 
JOIN inventory 
ON rental.inventory_id = inventory.inventory_id 
JOIN film 
ON film.film_id = inventory.film_id 
JOIN film_category 
ON film.film_id = film_category.film_id 
JOIN category 
ON category.category_id = film_category.category_id
     GROUP BY 1,2) t2

ON t2.category_id = t1.category_id

/*
Query 3 
Question: For the top three countries renting movies from Sakila, what month(s) of the year do customers rent movies out the most?
*/

WITH customer_base AS (
    SELECT city.country_id, country.country, COUNT(country.country_id)
    FROM CUSTOMER
    JOIN ADDRESS
    ON customer.address_id = address.address_id
    JOIN CITY
    ON address.city_id = city.city_id
    JOIN COUNTRY
    ON country.country_id = city.country_id
    GROUP BY 1, 2
    ORDER BY 3 DESC
    LIMIT 3
    )

SELECT DATE_PART('month',rental.rental_date) AS rental_month, COUNT(*)
FROM CUSTOMER
JOIN ADDRESS
ON customer.address_id = address.address_id
JOIN CITY
ON address.city_id = city.city_id
JOIN COUNTRY
ON country.country_id = city.country_id
JOIN customer_base
ON customer_base.country_id = country.country_id
JOIN RENTAL 
ON rental.customer_id = customer.customer_id 
JOIN inventory 
ON inventory.inventory_id = rental.inventory_id 
JOIN film 
ON inventory.film_id = film.film_id
GROUP BY 1
ORDER BY 1



/*
Query 4
Question: For the highest earning store, what percentage of their rentals are movies categorized as “very long”? 
*/

WITH store_earnings AS (
    SELECT store.store_id, SUM(payment.amount) AS store_earnings 
    FROM store 
    JOIN inventory 
    ON store.store_id = inventory.store_id 
    JOIN rental 
    ON inventory.inventory_id = rental.inventory_id 
    JOIN payment 
    ON payment.rental_id = rental.rental_id 
    JOIN film 
    ON inventory.film_id = film.film_id
    GROUP BY 1
    ORDER BY 2 DESC
    LIMIT 1
    ),

movie_length AS (
    SELECT inventory.inventory_id, inventory.store_id, inventory.film_id, film.length,
    CASE WHEN length > 150 THEN 'Very Long'
    WHEN length > 90 THEN 'Medium Length'
    ELSE 'Short'
    END AS movie_length
    FROM store 
    JOIN store_earnings
    ON store_earnings.store_id = store.store_id
    JOIN inventory 
    ON store.store_id = inventory.store_id 
    JOIN rental 
    ON inventory.inventory_id = rental.inventory_id 
    JOIN payment 
    ON payment.rental_id = rental.rental_id 
    JOIN film 
    ON inventory.film_id = film.film_id
    ORDER BY 4 DESC
    )

SELECT movie_length.movie_length,
100. * count(movie_length) / sum(count(*)) over () AS percent
FROM movie_length
GROUP BY 1

