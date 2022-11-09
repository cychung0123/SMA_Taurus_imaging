import numpy as np
from astropy.io import fits
from astropy.wcs import WCS
import matplotlib.pyplot as plt
from astropy.coordinates import SkyCoord
import math
from astropy.nddata import Cutout2D
from matplotlib.patches import Ellipse
from astropy import units as u
from astropy.visualization.wcsaxes import SphericalCircle


targets = ['FM_Tau', 'CW_Tau', '04113+2758', 'CY_Tau', 'DD_Tau', 'V892_Tau', 'BP_Tau', 'CoKu_Tau_1', 'RY_Tau', 'DE_Tau', 'IP_Tau', 'FT_Tau', 'FV_Tau', 'DH_Tau', 'IQ_Tau', 'DK_Tau', 'UZ_Tau', 'DL_Tau', 'GK_Tau', 'AA_Tau', 'LkCa_15', 'CI_Tau', '04278+2253', 'T_Tau', 'UX_Tau', 'V710_Tau', 'DM_Tau', 'DQ_Tau', 'Haro_6-37', 'DR_Tau', 'FY_Tau', 'HO_Tau', 'DN_Tau', 'DO_Tau', 'HV_Tau', 'IC_2087_IR', 'GO_Tau', 'CIDA-7', 'DS_Tau', 'UY_Aur', 'Haro_6-39', 'GM_Aur', 'AB_Aur', 'SU_Aur', 'RW_Aur', 'CIDA-9', 'V836_Tau']


tracks = ['track4', 'track5', 'track6']
rxs = ['rx345', 'rx400']
sidebands = ['lsb', 'usb']



for rx in rxs:
  for sideband in sidebands:

    boxes = []
    target = []
    filename='box.txt'

    file = open(filename, 'r')
    lines = file.readlines()
    for i in range(len(lines)):
        target.append(lines[i].split()[0])
        k = (rxs.index(rx)*2 + sidebands.index(sideband))*4
        boxes.append(eval(lines[i].split()[k+1]+lines[i].split()[k+2]+lines[i].split()[k+3]+lines[i].split()[k+4]))


    fig = plt.figure(figsize=(20, 15))
    for i in range(len(targets)):
        filename=targets[i]+'.'+rx+'.'+sideband+'.clean.fits'
        if_success = False
        try:
            hdul = fits.open(filename)
            hdul.info() 
            hdu = hdul[0]   
            data = hdu.data[0][0]   
            if_success = True
            box = boxes[target.index(targets[i])]
        except:
            print('Unable to read the intensity FITS image. Please double check the image file.')

        if (if_success == True ):
            try:
                wcs = WCS(hdu.header)   
                wcs = wcs.dropaxis(dropax=2)
                wcs = wcs.dropaxis(dropax=2)

                naxis1 = hdu.header['naxis1']
                naxis2 = hdu.header['naxis2']
                crval1 = hdu.header['crval1']
                crpix1 = hdu.header['crpix1']
                cdelt1 = hdu.header['cdelt1']
                crval2 = hdu.header['crval2']
                crpix2 = hdu.header['crpix2']
                cdelt2 = hdu.header['cdelt2']

                bmaj = hdu.header['bmaj']
                bmin = hdu.header['bmin']
                bpa  = hdu.header['bpa']
            except:
                print( 'Warning. No coordinate headers' )

            ax = plt.subplot2grid((6, 8),(math.floor(i/8), i%8), projection=wcs)
            ax.set_xlabel(' ', fontsize='small')
            ax.set_ylabel(' ', fontsize='small')
            ax.tick_params(axis='x', which='both', labelbottom=False) 
            ax.tick_params(axis='y', which='both', labelbottom=False) 

#           max_x, max_y = np.unravel_index(np.argmax(data, axis=None), data.shape)
#           world = wcs.wcs_pix2world([ [max_x, max_y] ], 0)
#           ra_center  = world[0][0]
#           dec_center = world[0][1]
    
#           center =  SkyCoord(ra_center, dec_center, unit='deg', frame='icrs')
#           size = u.Quantity((10, 10), u.arcsec)
#           cutout = Cutout2D(data, center, size, wcs=wcs)

            cutdata = data[box[0]:box[2] , box[1]:box[3]]
        
            vmax = np.nanmax(data)*1.2
            vmin = 0.0
            ax.imshow(cutdata, origin='lower', vmax = vmax, vmin = vmin) 
#           target = targets[i].split("_")[0]+' '+targets[i].split("_")[1]
            ax.text(cutdata.shape[0]*5/10, cutdata.shape[1]*8.5/10, targets[i], fontsize=11, color='white')
            beam = Ellipse((cutdata.shape[0]/5, cutdata.shape[1]/5), height = bmaj/abs(cdelt1), width = bmin/abs(cdelt2), angle = bpa, facecolor = "None", edgecolor='white', lw=1) 
            ax.add_patch(beam)


    fig.tight_layout() 
    plt.savefig(rx+'.'+sideband+'_poststamp.pdf', format='PDF', transparent=True)
    plt.savefig(rx+'.'+sideband+'_poststamp.png', transparent=True)
    plt.close(fig)


