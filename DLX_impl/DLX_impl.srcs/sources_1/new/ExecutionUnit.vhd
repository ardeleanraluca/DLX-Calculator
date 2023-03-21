LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.STD_LOGIC_UNSIGNED.ALL;
USE IEEE.numeric_std.ALL;

ENTITY ExecutionUnit IS
    PORT (
        PCinc : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
        RD1 : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
        RD2 : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
        Ext_Imm : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
        func : IN STD_LOGIC_VECTOR(5 DOWNTO 0);
        sa : IN STD_LOGIC_VECTOR(4 DOWNTO 0);
        ALUSrc : IN STD_LOGIC;
        ALUOp : IN STD_LOGIC_VECTOR(2 DOWNTO 0);
        BranchAddress : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
        ALURes : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
        Zero : OUT STD_LOGIC);
END ExecutionUnit;

ARCHITECTURE Behavioral OF ExecutionUnit IS

    SIGNAL In2 : STD_LOGIC_VECTOR(31 DOWNTO 0);
    SIGNAL ALUCtrl : STD_LOGIC_VECTOR(2 DOWNTO 0);
    SIGNAL ResAux : STD_LOGIC_VECTOR(31 DOWNTO 0) := x"00000000";
    SIGNAL Cat : STD_LOGIC_VECTOR(31 DOWNTO 0) := x"00000000";
    SIGNAL Rest : STD_LOGIC_VECTOR(31 DOWNTO 0) := x"00000000";

BEGIN

    -- MUX for ALU input 2
    In2 <= RD2 WHEN ALUSrc = '0'
        ELSE
        Ext_Imm WHEN ALUSrc = '1'
        ELSE
        (OTHERS => '0');

    -- ALU Control
    PROCESS (ALUOp, func)
    BEGIN
        CASE ALUOp IS
            WHEN "000" => -- R type 
                CASE func IS
                    WHEN "100000" => ALUCtrl <= "000"; -- ADD
                    WHEN "100010" => ALUCtrl <= "001"; -- SUB
                    WHEN "000000" => ALUCtrl <= "010"; -- SLLi
                    WHEN "000010" => ALUCtrl <= "011"; -- SRLi
                    WHEN "100100" => ALUCtrl <= "100"; -- AND
                    WHEN "100101" => ALUCtrl <= "101"; -- OR
                    WHEN "101000" => ALUCtrl <= "110"; -- sgt
                    WHEN "101010" => ALUCtrl <= "111"; -- slt
                    WHEN OTHERS => ALUCtrl <= (OTHERS => '0'); -- unknown
                END CASE;
            WHEN "001" => ALUCtrl <= "000"; -- +  ADDI, LW, SW
            WHEN "010" => ALUCtrl <= "001"; -- -  BEQ
            WHEN "100" => ALUCtrl <= "100"; -- & ANDI

            WHEN OTHERS => ALUCtrl <= (OTHERS => '0'); -- unknown
        END CASE;
    END PROCESS;

    -- ALU
    PROCESS (ALUCtrl, RD1, In2, sa, ResAux)
    BEGIN
        CASE ALUCtrl IS
            WHEN "000" => -- ADD
                ResAux <= RD1 + In2;
            WHEN "001" => -- SUB
                ResAux <= RD1 - In2;
            WHEN "010" => -- SLLi
                ResAux <= STD_LOGIC_VECTOR(unsigned(RD1) SLL TO_INTEGER(unsigned(sa)));
            WHEN "011" => -- SRLi
                ResAux <= STD_LOGIC_VECTOR(unsigned(RD1) SRL TO_INTEGER(unsigned(sa)));
            WHEN "100" => -- AND
                ResAux <= RD1 AND In2;
            WHEN "101" => -- OR
                ResAux <= RD1 OR In2;
            WHEN "110" => -- sqt
                IF signed(RD1) > signed(In2) THEN
                    ResAux <= X"00000001";
                ELSE
                    ResAux <= X"00000000";
                END IF;

            WHEN "111" => -- slt
                IF signed(RD1) < signed(In2) THEN
                    ResAux <= X"00000001";
                ELSE
                    ResAux <= X"00000000";
                END IF;
            WHEN OTHERS => -- unknown
                ResAux <= (OTHERS => '0');
        END CASE;
        -- zero detector
        CASE ResAux IS
            WHEN x"00000000" => Zero <= '1';
            WHEN OTHERS => Zero <= '0';
        END CASE;

    END PROCESS;

    -- ALU result
    ALURes <= ResAux;

    -- generate branch address
    BranchAddress <= PCinc + Ext_Imm;

END Behavioral;