LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.STD_LOGIC_UNSIGNED.ALL;

ENTITY MEM IS
    PORT (
        clock : IN STD_LOGIC;
        enable : IN STD_LOGIC;
        ALUResIn : IN STD_LOGIC_VECTOR(31 DOWNTO 0); --WriteData
        RD2 : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
        MemWrite : IN STD_LOGIC;
        MemData : OUT STD_LOGIC_VECTOR(31 DOWNTO 0); --ReadData
        ALUResOut : OUT STD_LOGIC_VECTOR(31 DOWNTO 0));
END MEM;

ARCHITECTURE Behavioral OF MEM IS

    TYPE ram_mem IS ARRAY (0 TO 31) OF STD_LOGIC_VECTOR(31 DOWNTO 0);
    SIGNAL MEM : ram_mem := (
        x"0000000a",
        X"00000001",
        X"00000007",
        OTHERS => x"00000000");

BEGIN

    -- Data Memory
    PROCESS (clock)
    BEGIN
        IF rising_edge(clock) THEN
            IF enable = '1' AND MemWrite = '1' THEN
                MEM(conv_integer(ALUResIn(4 DOWNTO 0))) <= RD2;
            END IF;
        END IF;
    END PROCESS;

    -- outputs
    MemData <= MEM(conv_integer(ALUResIn(4 DOWNTO 0)));
    ALUResOut <= ALUResIn;

END Behavioral;