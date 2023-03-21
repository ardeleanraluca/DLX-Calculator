LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.STD_LOGIC_UNSIGNED.ALL;

ENTITY IFetch IS
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
END IFetch;

ARCHITECTURE Behavioral OF IFetch IS

    -- Memorie ROM
    TYPE rom_mem IS ARRAY (0 TO 255) OF STD_LOGIC_VECTOR (31 DOWNTO 0);
    SIGNAL ROM : rom_mem := (

        x"20020004", -- addi r2, r0, 4
        x"20040002", -- addi r4, r0,2
        x"20050004", -- addi r5, r0, 4
        -- quick:
        x"aca30000", -- sw 0(r5), r3
        x"20a50001", -- addi r5,r5,1
        x"aca40000", -- sw 0(r5), r4
        -- While:
        x"8ca40000", -- lw r4,0(r5)
        x"20a5ffff", -- addi r5,r5,-1
        x"8ca30000", -- lw r3, 0(r5)
        x"20a5ffff", -- addi r5,r5,-1
        -- partition:
        x"00608820", -- add r17, r3, r0
        x"00243820", -- add r7,r1,r4
        x"8ce90000", -- lw r9, 0(r7) 
        x"222affff", -- addi r10, r17,-1
        -- for:
        x"00317020", -- add r14, r1, r17
        x"8dcb0000", -- lw r11, 0(r14)
        x"012b6028", -- sgt r12, r9,r11
        x"11800008", -- beqz r12, finalFor
        x"214a0001", -- addi r10, r10,1
        x"002a7820", -- add r15, r1, r10
        x"8ded0000", -- lw r13, 0(r15)
        x"01a04020", -- add r8, r13,r0
        x"000b6820", -- add r13, r0, r11
        x"00085820", -- add r11, r0, r8
        x"aded0000", -- sw 0(r15), r13
        x"adcb0000", -- sw 0(r14), r11
        -- finalFor:
        x"22310001", -- addi r17, r17, 1
        x"02248022", -- sub r16, r17,r4
        x"12000001", -- beqz r16, finalPart
        x"0800100e", -- j for
        -- finalPart:
        x"214a0001", -- addi r10, r10,1
        x"002a7820", -- add r15, r1, r10
        x"8ded0000", -- lw r13, 0(r15)
        x"01a04020", -- add r8, r13,r0
        x"00096820", -- add r13, r0, r9	
        x"00084820", -- add r9, r0, r8	
        x"aded0000", -- sw 0(r15), r13
        x"ace90000", -- sw 0(r7), r9
        x"2152ffff", -- addi r18, r10, -1
        x"02439828", -- sgt r19, r18, r3
        x"12600004", -- beqz r19, nextIF	
        x"20a50001", -- addi r5, r5, 1
        x"aca30000", -- sw 0(r5), r3
        x"20a50001", -- addi r5,r5,1
        x"acb20000", -- sw 0(r5), r18
        -- nextIF:
        x"21520001", -- addi r18, r10, 1 
        x"00929828", -- sgt r19, r4, r18
        x"12600004", -- beqz r19, finalQuick
        x"20a50001", -- addi r5, r5, 1
        x"acb20000", -- sw 0(r5), r18
        x"20a50001", -- addi r5,r5,1
        x"aca40000", -- sw 0(r5), r4
        -- finalQuick:
        x"00453028", -- sgt r6, r2,r5
        x"10c0ffd0", -- beqz r6, While

        x"8c010000",
        x"8c010001",
        x"8c010002",

        OTHERS => x"00000000");

    SIGNAL PC : STD_LOGIC_VECTOR(31 DOWNTO 0) := (OTHERS => '0');
    SIGNAL NextAddress, OutPCSrc : STD_LOGIC_VECTOR(31 DOWNTO 0);

BEGIN

    -- PC
    PROCESS (clock)
    BEGIN
        IF rising_edge(clock) THEN
            IF reset = '1' THEN
                PC <= (OTHERS => '0');
            ELSIF enable = '1' THEN
                PC <= NextAddress;
            END IF;
        END IF;
    END PROCESS;

    Instruction <= ROM(conv_integer(PC(7 DOWNTO 0)));

    PCinc <= PC + 1;

    -- MUX Branch
    PROCESS (PCSrc, PCinc, BranchAddress)
    BEGIN
        CASE PCSrc IS
            WHEN '1' => OutPCSrc <= BranchAddress;
            WHEN OTHERS => OutPCSrc <= PCinc;
        END CASE;
    END PROCESS;

    -- MUX Jump
    PROCESS (Jump, OutPCSrc, JumpAddress)
    BEGIN
        CASE Jump IS
            WHEN '1' => NextAddress <= JumpAddress;
            WHEN OTHERS => NextAddress <= OutPCSrc;
        END CASE;
    END PROCESS;

END Behavioral;