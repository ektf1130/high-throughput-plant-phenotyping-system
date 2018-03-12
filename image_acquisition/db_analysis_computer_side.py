import serial
from socket import *
import time
import os

HOST1='192.168.0.10' # raspberry pi's IP address 
#HOST2='192.168.0.11' #for multiple cameras
PORT=21567
BUFSIZE=1024
ser=serial.Serial('/dev/ttyUSB0',19200) #connection between PLC and db_analysis_computer via RS232 to USB cable
ser.isOpen()
SUCCESS='captured'
ERROR='error'
sync_cmd='sudo bash sync.sh'
out = ''
cnt=0

# downloading images from a raspberry pi to db_analysis_computer
def sync_images():
    print sync_cmd
    os.system(sync_cmd)

# sending a signal to the raspberry pi for capturing
def sendMsg(HOST,PORT,TRAY_ID):
    ADDR=(HOST,PORT)
    tcpClientSock=socket(AF_INET, SOCK_STREAM)
    tcpClientSock.connect(ADDR)
    tcpClientSock.send(TRAY_ID)
    print 'SENT'
    data=''
    data=tcpClientSock.recv(BUFSIZE)
    
    if data!='':
        ret=data.split(']')[-1]
        ret=ret.split(' ')[-1]
        
    else:
        print 'error'
    tcpClientSock.shutdown(SHUT_RDWR)
    tcpClientSock.close()

    return ret    


# Main
print 'RUN XYZ DATA'
print '*' * 50

while True:
        

        while ser.inWaiting() > 0:
            out += ser.read(1)

        if out != '' and len(out)==4:

            print len(out)
            if out[:3] in 'F00':
                print 'in'
                out=''
                cnt=0
                continue

            print ">>" + out[:3]


            ret=sendMsg(HOST1,PORT,out[:3])

            if ret==SUCCESS:
                print HOST1, 'OK'
                out=''
                cnt+=1
                print 'Current: ', cnt, ' images'
                
                # for multiple cameras
                ''' 
                ret2=sendMsg(HOST2,PORT,out[:3])
                if ret2==SUCCESS:
                    print HOST2, 'OK'
                    out=''
                    cnt+=1
                    print 'Current: ', cnt, ' images'
                else:
                    print HOST2,'re-try'
                '''
            else:
                print HOST1,'re-try'

        if cnt==28:
            print 'image downlading...'
            print '*' * 50
            out=''
            cnt=0
            sync_images()
