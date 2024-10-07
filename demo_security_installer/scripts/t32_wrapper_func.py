import ctypes
from ctypes import *
import enum
import os
import time
import sys

###### debugger #####
dll_name    = "t32api64.dll"
dllabspath  = os.environ.get('T32_DIR')+"\\demo\\api\\capi\\dll\\"+dll_name
t32api      = ctypes.cdll.LoadLibrary(dllabspath)


def debugger_init():
    error = t32api.T32_Config(b"NODE=",b"localhost")
    error = t32api.T32_Config(b"PORT=",b"20000")
    error = t32api.T32_Config(b"PACKLEN=",b"1024")

    error = t32api.T32_Init()
    error = t32api.T32_Attach(1)
    error = t32api.T32_Ping()

   # print "debug1"

    if error != 0:
        global error_check
        error_check = 1
        return -1
    return 0

def read_area_window():
    message=c_char * 256
    mode=c_uint16()
    mess=message()
    t32api.T32_GetMessage(byref(mess),byref(mode))
    return (str(mess.value),int(mode.value))

def mem_read(address, size):
    access = c_uint()
    access = 0x00
    content = c_uint()
    t32api.T32_ReadMemory(address, access, byref(content), size)

    var_value = int(content.value)
    var_value = hex(var_value).rstrip('L')
    return var_value

def mem_write(address,value,size):
    variable = c_uint()
    access = c_uint()
    access = 0x08
    value = value[value.find('x')+1:]
    var = c_uint8*4
    var = var(int(value[6:8],16),int(value[4:6],16),int(value[2:4],16),int(value[0:2],16))
    ret = t32api.T32_WriteMemory(address,access,byref(var),size)
    return ret

def close():
    t32api.T32_Cmd("QUIT")

def reset():
    t32api.T32_Cmd("sys.RESETTARGET")

def t32_break():
    t32api.T32_Cmd("break")

def terminate():
    t32api.T32_Terminate()

def exit_dbg():
    t32api.T32_Exit()
###############################


class PracticeInterpreterState(enum.IntEnum):
    UNKNOWN = -1
    NOT_RUNNING = 0
    RUNNING = 1
    DIALOG_OPEN = 2
class MessageLineState(enum.IntEnum):
    ERROR = 2
    ERROR_INFO = 16

def init_sysjtag():
    ret = t32api.T32_Ping()
    if ret == 0:
        t32api.T32_Cmd(b"System.reset")
        execute_cmm("attach_core_m7_0.cmm")
        #t32api.T32_cmd(b'GLOBALON ERROR CONTinue')
        #t32api.T32_Cmd(b"System.mode.Prepare")
        #t32api.T32_Cmd(b"D.S edbg:0x40000780 %Long 0xfffffff0")
        t32api.T32_Stop()
        #t32api.T32_Cmd(b'AREA.clear')
        time.sleep(1)
        '''
        msg,val = read_area_window()
        if val == 2 or val == 16:
            return -1
        else:
            return 0
            '''
        return 0
    else:
        return -1

def close_t32():
    t32api.T32_Break()
    t32api.T32_Stop()
    t32api.T32_ResetCPU()
    t32api.T32_Cmd("system.reset")
    time.sleep(0.5)
    close()
    terminate()


def init_t32_debugger():
    try:

        ret = debugger_init()
        if ret == -1:
            exit_dbg()
            print("coming to debugger_init")
            ret = debugger_init()
            if ret == -1:
                return -1
        print("completed debugger_init")
        try:
            ret = init_sysjtag()
            if ret == -1:
                return -1
        except Exception as err:
            print(str(err))
            return -1
    except Exception:
        return -1
    return 0

def execute_cmm(cmm_filename):
    t32api.T32_Cmd(b"AREA.CLEAR")
    # Execute .cmm
    message = ("CD.DO "+cmm_filename).encode('utf-8')
    ret = t32api.T32_Cmd(message)
    if ret < 0:
        return ret
    # Wait for script to finish
    state = c_int(PracticeInterpreterState.UNKNOWN)
    rc = 0
    while rc==0 and not state.value==PracticeInterpreterState.NOT_RUNNING:
        rc = t32api.T32_GetPracticeState(byref(state))
        time.sleep(0.1)

    retmsg,retval = read_area_window()
    
    # Get confirmation that everything worked
    eval = c_uint16(-1)
    rc = t32api.T32_EvalGet(byref(eval))
    '''
    if rc == 0 and eval.value == 0:
        if retval == 2 or retval == 16:
            return ECMM
        return 0
   '''
    return eval.value

def attach_debugger():
    state = c_int(-1)
    while int(state.value) != 3:
        ret = t32api.T32_Cmd("SYStem.Attach")
        ret = t32api.T32_GetState(byref(state))
    return 0

def execute_cmd(message):
    t32api.T32_Cmd(b"AREA.CLEAR")
    ret = t32api.T32_Cmd(message)
    # Wait for script to finish
    state = c_int(PracticeInterpreterState.UNKNOWN)
    rc = 0
    while rc==0 and not state.value==PracticeInterpreterState.NOT_RUNNING:
        rc = t32api.T32_GetPracticeState(byref(state))
        #time.sleep(0.1)
    
    #retmsg,retval = read_area_window()
    '''
    if retval == 2 or retval == 16:
        ret = EINVAL
    '''
    return ret

def read_cpu_reg(data):
    vname = data
    value = c_int32(0)
    hvalue = c_int32(0)
    ret = t32api.T32_ReadRegisterByName(vname, byref(value), byref(hvalue))
    return value

def read_per_reg(data):
    buff = [0]*60
    buf = (c_uint32 * len(buff))(*buff)
    mask1 = c_int32(data)
    mask2 = c_int32(0)
    ret = t32api.T32_ReadRegister(mask1, mask2, buf)
    return ret


def get_symbol_addr(data):
    vname = data.encode('utf-8')
    vaddr = c_int32(0)
    vsize = c_int32(0)
    vaccess = c_int32(0)
    ret = t32api.T32_GetSymbol(vname,byref(vaddr),byref(vsize),byref(vaccess))
    return vaddr.value,vsize.value

def get_pc_value():
    pcval = c_uint32(-1)
    ret=t32api.T32_ReadPP(byref(pcval))
    if ret<0:
        return EINVAL
    return pcval.value
