LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.STD_LOGIC_UNSIGNED.ALL;

ENTITY MPG IS
    PORT (
        enable : OUT STD_LOGIC;
        input : IN STD_LOGIC;
        clock : IN STD_LOGIC);
END MPG;

ARCHITECTURE Behavioral OF MPG IS

    SIGNAL count_int : STD_LOGIC_VECTOR (15 DOWNTO 0) := (OTHERS => '0');
    SIGNAL Q1 : STD_LOGIC := '0';
    SIGNAL Q2 : STD_LOGIC := '0';
    SIGNAL Q3 : STD_LOGIC := '0';

BEGIN

    enable <= Q2 AND (NOT Q3);

    PROCESS (clock)
    BEGIN
        IF clock = '1' AND clock'event THEN
            count_int <= count_int + 1;
        END IF;
    END PROCESS;

    PROCESS (clock)
    BEGIN
        IF clock'event AND clock = '1' THEN
            IF count_int(15 DOWNTO 0) = "1111111111111111" THEN
                Q1 <= input;
            END IF;
        END IF;
    END PROCESS;

    PROCESS (clock)
    BEGIN
        IF clock'event AND clock = '1' THEN
            Q2 <= Q1;
            Q3 <= Q2;
        END IF;
    END PROCESS;

END Behavioral;