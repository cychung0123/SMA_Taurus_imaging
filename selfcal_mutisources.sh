targets='UZ_Tau DL_Tau LkCa_15 CI_Tau T_Tau DR_Tau DO_Tau IC_2087_IR GM_Aur AB_Aur'
tracks='track4 track5 track6'
rxs='rx345 rx400'
sidebands='lsb usb'
refant='6'
image_targets='UZ_Tau DL_Tau LkCa_15 CI_Tau T_Tau DR_Tau DO_Tau IC_2087_ GM_Aur AB_Aur'


# creating a directory to host self-calibrated data
rm -rf selcal_Miriad
mkdir selcal_Miriad

rm -rf *.model
rm -rf *.txt
rm -rf *.sel
rm -rf *.gain
rm -rf *rx*

# generate visibility list and model list
vislist="'"
for target in $targets
do
    vislist+=$target"_'""$""track'.'""$""rx'.'""$""sideband'.cal.miriad,"
done
vislist=${vislist::-1}
vislist+="'"
echo $vislist

modellist="'"
for target in $targets
do
    modellist+=$target".'""$""track'.rx345.lsb.model,"
done
modellist=${modellist::-1}
modellist+="'"
echo $modellist

modellist="'"
for target in $image_targets
do
    modellist+=$target".'""$""track'.rx345.lsb.sel.10.model,"
done
modellist=${modellist::-1}
modellist+="'"
echo $modellist




for track in $tracks
do
    datadir='../../calibrated_Miriad/'$track'/'

    for rx in $rxs
    do
	 for sideband in $sidebands
	 do
	    for target in $targets
	    do
		imdir='../../imaging_box/ch0/'$track'/'$target'/'
		model=$target'.'$track'.rx345.lsb.model'
		cp -r $imdir$model ./

	    	vis=$target'_'$track'.'$rx'.'$sideband'.cal.miriad'
	    	cp -r $datadir$vis ./
	    	uvflag vis=$vis edge=64,64,0 flagval="f"
	    done
	    uvaver vis='UZ_Tau_'$track'.'$rx'.'$sideband'.cal.miriad,DL_Tau_'$track'.'$rx'.'$sideband'.cal.miriad,LkCa_15_'$track'.'$rx'.'$sideband'.cal.miriad,CI_Tau_'$track'.'$rx'.'$sideband'.cal.miriad,T_Tau_'$track'.'$rx'.'$sideband'.cal.miriad,DR_Tau_'$track'.'$rx'.'$sideband'.cal.miriad,DO_Tau_'$track'.'$rx'.'$sideband'.cal.miriad,IC_2087_IR_'$track'.'$rx'.'$sideband'.cal.miriad,GM_Aur_'$track'.'$rx'.'$sideband'.cal.miriad,AB_Aur_'$track'.'$rx'.'$sideband'.cal.miriad' options=nocal,nopass,nopol out='com_vis_'$track'.'$rx'.'$sideband'.cal.miriad'
	    
	    mv '04113+2758_'$track'.'$rx'.'$sideband'.cal.miriad' '04113+27_'$track'.'$rx'.'$sideband'.cal.miriad'
	    mv 'IC_2087_IR_'$track'.'$rx'.'$sideband'.cal.miriad' 'IC_2087__'$track'.'$rx'.'$sideband'.cal.miriad'

	 done
    done
done


# looping over observations on varios target sources
for track in $tracks
do

    for rx in $rxs
    do

       # set reference antenna and solution interval
      if [ $track = 'track4' ]
      then
        interval='5'
        refant='6'
	cellsize=0.25
	imsize=256
      fi

      if [ $track = 'track5' ]
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

        vis='com_vis_'$track'.'$rx'.'$sideband'.cal.miriad'

	if [ $rx = 'rx345' ] && [ $sideband = 'lsb' ]
	then
		model='UZ_Tau.'$track'.rx345.lsb.model,DL_Tau.'$track'.rx345.lsb.model,LkCa_15.'$track'.rx345.lsb.model,CI_Tau.'$track'.rx345.lsb.model,T_Tau.'$track'.rx345.lsb.model,DR_Tau.'$track'.rx345.lsb.model,DO_Tau.'$track'.rx345.lsb.model,IC_2087_IR.'$track'.rx345.lsb.model,GM_Aur.'$track'.rx345.lsb.model,AB_Aur.'$track'.rx345.lsb.model'


	else
		model='UZ_Tau.'$track'.rx345.lsb.sel.10.model,DL_Tau.'$track'.rx345.lsb.sel.10.model,LkCa_15.'$track'.rx345.lsb.sel.10.model,CI_Tau.'$track'.rx345.lsb.sel.10.model,T_Tau.'$track'.rx345.lsb.sel.10.model,DR_Tau.'$track'.rx345.lsb.sel.10.model,DO_Tau.'$track'.rx345.lsb.sel.10.model,IC_2087_.'$track'.rx345.lsb.sel.10.model,GM_Aur.'$track'.rx345.lsb.sel.10.model,AB_Aur.'$track'.rx345.lsb.sel.10.model'
	fi

        # convert to Stokes I data
        rm -rf $vis'.i'
        uvaver vis=$vis options=nopass,nocal,nopol out=$vis'.i' stokes=ii
 
        # produce ascii output for the self-calibration solution
        gaintable='com_vis_'$track'.'$rx'.'$sideband'.1p.gain'
        rm -rf $gaintable
        int='0.1'
        selfcal vis=$vis'.i' model=$model \
                out=$gaintable \
                options='pha,mfs,mosaic' \
                interval=$interval refant=$refant


        # perform gain self-claibration solution
        selfcal vis=$vis'.i' model=$model \
                options='pha,mfs,mosaic' \
                interval=$interval refant=$refant
 

        # inspecting the solution and yield ascii output for solution table
        rm -rf $gaintable'.txt'
        gpplt vis=$gaintable yaxis=phase nxy=1,1 log=$gaintable'.txt' # device=/xw

        # apply calibration solution
        rm -rf $vis'.sel'
        uvaver vis=$vis'.i' options=nopass,nopol out=$vis'.sel'
	
	for target in $image_targets
	do
	    # creating non-self-calibrated image
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

            rm -rf $target'.'$track'.'$rx'.'$sideband'.10.model'
            rm -rf $target'.'$track'.'$rx'.'$sideband'.10.model.fits'
            clean map=$target'.'$track'.'$rx'.'$sideband'.dirty' \
                beam=$target'.'$track'.'$rx'.'$sideband'.beam' \
                out=$target'.'$track'.'$rx'.'$sideband'.10.model' cutoff=0.01 niters=10
            fits in=$target'.'$track'.'$rx'.'$sideband'.10.model' op=xyout out=$target'.'$track'.'$rx'.'$sideband'.10.model.fits'

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
            invert vis=$vis'.sel' \
		options=systemp,mfs,double robust=2.0 select='source('$target')'\
                map=$target'.'$track'.'$rx'.'$sideband'.sel.dirty' \
                beam=$target'.'$track'.'$rx'.'$sideband'.sel.beam' cell=$cellsize imsize=$imsize

            rm -rf $target'.'$track'.'$rx'.'$sideband'.sel.dirty.fits'
            rm -rf $target'.'$track'.'$rx'.'$sideband'.sel.beam.fits'
            fits in=$target'.'$track'.'$rx'.'$sideband'.sel.dirty' op=xyout out=$target'.'$track'.'$rx'.'$sideband'.sel.dirty.fits'
            fits in=$target'.'$track'.'$rx'.'$sideband'.sel.beam' op=xyout out=$target'.'$track'.'$rx'.'$sideband'.sel.beam.fits'

            rm -rf $target'.'$track'.'$rx'.'$sideband'.sel.10.model'
            rm -rf $target'.'$track'.'$rx'.'$sideband'.sel.10.model.fits'
            clean map=$target'.'$track'.'$rx'.'$sideband'.sel.dirty' \
                beam=$target'.'$track'.'$rx'.'$sideband'.sel.beam' \
                out=$target'.'$track'.'$rx'.'$sideband'.sel.10.model' cutoff=0.01 niters=10 options=positive
            fits in=$target'.'$track'.'$rx'.'$sideband'.sel.10.model' op=xyout out=$target'.'$track'.'$rx'.'$sideband'.sel.10.model.fits'

            rm -rf $target'.'$track'.'$rx'.'$sideband'.sel.residual'
            rm -rf $target'.'$track'.'$rx'.'$sideband'.sel.residual.fits'
            restor map=$target'.'$track'.'$rx'.'$sideband'.sel.dirty' \
                beam=$target'.'$track'.'$rx'.'$sideband'.sel.beam' \
                model=$target'.'$track'.'$rx'.'$sideband'.sel.10.model'\
                mode=residual out=$target'.'$track'.'$rx'.'$sideband'.sel.residual'
            fits in=$target'.'$track'.'$rx'.'$sideband'.sel.residual' op=xyout out=$target'.'$track'.'$rx'.'$sideband'.sel.residual.fits'

            output=$(python get_rms.sel.py  $rx  $sideband  $target $track)
            IFS='   ' read -r -a array <<< "$output"
            cut=$(bc -l <<< "${array[0]}*1.5")
            rms=${array[0]}
            echo "The obtained rms for $target is ${array[0]} Jy/beam"
            box=${array[1]}','${array[2]}','${array[3]}','${array[4]}
            echo 'boxes('${array[1]}','${array[2]}','${array[3]}','${array[4]}')'

            rm -rf $target'.'$track'.'$rx'.'$sideband'.sel.dirty'
            rm -rf $target'.'$track'.'$rx'.'$sideband'.sel.beam'
            invert vis=$vis'.sel' \
                options=systemp,mfs,double robust=2.0 select='source('$target')'\
                map=$target'.'$track'.'$rx'.'$sideband'.sel.dirty' \
                beam=$target'.'$track'.'$rx'.'$sideband'.sel.beam' cell=$cellsize imsize=$imsize

            rm -rf $target'.'$track'.'$rx'.'$sideband'.sel.dirty.fits'
            rm -rf $target'.'$track'.'$rx'.'$sideband'.sel.beam.fits'
            fits in=$target'.'$track'.'$rx'.'$sideband'.sel.dirty' op=xyout out=$target'.'$track'.'$rx'.'$sideband'.sel.dirty.fits'
            fits in=$target'.'$track'.'$rx'.'$sideband'.sel.beam' op=xyout out=$target'.'$track'.'$rx'.'$sideband'.sel.beam.fits'

            rm -rf $target'.'$track'.'$rx'.'$sideband'.sel.10.model'
            rm -rf $target'.'$track'.'$rx'.'$sideband'.sel.10.model.fits'
            clean map=$target'.'$track'.'$rx'.'$sideband'.sel.dirty' \
                beam=$target'.'$track'.'$rx'.'$sideband'.sel.beam' \
                out=$target'.'$track'.'$rx'.'$sideband'.sel.10.model' cutoff=0.01 niters=10 options=positive \
                region='boxes('${array[1]}','${array[2]}','${array[3]}','${array[4]}')'
            fits in=$target'.'$track'.'$rx'.'$sideband'.sel.10.model' op=xyout out=$target'.'$track'.'$rx'.'$sideband'.sel.10.model.fits'

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

        # collecting self-calibrated visibilities into a folder
        mv *.sel ./selcal_Miriad

        # collecting solution tables into the folder
        mv *.gain ./selcal_Miriad
        mv *.gain.txt ./selcal_Miriad

      done
    done
done

