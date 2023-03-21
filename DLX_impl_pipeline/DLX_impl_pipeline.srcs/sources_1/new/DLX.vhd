LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.std_logic_unsigned.ALL;

ENTITY DLX IS
    PORT (
        clock : IN STD_LOGIC;
        btn : IN STD_LOGIC_VECTOR (4 DOWNTO 0);
        sw : IN STD_LOGIC_VECTOR (15 DOWNTO 0);
        led : OUT STD_LOGIC_VECTOR (15 DOWNTO 0);
        an : OUT STD_LOGIC_VECTOR (3 DOWNTO 0);
        cat : OUT STD_LOGIC_VECTOR (6 DOWNTO 0));
END DLX;

ARCHITECTURE Behavioral OF DLX IS

    COMPONENT MPG IS
        PORT (
            enable : OUT STD_LOGIC;
            input : IN STD_LOGIC;
            clock : IN STD_LOGIC);
    END COMPONENT;

    COMPONENT SSD IS
        PORT (
            digits : IN STD_LOGIC_VECTOR (15 DOWNTO 0);
            clock : IN STD_LOGIC;
            cat : OUT STD_LOGIC_VECTOR (6 DOWNTO 0);
            an : OUT STD_LOGIC_VECTOR (3 DOWNTO 0));
    END COMPONENT;

    COMPONENT IFetch
        PORT (
            clock : IN STD_LOGIC;
            reset : IN STD_LOGIC;
            enable : IN STD_LOGIC;
            BranchAddress : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
            JumpAddress : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
            Jump : IN STD_LOGIC;
            PCSrc : IN STD_LOGIC;
            Instruction : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
            PCinc : INOUT STD_LOGIC_VECTOR(31 DOWNTO 0));
    END COMPONENT;

    COMPONENT IDecode
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
    END COMPONENT;

    COMPONENT MainControl
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
    END COMPONENT;

    COMPONENT ExecutionUnit IS
        PORT (
            Instr : IN STD_LOGIC_VECTOR(25 DOWNTO 0);
            PCinc : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
            RD1 : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
            RD2 : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
            Ext_Imm : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
            func : IN STD_LOGIC_VECTOR(5 DOWNTO 0);
            sa : IN STD_LOGIC_VECTOR(4 DOWNTO 0);
            WriteAddress : OUT STD_LOGIC_VECTOR(4 DOWNTO 0);
            RegDst : IN STD_LOGIC;
            ALUSrc : IN STD_LOGIC;
            ALUOp : IN STD_LOGIC_VECTOR(2 DOWNTO 0);
            BranchAddress : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
            ALURes : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
            Zero : OUT STD_LOGIC);
    END COMPONENT;

    COMPONENT MEM
        PORT (
            clock : IN STD_LOGIC;
            enable : IN STD_LOGIC;
            ALUResIn : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
            RD2 : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
            MemWrite : IN STD_LOGIC;
            MemData : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
            ALUResOut : OUT STD_LOGIC_VECTOR(31 DOWNTO 0));
    END COMPONENT;

    SIGNAL Instruction, PCinc, RD1, RD2, WriteData, Ext_imm : STD_LOGIC_VECTOR(31 DOWNTO 0) := x"00000000";
    SIGNAL JumpAddress, BranchAddress, ALURes, ALURes1, MemData : STD_LOGIC_VECTOR(31 DOWNTO 0) := x"00000000";
    SIGNAL func : STD_LOGIC_VECTOR(5 DOWNTO 0) := "000000";
    SIGNAL sa : STD_LOGIC_VECTOR(4 DOWNTO 0) := "00000";
    SIGNAL zero : STD_LOGIC := '0';
    SIGNAL digits : STD_LOGIC_VECTOR(15 DOWNTO 0) := x"0000";
    SIGNAL enable, reset, PCSrc : STD_LOGIC := '0';

    -- main controls 
    SIGNAL RegDst, ExtOp, ALUSrc, Branch, BranchLtz, Jump, MemWrite, MemtoReg, RegWrite : STD_LOGIC;
    SIGNAL ALUOp : STD_LOGIC_VECTOR(2 DOWNTO 0);
    SIGNAL WriteAddress : STD_LOGIC_VECTOR(4 DOWNTO 0) := "00000";

    -- pipeline
    SIGNAL RegIF_ID : STD_LOGIC_VECTOR(63 DOWNTO 0);
    SIGNAL RegID_EX : STD_LOGIC_VECTOR(179 DOWNTO 0);
    SIGNAL RegEX_MEM : STD_LOGIC_VECTOR(105 DOWNTO 0);
    SIGNAL RegMEM_WB : STD_LOGIC_VECTOR(70 DOWNTO 0);

BEGIN
    -- PIPELINE

    MPG1 : MPG PORT MAP(enable, btn(0), clock);
    MPG2 : MPG PORT MAP(reset, btn(1), clock);
    PROCESS (clock)
    BEGIN
        IF (rising_edge(clock)) THEN
            IF enable = '1' THEN
                RegIF_ID(63 DOWNTO 32) <= PCinc;
                RegIF_ID(31 DOWNTO 0) <= Instruction;
            END IF;
        END IF;
    END PROCESS;
    PROCESS (clock)
    BEGIN
        IF (rising_edge(clock)) THEN
            IF enable = '1' THEN
                RegID_EX(179) <= RegDst;
                RegID_EX(178 DOWNTO 173) <= func;
                RegID_EX(172) <= MemtoReg;
                RegID_EX(171) <= RegWrite;
                RegID_EX(170) <= MemWrite;
                RegID_EX(169) <= Branch;
                RegID_EX(168 DOWNTO 166) <= ALUOp;
                RegID_EX(165) <= ALUSrc;
                RegID_EX(164 DOWNTO 160) <= sa;
                RegID_EX(159 DOWNTO 128) <= RegIF_ID(63 DOWNTO 32);
                RegID_EX(127 DOWNTO 96) <= RD1;
                RegID_EX(95 DOWNTO 64) <= RD2;
                RegID_EX(63 DOWNTO 32) <= Ext_Imm;
                RegID_EX(31 DOWNTO 0) <= RegIF_ID(31 DOWNTO 0);
            END IF;
        END IF;
    END PROCESS;
    PROCESS (clock)
    BEGIN
        IF (rising_edge(clock)) THEN
            IF enable = '1' THEN
                RegEX_MEM(105 DOWNTO 101) <= WriteAddress;
                RegEX_MEM(100) <= RegID_EX(172);
                RegEX_MEM(99) <= RegID_EX(171);
                RegEX_MEM(98) <= RegID_EX(170);
                RegEX_MEM(97) <= RegID_EX(169);
                RegEX_MEM(96 DOWNTO 65) <= BranchAddress;
                RegEX_MEM(64) <= zero;
                RegEX_MEM(63 DOWNTO 32) <= ALURes;
                RegEX_MEM(31 DOWNTO 0) <= RegID_EX(95 DOWNTO 64);

            END IF;
        END IF;
    END PROCESS;
    PROCESS (clock)
    BEGIN
        IF (rising_edge(clock)) THEN
            IF enable = '1' THEN
                RegMEM_WB(70 DOWNTO 66) <= RegEX_MEM(105 DOWNTO 101);
                RegMEM_WB(65) <= RegEX_MEM(100);
                RegMEM_WB(64) <= RegEX_MEM(99);
                RegMEM_WB(63 DOWNTO 32) <= MemData;
                RegMEM_WB(31 DOWNTO 0) <= ALURes1;

            END IF;
        END IF;
    END PROCESS;
    -- main units
    instrFetch : IFetch PORT MAP(
        clock,
        reset,
        enable,
        RegEX_MEM(96 DOWNTO 65),
        JumpAddress,
        Jump,
        PCSrc,
        Instruction,
        PCinc);

    instrDecode : IDecode PORT MAP(
        clock,
        enable,
        RegIF_ID(25 DOWNTO 0),
        WriteData,
        RegMEM_WB(70 DOWNTO 66),
        RegMEM_WB(64),
        ExtOp,
        RD1,
        RD2,
        Ext_imm,
        func,
        sa);

    instrMC : MainControl PORT MAP(
        RegIF_ID(31 DOWNTO 26),
        RegDst,
        ExtOp,
        ALUSrc,
        Branch,
        Jump,
        ALUOp,
        MemWrite,
        MemtoReg,
        RegWrite);

    instrEX : ExecutionUnit PORT MAP(
        RegID_EX(25 DOWNTO 0),
        RegID_EX(159 DOWNTO 128),
        RegID_EX(127 DOWNTO 96),
        RegID_EX(95 DOWNTO 64),
        RegID_EX(63 DOWNTO 32),
        RegID_EX(178 DOWNTO 173),
        RegID_EX(164 DOWNTO 160),
        WriteAddress,
        RegID_EX(179),
        RegID_EX(165),
        RegID_EX(168 DOWNTO 166),
        BranchAddress,
        ALURes,
        Zero);

    instrMEM : MEM PORT MAP(
        clock,
        enable,
        RegEX_MEM(63 DOWNTO 32),
        RegEX_MEM(31 DOWNTO 0),
        RegEX_MEM(98),
        MemData,
        ALURes1);

    -- WriteBack unit
    WriteData <= RegMEM_WB(63 DOWNTO 32) WHEN RegMEM_WB(65) = '1'
        ELSE
        RegMEM_WB(31 DOWNTO 0);

    -- branch control
    --     PCSrc <= (Zero and Branch)
    PCSrc <= RegEX_MEM(64) AND RegEX_MEM(97);

    -- jump address
    --    JumpAddress <= PCinc(31 DOWNTO 28) & Instruction(27 DOWNTO 0);
    JumpAddress <= RegIF_ID(63 DOWNTO 60) & RegIF_ID(27 DOWNTO 0);

    -- SSD display MUX
    digits <=
        Instruction(31 DOWNTO 16) WHEN sw(1 DOWNTO 0) = "00"
        ELSE
        Instruction(15 DOWNTO 0) WHEN sw(1 DOWNTO 0) = "01"
        ELSE
        MemData(31 DOWNTO 16) WHEN sw(1 DOWNTO 0) = "10"
        ELSE
        MemData(15 DOWNTO 0) WHEN sw(1 DOWNTO 0) = "11"

        ELSE
        (OTHERS => '0');

    display : SSD PORT MAP(digits, clock, cat, an);

END Behavioral;