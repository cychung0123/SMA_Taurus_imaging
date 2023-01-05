config="com"
flagval="f"

targets='CW_Tau  04113+2758  CY_Tau  V892_Tau  BP_Tau  RY_Tau  FT_Tau  IQ_Tau  UZ_Tau  DL_Tau  AA_Tau  LkCa_15  CI_Tau  T_Tau  UX_Tau  V710_Tau  DM_Tau  DQ_Tau  Haro_6-37  DR_Tau  DN_Tau  DO_Tau  IC_2087_IR  GO_Tau  GM_Aur  AB_Aur'
tracks='track4 track5 track6'
sidebands='lsb usb'
rxs='rx345 rx400'
rms=0.0015

#rm -rf *.txt
#rm -rf *.rx*
#rm -rf ch0
#mkdir ch0

for track in $tracks
do
  rm -rf axis_FWHM_$track.sel.txt
  rm -rf center_$track.sel.txt
  rm -rf flux_$track.sel.txt
  rm -rf SNR_$track.sel.txt
 
  for rx in $rxs
  do
      for sideband in $sidebands
      do

	for target in $targets
	do
	  
	  imdir='./ch0/'$track'/'
	  cleanim=$target'.'$track'.'$rx'.'$sideband'.clean.fits'
#	  cp -r $imdir$cleanim ./
	  
          output=$(python flux_measure.sel.py  $rx  $sideband  $target $track '107, 108, 147, 148' $rms)
          IFS='   ' read -r -a array <<< "$output"
	  echo "The peak flux of clean map is ${array[0]} mJy/beam"
          echo "The fitted 2D Gaussian component has major and minor FWHM ${array[1]} arcsec and ${array[2]} arcsec"
          echo "The integrated flux density is ${array[3]} mJy"

#	  rm *.clean.fits 
#	  cp *.txt ./ch0/$track/
        done
      done
  done
done

