LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;

ENTITY MainControl IS
    PORT (
        Instr : IN STD_LOGIC_VECTOR(5 DOWNTO 0);
        RegDst : OUT STD_LOGIC;
        ExtOp : OUT STD_LOGIC;
        ALUSrc : OUT STD_LOGIC;
        Branch : OUT STD_LOGIC;
        Jump : OUT STD_LOGIC;
        ALUOp : OUT STD_LOGIC_VECTOR(2 DOWNTO 0);
        MemWrite : OUT STD_LOGIC;
        MemtoReg : OUT STD_LOGIC;
        RegWrite : OUT STD_LOGIC);
END MainControl;

ARCHITECTURE Behavioral OF MainControl IS
BEGIN

    PROCESS (Instr)
    BEGIN
        RegDst <= '0';
        ExtOp <= '0';
        ALUSrc <= '0';
        Branch <= '0';
        Jump <= '0';
        MemWrite <= '0';
        MemtoReg <= '0';
        RegWrite <= '0';
        ALUOp <= "000";

        CASE (Instr) IS
            WHEN "000000" => -- R type
                RegDst <= '1';
                RegWrite <= '1';
                ALUOp <= "000";

            WHEN "001000" => -- ADDI
                ExtOp <= '1';
                ALUSrc <= '1';
                RegWrite <= '1';
                ALUOp <= "001";

            WHEN "100011" => -- LW
                ExtOp <= '1';
                ALUSrc <= '1';
                MemtoReg <= '1';
                RegWrite <= '1';
                ALUOp <= "001";

            WHEN "001100" => -- ANDI
                ALUSrc <= '1';
                RegWrite <= '1';
                ALUOp <= "100";

            WHEN "101011" => -- SW
                ExtOp <= '1';
                ALUSrc <= '1';
                MemWrite <= '1';
                ALUOp <= "001";

            WHEN "000100" => -- BEQ
                ExtOp <= '1';
                Branch <= '1';
                ALUOp <= "010";
            WHEN "000010" => -- J
                Jump <= '1';

            WHEN OTHERS =>
                RegDst <= '0';
                ExtOp <= '0';
                ALUSrc <= '0';
                Branch <= '0';
                Jump <= '0';
                MemWrite <= '0';
                MemtoReg <= '0';
                RegWrite <= '0';
                ALUOp <= "000";
        END CASE;
    END PROCESS;

END Behavioral;