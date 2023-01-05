from astropy.io import ascii
import numpy as np
import matplotlib.pyplot as plt
import matplotlib.cm as cm
import math

def SED_fit(freq, flux, idx):
    freq_log = []
    flux_log = []
    for k in range(len(flux)):
        freq_t = freq[k][idx]
        flux_t = flux[k][idx].ravel()
        zero_idx=np.where(flux_t<0)[0]
        freq_t = np.delete(freq_t,zero_idx)
        flux_t = np.delete(flux_t,zero_idx)
        freq_log.extend(np.log(freq_t).tolist())
        flux_log.extend(np.log(flux_t).tolist())

    z, cov = np.polyfit(freq_log, flux_log, 1, cov=True)
    p = np.poly1d(z)
    xp = np.linspace(np.log(freq[0][idx][0]), np.log(freq[-1][idx][-1]), 10)
    ax.plot(np.exp(xp), np.exp(p(xp)),'-', color='grey')
    return round(z[0],2)

tracks = ['track1','track2','track3','track4','track5','track6']
colors = cm.jet([0.2, 0.3, 0.5, 0.7, 0.8, 0.95])
freq1 = [199, 219, 228, 248]
freq2 = [260, 280, 292, 312]
freq3 = [337, 357, 397.5, 417.5]
freq = []
flux = []
rms = []
flux_sel = []
rms_sel = []
selcal_target = ['04113+2758','CY_Tau','V892_Tau','RY_Tau','FT_Tau','UZ_Tau','DL_Tau','LkCa_15','CI_Tau','T_Tau','DR_Tau','DO_Tau','IC_2087_IR','GM_Aur','AB_Aur']

target = []
spidx = []
table = ascii.read('datafile1.txt')

filename='flux_'+tracks[0]+'.sel.txt'
file = open(filename, 'r')
lines = file.readlines()
for i in range(len(lines)):
    if lines[i].split()[0] in selcal_target:
        name=""
        for j in range(len(lines[i].split()[0].split('_'))):
            name = name + ' ' + lines[i].split()[0].split('_')[j]
        target.append(name[1:])
        idx=np.where(table['Name'] == name[1:])[0]
        if len(idx) != 0:
            spidx.append(table['Sp+Index'][idx][0])
        else:
            spidx.append(np.nan)


for track in tracks:
    filename='flux_'+track+'.sel.txt'
    file = open(filename, 'r')
    lines = file.readlines()
    temp = []
    tempf = []
    a = 0
    for i in range(len(lines)):
        if lines[i].split()[0] in selcal_target:
            a = 1
            temp.append(lines[i].split()[1:])
            if track =='track1' or track == 'track2':
                tempf.append(freq1)
            elif track == 'track3':
                tempf.append(freq2)
            else:
                tempf.append(freq3)
    if a == 1:
        flux.append(temp)
        freq.append(tempf)

for track in tracks:
    filename='rms_'+track+'.sel.txt'
    file = open(filename, 'r')
    lines = file.readlines()
    temp = []
    a = 0
    for i in range(len(lines)):
        if lines[i].split()[0] in selcal_target:
            a = 1
            temp.append(lines[i].split()[1:])
    if a == 1:
        rms.append(temp)


flux=np.array(flux).astype(float)
flux=np.where(flux==0.0,-100,flux)
rms=np.array(rms).astype(float)*1000


def get_idx(target, flux_0, rank):
    # index [:,0] for 345 GHz lsb
    flux_0_s = sorted(flux_0[:,0], reverse = True)
    idx_l= list(np.where(flux_0[:,0]==flux_0_s[rank])[0])
    return idx_l

num = 6
num_sel = 3
num_figure= int((len(target))/num)

times = 1
for i in range(num_figure):
    fig = plt.figure(figsize=(15, 12))
    for j in range(num):
        ax = fig.add_subplot(321+j)
        rank = num*i+j
        idx_l = get_idx(target, flux[tracks.index('track5')], rank)
        if len(idx_l) > times:
            idx = idx_l[times-1]
            times += 1
        elif len(idx_l) == times and times > 1:
            idx = idx_l[times-1]
            times = 1
        else:
            idx = idx_l[0]
            times = 1
        if_zero = 0
        flux_max = 0
        for k in range(len(flux)):
            ax.errorbar(freq[k][idx][0:4], flux[k][idx][0:4], yerr=rms[k][idx][0:4], fmt='o', color=colors[k])
            if_zero+=flux[k][idx].tolist().count(0.0)
            flux_max = max(flux_max, max(flux[k][idx]))

        plt.ylim([0, flux_max*1.25])
        plt.legend(tracks)
        if (j%2==1):
            plt.ylabel('Flux density [mJy]', size=14)
        if (j==4 or j==5):
            plt.xlabel('Frequency [GHz]', size=14) 
        if (if_zero>0):
            ax.title.set_text(target[idx])
        else:
            alpha = SED_fit(freq, flux, idx)
            ax.title.set_text(target[idx]+', \u03B1='+str(alpha)+', ['+str(spidx[idx])+']')

    fig.tight_layout()
    plt.savefig('flux_measurement_'+str(i)+'.pdf', format='PDF', transparent=True)
    plt.close(fig) 

i = num_figure
fig = plt.figure(figsize=(15, 12))
for j in range(len(target)%num):
        ax = fig.add_subplot(321+j)
        rank = num*i+j
        idx_l = get_idx(target, flux[tracks.index('track5')], rank)
        if len(idx_l) > times:
            idx = idx_l[times-1]
            times += 1
        elif len(idx_l) == times and times > 1:
            idx = idx_l[times-1]
            times = 1
        else:
            idx = idx_l[0]
            times = 1
        if_zero = 0
        flux_max = 0
        for k in range(len(flux)):
            ax.errorbar(freq[k][idx][0:4], flux[k][idx][0:4], yerr=rms[k][idx][0:4], fmt='o', color=colors[k])
            if_zero+=flux[k][idx].tolist().count(0.0)
            flux_max = max(flux_max, max(flux[k][idx]))

        plt.ylim([0, flux_max*1.25])
        plt.legend(tracks)
        if (j%2==1):
            plt.ylabel('Flux density [mJy]', size=14)
        if (j==4 or j==5):
            plt.xlabel('Frequency [GHz]', size=14)
        if (if_zero>0):
            ax.title.set_text(target[idx])
        else:
            alpha = SED_fit(freq, flux, idx)
            ax.title.set_text(target[idx]+', \u03B1='+str(alpha)+', ['+str(spidx[idx])+']')

fig.tight_layout()
plt.savefig('flux_measurement_'+str(i)+'.pdf', format='PDF', transparent=True)
plt.close(fig)




