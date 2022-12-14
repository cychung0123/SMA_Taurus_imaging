config="com"
flagval="f"

targets='FM_Tau  CW_Tau  04113+2758  CY_Tau  DD_Tau  V892_Tau  BP_Tau  CoKu_Tau_1  RY_Tau  DE_Tau  IP_Tau  FT_Tau  FV_Tau  DH_Tau  IQ_Tau  DK_Tau  UZ_Tau  DL_Tau  GK_Tau  AA_Tau  LkCa_15  CI_Tau  04278+2253  T_Tau  UX_Tau  V710_Tau  DM_Tau  DQ_Tau  Haro_6-37  DR_Tau  FY_Tau  HO_Tau  DN_Tau  DO_Tau  HV_Tau  IC_2087_IR  CIDA-7  GO_Tau  DS_Tau  UY_Aur  Haro_6-39  GM_Aur  AB_Aur  SU_Aur  RW_Aur  CIDA-9  V836_Tau'
tracks='track12'
sidebands='lsb usb'
rxs='rx230 rx240'
trks='track1 track2'

#rm -rf *.txt
#rm -rf *.rx*
#rm -rf ch0
#mkdir ch0

cd ch0/
rm -rf $tracks
mkdir $tracks
cd ../
  
for rx in $rxs
do
      for sideband in $sidebands
      do
	for target in $targets
	do
	  for track in $trks
	  do
	  	datadir='../calibrated_Miriad/'$track'/'
		vis=$target'_'$track'.'$rx'.'$sideband'.cal.miriad'
		cp -r $datadir$vis ./
		uvflag vis=$target'_'$track'.'$rx'.'$sideband'.cal.miriad' edge=64,64,0 flagval=$flagval
	  done
	  
          uvaver vis=$target'_track1.'$rx'.'$sideband'.cal.miriad,'$target'_track2.'$rx'.'$sideband'.cal.miriad' options=nocal,nopass,nopol out=$target'_track12.'$rx'.'$sideband'.cal.miriad'
#          fi

          if [ $target = 'V892_Tau' ]
          then
                rm -rf $target'_track12.'$rx'.'$sideband'.cal.miriad'
                uvaver vis=$target'_track1.'$rx'.'$sideband'.cal.miriad' options=nocal,nopass,nopol out=$target'_track12.'$rx'.'$sideband'.cal.miriad'
          fi


          vis=$target'_track12.'$rx'.'$sideband'.cal.miriad'

	  rm -rf $target'.'$tracks'.'$rx'.'$sideband'.dirty'
	  rm -rf $target'.'$tracks'.'$rx'.'$sideband'.beam'
	  invert vis=$vis options=systemp,mfs,double robust=2.0 map=$target'.'$tracks'.'$rx'.'$sideband'.dirty' beam=$target'.'$tracks'.'$rx'.'$sideband'.beam' cell=0.25 imsize=256
	  rm -rf $target'.'$tracks'.'$rx'.'$sideband'.dirty.fits'
	  rm -rf $target'.'$tracks'.'$rx'.'$sideband'.beam.fits'
	  fits in=$target'.'$tracks'.'$rx'.'$sideband'.dirty' op=xyout out=$target'.'$tracks'.'$rx'.'$sideband'.dirty.fits'
	  fits in=$target'.'$tracks'.'$rx'.'$sideband'.beam' op=xyout out=$target'.'$tracks'.'$rx'.'$sideband'.beam.fits'
	  

          # deconvolve image
	  rm -rf $target'.'$tracks'.'$rx'.'$sideband'.10.model'
	  rm -rf $target'.'$tracks'.'$rx'.'$sideband'.10.model.fits'
	  clean map=$target'.'$tracks'.'$rx'.'$sideband'.dirty' beam=$target'.'$tracks'.'$rx'.'$sideband'.beam' out=$target'.'$tracks'.'$rx'.'$sideband'.10.model' cutoff=0.001 niters=10
	  fits in=$target'.'$tracks'.'$rx'.'$sideband'.10.model' op=xyout out=$target'.'$tracks'.'$rx'.'$sideband'.10.model.fits'

	  rm -rf $target'.'$tracks'.'$rx'.'$sideband'.clean'
          rm -rf $target'.'$tracks'.'$rx'.'$sideband'.clean.fits'
          restor map=$target'.'$tracks'.'$rx'.'$sideband'.dirty' beam=$target'.'$tracks'.'$rx'.'$sideband'.beam' model=$target'.'$tracks'.'$rx'.'$sideband'.10.model' mode=clean out=$target'.'$tracks'.'$rx'.'$sideband'.clean'
          fits in=$target'.'$tracks'.'$rx'.'$sideband'.clean' op=xyout out=$target'.'$tracks'.'$rx'.'$sideband'.clean.fits'

	  rm -rf $target'.'$tracks'.'$rx'.'$sideband'.residual'
          rm -rf $target'.'$tracks'.'$rx'.'$sideband'.residual.fits'
          restor map=$target'.'$tracks'.'$rx'.'$sideband'.dirty' beam=$target'.'$tracks'.'$rx'.'$sideband'.beam' model=$target'.'$tracks'.'$rx'.'$sideband'.10.model' mode=residual out=$target'.'$tracks'.'$rx'.'$sideband'.residual'
          fits in=$target'.'$tracks'.'$rx'.'$sideband'.residual' op=xyout out=$target'.'$tracks'.'$rx'.'$sideband'.residual.fits'
	  
	  
	  output=$(python get_rms.py  $rx  $sideband  $target $tracks)
	  IFS='   ' read -r -a array <<< "$output"
	  rms=${array[0]}
	  cut=$(bc -l <<< "${array[0]}*1.5")
	  echo "The obtained rms for $target is ${array[0]} Jy/beam"
	  box=${array[1]}','${array[2]}','${array[3]}','${array[4]}
	  echo 'boxes('${array[1]}','${array[2]}','${array[3]}','${array[4]}')'

	  rm -rf $target'.'$tracks'.'$rx'.'$sideband'.model'
	  rm -rf $target'.'$tracks'.'$rx'.'$sideband'.model.fits'
	  clean map=$target'.'$tracks'.'$rx'.'$sideband'.dirty' beam=$target'.'$tracks'.'$rx'.'$sideband'.beam' out=$target'.'$tracks'.'$rx'.'$sideband'.model' cutoff=$cut niters=1000 region='boxes('${array[1]}','${array[2]}','${array[3]}','${array[4]}')' options=positive
	  fits in=$target'.'$tracks'.'$rx'.'$sideband'.model' op=xyout out=$target'.'$tracks'.'$rx'.'$sideband'.model.fits'
	  
	  # restore image
	  rm -rf $target'.'$tracks'.'$rx'.'$sideband'.clean'
	  rm -rf $target'.'$tracks'.'$rx'.'$sideband'.clean.fits'
	  restor map=$target'.'$tracks'.'$rx'.'$sideband'.dirty' beam=$target'.'$tracks'.'$rx'.'$sideband'.beam' model=$target'.'$tracks'.'$rx'.'$sideband'.model' mode=clean out=$target'.'$tracks'.'$rx'.'$sideband'.clean'
	  fits in=$target'.'$tracks'.'$rx'.'$sideband'.clean' op=xyout out=$target'.'$tracks'.'$rx'.'$sideband'.clean.fits'
       
	  rm -rf $target'.'$tracks'.'$rx'.'$sideband'.residual'
	  rm -rf $target'.'$tracks'.'$rx'.'$sideband'.residual.fits'
	  restor map=$target'.'$tracks'.'$rx'.'$sideband'.dirty' beam=$target'.'$tracks'.'$rx'.'$sideband'.beam' model=$target'.'$tracks'.'$rx'.'$sideband'.model' mode=residual out=$target'.'$tracks'.'$rx'.'$sideband'.residual'
	  fits in=$target'.'$tracks'.'$rx'.'$sideband'.residual' op=xyout out=$target'.'$tracks'.'$rx'.'$sideband'.residual.fits'
       
	  rm -rf $target'.'$tracks'.'$rx'.'$sideband'.clean.pbcor'
	  rm -rf $target'.'$tracks'.'$rx'.'$sideband'.clean.pbcor.fits'
	  linmos in=$target'.'$tracks'.'$rx'.'$sideband'.clean' out=$target'.'$tracks'.'$rx'.'$sideband'.clean.pbcor'
	  fits in=$target'.'$tracks'.'$rx'.'$sideband'.clean.pbcor' op=xyout out=$target'.'$tracks'.'$rx'.'$sideband'.clean.pbcor.fits'

          output=$(python flux_measure.py  $rx  $sideband  $target $tracks $box $rms)
          IFS='   ' read -r -a array <<< "$output"
	  echo "The peak flux of clean map is ${array[0]} mJy/beam"
          echo "The fitted 2D Gaussian component has major and minor FWHM ${array[1]} arcsec and ${array[2]} arcsec"
          echo "The integrated flux density is ${array[3]} mJy"


	  mv *.beam ./ch0/$tracks/
	  mv *.model ./ch0/$tracks/
	  mv *.clean ./ch0/$tracks/
	  mv *.pbcor ./ch0/$tracks/
	  mv *.dirty ./ch0/$tracks/
	  mv *.residual ./ch0/$tracks/
	  mv *.fits ./ch0/$tracks/
	  cp *.txt ./ch0/$tracks/
	  rm -rf *.miriad

        done
      done
done


