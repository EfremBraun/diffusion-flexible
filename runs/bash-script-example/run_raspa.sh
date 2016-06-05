#$ -S /bin/sh
#$ -cwd
#$ -q all*

# Email at beginning and end of job.
#$ -m e
#$ -M efrem.braun@berkeley.edu 

# User set variables

# Set the location within your home directory of your 
# RASPA data directory. The directory you set in this 
# variable should contain the share directory.

export RASPA_DIR=${HOME}/bin/raspa-install/


# Setup the jobs directory. Please provide the location
# within your home directory of the jobs directory. This
# directory will contain symlinks to the directories
# where your simulations were launched, identified by 
# job ID and description field.

JOBSDIR=jobs

#
#
#
# MOST LIKELY DON'T NEED TO MAKE ANY CHANGES BELOW THIS POINT
#
#
#

# Test for jobs directory. If not available, create it.

if [ ! -d ${HOME}/${JOBSDIR} ]; then
    mkdir ${HOME}/${JOBSDIR}
fi
if [ ! -d ${HOME}/${JOBSDIR}/running ]; then
    mkdir ${HOME}/${JOBSDIR}/running
fi
if [ ! -d ${HOME}/${JOBSDIR}/completed ]; then
    mkdir ${HOME}/${JOBSDIR}/completed
fi
if [ ! -e ${HOME}/${JOBSDIR}/jobs.log ]; then
    touch ${HOME}/${JOBSDIR}/jobs.log
fi

# Record the current location.
CURDIR=`pwd`

TIMESTAMP=`date '+%m-%d-%y %H:%M:%S'`

# Determine whether the restart directory should be set as the inital configuration
RESTARTFLAG=`awk '/RestartFile/ {print $2}' simulation.input`

if [ "${RESTARTFLAG}" == "yes" ]
then
    mv Restart RestartInitial
fi

# Link to the running jobs directory

ln -s "${CURDIR}" ${HOME}/${JOBSDIR}/running/${JOB_ID}-${JOB_NAME}

echo "${TIMESTAMP} [SGE] Job ${JOB_ID}: ${JOB_NAME} started on ${HOSTNAME}" >> ${HOME}/${JOBSDIR}/jobs.log

# Run the simulation
${RASPA_DIR}/bin/simulate

ENDTIME=`date '+%m-%d-%y %H:%M:%S'`

echo "${ENDTIME} [SGE] Job ${JOB_ID}: ${JOB_NAME} completed" >> ${HOME}/${JOBSDIR}/jobs.log

rm -f ${HOME}/${JOBSDIR}/running/${JOB_ID}-${JOB_NAME}
ln -s "${CURDIR}" ${HOME}/${JOBSDIR}/completed/${JOB_ID}-${JOB_NAME}

