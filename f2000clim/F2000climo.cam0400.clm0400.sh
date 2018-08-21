case=F2000climo.cam0400.clm0400
run_time=12:00:00
queue=regular
account=UCLA0022

## ====================================================================
#   Define case and directories
## ====================================================================

export CASE=$case
export COMPSET=F2000climo
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

./xmlchange STOP_OPTION=nyears,STOP_N=5
./xmlchange --subgroup case.run JOB_WALLCLOCK_TIME=12:00:00
./xmlchange --subgroup case.st_archive JOB_WALLCLOCK_TIME=00:20:00

#./xmlchange --file env_run.xml --id RESUBMIT --val 1

### NOTES
# To continue run, uncomment lines below

#./xmlchange --file env_run.xml --id CONTINUE_RUN --val TRUE
#./xmlchange --file env_run.xml --id STOP_N --val 10

#------------------------------------
## Change to have daily output
#------------------------------------

# cd $CASEROOT
# cat <<EOF >>user_nl_cam
# nhtfrq = -24
# inithist = 'ENDOFRUN'
# EOF

# cat <<EOF >>user_nl_clm
# hist_nhtfrq = -24
# EOF

#------------------------------------
## Modify co2 value in atmosphere
#------------------------------------

# cd $CASEROOT
# cat <<EOF >>user_nl_cam
# co2vmr = 400.e-6
# EOF

## to add in a random perturbation, change 1.e-14 to 2.e, 3.e, etc.
#cat <<EOF >>user_nl_cam
#pertlim = 1.e-14
#EOF

#------------------------------------
## Modify co2 value in land
#------------------------------------

# cd $CASEROOT
# 
# ./xmlchange --file env_run.xml --id CCSM_CO2_PPMV --val 400.0
# ./xmlchange --file env_run.xml --id CLM_CO2_TYPE --val "constant"
# ./xmlchange --file env_run.xml --id RUN_STARTDATE --val "0001-03-20"

#------------------------------------
## Edit .run file to have correct run_time
#------------------------------------

# sed -i "s/^#PBS -l walltime=.*/#PBS -l walltime="$run_time"/" $CASE.run
# 
# sed -i '8 a #PBS -m abe' $CASE.run
# sed -i '9 a #PBS -M blangenb@uci.edu' $CASE.run

#------------------------------------
## Mess with orbital parameters
#------------------------------------

# see http://www.cesm.ucar.edu/models/paleo/faq/
# note by changing user_nl_cpl variables, you're affecting drv_in

# http://www.cesm.ucar.edu/models/cesm1.1/cesm/doc/usersguide/c1128.html --> on drv_in / user_nl_cpl
# http://www.cesm.ucar.edu/models/cesm1.2/cesm/doc/modelnl/nl_drv.html

# cd $CASEROOT
# cat <<EOF >>user_nl_cpl
# orb_mode = 'fixed_parameters'
# orb_mvelp = 0.
# orb_eccen = 0.
# orb_obliq = 0.
# EOF

#------------------------------------
## Build and run
#------------------------------------

cd $CASEROOT

#./$CASE.build

qcmd -- ./case.build

# case build fails, because of some ncoupling value
# /glade/p/work/baird/my_cesm_sandbox/components/mosart//cime_config/buildnml
# change coupling_period = basedt / mosart_ncpl
# to     coupling_period = basedt // mosart_ncpl

./case.submit -M begin,end

# case submit fails because mpiprocs is 12.0 instead of 12 (must be integer)
# change that in .case.run:

sed -i "s/^#PBS  -l select=96:ncpus=36:mpiprocs=12.0:ompthreads=3/#PBS  -l select=96:ncpus=36:mpiprocs=12:ompthreads=3/" $CASE.run