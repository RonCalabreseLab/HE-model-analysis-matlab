# Custom settings for PACE before executing MOAB script
#PBS -q tardis-6
#PBS -l nodes=1:ppn=64
#PBS -l pmem=1gb,mem=64gb
#PBS -l walltime=10:00:00
#PBS -j oe
#PBS -o Matlab.output.$PBS_JOBID

# Change to workdir
cd $PBS_O_WORKDIR 

exec ~/work/brute-scripts/pbs_scripts/pbs_matlab.sh
