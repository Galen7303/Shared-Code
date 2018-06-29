use stats
go
drop table agg_batting
go
select m.playerid, m.nameFirst, m.nameLast, 
sum(cast (b.h as float))/sum(cast (b.ab as float)) as average,
sum(cast (b.hr as float))/sum(cast (b.g as float)) as hrpergame,
sum(cast (b.rbi as float))/sum(cast (b.g as float)) as rbipergame,
sum(cast (b.bb as float))/sum(cast (b.g as float)) as bbpergame
into agg_batting
from master m
join batting b
on m.playerID = b.playerID
where b.ab >= 300
group by m.playerid, m.nameFirst, m.nameLast
order by m.playerid, m.nameLast, m.nameFirst
go

drop proc get_best_batters
go
create proc get_best_batters
as
exec sp_execute_external_script @language =N'R',@script =N'
ClusterCount <- 10;
df <- data.frame(InputDataSet);
ClusterFeatures <- data.frame(df$average, df$hrpergame, df$rbipergame, df$bbpergame);
ClusterResult <- kmeans(ClusterFeatures, centers = ClusterCount, iter.max = 25)$cluster;
OutputDataSet <- data.frame(df$playerid, df$nameFirst, df$nameLast, ClusterResult);', 
@input_data_1 =N'Select * from agg_batting';
go
drop table best_batters
go
create table best_batters (playerid varchar(50), nameFirst varchar(100), nameLast varchar(100), ClusteringResult int)
go

insert best_batters
exec get_best_batters
go

select * from best_batters where clusteringresult in
(select clusteringresult from best_batters where playerid = 'troutmi01')
order by NameFirst, nameLast
go

