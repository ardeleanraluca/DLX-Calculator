LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.STD_LOGIC_ARITH.ALL;
USE IEEE.STD_LOGIC_UNSIGNED.ALL;
ENTITY SSD IS
	PORT (
		digits : IN STD_LOGIC_VECTOR (15 DOWNTO 0);
		clock : IN STD_LOGIC;
		cat : OUT STD_LOGIC_VECTOR (6 DOWNTO 0);
		an : OUT STD_LOGIC_VECTOR (3 DOWNTO 0));
END SSD;

ARCHITECTURE Behavioral OF SSD IS

	SIGNAL tmp : STD_LOGIC_VECTOR(15 DOWNTO 0) := x"0000";
	SIGNAL x : STD_LOGIC_VECTOR(3 DOWNTO 0);
BEGIN
	PROCESS (clock)
	BEGIN
		IF rising_edge(clock) THEN
			tmp <= tmp + 1;
		END IF;
	END PROCESS;
	PROCESS (clock)
	BEGIN
		CASE tmp(15 DOWNTO 14) IS
			WHEN "00" => x <= digits(3 DOWNTO 0);
			WHEN "01" => x <= digits(7 DOWNTO 4);
			WHEN "10" => x <= digits(11 DOWNTO 8);
			WHEN OTHERS => x <= digits(15 DOWNTO 12);
		END CASE;
	END PROCESS;

	PROCESS (clock)
	BEGIN
		CASE tmp(15 DOWNTO 14) IS
			WHEN "00" => an <= "1110";
			WHEN "01" => an <= "1101";
			WHEN "10" => an <= "1011";
			WHEN OTHERS => an <= "0111";
		END CASE;
	END PROCESS;
	PROCESS (x)
	BEGIN
		CASE x IS
			WHEN X"0" => cat <= "1000000"; --0;
			WHEN X"1" => cat <= "1111001"; --1
			WHEN X"2" => cat <= "0100100"; --2
			WHEN X"3" => cat <= "0110000"; --3
			WHEN X"4" => cat <= "0011001"; --4
			WHEN X"5" => cat <= "0010010"; --5
			WHEN X"6" => cat <= "0000010"; --6
			WHEN X"7" => cat <= "1111000"; --7
			WHEN X"8" => cat <= "0000000"; --8
			WHEN X"9" => cat <= "0010000"; --9
			WHEN X"A" => cat <= "0001000"; --A
			WHEN X"B" => cat <= "0000011"; --b
			WHEN X"C" => cat <= "1000110"; --C
			WHEN X"D" => cat <= "0100001"; --d
			WHEN X"E" => cat <= "0000110"; --E
			WHEN X"F" => cat <= "0001110"; --F
			WHEN OTHERS => cat <= "0111111"; -- gol
		END CASE;
	END PROCESS;
END Behavioral;