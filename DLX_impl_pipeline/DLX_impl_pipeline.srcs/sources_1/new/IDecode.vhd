LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.STD_LOGIC_UNSIGNED.ALL;

ENTITY IDecode IS
    PORT (
        clock : IN STD_LOGIC;
        enable : IN STD_LOGIC;
        Instr : IN STD_LOGIC_VECTOR(25 DOWNTO 0);
        WriteData : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
        WriteAddress : STD_LOGIC_VECTOR(4 DOWNTO 0);
        RegWrite : IN STD_LOGIC;
        ExtOp : IN STD_LOGIC;
        RD1 : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
        RD2 : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
        Ext_Imm : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
        func : OUT STD_LOGIC_VECTOR(5 DOWNTO 0);
        sa : OUT STD_LOGIC_VECTOR(4 DOWNTO 0));
END IDecode;

ARCHITECTURE Behavioral OF IDecode IS

    -- RegFile
    TYPE register_file IS ARRAY(0 TO 31) OF STD_LOGIC_VECTOR(31 DOWNTO 0);
    SIGNAL reg_file : register_file := (OTHERS => X"00000000");

    SIGNAL RegAddress : STD_LOGIC_VECTOR(4 DOWNTO 0);

BEGIN

    PROCESS (clock)
    BEGIN
        IF rising_edge(clock) THEN
            IF enable = '1' AND RegWrite = '1' THEN
                reg_file(conv_integer(WriteAddress)) <= WriteData;
            END IF;
        END IF;
    END PROCESS;

    -- RegFile read
    RD1 <= reg_file(conv_integer(Instr(25 DOWNTO 21))); -- rs
    RD2 <= reg_file(conv_integer(Instr(20 DOWNTO 16))); -- rt

    -- immediate extend
    Ext_Imm(15 DOWNTO 0) <= Instr(15 DOWNTO 0);

    Ext_Imm(31 DOWNTO 16) <= (OTHERS => Instr(15))
    WHEN ExtOp = '1'
ELSE
    (OTHERS => '0');

    sa <= Instr(10 DOWNTO 6);
    func <= Instr(5 DOWNTO 0);

END Behavioral;