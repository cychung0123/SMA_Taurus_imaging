config="com"
flagval="f"

targets='FM_Tau  CW_Tau  04113+2758  CY_Tau  DD_Tau  V892_Tau  BP_Tau  CoKu_Tau_1  RY_Tau  DE_Tau  IP_Tau  FT_Tau  FV_Tau  DH_Tau  IQ_Tau  DK_Tau  UZ_Tau  DL_Tau  GK_Tau  AA_Tau  LkCa_15  CI_Tau  04278+2253  T_Tau  UX_Tau  V710_Tau  DM_Tau  DQ_Tau  Haro_6-37  DR_Tau  FY_Tau  HO_Tau  DN_Tau  DO_Tau  HV_Tau  IC_2087_IR  CIDA-7  GO_Tau  DS_Tau  UY_Aur  Haro_6-39  GM_Aur  AB_Aur  SU_Aur  RW_Aur  CIDA-9  V836_Tau'
tracks='track3'
sidebands='lsb usb'
rxs='rx240 rx345'
rms=0.0015

#rm -rf *.txt
#rm -rf *.rx*
#rm -rf ch0
#mkdir ch0

for track in $tracks
do
  rm -rf axis_FWHM_$track.txt
  rm -rf center_$track.txt
  rm -rf flux_$track.txt
  rm -rf SNR_$track.txt
 
  for rx in $rxs
  do
      for sideband in $sidebands
      do

	for target in $targets
	do
	  
	  imdir='./ch0/'$track'/'
	  cleanim=$target'.'$track'.'$rx'.'$sideband'.clean.fits'
	  cp -r $imdir$cleanim ./
	  
          output=$(python flux_measure.py  $rx  $sideband  $target $track '107, 108, 147, 148' $rms)
          IFS='   ' read -r -a array <<< "$output"
	  echo "The peak flux of clean map is ${array[0]} mJy/beam"
          echo "The fitted 2D Gaussian component has major and minor FWHM ${array[1]} arcsec and ${array[2]} arcsec"
          echo "The integrated flux density is ${array[3]} mJy"

	  rm *.clean.fits 
	  cp *.txt ./ch0/$track/
        done
      done
  done
done

