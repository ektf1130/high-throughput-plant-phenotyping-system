import cv2
import numpy as np
import imutils
import os
import math
import csv
import sys

path = './raw_data'  # Images source directory
newpath = './test_data/'                # Cropped images destination directory
#pts_dst = [[50, 50], [50, 930], [1810, 50], [1810, 930]]    # references point for image warping
tray_row = 8
tray_col = 4
pot_size=225
offset=0
pts_dst = [[0, 0], [0, pot_size*tray_col], [pot_size*tray_row, 0], [pot_size*tray_row, pot_size*tray_col]]    # references point for image warping


b1, g1, r1 = 255, 255, 200  # Color original value
b2, g2, r2 = 255, 255, 255  # Color value that we want to replace it with
pot_dist = []               # List of distance between pot
dict_src = {}

def detect_red_color(im):
    # Detecting red color by substracting red color only
    # Set Green and Blue value to 255 as shown on line 11
    data = np.array(im)
    red, green, blue = data[:, :, 2], data[:, :, 1], data[:, :, 0]
    mask = (red <= r1) & (green <= g1) & (blue <= b1)
    data[:, :, :3][mask] = [r2, g2, b2]
    gray = cv2.cvtColor(data, cv2.COLOR_BGR2GRAY)
    _, thresh = cv2.threshold(gray, 150, 255, cv2.THRESH_BINARY_INV)
    #cv2.imshow('thresh1', thresh)
    return thresh


def delete_small_cont():
    # Deleting small contour (area less than 150 pixels)
    im, contours, hier = cv2.findContours(thresh, cv2.RETR_TREE, cv2.CHAIN_APPROX_NONE)
    mask = np.ones(im.shape[:2], dtype='uint8') * 255

    for cnt in contours:
        area = cv2.contourArea(cnt)
        if area < 150:
            cv2.drawContours(mask, [cnt], -1, 0, -1)

    im = cv2.bitwise_and(im, im, mask=mask)
    #cv2.imshow('deleted small part1', mask)
    #cv2.imshow('small-big contour1', im)
    return im


def find_if_close(cnt1, cnt2):
    # Merging contour based on distance between contours
    row1, row2 = cnt1.shape[0], cnt2.shape[0]
    for i in xrange(row1):
        for j in xrange(row2):
            dist = np.linalg.norm(cnt1[i]-cnt2[j])
            if abs(dist) < 50:
                return True
            elif i == row1-1 and j == row2-1:
                return False


def merging_close_cont():
    im = delete_small_cont()
    # Merging close contour
    _, contours, hier = cv2.findContours(im, cv2.RETR_EXTERNAL, 2)
    length = len(contours)
    #print length
    if length < 4: # There is no 4 red dots available on the image
        return '0'
    else:
        status = np.zeros((length, 1))
        for i, cnt1 in enumerate(contours):
            x = i
            if i != length-1:
                for j, cnt2 in enumerate(contours[i+1:]):
                    x += 1
                    dist = find_if_close(cnt1, cnt2)
                    if dist is True:
                        val = min(status[i], status[x])
                        status[x] = status[i] = val
                    else:
                        if status[x] == status[i]:
                            status[x] = i+1

        unified = []
        maximum = int(status.max())+1
        for i in xrange(maximum):
            pos = np.where(status == i)[0]
            if pos.size != 0:
                cont = np.vstack(contours[i] for i in pos)
                hull = cv2.convexHull(cont)
                unified.append(hull)

        #cv2.drawContours(im,unified,-1,(0,255,0),2)
        #cv2.drawContours(thresh,unified,-1,255,-1)
        cv2.drawContours(im, unified, -1, 255, -1)

        #cv2.imshow('thresh2', thresh)
        #cv2.imshow('uni image', im)
        #cv2.imwrite('uni.png', im)
        return im


def find_cont():
    # Finding contours on merged contours binary image
    cnts = cv2.findContours(im.copy(), cv2.RETR_EXTERNAL, cv2.CHAIN_APPROX_SIMPLE)
    cnts = cnts[0] if imutils.is_cv2() else cnts[1]
    coor = []
    i = 1

    for c in cnts:
        # Computing the center of the contour
        M = cv2.moments(c)
        cX = int(M['m10'] / M['m00'])
        cY = int(M['m01'] / M['m00'])
        text = str(str(cX) + ',' + str(cY))

        # Drawing the contour and center of the shape on the image
        cv2.drawContours(ims, [c], -1, (0, 255, 0), 2)
        cv2.circle(ims, (cX, cY), 5, (255, 255, 255), -1)
        #cv2.putText(ims, str(i), (cX - 20, cY - 20), cv2.FONT_HERSHEY_SIMPLEX, 0.5, (255, 255, 255), 2)
        cv2.putText(ims, text, (cX - 20, cY - 20), cv2.FONT_HERSHEY_SIMPLEX, 0.5, (255, 255, 255), 2)

        coor.append([cX, cY])
        #print i
        i += 1
        #print coor
    return [ims, coor]


def sorting_cont(coor):
    # Labeling the 4 red dots as below:
    # top left = 1
    # bottom left = 2
    # top right = 3
    # bottom right = 4
    coor = sorted(coor, key=lambda coor: coor[0])
    src1 = coor[:2]
    src1 = sorted(src1, key=lambda src1: src1[1])
    src2 = coor[2:]
    src2 = sorted(src2, key=lambda src2: src2[1])
    src_coor = src1 + src2
    #print src_coor
    return src_coor


def calc_corner(src_coor):
    # calculating X and Y distance on each corner and returning the value as list
    xtop = (src_coor[2][0] - src_coor[0][0])/4
    xbot = (src_coor[3][0] - src_coor[1][0])/4
    yleft = (src_coor[1][1] - src_coor[0][1])/2
    yright = (src_coor[3][1] - src_coor[2][1])/2
    pot_dist.extend([xtop, xbot, yleft, yright])
    #print pot_dist
    return pot_dist


def src_adj(pot_dist, src_coor):
    # calculating the tray boundary on original image
    # x coordinate
    src_coor[0][0] = src_coor[0][0] - 2*pot_dist[0]
    src_coor[1][0] = src_coor[1][0] - 2*pot_dist[1]
    src_coor[2][0] = src_coor[2][0] + 2*pot_dist[0]
    src_coor[3][0] = src_coor[3][0] + 2*pot_dist[1]
    # y coordinate
    src_coor[0][1] = src_coor[0][1] - pot_dist[2]
    src_coor[1][1] = src_coor[1][1] + pot_dist[2]
    src_coor[2][1] = src_coor[2][1] - pot_dist[3]
    src_coor[3][1] = src_coor[3][1] + pot_dist[3]
    dict_src[trayno] = src_coor
    print src_coor
    print dict_src
    return src_coor


def warping(src_coor, pts_dst):
    # Warping the original image based on src_coor to pts_dst
    src_coor = np.array(src_coor)
    pts_dst = np.array(pts_dst)
    # Calculate Homography
    h, status = cv2.findHomography(src_coor, pts_dst)
    im_out = cv2.warpPerspective(imr, h, (imr.shape[1], imr.shape[0]))
    #cv2.imwrite('ori.png', imr)
    #cv2.imwrite('warped.png', im_out)
    return im_out


def crop(im_out, newpath):
    # Cropping the tray image and save each pot picture on destinantion directory
    #im_out = im_out[0:980, 0:1860]
    #im_out = im_out[0:900, 0:1800]
    np = 1
    if hourno in ['18']: #filtering by time
        for i in range(4):
            for j in range(8):
                cropped = im_out[i*pot_size:(i+1)*pot_size+offset, j*pot_size:(j+1)*pot_size+offset]
                #dire = str(newpath+'%s_Pot%02d/%s/' % (trayno, np,hourno))
                dire = str(newpath+'%s_Pot%02d/' % (trayno, np))
                
                if not os.path.exists(dire):
                    os.makedirs(dire)
                print dire
            
                #_,_,files=os.walk(dire).next()
                #file_count=len(files)
                name = str('Pot%02d_%s_%s.bmp' % (np, dateno,hourno))
                print name
                os.chdir(dire)
                cv2.imwrite(name, cropped)
                print 'pot%d cropped pic was successfully generated' %np
                np += 1


if os.path.isfile('src_pts.csv') == True:
    with open('src_pts.csv', 'rb') as csv_file:
        reader = csv.reader(csv_file)
        dict_src = dict(reader)
        print dict_src
        csf = 'tr'

else:
    print 'csv file is not available'
    csf = 'fls'
for dirs in os.listdir(path):
    print dirs

for (root, subdirs, files) in os.walk(path):

    for file in files:
        if file.endswith('.png'):
            trayno = root.split(os.path.sep)[-1]
            hourno = root.split(os.path.sep)[-2]
            dateno = root.split(os.path.sep)[-3]
            if int(trayno[2:]) % 7 == 0:
                index2 = 7
            else:
                index2 = int(trayno[2:]) % 7
            trayno = 'F' + str(int(math.ceil(float(trayno[2:]) / 7))) + str(index2)
            print trayno
            # print os.path.join(root, file)
            pic = os.path.join(root, file)
            print pic

            im = cv2.imread(pic)
            ims = cv2.imread(pic)
            imr = cv2.imread(pic)

            if trayno in dict_src:
                print 'red dot data from db is available'
                if csf == 'tr':
                    src_coor = eval(dict_src[trayno])
                elif csf == 'fls':
                    src_coor = dict_src[trayno]
                im_out = warping(src_coor, pts_dst)
                # cv2.imshow('warped', im_out)
                
                crop(im_out, newpath)
                # cv2.imwrite('warped.png', im_out)
                # cv2.imshow('red dot coordinate', ims)
                # cv2.waitKey()
                print 'one pot succeeded'

            else:
                print 'red dot data from db is not available'
                im_hsv = cv2.cvtColor(im, cv2.COLOR_BGR2HSV)

                thresh = detect_red_color(im)
                im = merging_close_cont()
                if im == '0':
                    print 'contours are not found'
                else:
                    ims, coor = find_cont()
                    if len(coor) != 4:
                        print 'contours are not 4'
                    else:
                        src_coor = sorting_cont(coor)
                        calc_corner(src_coor)
                        src_coor = src_adj(pot_dist, src_coor)
                        im_out = warping(src_coor, pts_dst)
                        #cv2.imshow('warped', im_out)
                        crop(im_out, newpath)
                        #cv2.imwrite('warped.png', im_out)
                        #cv2.imshow('red dot coordinate', ims)
                        #cv2.waitKey()
                        print 'tray %s was successfully proceeded' %trayno

print dict_src
with open('./src_pts.csv', 'wb') as csv_file:
    writer = csv.writer(csv_file)
    for key, value in dict_src.items():
       writer.writerow([key, value])
print 'FINISH'