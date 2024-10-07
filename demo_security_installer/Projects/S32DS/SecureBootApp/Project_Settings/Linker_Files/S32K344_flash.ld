/*****************************************************************************
 *
 * Copyright 2020 NXP
 * All Rights Reserved
 *
 *****************************************************************************
 *
 * THIS SOFTWARE IS PROVIDED BY NXP "AS IS" AND ANY EXPRESSED OR
 * IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES
 * OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
 * IN NO EVENT SHALL NXP OR ITS CONTRIBUTORS BE LIABLE FOR ANY DIRECT,
 * INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 * SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
 * STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING
 * IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF
 * THE POSSIBILITY OF SUCH DAMAGE.
 *
 ****************************************************************************/

__STACK_SIZE = 0x1000;

/* Linker script to configure memory regions. */
MEMORY
{
  FIXED_ADDR_APP_HEADER  (R)   : ORIGIN = 0x00451FC0, LENGTH = 0x40
  FLASH                  (RX)  : ORIGIN = 0x00452000, LENGTH = 0x1000
  INT_SRAM               (RW)  : ORIGIN = 0x20400000, LENGTH = 0x2000
}

/* Linker script to place sections and symbol values. Should be used together
 * with other linker script that defines memory regions FLASH and RAM.
 * It references following symbols, which must be defined in code:
 *   Reset_Handler : Entry of reset handler
 *
 * It defines following symbols, which code can use without definition:
 *   __exidx_start
 *   __exidx_end
 *   __ecc_table_start__
 *   __ecc_table_end__
 *   __etext
 *   __data_start__
 *   __preinit_array_start
 *   __preinit_array_end
 *   __init_array_start
 *   __init_array_end
 *   __fini_array_start
 *   __fini_array_end
 *   __data_end__
 *   __bss_start__
 *   __bss_end__
 *   __end__
 *   end
 *   __HeapLimit
 *   __StackLimit
 *   __StackTop
 *   __stack
 */
ENTRY(Reset_Handler)

STACK_SIZE = DEFINED(__STACK_SIZE) ? __STACK_SIZE : 0x1000;

SECTIONS
{

/***********************************************************************************************************************************************/
/*                              FLASH SECTIONS                                                                                                   */
/***********************************************************************************************************************************************/
    
    ._app_header                                    : {} > FIXED_ADDR_APP_HEADER
    
    .intc_vector                                    : {} > FLASH 
    
    .startup                                        :
    {
        *(.startup)
    } > FLASH
    
    .intc_vector_rom                                : {} > FLASH
    
    .systeminit                                     : {} > FLASH
    
    .text.startup                                   :
    {
        *startup*.o(.text)
    } > FLASH
    
    .text                                           :
    {
        *(.text)                 
        *(.text*)  
    } > FLASH
    
    .mcal_text                                      : {} > FLASH
    
    .rodata                                         :
    {
        *(.rodata)               
        *(.rodata*)  
    } > FLASH
    
    RC_RAMCODE_SRC = .;
    
    .ramcode : AT(RC_RAMCODE_SRC)
    {

    } > INT_SRAM
    
    RC_RAMCODE_DEST                = ORIGIN(INT_SRAM);
    RC_RAMCODE_SIZE                = SIZEOF(.ramcode);
    RC_CODE_SRC_END                = RC_RAMCODE_SRC + RC_RAMCODE_SIZE;
    
    .init_pflash_sec    : AT(RC_CODE_SRC_END)
    {
    
    } > INT_SRAM
  
    INIT_PFLASH_DATA_DEST       = ORIGIN(INT_SRAM);
    INIT_PFLASH_DATA_SIZE       = SIZEOF(.init_pflash_sec);
    INIT_PFLASH_DATA_SRC_END    = RC_CODE_SRC_END + INIT_PFLASH_DATA_SIZE;
    
    RC_RAMCODE_SIZE     = INIT_PFLASH_DATA_SIZE;
    RC_CODE_SRC_END        = INIT_PFLASH_DATA_SRC_END;
    
    RC_DATA_SRC = RC_CODE_SRC_END;
    
    .data : AT(RC_CODE_SRC_END)
    {
      . = ALIGN(4);
      __data_start__ = .;
      
        *(.data)
        *(.data.*)
      
      . = ALIGN(4);
      __data_end__ = .;
    } > INT_SRAM

    RC_DATA_DEST                = __data_start__;
    RC_DATA_SIZE                = (__data_end__ - __data_start__);
    RC_DATA_SRC_END             = RC_DATA_SRC + RC_DATA_SIZE ;
    
    .bss                                            : 
    {
        . = ALIGN(4);
        __bss_start__ = .;
        
        *(.bss)
        *(.bss.*)
        
        . = ALIGN(4);
        __bss_end__ = .;
    } > INT_SRAM
    
    _bss_start = __bss_start__;
    _bss_end   = __bss_end__;
    
    .stack_main                         ALIGN(16)   : {} > INT_SRAM
  
    _Stack_end    = ADDR(.stack_main);
    _Stack_start  = ADDR(.stack_main) + STACK_SIZE; 
    
}
