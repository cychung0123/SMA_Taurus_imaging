targets='FM_Tau  CW_Tau  04113+2758  CY_Tau  DD_Tau  V892_Tau  BP_Tau  CoKu_Tau_1  RY_Tau  DE_Tau  IP_Tau  FT_Tau  FV_Tau  DH_Tau  IQ_Tau  DK_Tau  UZ_Tau  DL_Tau  GK_Tau  AA_Tau  LkCa_15  CI_Tau  04278+2253  T_Tau  UX_Tau  V710_Tau  DM_Tau  DQ_Tau  Haro_6-37  DR_Tau  FY_Tau  HO_Tau  DN_Tau  DO_Tau  HV_Tau  IC_2087_IR  CIDA-7  GO_Tau  DS_Tau  UY_Aur  Haro_6-39  GM_Aur  AB_Aur  SU_Aur  RW_Aur  CIDA-9  V836_Tau'
tracks='track1 track2'
rxs='rx230 rx240'
sidebands='lsb usb'

refant='6'

# creating a directory to host self-calibrated data
#rm -rf selcal_Miriad
#mkdir selcal_Miriad

#rm -rf *.model
#rm -rf *.txt
#rm -rf *.sel
#rm -rf *.gain
#rm -rf *rx*
#cp ../../imaging_com/center_track456.txt .

# looping over observations on varios target sources
for track in $tracks
do
  for rx in $rxs
  do

    # set reference antenna and solution interval
    if [ $track = 'track1' ]
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

    for sideband in $sidebands
    do

      for target in $targets
      do
        datadir='../../calibrated_Miriad/'$track'/'
        imdir='../../imaging_box/ch0/'$track'/'
	
	# copy over visibility data
        vis=$target'_'$track'.'$rx'.'$sideband'.cal.miriad'
        cp -r $datadir$vis ./
	uvflag vis=$vis edge=64,64,0 flagval="f"

	model=$target'.'$track'.'$rx'.'$sideband'.10.model'
	cp -r $imdir$model ./

        # copy over image model
#        model=$target'.rx345.usb.model'
#        cp -r ../v2022Aug03/$model ./

        # convert to Stokes I data
        rm -rf $vis'.i'
        uvaver vis=$vis options=nopass,nocal,nopol out=$vis'.i' stokes=ii
 
        # produce ascii output for the self-calibration solution
        gaintable=$target'_'$track'.'$rx'.'$sideband'.1p.gain'
        rm -rf $gaintable
        int='0.1'
        selfcal vis=$vis'.i' model=$model \
                out=$gaintable \
                options='pha,mfs' \
                interval=$interval refant=$refant


        # perform gain self-claibration solution
        selfcal vis=$vis'.i' model=$model \
                options='pha,mfs' \
                interval=$interval refant=$refant
 

        # inspecting the solution and yield ascii output for solution table
        rm -rf $gaintable'.txt'
        gpplt vis=$gaintable yaxis=phase nxy=1,1 log=$gaintable'.txt' # device=/xw

        # apply calibration solution
        rm -rf $vis'.sel'
        uvaver vis=$vis'.i' options=nopass,nopol out=$vis'.sel'
	

        rm -rf $vis
        cp -r $datadir$vis ./
        uvflag vis=$vis edge=64,64,0 flagval="f"

        # creating non-self-calibrated image
        rm -rf $target'.'$track'.'$rx'.'$sideband'.dirty'
        rm -rf $target'.'$track'.'$rx'.'$sideband'.beam'
        invert vis=$target'_'$track'.'$rx'.'$sideband'.cal.miriad' \
                options=systemp,mfs,double robust=2.0 \
                map=$target'.'$track'.'$rx'.'$sideband'.dirty' \
                beam=$target'.'$track'.'$rx'.'$sideband'.beam' cell=$cellsize imsize=$imsize
#		select='uvrange(0,80)'

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
        invert vis=$target'_'$track'.'$rx'.'$sideband'.cal.miriad.sel' \
		options=systemp,mfs,double robust=2.0 \
		map=$target'.'$track'.'$rx'.'$sideband'.sel.dirty' \
	       	beam=$target'.'$track'.'$rx'.'$sideband'.sel.beam' cell=$cellsize imsize=$imsize
#		select='uvrange(0,80)'

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

	rm -rf $target'.'$track'.'$rx'.'$sideband'.sel.clean'
        rm -rf $target'.'$track'.'$rx'.'$sideband'.sel.clean.fits'
        restor map=$target'.'$track'.'$rx'.'$sideband'.sel.dirty' \
                beam=$target'.'$track'.'$rx'.'$sideband'.sel.beam' \
                model=$target'.'$track'.'$rx'.'$sideband'.sel.10.model' \
                mode=clean out=$target'.'$track'.'$rx'.'$sideband'.sel.clean'
        fits in=$target'.'$track'.'$rx'.'$sideband'.sel.clean' op=xyout out=$target'.'$track'.'$rx'.'$sideband'.sel.clean.fits'

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
        invert vis=$target'_'$track'.'$rx'.'$sideband'.cal.miriad.sel' \
                options=systemp,mfs,double robust=2.0 \
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



        # collecting self-calibrated visibilities into a folder
        mv *.sel ./selcal_Miriad

        # collecting solution tables into the folder
        mv *.gain ./selcal_Miriad
        mv *.gain.txt ./selcal_Miriad

      done
    done
  done
done

echo $(python plot_SED.py)
