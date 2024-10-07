import os, time
import sys
import base64
import t32_wrapper_func as t32lib
try:
    from Crypto.Cipher import AES
    from Crypto.Hash import SHA256
except ModuleNotFoundError as error:
    print(error.__class__.__name__ + ': ' + error.msg)
    print('Use "python -m pip install pycryptodome" to install the dependency.')
    exit(1)

#To Run python debug_App_ADKP.py -PASS/-CHL_RSP

#Convert 32-bit value from big endian to little endian
def be2le32(value):
    mod_value = value[6:8]+value[4:6]+value[2:4]+value[:2]
    return mod_value

def deriveAdkp(ADKP):
    # Computing UID
    t32lib.execute_cmm("S32_SDAP_READ_UID.cmm")
    config_file2 = open("uid.txt", "r")
    contents2 = config_file2.readlines()
    contList = contents2[0].split(": ")
    uid = ""
    for item in range(0,len(contList)-1):
        data = (contList[item][2:])
        data = data.zfill(8)
        nwItem = be2le32(data)
        uid = uid+nwItem
    print("UID: ")
    print(uid)
      
    hash_object = SHA256.new(data=bytearray.fromhex(uid))
    huid = hash_object.hexdigest().upper()
    print("HUID: ")
    print(huid)

    hash_object = SHA256.new(data=bytearray.fromhex(ADKP))
    adkpm = hash_object.hexdigest().upper()
    print("ADKPM: ")
    print(adkpm)
    
    print("HUID (16Bytes): ")
    huid_16 = huid[:32].upper()
    print(huid_16)

    # Computing Response
    cipher = AES.new(bytearray.fromhex(adkpm), AES.MODE_ECB)
    dAdkp = cipher.encrypt(bytearray.fromhex(huid_16)).hex().upper()
    print("Derived Adkp: ")
    print(dAdkp)

    return dAdkp

def ChallengeResponse_Application_core(ADKP, ADKPM):
    print("Executing Challenge/Response Scheme\n")
    print("Reading Challenge from Trace32...")
    t32lib.execute_cmm("S32_SDAP_READ.cmm")
    config_file2 = open("challenge.txt", "r")
    contents2 = config_file2.readlines()
    contList = contents2[0].split(": ")
    challenge = ""
    for item in range(0,len(contList)-1):
        data = (contList[item][2:])
        data = data.zfill(8)
        nwItem = be2le32(data)
        challenge = challenge+nwItem
    print("Challenge: ")
    print(challenge)

    if (ADKPM.startswith("-MSTR_DEB_KEY")):
        # Computing Response
        cipher = AES.new(bytearray.fromhex(ADKP), AES.MODE_ECB)
        response = cipher.encrypt(bytearray.fromhex(challenge)).hex().upper()
        print("Response: ")
        print(response)
        return response
        
    else :
        dAdkp_16 = deriveAdkp(ADKP)

        # Computing Response
        cipher = AES.new(bytearray.fromhex(dAdkp_16), AES.MODE_ECB)
        response = cipher.encrypt(bytearray.fromhex(challenge)).hex().upper()
        print("Response: ")
        print(response)
        return response

def ReadADKP():
    adkp_value = ""
    config_file = open("adkp_key_input.txt", "r")
    contents = config_file.readlines()

    for line in range(0, len(contents)):
        #if (contents[line].startswith("0x")):
        adkp_value = contents[line].split(" = ")[-1].strip("\n")[2:]

    print("adkp_value: " + str(adkp_value))
    return adkp_value
    
def Usage():    
    print("Usage: debug_App_ADKP.py -PASS/-CHL_RSP -MSTR_DEB_KEY/-DER_DEB_KEY")
    print("-PASS: Open Application Core Debugger using Password Scheme ")
    print("-CHL_RSP: Open Application Core Debugger using Challenge-Response Scheme & DEBUG_AUTH flag is enabled")
    print("-MSTR_DEB_KEY: Debugger supports Debug Authorization via Master Debug Key")
    print("-DER_DEB_KEY: Debugger supports Debug Authorization via Derived Debug Key")
    
if __name__ == "__main__":
    
    if len(sys.argv) != 3:
        Usage()
        exit(1)

    err = t32lib.init_t32_debugger()
    if err == -1:
        print("Cannot Establish connection with debugger")  
        exit(1)
    
    dir_path = os.path.dirname(os.path.realpath(__file__))
    t32lib.execute_cmd("CD "+dir_path)

    ADKP = ReadADKP()
    r2List = []
    if (sys.argv[1].startswith("-CHL_RSP")):
        r2 = ChallengeResponse_Application_core(ADKP,sys.argv[2])
    elif(sys.argv[1].startswith("-PASS")):
        print("Executing PASSWORD Scheme\n")
        if (sys.argv[2].startswith("-MSTR_DEB_KEY")):
            r2 = str(ADKP)
            print("PASSWORD: "+r2)
        else:
            dAdkp_16 = deriveAdkp(ADKP)
            r2 = str(dAdkp_16)
            print("PASSWORD: "+r2)            
    else:
        Usage()
        exit(1)
        
    count = 0
    while count < len(r2):
        r2Data = r2[count:(count+8)]
        count += 8
        r2List.append("0x"+be2le32(r2Data))
    
    if(sys.argv[1].startswith("-PASS")):
        r2List.append("0x00000000")
        r2List.append("0x00000000")
        r2List.append("0x00000000")
        r2List.append("0x00000000")

    print("Sending PASSWORD/RESPONSE to Device....")
    print("Response List: ")
    print(r2List)
    t32lib.execute_cmm(str("S32_SDAP_WRITE.cmm " + r2List[0]+" " + r2List[1] + " " +r2List[2] + " " +r2List[3] + " " +r2List[4] + " " +r2List[5] + " " +r2List[6] + " " +r2List[7]))
    print("RESPOSE Sent. Should be able to connect the Debugger....")
    print("Attaching Trace32 to Device..")
    t32lib.execute_cmm("attach_core_m7_0.cmm")
    exit(0)
