config="com"
flagval="f"

targets='FM_Tau  CW_Tau  04113+2758  CY_Tau  DD_Tau  V892_Tau  BP_Tau  CoKu_Tau_1  RY_Tau  DE_Tau  IP_Tau  FT_Tau  FV_Tau  DH_Tau  IQ_Tau  DK_Tau  UZ_Tau  DL_Tau  GK_Tau  AA_Tau  LkCa_15  CI_Tau  04278+2253  T_Tau  UX_Tau  V710_Tau  DM_Tau  DQ_Tau  Haro_6-37  DR_Tau  FY_Tau  HO_Tau  DN_Tau  DO_Tau  HV_Tau  IC_2087_IR  CIDA-7  GO_Tau  DS_Tau  UY_Aur  Haro_6-39  GM_Aur  AB_Aur  SU_Aur  RW_Aur  CIDA-9  V836_Tau'
tracks='track4 track5 track6'
sidebands='lsb usb'
rxs='rx345 rx400'

rm -rf *.txt
rm -rf *.rx*
rm -rf ch0
mkdir ch0


cd ch0/
rm -rf track456
mkdir track456
cd ../
  
for target in $targets
do

     for rx in $rxs
     do
	for sideband in $sidebands
	do
	  for track in $tracks
	  do
		datadir='../calibrated_Miriad/'$track'/'
		vis=$target'_'$track'.'$rx'.'$sideband'.cal.miriad'
		cp -r $datadir$vis ./
		uvflag vis=$target'_'$track'.'$rx'.'$sideband'.cal.miriad' edge=64,64,0 flagval=$flagval
	  done

	  vis=$target'_track4.'$rx'.'$sideband'.cal.miriad,'$target'_track5.'$rx'.'$sideband'.cal.miriad,'$target'_track6.'$rx'.'$sideband'.cal.miriad'

	  rm -rf $target'.'$rx'.'$sideband'.dirty'
	  rm -rf $target'.'$rx'.'$sideband'.beam'
	  invert vis=$vis options=systemp,mfs,double robust=2.0 map=$target'.'$rx'.'$sideband'.dirty' beam=$target'.'$rx'.'$sideband'.beam' cell=0.25 imsize=256
	  rm -rf $target'.'$rx'.'$sideband'.dirty.fits'
	  rm -rf $target'.'$rx'.'$sideband'.beam.fits'
	  fits in=$target'.'$rx'.'$sideband'.dirty' op=xyout out=$target'.'$rx'.'$sideband'.dirty.fits'
	  fits in=$target'.'$rx'.'$sideband'.beam' op=xyout out=$target'.'$rx'.'$sideband'.beam.fits'
	  

          # deconvolve image
	  rm -rf $target'.'$rx'.'$sideband'.model'
	  rm -rf $target'.'$rx'.'$sideband'.model.fits'
	  clean map=$target'.'$rx'.'$sideband'.dirty' beam=$target'.'$rx'.'$sideband'.beam' out=$target'.'$rx'.'$sideband'.model' cutoff=0.001 niters=10
	  fits in=$target'.'$rx'.'$sideband'.model' op=xyout out=$target'.'$rx'.'$sideband'.model.fits'

	  rm -rf $target'.'$rx'.'$sideband'.residual'
          rm -rf $target'.'$rx'.'$sideband'.residual.fits'
          restor map=$target'.'$rx'.'$sideband'.dirty' beam=$target'.'$rx'.'$sideband'.beam' model=$target'.'$rx'.'$sideband'.model' mode=residual out=$target'.'$rx'.'$sideband'.residual'
          fits in=$target'.'$rx'.'$sideband'.residual' op=xyout out=$target'.'$rx'.'$sideband'.residual.fits'

	  rms=$(python get_rms.py  $rx  $sideband  $target $track)
	  echo "The obtained rms for $target is $rms Jy/beam"
	  
	  rm -rf $target'.'$rx'.'$sideband'.model'
	  rm -rf $target'.'$rx'.'$sideband'.model.fits'
	  clean map=$target'.'$rx'.'$sideband'.dirty' beam=$target'.'$rx'.'$sideband'.beam' out=$target'.'$rx'.'$sideband'.model' cutoff=$rms*3 niters=1000
	  fits in=$target'.'$rx'.'$sideband'.model' op=xyout out=$target'.'$rx'.'$sideband'.model.fits'
	  
	  # restore image
	  rm -rf $target'.'$rx'.'$sideband'.clean'
	  rm -rf $target'.'$rx'.'$sideband'.clean.fits'
	  restor map=$target'.'$rx'.'$sideband'.dirty' beam=$target'.'$rx'.'$sideband'.beam' model=$target'.'$rx'.'$sideband'.model' mode=clean out=$target'.'$rx'.'$sideband'.clean'
	  fits in=$target'.'$rx'.'$sideband'.clean' op=xyout out=$target'.'$rx'.'$sideband'.clean.fits'
       
	  rm -rf $target'.'$rx'.'$sideband'.residual'
	  rm -rf $target'.'$rx'.'$sideband'.residual.fits'
	  restor map=$target'.'$rx'.'$sideband'.dirty' beam=$target'.'$rx'.'$sideband'.beam' model=$target'.'$rx'.'$sideband'.model' mode=residual out=$target'.'$rx'.'$sideband'.residual'
	  fits in=$target'.'$rx'.'$sideband'.residual' op=xyout out=$target'.'$rx'.'$sideband'.residual.fits'
       
	  rm -rf $target'.'$rx'.'$sideband'.clean.pbcor'
	  rm -rf $target'.'$rx'.'$sideband'.clean.pbcor.fits'
	  linmos in=$target'.'$rx'.'$sideband'.clean' out=$target'.'$rx'.'$sideband'.clean.pbcor'
	  fits in=$target'.'$rx'.'$sideband'.clean.pbcor' op=xyout out=$target'.'$rx'.'$sideband'.clean.pbcor.fits'

	  mv *.beam ./ch0/track456
	  mv *.model ./ch0/track456
	  mv *.clean ./ch0/track456
	  mv *.pbcor ./ch0/track456
	  mv *.dirty ./ch0/track456
	  mv *.residual ./ch0/track456
	  mv *.fits ./ch0/track456
	  rm -rf *.miriad

        done
     done

done

