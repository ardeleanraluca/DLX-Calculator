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
            RegWrite : IN STD_LOGIC;
            RegDst : IN STD_LOGIC;
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
    END COMPONENT;

    COMPONENT MEM
        PORT (
            clock : IN STD_LOGIC;
            enable : IN STD_LOGIC;
            ALUResIn : IN STD_LOGIC_VECTOR(31 DOWNTO 0); --WriteData
            RD2 : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
            MemWrite : IN STD_LOGIC;
            MemData : OUT STD_LOGIC_VECTOR(31 DOWNTO 0); --ReadData
            ALUResOut : OUT STD_LOGIC_VECTOR(31 DOWNTO 0));
    END COMPONENT;

    SIGNAL Instruction, PCinc, RD1, RD2, WriteData, Ext_imm : STD_LOGIC_VECTOR(31 DOWNTO 0);
    SIGNAL JumpAddress, BranchAddress, ALURes, ALURes1, MemData : STD_LOGIC_VECTOR(31 DOWNTO 0);
    SIGNAL func : STD_LOGIC_VECTOR(5 DOWNTO 0);
    SIGNAL sa : STD_LOGIC_VECTOR(4 DOWNTO 0);
    SIGNAL zero : STD_LOGIC;
    SIGNAL digits : STD_LOGIC_VECTOR(15 DOWNTO 0);
    SIGNAL enable, reset, PCSrc : STD_LOGIC;

    -- main controls 
    SIGNAL RegDst, ExtOp, ALUSrc, Branch, Jump, MemWrite, MemtoReg, RegWrite : STD_LOGIC;
    SIGNAL ALUOp : STD_LOGIC_VECTOR(2 DOWNTO 0);

BEGIN

    -- buttons: reset, enable
    MPG1 : MPG PORT MAP(enable, btn(0), clock);
    MPG2 : MPG PORT MAP(reset, btn(1), clock);

    -- main units
    instrFetch : IFetch PORT MAP(clock, reset, enable, BranchAddress, JumpAddress, Jump, PCSrc, Instruction, PCinc);
    instrDecode : IDecode PORT MAP(clock, enable, Instruction(25 DOWNTO 0), WriteData, RegWrite, RegDst, ExtOp, RD1, RD2, Ext_imm, func, sa);
    instrMC : MainControl PORT MAP(Instruction(31 DOWNTO 26), RegDst, ExtOp, ALUSrc, Branch, Jump, ALUOp, MemWrite, MemtoReg, RegWrite);
    instrEX : ExecutionUnit PORT MAP(PCinc, RD1, RD2, Ext_imm, func, sa, ALUSrc, ALUOp, BranchAddress, ALURes, Zero);
    instrMEM : MEM PORT MAP(clock, enable, ALURes, RD2, MemWrite, MemData, ALURes1);

    -- WriteBack unit
    WriteData <= MemData WHEN MemtoReg = '1'
        ELSE
        ALURes1;

    -- branch control
    PCSrc <= (Zero AND Branch);

    -- jump address
    JumpAddress <= PCinc(31 DOWNTO 28) & Instruction(27 DOWNTO 0);

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