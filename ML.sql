DELIMITER |
DROP PROCEDURE IF EXISTS player_winning;
CREATE PROCEDURE player_winning(PName VARCHAR(50))
BEGIN
    SELECT PlayerName, WinningRate
    FROM Predict 
    WHERE PlayerName = PName
END;
|

DELIMITER |
DROP PROCEDURE IF EXISTS compare_player;
CREATE PROCEDURE compare_palyer(PName1 VARCHAR(50), PName2 VARCHAR(50))
BEGIN
    SELECT PlayerName, WinningRate
    FROM Predict 
    WHERE PlayerName = PName1 OR PlayerName = PName2
    ORDER BY WinningRate
END;
|

DELIMITER |
DROP PROCEDURE IF EXISTS player_ranking;
CREATE PROCEDURE player_ranking()
BEGIN
    SELECT *
    FROM Predict 
    ORDER BY WinningRate DESC
END;
|