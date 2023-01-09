config="com"
flagval="f"

targets='CW_Tau  04113+2758  CY_Tau  V892_Tau  BP_Tau  RY_Tau  FT_Tau  IQ_Tau  UZ_Tau  DL_Tau  AA_Tau  LkCa_15  CI_Tau  T_Tau  UX_Tau  V710_Tau  DM_Tau  DQ_Tau  Haro_6-37  DR_Tau  DN_Tau  DO_Tau  IC_2087_IR  GO_Tau  GM_Aur  AB_Aur'
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
	  	datadir='../selcal/v2022Dec10_track45/selcal_Miriad/'
		vis=$target'_'$track'.'$rx'.'$sideband'.cal.miriad.sel'
		cp -r $datadir$vis ./
		uvflag vis=$target'_'$track'.'$rx'.'$sideband'.cal.miriad.sel' edge=64,64,0 flagval=$flagval
	  done
	  
#          if [ $target=='V892_Tau' ]
#          then
#		uvaver vis=$target'_track1.'$rx'.'$sideband'.cal.miriad.sel' options=nocal,nopass,nopol out=$target'_track12.'$rx'.'$sideband'.cal.miriad.sel'
#          else
	  uvaver vis=$target'_track1.'$rx'.'$sideband'.cal.miriad.sel,'$target'_track2.'$rx'.'$sideband'.cal.miriad.sel' options=nocal,nopass,nopol out=$target'_track12.'$rx'.'$sideband'.cal.miriad.sel'
#          fi

	  if [ $target = 'V892_Tau' ]
          then
		rm -rf $target'_track12.'$rx'.'$sideband'.cal.miriad.sel'
		uvaver vis=$target'_track1.'$rx'.'$sideband'.cal.miriad.sel' options=nocal,nopass,nopol out=$target'_track12.'$rx'.'$sideband'.cal.miriad.sel'
	  fi

		
	  vis=$target'_track12.'$rx'.'$sideband'.cal.miriad.sel'

	  rm -rf $target'.'$tracks'.'$rx'.'$sideband'.sel.dirty'
	  rm -rf $target'.'$tracks'.'$rx'.'$sideband'.sel.beam'
	  invert vis=$vis options=systemp,mfs,double robust=2.0 map=$target'.'$tracks'.'$rx'.'$sideband'.sel.dirty' beam=$target'.'$tracks'.'$rx'.'$sideband'.sel.beam' cell=0.25 imsize=256
	  rm -rf $target'.'$tracks'.'$rx'.'$sideband'.sel.dirty.fits'
	  rm -rf $target'.'$tracks'.'$rx'.'$sideband'.sel.beam.fits'
	  fits in=$target'.'$tracks'.'$rx'.'$sideband'.sel.dirty' op=xyout out=$target'.'$tracks'.'$rx'.'$sideband'.sel.dirty.fits'
	  fits in=$target'.'$tracks'.'$rx'.'$sideband'.sel.beam' op=xyout out=$target'.'$tracks'.'$rx'.'$sideband'.sel.beam.fits'
	  

          # deconvolve image
	  rm -rf $target'.'$tracks'.'$rx'.'$sideband'.10.sel.model'
	  rm -rf $target'.'$tracks'.'$rx'.'$sideband'.10.sel.model.fits'
	  clean map=$target'.'$tracks'.'$rx'.'$sideband'.sel.dirty' beam=$target'.'$tracks'.'$rx'.'$sideband'.sel.beam' out=$target'.'$tracks'.'$rx'.'$sideband'.10.sel.model' cutoff=0.001 niters=10
	  fits in=$target'.'$tracks'.'$rx'.'$sideband'.10.sel.model' op=xyout out=$target'.'$tracks'.'$rx'.'$sideband'.10.sel.model.fits'

	  rm -rf $target'.'$tracks'.'$rx'.'$sideband'.sel.clean'
          rm -rf $target'.'$tracks'.'$rx'.'$sideband'.sel.clean.fits'
          restor map=$target'.'$tracks'.'$rx'.'$sideband'.sel.dirty' beam=$target'.'$tracks'.'$rx'.'$sideband'.sel.beam' model=$target'.'$tracks'.'$rx'.'$sideband'.10.sel.model' mode=clean out=$target'.'$tracks'.'$rx'.'$sideband'.sel.clean'
          fits in=$target'.'$tracks'.'$rx'.'$sideband'.sel.clean' op=xyout out=$target'.'$tracks'.'$rx'.'$sideband'.sel.clean.fits'

	  rm -rf $target'.'$tracks'.'$rx'.'$sideband'.sel.residual'
          rm -rf $target'.'$tracks'.'$rx'.'$sideband'.sel.residual.fits'
          restor map=$target'.'$tracks'.'$rx'.'$sideband'.sel.dirty' beam=$target'.'$tracks'.'$rx'.'$sideband'.sel.beam' model=$target'.'$tracks'.'$rx'.'$sideband'.10.sel.model' mode=residual out=$target'.'$tracks'.'$rx'.'$sideband'.sel.residual'
          fits in=$target'.'$tracks'.'$rx'.'$sideband'.sel.residual' op=xyout out=$target'.'$tracks'.'$rx'.'$sideband'.sel.residual.fits'
	  
	  
	  output=$(python get_rms.sel.py  $rx  $sideband  $target $tracks)
	  IFS='   ' read -r -a array <<< "$output"
	  rms=${array[0]}
	  cut=$(bc -l <<< "${array[0]}*1.5")
	  echo "The obtained rms for $target is ${array[0]} Jy/beam"
	  box=${array[1]}','${array[2]}','${array[3]}','${array[4]}
	  echo 'boxes('${array[1]}','${array[2]}','${array[3]}','${array[4]}')'

	  rm -rf $target'.'$tracks'.'$rx'.'$sideband'.sel.model'
	  rm -rf $target'.'$tracks'.'$rx'.'$sideband'.sel.model.fits'
	  clean map=$target'.'$tracks'.'$rx'.'$sideband'.sel.dirty' beam=$target'.'$tracks'.'$rx'.'$sideband'.sel.beam' out=$target'.'$tracks'.'$rx'.'$sideband'.sel.model' cutoff=$cut niters=1000 region='boxes('${array[1]}','${array[2]}','${array[3]}','${array[4]}')' options=positive
	  fits in=$target'.'$tracks'.'$rx'.'$sideband'.sel.model' op=xyout out=$target'.'$tracks'.'$rx'.'$sideband'.sel.model.fits'
	  
	  # restore image
	  rm -rf $target'.'$tracks'.'$rx'.'$sideband'.sel.clean'
	  rm -rf $target'.'$tracks'.'$rx'.'$sideband'.sel.clean.fits'
	  restor map=$target'.'$tracks'.'$rx'.'$sideband'.sel.dirty' beam=$target'.'$tracks'.'$rx'.'$sideband'.sel.beam' model=$target'.'$tracks'.'$rx'.'$sideband'.sel.model' mode=clean out=$target'.'$tracks'.'$rx'.'$sideband'.sel.clean'
	  fits in=$target'.'$tracks'.'$rx'.'$sideband'.sel.clean' op=xyout out=$target'.'$tracks'.'$rx'.'$sideband'.sel.clean.fits'
       
	  rm -rf $target'.'$tracks'.'$rx'.'$sideband'.sel.residual'
	  rm -rf $target'.'$tracks'.'$rx'.'$sideband'.sel.residual.fits'
	  restor map=$target'.'$tracks'.'$rx'.'$sideband'.sel.dirty' beam=$target'.'$tracks'.'$rx'.'$sideband'.sel.beam' model=$target'.'$tracks'.'$rx'.'$sideband'.sel.model' mode=residual out=$target'.'$tracks'.'$rx'.'$sideband'.sel.residual'
	  fits in=$target'.'$tracks'.'$rx'.'$sideband'.sel.residual' op=xyout out=$target'.'$tracks'.'$rx'.'$sideband'.sel.residual.fits'
       
	  rm -rf $target'.'$tracks'.'$rx'.'$sideband'.sel.clean.pbcor'
	  rm -rf $target'.'$tracks'.'$rx'.'$sideband'.sel.clean.pbcor.fits'
	  linmos in=$target'.'$tracks'.'$rx'.'$sideband'.sel.clean' out=$target'.'$tracks'.'$rx'.'$sideband'.sel.clean.pbcor'
	  fits in=$target'.'$tracks'.'$rx'.'$sideband'.sel.clean.pbcor' op=xyout out=$target'.'$tracks'.'$rx'.'$sideband'.sel.clean.pbcor.fits'

          output=$(python flux_measure.sel.py  $rx  $sideband  $target $tracks $box $rms)
          IFS='   ' read -r -a array <<< "$output"
	  echo "The peak flux of clean map is ${array[0]} mJy/beam"
          echo "The fitted 2D Gaussian component has major and minor FWHM ${array[1]} arcsec and ${array[2]} arcsec"
          echo "The integrated flux density is ${array[3]} mJy"


	  mv *.beam ./ch0/$tracks/
	  mv *.sel.model ./ch0/$tracks/
	  mv *.clean ./ch0/$tracks/
	  mv *.pbcor ./ch0/$tracks/
	  mv *.sel.dirty ./ch0/$tracks/
	  mv *.residual ./ch0/$tracks/
	  mv *.fits ./ch0/$tracks/
	  cp *.txt ./ch0/$tracks/
	  mv $vis ./ch0/$tracks/
	  rm -rf *.miriad.sel

        done
      done
done


