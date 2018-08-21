case=FEQUINOXNOCROP.cam0367.clm0367
run_time=12:00:00
queue=regular
account=UCLA0022

## ====================================================================
#   Define case and directories
## ====================================================================

export CASE=$case
export COMPSET=FEQUINOXNOCROP
export CASERES=f09_f09_mg17
export PROJECT=$account
export ACCOUNT=$account
export MACH=cheyenne
export CESMROOT=/glade2/work/baird/cesm2_models/cesm2_0_0/cime
export CASEROOT=/glade2/work/baird/cesm200_cases/$CASE

#export CESMTAG=cesm2_0_0
#export SOURCE_MODS_DIR=/glade/u/home/baird/PPE_source_mods/$CESMTAG/$parameter_values
#mkdir -p $SOURCE_MODS_DIR # if the case doesn't exist, it will still create the dir, and the model will run with default settings

## ====================================================================
#   Create new case, configure, compile and, run
## ====================================================================

rm -rf $CASEROOT 
#rm -rf $PTMP/$CASE

#------------------------------------
## Create new case
#------------------------------------

cd $CESMROOT/scripts

./create_newcase --case $CASEROOT --mach $MACH --res $CASERES --compset $COMPSET

#------------------------------------
## Change processor layout (too slow by default)
#------------------------------------

# cd $CASEROOT
# 
# ./xmlchange --file env_mach_pes.xml --id NTASKS_ATM --val 128
# ./xmlchange --file env_mach_pes.xml --id NTHRDS_ATM --val 2
# 
# ./xmlchange --file env_mach_pes.xml --id NTASKS_LND --val 128
# ./xmlchange --file env_mach_pes.xml --id NTHRDS_LND --val 2
# 
# ./xmlchange --file env_mach_pes.xml --id NTASKS_OCN --val 128
# ./xmlchange --file env_mach_pes.xml --id NTHRDS_OCN --val 2

#------------------------------------
## Set up case
#------------------------------------

cd $CASEROOT
./case.setup

#------------------------------------
## Set environment
#------------------------------------

cd $CASEROOT

./xmlchange STOP_OPTION=nyears,STOP_N=1
./xmlchange --subgroup case.run JOB_WALLCLOCK_TIME=12:00:00

#./xmlchange RUN_REFDATE=2000-01-01

#./xmlchange --file env_run.xml --id RESUBMIT --val 1
#./xmlchange --file env_run.xml --id CONTINUE_RUN --val TRUE
#./xmlchange --file env_run.xml --id STOP_N --val 10

#------------------------------------
## Change to have daily output
#------------------------------------

cd $CASEROOT
cat <<EOF >>user_nl_cam
nhtfrq = -24
inithist = 'ENDOFRUN'
EOF

cat <<EOF >>user_nl_clm
hist_nhtfrq = -24
EOF

#------------------------------------
## Set equinox conditions
#------------------------------------

cd $CASEROOT
cat <<EOF >>user_nl_cpl
orb_mode = 'fixed_parameters'
orb_mvelp = 0.
orb_eccen = 0.
orb_obliq = 0.
EOF

#------------------------------------
## Modify co2 value in land
#------------------------------------

cd $CASEROOT

#./xmlchange CCSM_CO2_PPMV=1468.0
./xmlchange CLM_CO2_TYPE=constant

#------------------------------------
## Modify co2 value in atmosphere
#------------------------------------

#cd $CASEROOT
#cat <<EOF >>user_nl_cam
#co2vmr = 367.0e-6
#EOF

## to add in a random perturbation, change 1.e-14 to 2.e, 3.e, etc.
#cat <<EOF >>user_nl_cam
#pertlim = 1.e-14
#EOF

#------------------------------------
## Build and submit
#------------------------------------

cd $CASEROOT
qcmd -- ./case.build

# case build fails, because of some ncoupling value
# /glade/p/work/baird/cesm2_models/cesm2_0_0/components/mosart//cime_config/buildnml
# change coupling_period = basedt / mosart_ncpl
# to     coupling_period = basedt // mosart_ncpl

./case.submit -M begin,end

# case submit fails because mpiprocs is 12.0 instead of 12 (must be integer)
# change that in .case.run:

# sed -i "s/^#PBS  -l select=96:ncpus=36:mpiprocs=12.0:ompthreads=3/#PBS  -l select=96:ncpus=36:mpiprocs=12:ompthreads=3/" .case.run