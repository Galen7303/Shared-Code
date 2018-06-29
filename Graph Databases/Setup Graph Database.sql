-- Create person node table
CREATE TABLE dbo.Person (ID integer PRIMARY KEY, name varchar(50)) AS NODE;
CREATE TABLE dbo.friend (start_date DATE) AS EDGE;

-- Insert into node table
INSERT INTO dbo.Person VALUES (1, 'Alice');
INSERT INTO dbo.Person VALUES (2,'John');
INSERT INTO dbo.Person VALUES (3, 'Jacob');

-- Insert into edge table
INSERT INTO dbo.friend VALUES ((SELECT $node_id FROM dbo.Person WHERE name = 'Alice'),
       (SELECT $node_id FROM dbo.Person WHERE name = 'John'), '9/15/2011');

INSERT INTO dbo.friend VALUES ((SELECT $node_id FROM dbo.Person WHERE name = 'Alice'),
       (SELECT $node_id FROM dbo.Person WHERE name = 'Jacob'), '10/15/2011');

INSERT INTO dbo.friend VALUES ((SELECT $node_id FROM dbo.Person WHERE name = 'John'),
       (SELECT $node_id FROM dbo.Person WHERE name = 'Jacob'), '10/15/2012');

-- use MATCH in SELECT to find friends of Alice
SELECT Person2.name AS FriendName
FROM Person Person1, friend, Person Person2
WHERE MATCH(Person1-(friend)->Person2)
AND Person1.name = 'Alice';


EXECUTE sp_execute_external_script @language = N'R',
@script = N'
	require(igraph)
	g <- graph.data.frame(graphdf)
	V(g)$label.cex <- 2
	png(filename = "c:\\temp\\PLVeterans.png", height = 800, width = 1500, res = 100);
	plot(g, vertex.label.family = "sans", vertex.size = 5)
	dev.off()',
@input_data_1 = N'
	SELECT Person1.name, Person2.name AS FriendName
	FROM Person Person1, friend, Person Person2
	WHERE MATCH(Person1-(friend)->Person2)
	AND Person1.name = ''Alice'';',
@input_data_1_name = N'graphdf'
GO

