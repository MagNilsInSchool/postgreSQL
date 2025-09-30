CREATE TABLE players (
id INT PRIMARY KEY GENERATED ALWAYS AS IDENTITY,--* newer syntax replacing SERIAL
name VARCHAR(50) NOT NULL,
join_date DATE DEFAULT CURRENT_DATE NOT NULL
);

CREATE TABLE games (
id INT PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
title VARCHAR(250) NOT NULL,
genre VARCHAR(50) NOT NULL
);

CREATE TABLE scores (
id INT PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
-- player_ID INT NOT NULL REFERENCES players(id), "column-level"
player_id INT,
FOREIGN KEY (player_id) REFERENCES players(id) --"table-level"
-- game_id INT NOT NULL REFERENCES games(id), "column-level"
game_id INT,
FOREIGN KEY (game_id) REFERENCES games(id)--"table-level"
score INT NOT NULL,
date_played TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);


--* DET ÄR SKILLNAD PÅ ENKELFNUTTAR OCH DUBBELFNUTTAR. DUBBELFNUTTAR = SELECTOR (typ?)

INSERT INTO players(name) 
VALUES('Bean'),('MrBean'),('BeanyMan'),('JellyBean'),('FlickTheBean')
INSERT INTO games(title, genre) 
VALUES('Run the beans', 'action'),('Operation beanstorm','action'),('Blox of beans', 'puzzle'),('Say it aint beans?', 'casual'),('The man in the canoe', 'adventure')
INSERT INTO scores(player_ID, game_id, score) 
VALUES(5, 1, 500),(3, 2, 1500),(1, 5, 12500),(2, 1, 1600),(3, 2, 2500),(1, 5, 23500),(1, 4, 11500),(4, 2, 200)

SELECT * FROM scores;


-- !Task 1: List All Players and Their Scores  
-- Write a query that uses an INNER JOIN to display all players along with the games they have played and their scores. 
-- Include the player’s name, game title, and score. 

SELECT players.name, games.title, scores.score
FROM players
INNER JOIN scores ON players.id = scores.player_id
INNER JOIN games ON games.id = scores.game_id;

/*
*Kan också skrivas:
SELECT p.name, g.title, s.score
FROM players p
JOIN scores s ON p.id = s.player_id
JOIN games g  ON g.id = s.game_id;
* När man skriver ex players p skapar man ett alias "p".
* JOIN without a modifier is the same as INNER JOIN in standard SQL and in PostgreSQL. Both return only rows where the join condition matches.
*/

-- !Task 2: Find High Scorers  
-- Use GROUP BY and ORDER BY to find the top 3 players with the highest total scores across all games.
SELECT p.name, SUM(s.score) AS total_score --* Om man använder ex LEFT JOIN kan man wrappa SUM med COALESCE och sätta default value till 0 för att undvida undefined/null
FROM players p
JOIN scores s ON p.id = s.player_id
GROUP BY p.id, p.name
ORDER BY total_score DESC
LIMIT 3;

-- !Task 3: Players Who Didn’t Play Any Games  
-- Use a LEFT OUTER JOIN  to list all players who haven’t played any games yet.
SELECT p.id, p.name
FROM players p
LEFT JOIN scores s ON s.player_id = p.id --* LEFT JOIN returnerar även null värden.
WHERE s.id IS NULL;

/* 
*Kan också skrivas:
SELECT p.id, p.name, COALESCE(SUM(s.score),0) AS total_score --* Om man vill se en total_score column. Nullvärde blir 0. Men då vi letar specifikt efter null så är det onödigt.
FROM players p 
LEFT JOIN scores s ON s.player_id = p.id --* LEFT JOIN returnerar även null värden. Så wrappa agregator i COALESCE för att sätta ett default värde, i det här fallet 0, ifall värdet annars är null/undefined.
GROUP BY p.id, p.name
HAVING COUNT(s.id) = 0 OR SUM(s.score) IS NULL --* HAVING filtrerar efter gruppering, WHERE innan. WHERE kan inte använda en aggregator (COUNT,SUM osv). COUNT(s.id) räknar hur många score rader användaren har och returnerar i det här fallet de som har 0.
ORDER BY p.name DESC;
*/

-- !Task 4: Find Popular Game Genres  
-- Use GROUP BY and COUNT() to find out which game genre is the most popular among players.
SELECT g.id, g.genre, COUNT(s.id) AS plays --* Eftersom JOIN inte returnerar poster som är null behövs inte COUNT wrappas i COALESCE.
FROM games g
JOIN scores s ON s.game_id = g.id
GROUP BY g.id, g.genre
ORDER BY plays DESC
LIMIT 3;

-- !Task 5: Recently Joined Players  
-- Write a query to find all players who joined in the last 30 days. Use the WHERE clause to filter by the `join_date`.
SELECT p.id, p.name, p.join_date
FROM players p
WHERE p.join_date >= CURRENT_DATE - INTERVAL '30 days' --* DATEDIFF funkar inte i postresql?
ORDER BY p.join_date ASC;

-- !Bonus Task: Players' Favorite Games  
-- Use JOIN and GROUP BY to find out which game each player has played the most times. Show the player’s name and the game title.

--! 100% CHATGPT SOLUTION:

WITH plays_per_game AS (
  SELECT player_id, game_id, COUNT(*) AS plays
  FROM scores
  GROUP BY player_id, game_id
),
ranked AS (
  SELECT *,
         ROW_NUMBER() OVER (PARTITION BY player_id ORDER BY plays DESC) AS rn
  FROM plays_per_game
)
SELECT p.id, p.name, g.title, r.plays
FROM ranked r
JOIN players p ON p.id = r.player_id
JOIN games  g ON g.id = r.game_id
WHERE r.rn = 1
ORDER BY p.id;
