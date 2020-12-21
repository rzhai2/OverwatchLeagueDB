DROP TABLE Player;
CREATE TABLE Player (
    PlayerName VARCHAR(20),
    RealName VARCHAR(30),
    Birthday VARCHAR(20),
    Country VARCHAR(40),
    Status VARCHAR(10),
    Role VARCHAR(30),
    PRIMARY KEY (PlayerName)
);

DROP TABLE Team;
CREATE TABLE Team (
    TeamName VARCHAR(30),
    City VARCHAR(15),
    Country VARCHAR(15),
    PRIMARY KEY (TeamName)
);

DROP TABLE ServesIn;
CREATE TABLE ServesIn (
    PlayerName VARCHAR(20),
    TeamName VARCHAR(30),
    StartDate DATE,
    EndDate DATE,
    PRIMARY KEY (PlayerName, TeamName, StartDate)
);

DROP TABLE Hero;
CREATE TABLE Hero (
    HeroName VARCHAR(15),
    Role VARCHAR(7),
    PRIMARY KEY (HeroName)
);

DROP TABLE Map;
CREATE TABLE Map (
    MapName VARCHAR(25),
    MapType VARCHAR(10),
    PRIMARY KEY (MapName)
);

DROP TABLE Match_;
CREATE TABLE Match_ (
    MatchID INTEGER(10),
    TournamentTitle VARCHAR(50),
    StartDate DATE,
    MatchWinner VARCHAR(30),
    MatchLoser VARCHAR(30),
    PRIMARY KEY (MatchID)
);

DROP TABLE PlaysMatch;
CREATE TABLE PlaysMatch (
    MatchID INTEGER(10),
    TeamName VARCHAR(30),
    PRIMARY KEY (MatchID, TeamName)
);

DROP TABLE PlaysMap;
CREATE TABLE PlaysMap (
    MatchID INTEGER(10),
    MapName VARCHAR(25),
    MapNo INTEGER,
    MapWinner VARCHAR(30),
    MapLoser VARCHAR(30),
    PRIMARY KEY (MatchID, MapName, MapNo)
);

DROP TABLE MapPlayerStat;
CREATE TABLE MapPlayerStat (
    MatchID INTEGER,
    MapName VARCHAR(25),
    PlayerName VARCHAR(20),
    TeamName VARCHAR(30),
    HeroName VARCHAR(15),
    StatName VARCHAR(50),
    StatAmount DOUBLE,
    PRIMARY KEY (MatchID, MapName, PlayerName, HeroName, StatName)
);

DROP TABLE MapRoundStat;
CREATE TABLE MapRoundStat (
    MatchID INTEGER(10),
    MapName VARCHAR(25),
    MapNo Integer,
    RoundNo INTEGER,
    StartTime DATETIME,
    EndTime DATETIME,
    ControlRoundName VARCHAR(25),
    AttackerTeam VARCHAR(30),
    DefenderTeam VARCHAR(30),
    AttackerPayloadDistance DOUBLE,
    DefenderPayloadDistance DOUBLE,
    AttackerTimeBanked DOUBLE,
    DefenderTimeBanked DOUBLE,
    AttackerControlPercent INTEGER,
    DefenderControlPercent INTEGER,
    AttackerRoundEndScore INTEGER,
    DefenderRoundEndScore INTEGER,
    PRIMARY KEY (MatchID, MapNo, RoundNo)
);

/* 1 */
DELIMITER |
DROP PROCEDURE IF EXISTS proc_1;
CREATE PROCEDURE proc_1()
BEGIN
    SELECT DISTINCT MPS.PlayerName, M.StartDate, MPS.TeamName, M.MatchLoser
    FROM MapPlayerStat AS MPS, Match_ AS M
    WHERE MPS.MatchID = M.MatchID AND MPS.TeamName = M.MatchWinner AND
        EXISTS (    SELECT * 
                    FROM ServesIn 
                    WHERE ServesIn.PlayerName = MPS.PlayerName AND ServesIn.TeamName = M.MatchLoser);
END;
|

/* 2 */
DELIMITER |
DROP PROCEDURE IF EXISTS proc_2;
CREATE PROCEDURE proc_2()
BEGIN
    SELECT P.PlayerName, P.Role, COUNT(DISTINCT MPS.HeroName) AS NumHero, M.StartDate, M.TournamentTitle
    FROM Player AS P NATURAL INNER JOIN MapPlayerStat AS MPS NATURAL INNER JOIN Match_ AS M
    WHERE MPS.HeroName != 'All Heroes'
    GROUP BY P.PlayerName, M.MatchID
    HAVING COUNT(DISTINCT MPS.HeroName) >= 5
    ORDER BY NumHero DESC;
END;
|

/* 3 */
DELIMITER |
DROP PROCEDURE IF EXISTS proc_3;
CREATE PROCEDURE proc_3(Input_PlayerName VARCHAR(20))
BEGIN
    SELECT DISTINCT M.MatchLoser AS DefeatedTeam, M.StartDate, M.TournamentTitle, M.MatchWinner AS PlayerTeam
    FROM MapPlayerStat AS MPS, Match_ AS M
    WHERE Input_PlayerName = MPS.PlayerName AND M.MatchWinner = MPS.TeamName AND MPS.MatchID = M.MatchID
    ORDER BY M.StartDate DESC;
END;
|

/* 4 */
DELIMITER |
DROP PROCEDURE IF EXISTS proc_4;
CREATE PROCEDURE proc_4(Input_Title VARCHAR(50))
BEGIN
    (   SELECT H.HeroName, H.Role, SUM(MPS.StatAmount) AS TotalTimeSeconds
        FROM MapPlayerStat AS MPS NATURAL INNER JOIN Hero AS H
        WHERE H.Role = 'Tank' AND MPS.StatName = 'Time Played'
        GROUP BY MPS.HeroName
        ORDER BY TotalTimeSeconds DESC
        LIMIT 3)
    UNION
    (   SELECT H.HeroName, H.Role, SUM(MPS.StatAmount) AS TotalTimeSeconds
        FROM MapPlayerStat AS MPS NATURAL INNER JOIN Hero AS H
        WHERE H.Role = 'DPS' AND MPS.StatName = 'Time Played'
        GROUP BY MPS.HeroName
        ORDER BY TotalTimeSeconds DESC
        LIMIT 3)
    UNION
    (   SELECT H.HeroName, H.Role, SUM(MPS.StatAmount) AS TotalTimeSeconds
        FROM MapPlayerStat AS MPS NATURAL INNER JOIN Hero AS H
        WHERE H.Role = 'Support' AND MPS.StatName = 'Time Played'
        GROUP BY MPS.HeroName
        ORDER BY TotalTimeSeconds DESC
        LIMIT 3);
END;
|

/* 5 */
DELIMITER |
DROP PROCEDURE IF EXISTS proc_5;
CREATE PROCEDURE proc_5(Input_Title VARCHAR(50))
BEGIN
    SELECT Temp1.PlayerName, (Temp1.TimeAlive / Temp2.TimePlayed) AS AlivePercentage
    FROM (  SELECT PlayerName, SUM(StatAmount) AS TimeAlive
            FROM MapPlayerStat NATURAL INNER JOIN Match_
            WHERE HeroName = 'All Heroes' AND StatName = 'Time Alive' AND TournamentTitle = Input_Title
            GROUP BY PlayerName) AS Temp1,
         (  SELECT PlayerName, SUM(StatAmount) AS TimePlayed
            FROM MapPlayerStat NATURAL INNER JOIN Match_
            WHERE HeroName = 'All Heroes' AND StatName = 'Time Played' AND TournamentTitle = Input_Title
            GROUP BY PlayerName) AS Temp2
    WHERE Temp1.PlayerName = Temp2.PlayerName
    ORDER BY AlivePercentage ASC
    LIMIT 10;
END;
|

/* 6 */
DELIMITER |
DROP PROCEDURE IF EXISTS proc_6;
CREATE PROCEDURE proc_6(Input_Title VARCHAR(50), Input_HeroName VARCHAR(15))
BEGIN
    SELECT Temp1.PlayerName, (Temp1.TotalDamage / Temp2.TimePlayed * 600) AS Damage10min, Temp2.TimePlayed
    FROM (  SELECT PlayerName, SUM(StatAmount) AS TotalDamage
            FROM MapPlayerStat NATURAL INNER JOIN Match_
            WHERE HeroName = Input_HeroName AND StatName = 'All Damage Done' AND TournamentTitle = Input_Title
            GROUP BY PlayerName) AS Temp1,
         (  SELECT PlayerName, SUM(StatAmount) AS TimePlayed
            FROM MapPlayerStat NATURAL INNER JOIN Match_
            WHERE HeroName = Input_HeroName AND StatName = 'Time Played' AND TournamentTitle = Input_Title
            GROUP BY PlayerName) AS Temp2
    WHERE Temp1.PlayerName = Temp2.PlayerName
    ORDER BY Damage10min DESC
    LIMIT 10;
END;
|

/* 7 */
DELIMITER |
DROP PROCEDURE IF EXISTS proc_7;
CREATE PROCEDURE proc_7()
BEGIN
    SELECT DISTINCT Temp1.PlayerName, Temp1.TeamName, M.StartDate, Temp3.TeamName AS OpponentTeam, Temp1.MapName,
        (Temp1.PlayerFinalBlow * 2 / Temp2.TeamFinalBlow) AS DeadliftSize
    FROM (  SELECT MPS.MatchID, MPS.MapName, MPS.PlayerName, MPS.TeamName, MPS.StatAmount AS PlayerFinalBlow
            FROM MapPlayerStat AS MPS NATURAL INNER JOIN PlaysMap AS PM
            WHERE MPS.HeroName = 'All Heroes' AND MPS.StatName = 'Final Blows' AND MPS.TeamName = PM.MapWinner) AS Temp1 NATURAL INNER JOIN
         (  SELECT MPS.MatchID, MPS.MapName, MPS.TeamName, SUM(MPS.StatAmount) AS TeamFinalBlow
            FROM MapPlayerStat AS MPS NATURAL INNER JOIN PlaysMap AS PM
            WHERE MPS.HeroName = 'All Heroes' AND MPS.StatName = 'Final Blows' AND MPS.TeamName = PM.MapWinner
            GROUP BY MPS.MatchID, MPS.MapName, MPS.TeamName) AS Temp2,
         (  SELECT MatchID, TeamName FROM MapPlayerStat) AS Temp3,
         Match_ AS M
    WHERE Temp1.PlayerFinalBlow * 2 / Temp2.TeamFinalBlow >= 1 AND 
        Temp1.MatchID = Temp3.MatchID AND Temp1.TeamName != Temp3.TeamName AND Temp1.MatchID = M.MatchID
    ORDER BY DeadliftSize DESC;
END;
|

/* 8 */
DELIMITER |
DROP PROCEDURE IF EXISTS proc_8;
CREATE PROCEDURE proc_8(Input_Title VARCHAR(50), Input_TeamName VARCHAR(30), Input_MapName VARCHAR(25))
BEGIN
    SELECT Temp1.NumWin, Temp2.NumLose, Temp3.NumDraw,
        (Temp1.NumWin / (Temp1.NumWin + Temp2.NumLose + Temp3.NumDraw)) AS WinPercentage
    FROM (  SELECT COUNT(*) AS NumWin
            FROM PlaysMap NATURAL INNER JOIN PlaysMatch NATURAL INNER JOIN Match_
            WHERE Match_.TournamentTitle = Input_Title AND PlaysMatch.TeamName = Input_TeamName AND
                PlaysMap.MapName = Input_MapName AND PlaysMap.MapWinner = Input_TeamName) AS Temp1,
         (  SELECT COUNT(*) AS NumLose
            FROM PlaysMap NATURAL INNER JOIN PlaysMatch NATURAL INNER JOIN Match_
            WHERE Match_.TournamentTitle = Input_Title AND PlaysMatch.TeamName = Input_TeamName AND
                PlaysMap.MapName = Input_MapName AND PlaysMap.MapLoser = Input_TeamName) AS Temp2,
         (  SELECT COUNT(*) AS NumDraw
            FROM PlaysMap NATURAL INNER JOIN PlaysMatch NATURAL INNER JOIN Match_
            WHERE Match_.TournamentTitle = Input_Title AND PlaysMatch.TeamName = Input_TeamName AND
                PlaysMap.MapName = Input_MapName AND PlaysMap.MapWinner = 'draw') AS Temp3;
END;
|

/* 9 */
DELIMITER |
DROP PROCEDURE IF EXISTS proc_9;
CREATE PROCEDURE proc_9(Input_Title VARCHAR(50))
BEGIN
     SELECT DISTINCT Temp1.MapName, Temp1.StartDate, Temp1.AttackerTeam, Temp1.DefenderTeam
     FROM ( SELECT * 
            FROM MapRoundStat NATURAL INNER JOIN Map NATURAL INNER JOIN Match_
            WHERE Map.MapType = 'CONTROL' AND Match_.TournamentTitle = Input_Title) AS Temp1
     WHERE EXISTS ( SELECT * FROM MapRoundStat AS MRS
                    WHERE Temp1.MatchID = MRS.MatchID AND Temp1.MapName = MRS.MapName AND
                    MRS.RoundNo = 1 AND
                    ((MRS.AttackerControlPercent = 99 AND MRS.DefenderControlPercent = 100) OR
                    (MRS.AttackerControlPercent = 100 AND MRS.DefenderControlPercent = 99))) AND
        EXISTS ( SELECT * FROM MapRoundStat AS MRS
                 WHERE Temp1.MatchID = MRS.MatchID AND Temp1.MapName = MRS.MapName AND
                 MRS.RoundNo = 2 AND
                 ((MRS.AttackerControlPercent = 99 AND MRS.DefenderControlPercent = 100) OR
                 (MRS.AttackerControlPercent = 100 AND MRS.DefenderControlPercent = 99))) AND
        EXISTS ( SELECT * FROM MapRoundStat AS MRS
                 WHERE Temp1.MatchID = MRS.MatchID AND Temp1.MapName = MRS.MapName AND
                 MRS.RoundNo = 3 AND
                 ((MRS.AttackerControlPercent = 99 AND MRS.DefenderControlPercent = 100) OR
                 (MRS.AttackerControlPercent = 100 AND MRS.DefenderControlPercent = 99)));
END;
|

/* 10 */
DELIMITER |
DROP PROCEDURE IF EXISTS proc_10;
CREATE PROCEDURE proc_10()
BEGIN
    SELECT Temp1.PlayerName, Temp1.TeamName, M.StartDate, (Temp1.PlayerHealing / Temp2.TeamDamageTaken) AS HealPercentage
    FROM (  SELECT MPS.MatchID, MPS.PlayerName, MPS.TeamName, SUM(StatAmount) AS PlayerHealing
            FROM MapPlayerStat AS MPS NATURAL INNER JOIN Player AS P
            WHERE P.Role LIKE '%Support%' AND MPS.StatName = 'Healing Done' AND MPS.HeroName = 'All Heroes'
            GROUP BY MPS.MatchID, MPS.PlayerName, MPS.TeamName) AS Temp1,
         (  SELECT MPS.MatchID, MPS.TeamName, SUM(StatAmount) AS TeamDamageTaken
            FROM MapPlayerStat AS MPS
            WHERE MPS.StatName = 'Damage Taken' AND MPS.HeroName = 'All Heroes'
            GROUP BY MPS.MatchID, MPS.TeamName) AS Temp2, Match_ AS M
    WHERE Temp1.MatchID = Temp2.MatchID AND Temp1.TeamName = Temp2.Teamname AND Temp1.MatchID = M.MatchID
    ORDER BY HealPercentage DESC
    LIMIT 20;
END;
|

/* 11 */
DELIMITER |
DROP PROCEDURE IF EXISTS proc_11;
CREATE PROCEDURE proc_11()
BEGIN
    SELECT Temp1.PlayerName, (Temp1.TotalFinalBlow / Temp2.TimePlayed * 600) AS FinalBlow10min
    FROM (  SELECT PlayerName, SUM(StatAmount) AS TotalFinalBlow
            FROM MapPlayerStat
            WHERE HeroName = 'Mercy' AND StatName = 'Final Blows'
            GROUP BY PlayerName) AS Temp1,
         (  SELECT PlayerName, SUM(StatAmount) AS TimePlayed
            FROM MapPlayerStat
            WHERE HeroName = 'Mercy' AND StatName = 'Time Played'
            GROUP BY PlayerName) AS Temp2
    WHERE Temp1.PlayerName = Temp2.PlayerName
    ORDER BY FinalBlow10min DESC
    LIMIT 10;
END;
|

/* 12 */
DELIMITER |
DROP PROCEDURE IF EXISTS proc_12;
CREATE PROCEDURE proc_12(Input_Title VARCHAR(50))
BEGIN
    SELECT Temp1.PlayerName, Player.Role, Temp1.HeroName, Hero.Role,
        (Temp1.TotalDamage / Temp3.TimePlayed * 600) AS Damage10min,
        (Temp2.TotalHealing / Temp3.TimePlayed * 600) AS Healing10min
    FROM (  SELECT MPS.PlayerName, MPS.HeroName, SUM(MPS.StatAmount) AS TotalDamage
            FROM MapPlayerStat AS MPS, Match_ AS M, Player AS P, Hero AS H
            WHERE MPS.MatchID = M.MatchID AND MPS.PlayerName = P.PlayerName AND MPS.HeroName = H.HeroName AND
                P.Role != H.Role AND MPS.StatName = 'Damage Done' AND M.TournamentTitle = Input_Title
            GROUP BY MPS.PlayerName, MPS.HeroName) AS Temp1 LEFT OUTER JOIN
         (  SELECT MPS.PlayerName, MPS.HeroName, SUM(MPS.StatAmount) AS TotalHealing
            FROM MapPlayerStat AS MPS, Match_ AS M, Player AS P, Hero AS H
            WHERE MPS.MatchID = M.MatchID AND MPS.PlayerName = P.PlayerName AND MPS.HeroName = H.HeroName AND
                P.Role != H.Role AND MPS.StatName = 'Healing Done' AND M.TournamentTitle = Input_Title
            GROUP BY MPS.PlayerName, MPS.HeroName) AS Temp2 ON Temp1.PlayerName = Temp2.PlayerName AND Temp1.HeroName = Temp2.HeroName LEFT OUTER JOIN
         (  SELECT MPS.PlayerName, MPS.HeroName, SUM(MPS.StatAmount) AS TimePlayed
            FROM MapPlayerStat AS MPS, Match_ AS M, Player AS P, Hero AS H
            WHERE MPS.MatchID = M.MatchID AND MPS.PlayerName = P.PlayerName AND MPS.HeroName = H.HeroName AND
                P.Role != H.Role AND MPS.StatName = 'Time Played' AND M.TournamentTitle = Input_Title
            GROUP BY MPS.PlayerName, MPS.HeroName) AS Temp3 ON Temp1.PlayerName = Temp3.PlayerName AND Temp1.HeroName = Temp3.HeroName, Player, Hero
    WHERE Temp1.PlayerName = Player.PlayerName AND Temp1.HeroName = Hero.HeroName;
END;
|

