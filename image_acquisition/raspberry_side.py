from socket import *
from time import ctime
import os
import sys
import time
import datetime

savePathStr ='/home/pi/LiveView/' # root folder
HOST = ''
PORT = 21567
BUFSIZ = 1024
ADDR = (HOST, PORT)
tcpSerSock = socket(AF_INET, SOCK_STREAM)
tcpSerSock.bind(ADDR)
tcpSerSock.listen(10)
ii = 0

def captureImages(index):
	ii = 0
	now = datetime.datetime.now()
	print now
	strBufDate = '%d%02d%02d' % (now.year,now.month,now.day) 
	print strBufDate
	os.system('sudo mkdir ' + savePathStr + strBufDate)
	strBufTime = '%02d' % (now.hour)
	
        strBufMin = '%02d' % (now.minute)
        
        strBufSec = '%02d' % (now.second)
  
        
	os.system('sudo mkdir ' + savePathStr + strBufDate +  '/' + strBufTime )

        fileNameOffset = (int(index[1])-1)*7
        filePath=int(index[2]) + fileNameOffset
        folderName = 'V0%02d' % filePath

	os.system('sudo mkdir ' + savePathStr + strBufDate +  '/' + strBufTime +'/' + folderName)
	fullSavePath = savePathStr + strBufDate +  '/' + strBufTime +'/' + folderName + '/' 

	while ii < 1:
                strBufTime = '%02d' % (now.hour)
	
                strBufMin = '%02d' % (now.minute)
                strBufSec = '%02d' % (now.second)
		strBuf = '%s_%s_%s%s%s.png' % (index,strBufDate,strBufTime,strBufMin,strBufSec)	
                print strBuf
		os.system('sudo raspistill -n -o '+fullSavePath + strBuf)
		ii+=1	 



# Main
while True:
	print 'waiting for connection...'
	tcpCliSock, addr = tcpSerSock.accept()
	print '...connected from:', addr

	while True:
		try:
			data = tcpCliSock.recv(BUFSIZ)
			if not data:
				break
			print data
		
			captureImages(data)
			
		except error, e:
			print 'error, %s' % e
			break
		tcpCliSock.send('[%s] %s' % (ctime(), 'captured'))
	tcpCliSock.close()
tcpSerSock.close()
