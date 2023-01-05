config="com"
flagval="f"

targets='CW_Tau  04113+2758  CY_Tau  V892_Tau  BP_Tau  RY_Tau  FT_Tau  IQ_Tau  UZ_Tau  DL_Tau  AA_Tau  LkCa_15  CI_Tau  T_Tau  UX_Tau  V710_Tau  DM_Tau  DQ_Tau  Haro_6-37  DR_Tau  DN_Tau  DO_Tau  IC_2087_IR  GO_Tau  GM_Aur  AB_Aur'
tracks='track1 track2'
sidebands='lsb usb'
rxs='rx230 rx240'

#rm -rf *.txt
#rm -rf *.rx*
#rm -rf ch0
#mkdir ch0
#cp ../imaging_com/center_track456.txt .

for track in $tracks
do
  cd ch0/
  rm -rf $track
  mkdir $track
  cd ../
  
  for rx in $rxs
  do
      for sideband in $sidebands
      do

        if [ $track = 'track1' ]
	then
		cellsize=0.25
		imsize=256
	fi
	if [ $track = 'track2' ]
	then
		cellsize=0.2
		imsize=256
	fi
        if [ $track = 'track6' ]
        then
                cellsize=0.3
                imsize=256
        fi

	for target in $targets
	do
	  
	  datadir='../selcal/v2022Dec10_track45/selcal_Miriad/'
	  vis=$target'_'$track'.'$rx'.'$sideband'.cal.miriad.sel'
	  cp -r $datadir$vis ./

	  uvflag vis=$target'_'$track'.'$rx'.'$sideband'.cal.miriad.sel' edge=64,64,0 flagval=$flagval

	  # creating non-self-calibrated image
          rm -rf $target'.'$track'.'$rx'.'$sideband'.sel.dirty'
          rm -rf $target'.'$track'.'$rx'.'$sideband'.sel.beam'
          invert vis=$target'_'$track'.'$rx'.'$sideband'.cal.miriad.sel' \
                  options=systemp,mfs,double robust=2.0 \
                  map=$target'.'$track'.'$rx'.'$sideband'.sel.dirty' \
                  beam=$target'.'$track'.'$rx'.'$sideband'.sel.beam' cell=$cellsize imsize=$imsize
#                 select='uvrange(0,80)'

          rm -rf $target'.'$track'.'$rx'.'$sideband'.sel.dirty.fits'
          rm -rf $target'.'$track'.'$rx'.'$sideband'.sel.beam.fits'
          fits in=$target'.'$track'.'$rx'.'$sideband'.sel.dirty' op=xyout out=$target'.'$track'.'$rx'.'$sideband'.sel.dirty.fits'
          fits in=$target'.'$track'.'$rx'.'$sideband'.sel.beam' op=xyout out=$target'.'$track'.'$rx'.'$sideband'.sel.beam.fits'

          rm -rf $target'.'$track'.'$rx'.'$sideband'.10.sel.model'
          rm -rf $target'.'$track'.'$rx'.'$sideband'.10.sel.model.fits'
          clean map=$target'.'$track'.'$rx'.'$sideband'.sel.dirty' \
                  beam=$target'.'$track'.'$rx'.'$sideband'.sel.beam' \
                  out=$target'.'$track'.'$rx'.'$sideband'.10.sel.model' cutoff=0.01 niters=10 \
	  	  options=positive
          fits in=$target'.'$track'.'$rx'.'$sideband'.10.sel.model' op=xyout out=$target'.'$track'.'$rx'.'$sideband'.10.sel.model.fits'

          rm -rf $target'.'$track'.'$rx'.'$sideband'.sel.clean'
          rm -rf $target'.'$track'.'$rx'.'$sideband'.sel.clean.fits'
          restor map=$target'.'$track'.'$rx'.'$sideband'.sel.dirty' \
                  beam=$target'.'$track'.'$rx'.'$sideband'.sel.beam' \
                  model=$target'.'$track'.'$rx'.'$sideband'.10.sel.model' \
                  mode=clean out=$target'.'$track'.'$rx'.'$sideband'.sel.clean'
          fits in=$target'.'$track'.'$rx'.'$sideband'.sel.clean' op=xyout out=$target'.'$track'.'$rx'.'$sideband'.sel.clean.fits'
  
          rm -rf $target'.'$track'.'$rx'.'$sideband'.sel.residual'
          rm -rf $target'.'$track'.'$rx'.'$sideband'.sel.residual.fits'
          restor map=$target'.'$track'.'$rx'.'$sideband'.sel.dirty' \
                  beam=$target'.'$track'.'$rx'.'$sideband'.sel.beam' \
                  model=$target'.'$track'.'$rx'.'$sideband'.10.sel.model' \
                  mode=residual out=$target'.'$track'.'$rx'.'$sideband'.sel.residual'
          fits in=$target'.'$track'.'$rx'.'$sideband'.sel.residual' op=xyout out=$target'.'$track'.'$rx'.'$sideband'.sel.residual.fits'

          output=$(python get_rms.sel.py  $rx  $sideband  $target $track)
          IFS='   ' read -r -a array <<< "$output"
          rms=${array[0]}
          cut=$(bc -l <<< "${array[0]}*1.5")
          echo "The obtained rms for $target is ${array[0]} Jy/beam"
          box=${array[1]}','${array[2]}','${array[3]}','${array[4]}
          echo 'boxes('${array[1]}','${array[2]}','${array[3]}','${array[4]}')'

          rm -rf $target'.'$track'.'$rx'.'$sideband'.sel.dirty'
          rm -rf $target'.'$track'.'$rx'.'$sideband'.sel.beam'
          invert vis=$target'_'$track'.'$rx'.'$sideband'.cal.miriad.sel' \
                  options=systemp,mfs,double robust=2.0 \
                  map=$target'.'$track'.'$rx'.'$sideband'.sel.dirty' \
                  beam=$target'.'$track'.'$rx'.'$sideband'.sel.beam' cell=$cellsize imsize=$imsize

          rm -rf $target'.'$track'.'$rx'.'$sideband'.sel.dirty.fits'
          rm -rf $target'.'$track'.'$rx'.'$sideband'.sel.beam.fits'
          fits in=$target'.'$track'.'$rx'.'$sideband'.sel.dirty' op=xyout out=$target'.'$track'.'$rx'.'$sideband'.sel.dirty.fits'
          fits in=$target'.'$track'.'$rx'.'$sideband'.sel.beam' op=xyout out=$target'.'$track'.'$rx'.'$sideband'.sel.beam.fits'

          rm -rf $target'.'$track'.'$rx'.'$sideband'.sel.model'
          rm -rf $target'.'$track'.'$rx'.'$sideband'.sel.model.fits'
          clean map=$target'.'$track'.'$rx'.'$sideband'.sel.dirty' \
                  beam=$target'.'$track'.'$rx'.'$sideband'.sel.beam' \
                  out=$target'.'$track'.'$rx'.'$sideband'.sel.model' cutoff=$cut niters=1000 \
                  region='boxes('${array[1]}','${array[2]}','${array[3]}','${array[4]}')' 
          fits in=$target'.'$track'.'$rx'.'$sideband'.sel.model' op=xyout out=$target'.'$track'.'$rx'.'$sideband'.sel.model.fits'

          # restore image
          rm -rf $target'.'$track'.'$rx'.'$sideband'.sel.clean'
          rm -rf $target'.'$track'.'$rx'.'$sideband'.sel.clean.fits'
          restor map=$target'.'$track'.'$rx'.'$sideband'.sel.dirty' \
                  beam=$target'.'$track'.'$rx'.'$sideband'.sel.beam' \
                  model=$target'.'$track'.'$rx'.'$sideband'.sel.model' \
                  mode=clean out=$target'.'$track'.'$rx'.'$sideband'.sel.clean'
          fits in=$target'.'$track'.'$rx'.'$sideband'.sel.clean' op=xyout out=$target'.'$track'.'$rx'.'$sideband'.sel.clean.fits'

          rm -rf $target'.'$track'.'$rx'.'$sideband'.sel.residual'
          rm -rf $target'.'$track'.'$rx'.'$sideband'.sel.residual.fits'
          restor map=$target'.'$track'.'$rx'.'$sideband'.sel.dirty' \
                  beam=$target'.'$track'.'$rx'.'$sideband'.sel.beam' \
                  model=$target'.'$track'.'$rx'.'$sideband'.sel.model' \
                  mode=residual out=$target'.'$track'.'$rx'.'$sideband'.sel.residual'
          fits in=$target'.'$track'.'$rx'.'$sideband'.sel.residual' op=xyout out=$target'.'$track'.'$rx'.'$sideband'.sel.residual.fits'

          rm -rf $target'.'$track'.'$rx'.'$sideband'.sel.clean.pbcor'
          rm -rf $target'.'$track'.'$rx'.'$sideband'.sel.clean.pbcor.fits'
          linmos in=$target'.'$track'.'$rx'.'$sideband'.sel.clean' out=$target'.'$track'.'$rx'.'$sideband'.sel.clean.pbcor'
          fits in=$target'.'$track'.'$rx'.'$sideband'.sel.clean.pbcor' op=xyout out=$target'.'$track'.'$rx'.'$sideband'.sel.clean.pbcor.fits'

          output=$(python flux_measure.sel.py  $rx  $sideband  $target $track $box $rms)
          IFS='   ' read -r -a array <<< "$output"
          echo "The peak flux of clean map is ${array[0]} mJy/beam"
          echo "The fitted 2D Gaussian component has major and minor FWHM ${array[1]} arcsec and ${array[2]} arcsec"
          echo "The integrated flux density is ${array[3]} mJy"




	  mv *.beam ./ch0/$track/
	  mv *.model ./ch0/$track/
	  mv *.clean ./ch0/$track/
	  mv *.pbcor ./ch0/$track/
	  mv *.sel.dirty ./ch0/$track/
	  mv *.residual ./ch0/$track/
	  mv *.fits ./ch0/$track/
	  cp *.txt ./ch0/$track/
	  rm -rf *.miriad.sel

        done
      done
  done
done

