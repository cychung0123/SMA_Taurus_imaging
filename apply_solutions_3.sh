targets='AA_Tau DM_Tau DN_Tau DH_Tau IQ_Tau DK_Tau FY_Tau GK_Tau CI_Tau 04278+2253 UX_Tau V710_Tau DQ_Tau HO_Tau HV_Tau CIDA-7 GO_Tau DS_Tau UY_Aur Haro_6-39 SU_Aur RW_Aur CIDA-9 V836_Tau'
tracks='track3'
rxs='rx240 rx345'
sidebands='lsb usb'
refant='6'
vislist="'"
for target in $targets
do
    vislist+=$target"_'""$""track'.'""$""rx'.'""$""sideband'.cal.miriad,"
done
vislist=${vislist::-1}
vislist+="'"
echo $vislist

cp ../../imaging_box/center_track456.txt .

for track in $tracks
do
    datadir='../../calibrated_Miriad/'$track'/'

    for rx in $rxs
    do
         for sideband in $sidebands
         do
	    rm -rf 'com_vis_faint_'$track'.'$rx'.'$sideband'.cal.miriad'

            for target in $targets
            do
                vis=$target'_'$track'.'$rx'.'$sideband'.cal.miriad'
                cp -r $datadir$vis ./
                uvflag vis=$vis edge=64,64,0 flagval="f"
            done
	    uvaver vis='AA_Tau_'$track'.'$rx'.'$sideband'.cal.miriad,DM_Tau_'$track'.'$rx'.'$sideband'.cal.miriad,DN_Tau_'$track'.'$rx'.'$sideband'.cal.miriad,DH_Tau_'$track'.'$rx'.'$sideband'.cal.miriad,IQ_Tau_'$track'.'$rx'.'$sideband'.cal.miriad,DK_Tau_'$track'.'$rx'.'$sideband'.cal.miriad,FY_Tau_'$track'.'$rx'.'$sideband'.cal.miriad,GK_Tau_'$track'.'$rx'.'$sideband'.cal.miriad,CI_Tau_'$track'.'$rx'.'$sideband'.cal.miriad,04278+2253_'$track'.'$rx'.'$sideband'.cal.miriad,UX_Tau_'$track'.'$rx'.'$sideband'.cal.miriad,V710_Tau_'$track'.'$rx'.'$sideband'.cal.miriad,DQ_Tau_'$track'.'$rx'.'$sideband'.cal.miriad,HO_Tau_'$track'.'$rx'.'$sideband'.cal.miriad,DN_Tau_'$track'.'$rx'.'$sideband'.cal.miriad,HV_Tau_'$track'.'$rx'.'$sideband'.cal.miriad,CIDA-7_'$track'.'$rx'.'$sideband'.cal.miriad,GO_Tau_'$track'.'$rx'.'$sideband'.cal.miriad,DS_Tau_'$track'.'$rx'.'$sideband'.cal.miriad,UY_Aur_'$track'.'$rx'.'$sideband'.cal.miriad,Haro_6-39_'$track'.'$rx'.'$sideband'.cal.miriad,SU_Aur_'$track'.'$rx'.'$sideband'.cal.miriad,RW_Aur_'$track'.'$rx'.'$sideband'.cal.miriad,CIDA-9_'$track'.'$rx'.'$sideband'.cal.miriad,V836_Tau_'$track'.'$rx'.'$sideband'.cal.miriad' options=nocal,nopass,nopol out='com_vis_faint_'$track'.'$rx'.'$sideband'.cal.miriad'

         done
    done
done

for track in $tracks
do

    for rx in $rxs
    do

       # set reference antenna and solution interval
      if [ $track = 'track3' ]
      then
        interval='5'
        refant='6'
        cellsize=0.25
        imsize=256
      fi

      if [ $track = 'track2' ]
      then
        interval='5'
        refant='6'
        cellsize=0.25
        imsize=256
      fi

      if [ $track = 'track6' ]
      then
        interval='5'
        refant='6'
        cellsize=0.125
        imsize=512
      fi

      for sideband in $sidebands
      do

        vis_f='com_vis_faint_'$track'.'$rx'.'$sideband'.cal.miriad'

	vis_b='com_vis_'$track'.'$rx'.'$sideband'.cal.miriad.sel'
	cp -r ./selcal_Miriad/$vis_b .

	gpcopy vis=$vis_b out=$vis_f mode=apply options=nopol,nopass,relax
		
	for target in $targets
        do

          # creating non-self-calibrated image
          rm -rf $target'.'$track'.'$rx'.'$sideband'.dirty'
          rm -rf $target'.'$track'.'$rx'.'$sideband'.beam'
          invert vis=$target'_'$track'.'$rx'.'$sideband'.cal.miriad' \
                  options=systemp,mfs,double robust=2.0 \
                  map=$target'.'$track'.'$rx'.'$sideband'.dirty' \
                  beam=$target'.'$track'.'$rx'.'$sideband'.beam' cell=$cellsize imsize=$imsize
#                 select='uvrange(0,80)'

          rm -rf $target'.'$track'.'$rx'.'$sideband'.dirty.fits'
          rm -rf $target'.'$track'.'$rx'.'$sideband'.beam.fits'
          fits in=$target'.'$track'.'$rx'.'$sideband'.dirty' op=xyout out=$target'.'$track'.'$rx'.'$sideband'.dirty.fits'
          fits in=$target'.'$track'.'$rx'.'$sideband'.beam' op=xyout out=$target'.'$track'.'$rx'.'$sideband'.beam.fits'

          rm -rf $target'.'$track'.'$rx'.'$sideband'.10.model'
          rm -rf $target'.'$track'.'$rx'.'$sideband'.10.model.fits'
          clean map=$target'.'$track'.'$rx'.'$sideband'.dirty' \
                  beam=$target'.'$track'.'$rx'.'$sideband'.beam' \
                  out=$target'.'$track'.'$rx'.'$sideband'.10.model' cutoff=0.01 niters=10 \
                  options=positive
          fits in=$target'.'$track'.'$rx'.'$sideband'.10.model' op=xyout out=$target'.'$track'.'$rx'.'$sideband'.10.model.fits'

          rm -rf $target'.'$track'.'$rx'.'$sideband'.clean'
          rm -rf $target'.'$track'.'$rx'.'$sideband'.clean.fits'
          restor map=$target'.'$track'.'$rx'.'$sideband'.dirty' \
                  beam=$target'.'$track'.'$rx'.'$sideband'.beam' \
                  model=$target'.'$track'.'$rx'.'$sideband'.10.model' \
                  mode=clean out=$target'.'$track'.'$rx'.'$sideband'.clean'
          fits in=$target'.'$track'.'$rx'.'$sideband'.clean' op=xyout out=$target'.'$track'.'$rx'.'$sideband'.clean.fits'

          rm -rf $target'.'$track'.'$rx'.'$sideband'.residual'
          rm -rf $target'.'$track'.'$rx'.'$sideband'.residual.fits'
          restor map=$target'.'$track'.'$rx'.'$sideband'.dirty' \
                  beam=$target'.'$track'.'$rx'.'$sideband'.beam' \
                  model=$target'.'$track'.'$rx'.'$sideband'.10.model' \
                  mode=residual out=$target'.'$track'.'$rx'.'$sideband'.residual'
          fits in=$target'.'$track'.'$rx'.'$sideband'.residual' op=xyout out=$target'.'$track'.'$rx'.'$sideband'.residual.fits'

          output=$(python get_rms.py  $rx  $sideband  $target $track)
          IFS='   ' read -r -a array <<< "$output"
          rms=${array[0]}
          cut=$(bc -l <<< "${array[0]}*1.5")
          echo "The obtained rms for $target is ${array[0]} Jy/beam"
          box=${array[1]}','${array[2]}','${array[3]}','${array[4]}
          echo 'boxes('${array[1]}','${array[2]}','${array[3]}','${array[4]}')'

          rm -rf $target'.'$track'.'$rx'.'$sideband'.dirty'
          rm -rf $target'.'$track'.'$rx'.'$sideband'.beam'
          invert vis=$target'_'$track'.'$rx'.'$sideband'.cal.miriad' \
                  options=systemp,mfs,double robust=2.0 \
                  map=$target'.'$track'.'$rx'.'$sideband'.dirty' \
                  beam=$target'.'$track'.'$rx'.'$sideband'.beam' cell=$cellsize imsize=$imsize

          rm -rf $target'.'$track'.'$rx'.'$sideband'.dirty.fits'
          rm -rf $target'.'$track'.'$rx'.'$sideband'.beam.fits'
          fits in=$target'.'$track'.'$rx'.'$sideband'.dirty' op=xyout out=$target'.'$track'.'$rx'.'$sideband'.dirty.fits'
          fits in=$target'.'$track'.'$rx'.'$sideband'.beam' op=xyout out=$target'.'$track'.'$rx'.'$sideband'.beam.fits'

          rm -rf $target'.'$track'.'$rx'.'$sideband'.model'
          rm -rf $target'.'$track'.'$rx'.'$sideband'.model.fits'
          clean map=$target'.'$track'.'$rx'.'$sideband'.dirty' \
                  beam=$target'.'$track'.'$rx'.'$sideband'.beam' \
                  out=$target'.'$track'.'$rx'.'$sideband'.model' cutoff=$cut niters=1000 \
                  region='boxes('${array[1]}','${array[2]}','${array[3]}','${array[4]}')'
          fits in=$target'.'$track'.'$rx'.'$sideband'.model' op=xyout out=$target'.'$track'.'$rx'.'$sideband'.model.fits'

          # restore image
          rm -rf $target'.'$track'.'$rx'.'$sideband'.clean'
          rm -rf $target'.'$track'.'$rx'.'$sideband'.clean.fits'
          restor map=$target'.'$track'.'$rx'.'$sideband'.dirty' \
                  beam=$target'.'$track'.'$rx'.'$sideband'.beam' \
                  model=$target'.'$track'.'$rx'.'$sideband'.model' \
                  mode=clean out=$target'.'$track'.'$rx'.'$sideband'.clean'
          fits in=$target'.'$track'.'$rx'.'$sideband'.clean' op=xyout out=$target'.'$track'.'$rx'.'$sideband'.clean.fits'

          rm -rf $target'.'$track'.'$rx'.'$sideband'.residual'
          rm -rf $target'.'$track'.'$rx'.'$sideband'.residual.fits'
          restor map=$target'.'$track'.'$rx'.'$sideband'.dirty' \
                  beam=$target'.'$track'.'$rx'.'$sideband'.beam' \
                  model=$target'.'$track'.'$rx'.'$sideband'.model' \
                  mode=residual out=$target'.'$track'.'$rx'.'$sideband'.residual'
          fits in=$target'.'$track'.'$rx'.'$sideband'.residual' op=xyout out=$target'.'$track'.'$rx'.'$sideband'.residual.fits'

          rm -rf $target'.'$track'.'$rx'.'$sideband'.clean.pbcor'
          rm -rf $target'.'$track'.'$rx'.'$sideband'.clean.pbcor.fits'
          linmos in=$target'.'$track'.'$rx'.'$sideband'.clean' out=$target'.'$track'.'$rx'.'$sideband'.clean.pbcor'
          fits in=$target'.'$track'.'$rx'.'$sideband'.clean.pbcor' op=xyout out=$target'.'$track'.'$rx'.'$sideband'.clean.pbcor.fits'

          output=$(python flux_measure.py  $rx  $sideband  $target $track $box $rms)
          IFS='   ' read -r -a array <<< "$output"
          echo "The peak flux of clean map is ${array[0]} mJy/beam"
          echo "The fitted 2D Gaussian component has major and minor FWHM ${array[1]} arcsec and ${array[2]} arcsec"
          echo "The integrated flux density is ${array[3]} mJy"


          # creating self-calibrated image
          rm -rf $target'.'$track'.'$rx'.'$sideband'.sel.dirty'
          rm -rf $target'.'$track'.'$rx'.'$sideband'.sel.beam'

	  if [ $target = '04278+2253' ]
	  then
		  select='source(04278+22)'
	  elif [ $target = 'Haro_6-39' ]
	  then
		  select='source(Haro_6-3)'
	  else
		  select='source('$target')' 
	  fi

          invert vis=$vis_f \
                options=systemp,mfs,double robust=2.0 select=$select\
                map=$target'.'$track'.'$rx'.'$sideband'.sel.dirty' \
                beam=$target'.'$track'.'$rx'.'$sideband'.sel.beam' cell=$cellsize imsize=$imsize

          rm -rf $target'.'$track'.'$rx'.'$sideband'.sel.dirty.fits'
          rm -rf $target'.'$track'.'$rx'.'$sideband'.sel.beam.fits'
          fits in=$target'.'$track'.'$rx'.'$sideband'.sel.dirty' op=xyout out=$target'.'$track'.'$rx'.'$sideband'.sel.dirty.fits'
          fits in=$target'.'$track'.'$rx'.'$sideband'.sel.beam' op=xyout out=$target'.'$track'.'$rx'.'$sideband'.sel.beam.fits'

          rm -rf $target'.'$track'.'$rx'.'$sideband'.10.sel.model'
          rm -rf $target'.'$track'.'$rx'.'$sideband'.10.sel.model.fits'
          clean map=$target'.'$track'.'$rx'.'$sideband'.sel.dirty' \
                beam=$target'.'$track'.'$rx'.'$sideband'.sel.beam' \
                out=$target'.'$track'.'$rx'.'$sideband'.10.sel.model' cutoff=0.01 niters=10 options=positive
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
                model=$target'.'$track'.'$rx'.'$sideband'.10.sel.model'\
                mode=residual out=$target'.'$track'.'$rx'.'$sideband'.sel.residual'
          fits in=$target'.'$track'.'$rx'.'$sideband'.sel.residual' op=xyout out=$target'.'$track'.'$rx'.'$sideband'.sel.residual.fits'
	    

	  output=$(python get_rms.sel.py  $rx  $sideband $target $track)
          IFS='   ' read -r -a array <<< "$output"
          cut=$(bc -l <<< "${array[0]}*1.5")
          rms=${array[0]}
          echo "The obtained rms for $target is ${array[0]} Jy/beam"
          box=${array[1]}','${array[2]}','${array[3]}','${array[4]}
          echo 'boxes('${array[1]}','${array[2]}','${array[3]}','${array[4]}')'

          rm -rf $target'.'$track'.'$rx'.'$sideband'.sel.dirty'
          rm -rf $target'.'$track'.'$rx'.'$sideband'.sel.beam'
          invert vis=$vis_f \
                options=systemp,mfs,double robust=2.0 select=$select\
                map=$target'.'$track'.'$rx'.'$sideband'.sel.dirty' \
                beam=$target'.'$track'.'$rx'.'$sideband'.sel.beam' cell=$cellsize imsize=$imsize

          rm -rf $target'.'$track'.'$rx'.'$sideband'.sel.dirty.fits'
          rm -rf $target'.'$track'.'$rx'.'$sideband'.sel.beam.fits'
          fits in=$target'.'$track'.'$rx'.'$sideband'.sel.dirty' op=xyout out=$target'.'$track'.'$rx'.'$sideband'.sel.dirty.fits'
          fits in=$target'.'$track'.'$rx'.'$sideband'.sel.beam' op=xyout out=$target'.'$track'.'$rx'.'$sideband'.sel.beam.fits'

    	  rm -rf $target'.'$track'.'$rx'.'$sideband'.10.sel.model'
    	  rm -rf $target'.'$track'.'$rx'.'$sideband'.10.sel.model.fits'
	  clean map=$target'.'$track'.'$rx'.'$sideband'.sel.dirty' \
                beam=$target'.'$track'.'$rx'.'$sideband'.sel.beam' \
                out=$target'.'$track'.'$rx'.'$sideband'.10.sel.model' cutoff=0.01 niters=10 options=positive \
                region='boxes('${array[1]}','${array[2]}','${array[3]}','${array[4]}')'
			    
	  fits in=$target'.'$track'.'$rx'.'$sideband'.10.sel.model' op=xyout out=$target'.'$track'.'$rx'.'$sideband'.10.sel.model.fits'

          rm -rf $target'.'$track'.'$rx'.'$sideband'.sel.model'
          rm -rf $target'.'$track'.'$rx'.'$sideband'.sel.model.fits'
          clean map=$target'.'$track'.'$rx'.'$sideband'.sel.dirty' \
                beam=$target'.'$track'.'$rx'.'$sideband'.sel.beam' \
                out=$target'.'$track'.'$rx'.'$sideband'.sel.model' cutoff=$cut niters=1000 options=positive \
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

        done
      done
    done
done

mv com_vis_faint* selcal_Miriad

mkdir SED_f 
mv *_track* SED_f

