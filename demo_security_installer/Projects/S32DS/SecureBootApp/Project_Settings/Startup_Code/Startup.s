

.globl VTABLE
.section ".startup","ax"

.set VTOR_REG, 0xE000ED08

.thumb
.thumb_func
.align      2
.globl      Reset_Handler
Reset_Handler:

/*****************************************************/
/* Skip normal entry point as nothing is initialized */
/*****************************************************/
 mov   r0, #0
 mov   r1, #0
 mov   r2, #0
 mov   r3, #0
 mov   r4, #0
 mov   r5, #0
 mov   r6, #0
 mov   r7, #0


/*******************************************************************/
/* Freescale Guidance 1 - Init registers to avoid lock-step issues */
/* N/A                                                             */
/*******************************************************************/

/*******************************************************************/
/* Freescale Guidance 2 - MMU Initialization for CPU               */
/*  TLB0 - PbridgeB                                                */
/*  TLB1 - Internal Flash                                          */
/*  TLB2 - External SRAM                                           */
/*  TLB3 - Internal SRAM                                           */
/*  TLB4 - PbridgeA                                                */
/*******************************************************************/

/******************************************************************/
/* Autosar Guidance 1 - The start-up code shall initialize the    */
/* base addresses for interrupt and trap vector tables. These base*/
/* addresses are provided as configuration parameters or          */
/* linker/locator setting.                                        */
/******************************************************************/

/* relocate vector table to RAM */
ldr  r0, =VTOR_REG
ldr  r1, =VTABLE
/* ;ldr  r2, =(1 << 29) */
/*;orr  r1, r2 *//* r1 = r1 | r2 */
str  r1,[r0]

/******************************************************************/
/* Autosar Guidance 2 - The start-up code shall initialize the    */
/* interrupt stack pointer, if an interrupt stack is              */
/* supported by the MCU. The interrupt stack pointer base address */
/* and the stack size are provided as configuration parameter or  */
/* linker/locator setting.                                        */
/*                                                                */
/******************************************************************/


/******************************************************************/
/* Autosar Guidance 3 - The start-up code shall initialize the    */
/* user stack pointer. The user stack pointer base address and    */
/* the stack size are provided as configuration parameter or      */
/* linker/locator setting.                                        */
/******************************************************************/

/* set up stack; r13 SP*/
ldr  r0, =_Stack_start
msr MSP, r0

/******************************************************************/
/* Autosar Guidance 4 - If the MCU supports context save          */
/* operation, the start-up code shall initialize the memory which */
/* is used for context save operation. The maximum amount of      */
/* consecutive context save operations is provided as             */
/* configuration parameter or linker/locator setting.             */
/*                                                                */
/******************************************************************/

/******************************************************************/
/* Autosar Guidance 5 - The start-up code shall ensure that the   */
/* MCU internal watchdog shall not be serviced until the watchdog */
/* is initialized from the MCAL watchdog driver. This can be      */
/* done for example by increasing the watchdog service time.      */
/*                                                                */
/******************************************************************/

/******************************************************************/
/* Autosar Guidance 6 - If the MCU supports cache memory for data */
/* and/or code, it shall be initialized and enabled in the        */
/* start-up code.                                                 */
/*                                                                */
/******************************************************************/

/******************************************************************/
/* Autosar Guidance 7 - The start-up code shall initialize MCU    */
/* specific features of internal memory like memory protection.   */
/*                                                                */
/******************************************************************/

/******************************************************************/
/* Autosar Guidance 8 - If external memory is used, the memory    */
/* shall be initialized in the start-up code. The start-up code   */
/* shall be prepared to support different memory configurations   */
/* depending on code location. Different configuration options    */
/* shall be taken into account for code execution from            */
/* external/internal memory.                                      */
/* N/A - external memory is not used                              */
/******************************************************************/

/******************************************************************/
/* Autosar Guidance 9 - The settings of the different memories    */
/* shall be provided to the start-up code as configuration        */
/* parameters.                                                    */
/* N/A - all memories are already configured                      */
/******************************************************************/

/******************************************************************/
/* Autosar Guidance 10 - In the start-up code a default           */
/* initialization of the MCU clock system shall be performed      */
/* including global clock prescalers.                             */
/******************************************************************/
.equ CH0_ENABLE,(0x40280000)
.equ TCD0_CH0_BASE,(0x40210000)
.equ TCD0_CH1_BASE,(0x40214000)
.equ TCD0_CH2_BASE,(0x40218000)
.equ DMA_MUX0_BASE,(0x40280000)
.equ MC_ME_BASE,(0x402DC000)

    /* Configure Mode Entry Module */
    ldr R0, =0x402DC000
    
    /* clock enable of eDMA in partition 1 */
    ldr R0, =0x402DC330
    ldr R4, =0x00000018
    str R4, [R0]

    /* clock enable of DMAMUX_0 in partition 1 */
    ldr R0, =0x402DC334
    ldr R1, =0x00000001
    str R1, [R0]

    /* Partition clock update - Trigger the hardware process */
    ldr R0, =0x402DC304
    ldr R1, =0x00000001
    str R1, [R0]

    /* Writing Key for starting the hardware processes.
       Writes with a value other than key or inverted key are
       ignored. 
    */
    ldr R0, =0x402DC000
    ldr R1, =0x00005AF0
    str R1, [R0]

    /* Writing Inverted Key for starting the hardware processes */
    ldr R0, =0x402DC000
    ldr R1, =0x0000A50F
    str R1, [R0]

    /* DMA SRAM Stack init */
    /* Channel 0 Enable*/
    ldr R0, =CH0_ENABLE
    ldr R1, =0x80000000
    str R1, [R0]
    
    /* Source Address */
    ldr R0, =TCD0_CH0_BASE
    /* Clear Channel DONE bit */
    mov r1, #0
    str r1, [r0]
    
    /* Memory address pointing to the source data. */
    ldr R1, =0x00400000
    str R1,[R0, #0x20]
    
    /* Source Address Signed Offset.
       Sign-extended offset applied to the current source
       address to form the next-state value as each source
       read is completed.
    */
    ldr R1, =0x02030004
    str R1,[R0, #0x24]

    /* Number of Bytes To Transfer Per Service Request */
    ldr R1, =0x00020000
    str R1,[R0, #0x28]

    /* Source last address adjustment or the system memory
       address for destination address (DADDR)
       storage.*/
    ldr R1, =0x000D8000
    str R1,[R0, #0x2C]

    /* Destination Address */
    ldr R1, =0x20400000
    str R1,[R0, #0x30]

    /* Destination Address Signed Offset */
    ldr R1, =0x00020008
    str R1,[R0, #0x34]

    /* Last Destination Address Adjustment */
    ldr R1, =0x00020000
    str R1,[R0, #0x38]

    /* Channel Start */
    ldr R1, =0x00020001
    str R1,[R0, #0x3C]
    
    /*Wait for Ch[0] to complete */
    ldr r5, =0xFFFF
loop_wait_1:
    sub r5, r5, #0x1
    bne loop_wait_1

    ldr r1, =RC_DATA_SRC
    ldr r2, =RC_DATA_DEST
    ldr r3, =RC_DATA_SRC_END
    bl  CopyAtR2MemRangeR1R3

    /* Zero fill the CAAM RAM bss segment */
    ldr r1, =_bss_start
    ldr r3, =_bss_end
    mov r2, #0
    bl FillMemRangeR1R3withR2

/*bl SystemInit*/

/******************************************************************/
/* Autosar Guidance 11 - The start-up code shall enable           */
/* protection mechanisms for special function registers(SFR's),   */
/* if supported by the MCU.                                       */
/* N/A - will be handled by Autosar OS                            */
/******************************************************************/

/******************************************************************/
/* Autosar Guidance 12 - The start-up code shall initialize all   */
/* necessary write once registers or registers common to several  */
/* drivers where one write, rather than repeated writes, to the   */
/* register is required or highly desirable.                      */
/******************************************************************/

/******************************************************************/
/* Autosar Guidance 13 - The start-up code shall initialize a     */
/* minimum amount of RAM in order to allow proper execution of    */
/* the MCU driver services and the caller of these services.      */
/******************************************************************/
/* MPC574xP - internal ram must be initialized for error correction*/
/******************************************************************/

/*********************************/
/* Set the small ro data pointer */
/*********************************/

/*********************************/
/* Set the small rw data pointer */
/*********************************/

/******************************************************************/
/* Go to user mode and Call Main Routine                          */
/******************************************************************/

bl main

/******************************************************************/
/* Init runtime check data space                                  */
/******************************************************************/

.globl MCAL_LTB_TRACE_OFF
 MCAL_LTB_TRACE_OFF:
    nop

#ifdef CCOV_ENABLE
    /* code coverage is requested */
    bl ccov_main
#endif


.globl _end_of_eunit_test
_end_of_eunit_test:

    /*BKPT #1 Instruction not supported on VLAB simulator. todo: revert workaround on sillicon. */ /* last instruction for the debugger to dump results data */

    b .

FillMemRangeR1R3withR2:
      str r2, [r1]
      add r1, r1, #4
      cmp r1, r3
      bcc FillMemRangeR1R3withR2
    bx  lr

CopyAtR2MemRangeR1R3:
    cmp r1, r3
    beq DoneCopyAt
    1:
       ldr r4, [r1]
       str r4, [r2]
       add r1, r1, #4
       add r2, r2, #4
       cmp r1, r3
       bcc 1b
    DoneCopyAt:
       bx lr

 

#ifdef MCAL_ENABLE_USER_MODE_SUPPORT
.globl startup_getControlRegisterValue
startup_getControlRegisterValue:
mrs r0, CONTROL
bx r14

.globl startup_getAipsRegisterValue
startup_getAipsRegisterValue:
mrs r0, IPSR
bx r14
#endif

.globl HSE_CORE_LOOP
HSE_CORE_LOOP:
    b HSE_CORE_LOOP


.section ".stack_main","aw"
.thumb
.align 4

#ifdef __STACK_SIZE
.set Stack_Size, __STACK_SIZE
#else
.set Stack_Size, 0x1000
#endif

.space Stack_Size

