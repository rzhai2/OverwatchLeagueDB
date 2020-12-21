/* Team */
INSERT INTO Team
SELECT TeamName, City, Country
FROM Team_raw;

/* ServesIn */
INSERT INTO ServesIn
SELECT PlayerName, TeamName, StartDate, EndDate
FROM ServesIn_raw
WHERE EXISTS (SELECT * FROM Team WHERE Team.TeamName = ServesIn_raw.TeamName);

/* Player */
INSERT INTO Player
SELECT PlayerName, RealName, Birthday, Country, Status, Role
FROM Player_raw;

/* Hero */
INSERT INTO Hero VALUES ('Ana','Support');
INSERT INTO Hero VALUES ('Ashe','DPS');
INSERT INTO Hero VALUES ('Baptiste','Support');
INSERT INTO Hero VALUES ('Bastion','DPS');
INSERT INTO Hero VALUES ('Brigitte','Support');
INSERT INTO Hero VALUES ('D.Va','Tank');
INSERT INTO Hero VALUES ('Doomfist','DPS');
INSERT INTO Hero VALUES ('Echo','DPS');
INSERT INTO Hero VALUES ('Genji','DPS');
INSERT INTO Hero VALUES ('Hanzo','DPS');
INSERT INTO Hero VALUES ('Junkrat','DPS');
INSERT INTO Hero VALUES ('Lúcio','Support');
INSERT INTO Hero VALUES ('McCree','DPS');
INSERT INTO Hero VALUES ('Mei','DPS');
INSERT INTO Hero VALUES ('Mercy','Support');
INSERT INTO Hero VALUES ('Moira','Support');
INSERT INTO Hero VALUES ('Orisa','Tank');
INSERT INTO Hero VALUES ('Pharah','DPS');
INSERT INTO Hero VALUES ('Reaper','DPS');
INSERT INTO Hero VALUES ('Reinhardt','Tank');
INSERT INTO Hero VALUES ('Roadhog','Tank');
INSERT INTO Hero VALUES ('Sigma','Tank');
INSERT INTO Hero VALUES ('Soldier: 76','DPS');
INSERT INTO Hero VALUES ('Sombra','DPS');
INSERT INTO Hero VALUES ('Symmetra','DPS');
INSERT INTO Hero VALUES ('Torbjörn','DPS');
INSERT INTO Hero VALUES ('Tracer','DPS');
INSERT INTO Hero VALUES ('Widowmaker','DPS');
INSERT INTO Hero VALUES ('Winston','Tank');
INSERT INTO Hero VALUES ('Wrecking Ball','Tank');
INSERT INTO Hero VALUES ('Zarya','Tank');

/* Map */
INSERT INTO Map
SELECT DISTINCT map_name AS MapName, map_type AS MapType
FROM MapPlayerStat_raw;

/* Match_ */
INSERT INTO Match_
SELECT MatchID, TournamentTitle, MIN(StartDate) AS StartDate, MatchWinner, MatchLoser
FROM (  SELECT MRSr.match_id AS MatchID, MRSr.stage AS TournamentTitle, CAST(MIN(MRSr.round_start_time) AS DATE) AS StartDate, MRSr.match_winner AS MatchWinner, MRSr.team_one_name AS MatchLoser
        FROM MapRoundStat_raw AS MRSr
        WHERE MRSr.match_winner != MRSr.team_one_name
        GROUP BY MRSr.match_id
        UNION
        SELECT MRSr.match_id AS MatchID, MRSr.stage AS TournamentTitle, CAST(MIN(MRSr.round_start_time) AS DATE) AS StartDate, MRSr.match_winner AS MatchWinner, MRSr.team_two_name AS MatchLoser
        FROM MapRoundStat_raw AS MRSr
        WHERE MRSr.match_winner != MRSr.team_two_name
        GROUP BY MRSr.match_id) AS Temp
GROUP BY MatchID
ORDER BY MatchID ASC;

/* PlaysMatch */
INSERT INTO PlaysMatch
SELECT MatchID, MatchWinner AS TeamName
FROM Match_
UNION
SELECT MatchID, MatchLoser AS TeamName
FROM Match_;

/* PlaysMap */
INSERT INTO PlaysMap
SELECT DISTINCT match_id AS MatchID, map_name AS MapName, game_number AS MapNo, map_winner AS MapWinner, map_loser AS MapLoser
FROM MapRoundStat_raw
WHERE EXISTS (SELECT * FROM Match_ WHERE Match_.MatchID = MapRoundStat_raw.match_id);

/* MapPlayerStat */
INSERT INTO MapPlayerStat
SELECT DISTINCT esports_match_id AS MatchID, map_name AS MapName, player_name AS PlayerName, team_name AS TeamName, 
    hero_name AS HeroName, stat_name AS StatName, stat_amount AS StatAmount
FROM MapPlayerStat_raw
WHERE EXISTS (SELECT * FROM Match_ WHERE Match_.MatchID = MapPlayerStat_raw.esports_match_id);

/* MapRoundStat */
INSERT IGNORE INTO MapRoundStat
SELECT DISTINCT match_id, map_name, game_number, map_round, round_start_time, round_end_time, control_round_name, attacker, defender, attacker_payload_distance, defender_payload_distance,
    attacker_time_banked, defender_time_banked, attacker_control_perecent, defender_control_perecent, attacker_round_end_score, defender_round_end_score
FROM MapRoundStat_raw
WHERE EXISTS (SELECT * FROM Match_ WHERE Match_.MatchID = MapRoundStat_raw.match_id);
