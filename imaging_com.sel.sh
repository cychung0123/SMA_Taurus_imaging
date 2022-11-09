config="com"
flagval="f"

targets='FM_Tau  CW_Tau  04113+2758  CY_Tau  DD_Tau  V892_Tau  BP_Tau  CoKu_Tau_1  RY_Tau  DE_Tau  IP_Tau  FT_Tau  FV_Tau  DH_Tau  IQ_Tau  DK_Tau  UZ_Tau  DL_Tau  GK_Tau  AA_Tau  LkCa_15  CI_Tau  04278+2253  T_Tau  UX_Tau  V710_Tau  DM_Tau  DQ_Tau  Haro_6-37  DR_Tau  FY_Tau  HO_Tau  DN_Tau  DO_Tau  HV_Tau  IC_2087_IR  CIDA-7  GO_Tau  DS_Tau  UY_Aur  Haro_6-39  GM_Aur  AB_Aur  SU_Aur  RW_Aur  CIDA-9  V836_Tau'
tracks='track4 track5 track6'
sidebands='lsb usb'
rxs='rx345 rx400'

#rm -rf *.txt
rm -rf *.rx*
#rm -rf ch0
#mkdir ch0



cd ch0/
dir='track456_sel'
rm -rf $dir
mkdir $dir
cd ../
  
for rx in $rxs
do

     for sideband in $sidebands
     do
	for target in $targets
	do
	
	  for track in $tracks
	  do
		datadir='../selcal_Miriad/'
		vis=$target'_'$track'.'$rx'.'$sideband'.cal.miriad.sel'
		cp -r $datadir$vis ./
		uvflag vis=$vis edge=64,64,0 flagval=$flagval
	  done

	  cellsize=0.25
	  imsize=256

	  vis=$target'_track4.'$rx'.'$sideband'.cal.miriad.sel,'$target'_track5.'$rx'.'$sideband'.cal.miriad.sel,'$target'_track6.'$rx'.'$sideband'.cal.miriad.sel'

	  rm -rf $target'.'$rx'.'$sideband'.sel.dirty'
	  rm -rf $target'.'$rx'.'$sideband'.sel.beam'
	  invert vis=$vis options=systemp,mfs,double robust=2.0 map=$target'.'$rx'.'$sideband'.sel.dirty' beam=$target'.'$rx'.'$sideband'.sel.beam' cell=$cellsize imsize=$imsize
	  rm -rf $target'.'$rx'.'$sideband'.sel.dirty.fits'
	  rm -rf $target'.'$rx'.'$sideband'.sel.beam.fits'
	  fits in=$target'.'$rx'.'$sideband'.sel.dirty' op=xyout out=$target'.'$rx'.'$sideband'.sel.dirty.fits'
	  fits in=$target'.'$rx'.'$sideband'.sel.beam' op=xyout out=$target'.'$rx'.'$sideband'.sel.beam.fits'
	  

          # deconvolve image
	  rm -rf $target'.'$rx'.'$sideband'.sel.model'
	  rm -rf $target'.'$rx'.'$sideband'.sel.model.fits'
	  clean map=$target'.'$rx'.'$sideband'.sel.dirty' beam=$target'.'$rx'.'$sideband'.sel.beam' out=$target'.'$rx'.'$sideband'.sel.model' cutoff=0.001 niters=10
	  fits in=$target'.'$rx'.'$sideband'.sel.model' op=xyout out=$target'.'$rx'.'$sideband'.sel.model.fits'

	  rm -rf $target'.'$rx'.'$sideband'.sel.residual'
          rm -rf $target'.'$rx'.'$sideband'.sel.residual.fits'
          restor map=$target'.'$rx'.'$sideband'.sel.dirty' beam=$target'.'$rx'.'$sideband'.sel.beam' model=$target'.'$rx'.'$sideband'.sel.model' mode=residual out=$target'.'$rx'.'$sideband'.sel.residual'
          fits in=$target'.'$rx'.'$sideband'.sel.residual' op=xyout out=$target'.'$rx'.'$sideband'.sel.residual.fits'
	  
	  
	  output=$(python get_rms.sel.py  $rx  $sideband  $target $track)
	  IFS='   ' read -r -a array <<< "$output"
	  rms=${array[0]}
	  cut=$(bc -l <<< "${array[0]}*1.5")
	  echo "The obtained rms for $target is ${array[0]} Jy/beam"
	  box=${array[1]}','${array[2]}','${array[3]}','${array[4]}
	  echo 'boxes('${array[1]}','${array[2]}','${array[3]}','${array[4]}')'

	  rm -rf $target'.'$rx'.'$sideband'.sel.model'
	  rm -rf $target'.'$rx'.'$sideband'.sel.model.fits'
	  clean map=$target'.'$rx'.'$sideband'.sel.dirty' beam=$target'.'$rx'.'$sideband'.sel.beam' out=$target'.'$rx'.'$sideband'.sel.model' cutoff=$cut niters=1000 region='boxes('${array[1]}','${array[2]}','${array[3]}','${array[4]}')' options=positive
	  fits in=$target'.'$rx'.'$sideband'.sel.model' op=xyout out=$target'.'$rx'.'$sideband'.sel.model.fits'
	  
	  # restore image
	  rm -rf $target'.'$rx'.'$sideband'.sel.clean'
	  rm -rf $target'.'$rx'.'$sideband'.sel.clean.fits'
	  restor map=$target'.'$rx'.'$sideband'.sel.dirty' beam=$target'.'$rx'.'$sideband'.sel.beam' model=$target'.'$rx'.'$sideband'.sel.model' mode=clean out=$target'.'$rx'.'$sideband'.sel.clean'
	  fits in=$target'.'$rx'.'$sideband'.sel.clean' op=xyout out=$target'.'$rx'.'$sideband'.sel.clean.fits'
       
	  rm -rf $target'.'$rx'.'$sideband'.sel.residual'
	  rm -rf $target'.'$rx'.'$sideband'.sel.residual.fits'
	  restor map=$target'.'$rx'.'$sideband'.sel.dirty' beam=$target'.'$rx'.'$sideband'.sel.beam' model=$target'.'$rx'.'$sideband'.sel.model' mode=residual out=$target'.'$rx'.'$sideband'.sel.residual'
	  fits in=$target'.'$rx'.'$sideband'.sel.residual' op=xyout out=$target'.'$rx'.'$sideband'.sel.residual.fits'
       
	  rm -rf $target'.'$rx'.'$sideband'.sel.clean.pbcor'
	  rm -rf $target'.'$rx'.'$sideband'.sel.clean.pbcor.fits'
	  linmos in=$target'.'$rx'.'$sideband'.sel.clean' out=$target'.'$rx'.'$sideband'.sel.clean.pbcor'
	  fits in=$target'.'$rx'.'$sideband'.sel.clean.pbcor' op=xyout out=$target'.'$rx'.'$sideband'.sel.clean.pbcor.fits'

          output=$(python flux_measure.sel.py  $rx  $sideband  $target $track $box $rms)
          IFS='   ' read -r -a array <<< "$output"
	  echo "The peak flux of clean map is ${array[0]} mJy/beam"
          echo "The fitted 2D Gaussian component has major and minor FWHM ${array[1]} arcsec and ${array[2]} arcsec"
          echo "The integrated flux density is ${array[3]} mJy"


	  mv *.beam ./ch0/$dir
	  mv *.model ./ch0/$dir
	  mv *.clean ./ch0/$dir
	  mv *.pbcor ./ch0/$dir
	  mv *.dirty ./ch0/$dir
	  mv *.residual ./ch0/$dir
	  mv *.fits ./ch0/$dir
	  rm -rf *.miriad.sel

        done
     done
done

