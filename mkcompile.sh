#!/bin/bash

# Where are we?
PTH=`echo $0 | awk -F "/" '{ s="" ; for(i=1;i<NF;i++){ if(i==1){ s=$i; } else { s=s"/"$i; } } printf "%s",s; }'`
echo "path is $PTH"

CFGFILE=$PTH/config

if [ -r $CFGFILE ]; then
    source $CFGFILE
else
    WORK_ROOT=/usr/work
    INSTALL_PREFIX=/usr
    ARCH_DIR=$WORK_ROOT/archive
    REPO_DIR=$WORK_ROOT/repo
    JOBS=8
    NO_SCM=0
fi

# Toolchain-specific variables
TOOLCHAIN=""
TOOLCHAINS=""
USE_TOOLCHAIN=0
TOOLCHAIN_BUILT=0
CC=""
CXX=""
CPP=""
CFLAGS=""
CPPFLAGS=""
CXXFLAGS=""
LD=""
LDFLAGS=""

DEP_BUILT=""
REINIT_LIST=""
MOD_LIST=""
TARGET_LIST=""
TEMPORARY_LIST=""
BUILD_TARGET_MODULE=""
MODULE_RECURSIVE=0
IGNORE_TARGET=0
BLOCKED_MODULES=""
TRACE_RUN=0

if [ -d $ARCH_DIR ]; then
    echo "Work directory exists"
else
    mkdir -p $ARCH_DIR
fi

if [ -d ${WORK_ROOT}/logs ]; then
    echo "Log directory exists"
else
    mkdir -p ${WORK_ROOT}/logs
fi


if [ -d $REPO_DIR ]; then
    echo "Repo directory exists"
else
    mkdir -p $REPO_DIR
fi


mkdir -p ${WORK_ROOT}/build

# Usage: get_dependents <module_name> - it will return all the modules that are directly dependent on this very module
function get_dependents {
    local ON_WHAT=$1
    local XC=`echo " $ON_WHAT" | wc -c`
    if [ $XC -lt 3 ]; then
	echo ""
    fi
# so, the 1st argument is actually exists, we can go on
    local Z=""
    local DTMP=""
    local EN_COUNTER=0
    for i in $MOD_LIST; do
	DEPLIST_NAME=${i}_DEPENDENCIES
	DTMP=${!DEPLIST_NAME}
	DEP_COUNTER=`echo "$DTMP" | grep -c $ON_WHAT`
	if [ $DEP_COUNTER -gt 0 ]; then
	    # potential dependency found, checking enabled status
	    EN_COUNTER=`echo "$BLOCKED_MODULES" | grep -c $i`
	    if [ $EN_COUNTER -lt 1 ]; then
		# OK, module is enabled
		Z="$i $Z"
	    fi
	fi
    done
    echo $Z
}


# Usage: git_fetch <module_name> <git_scm_url>
function git_fetch {
    local GIT_URL=$2
    local FOLDER_PATH=$REPO_DIR/$1
    if [ -d $FOLDER_PATH ]; then
	if [ $NO_SCM -eq 0 ]; then
	    echo "[$1] SCM repo exists, updating"
	    cd $FOLDER_PATH
	    git pull
	fi
    else
	echo "[$1]: fetching from SCM"
	cd $REPO_DIR
	git clone $GIT_URL $1
    fi
}

# Usage: arch_fetch <module_name> <archive_url> <archive_file_name>
function arch_fetch {
    local ARCH_URL=$2
    local FILE_PATH=$ARCH_DIR/$3
    if [ -f $FILE_PATH ]; then
	echo "[$1] archive file exists"
    else
	echo "[$1] archive not found, fetching"
	cd $ARCH_DIR
	wget -O $3 $ARCH_URL
    fi
}

# Usage: git_extract <module_name>
function git_extract {
    local FOLDER_PATH=$REPO_DIR/$1
    if [ -d $FOLDER_PATH ]; then
	cd $FOLDER_PATH
	echo "[$1] Git SCM extract for $1 to $WORK_ROOT/build/$1/"
	git checkout-index -f -a --prefix=$WORK_ROOT/build/$1/
    else
	echo "[$1] No SCM repository exists, exiting!"
	exit 0
    fi
}

# Usage: arch_extract <module_name> <archive_file_name>
function arch_extract {
    local FILE_PATH=$ARCH_DIR/$2
    if [ -z $3 ]; then
	local DESTINATION=${WORK_ROOT}/build/$1
    else
	local DESTINATION=$3
    fi
    if [ -f $FILE_PATH ]; then
	echo "[$1] archive exists, extracting $2 to $DESTINATION"
	mkdir -p $DESTINATION
	tar xf $FILE_PATH -C $DESTINATION --strip-components=1 
    else
	echo "[$1] archive file $2 not found, exiting!"
	exit 0
    fi
}

# Usage: get_dependency_list <module_name> - it will return a string of modules needed to be built to compile your module
function get_dependency_list {
    local UNSATISFIED_DEPENDENCIES=""
    local MODULE_NAME=$1
    local DEPNAME=${MODULE_NAME}_DEPENDENCIES
    local DLC=`echo ${!DEPNAME}  | wc -c`
    if [ $DLC -lt 2 ]; then
	echo ""
    else
	# We have something to check up
	local CFLAG=0
	local MODDEPS=${MODULE_NAME}_DEPENDENCIES
	for i in ${!MODDEPS}; do
	    CFLAG=`echo "$DEP_BUILT" | grep -c $i`
	    if [ $CFLAG -lt 1 ]; then
		UNSATISFIED_DEPENDENCIES="$i $UNSATISFIED_DEPENDENCIES"
	    fi
	done
	echo $UNSATISFIED_DEPENDENCIES
    fi
}

# Get the module name that can be built right now
function get_build_candidate {
    local CANDIDATE=""
    local CANDIDATE_DEPENDENCIES=""
    local CDC=0
    local CDCN=0
    for i in $MOD_LIST; do
	CANDIDATE_DEPENDENCIES=$(get_dependency_list $i)
	CDC=`echo $CANDIDATE_DEPENDENCIES | wc -c`
	if [ $CDC -lt 2 ]; then
	    # Potential candidate is found, let's avoid a re-building loop
	    CDCN=`echo "$DEP_BUILT" | grep -c $i`
	    if [ $CDCN -lt 1 ]; then
		CANDIDATE=$i
	    fi
	fi
    done
    echo $CANDIDATE
}

# Usage: build_module_recursive <module_name> <previous_dependency_list> - second argument is for avoiding a deadlock inside a recursive loop
function build_module_recursive {
    local MODULE_NAME=$1
    local PREV_DEPLIST=$2
    local BUILD_FUNCTION=""
    local DEPLIST=""
    local DCNT=`echo "$DEP_BUILT" | grep -c $MODULE_NAME`
    if [ $DCNT -lt 1 ]; then
    # Module is not built yet
	local MDEPS=$(get_dependency_list $MODULE_NAME)
	local DCC=`echo $MDEPS | wc -c`
	if [ $DCC -gt 2 ]; then
	    # Module has unresolved dependencies
		build_available $MODULE_NAME
		DEPLIST=$(get_dependency_list $MODULE_NAME)
		DCC=`echo $DEPLIST | wc -c`
		if [ $DCC -gt 2 ]; then
		    # Loop deadlock check
		    if [ "$DEPLIST" == "$PREV_DEPLIST" ]; then
			echo "[$MODULE_NAME] Dependency deadlock detected : $DEPLIST Built $DEP_BUILT . Exiting"
			exit 0
		    else
			echo "[$MODULE_NAME][$DCNT][$BUILT_DEP] calling directly $BUILD_FUNCTION"
			build_module_recursive $MODULE_NAME "$DEPLIST"
		    fi
		else
		    BUILD_FUNCTION=${MODULE_NAME}_build
		    DCNT=`echo "$DEP_BUILT" | grep -c $MODULE_NAME`
		    if [ $DCNT -lt 1 ]; then
			echo "[$MODULE_NAME][$DCNT][$BUILT_DEP] calling directly $BUILD_FUNCTION due to an empty dependency list"
			$BUILD_FUNCTION $MODULE_NAME
			ldconfig
		    fi
		fi
	else
	    # Module has no further dependencies, so build it!
	    BUILD_FUNCTION=${MODULE_NAME}_build
	    echo "[$MODULE_NAME] calling directly $BUILD_FUNCTION"
	    $BUILD_FUNCTION $MODULE_NAME
	    ldconfig
	fi
    fi
}

# Usage: build_available <module_name> - it will build all the modules that have satisfied dependencies installed. It echoes the process info and status, so avoid it's usage in a functions that are returning values
function build_available {
    local WFLAG=0
    local BUILD_CANDIDATE=""
    local BUILD_COUNTER=0
    local BUILD_FUNCTION=""
    local MODULE_NAME=$1
    local EN_COUNTER=0

    while [ $WFLAG -lt 1 ]; do
	BUILD_CANDIDATE=$(get_build_candidate)
	BUILD_COUNTER=`echo $BUILD_CANDIDATE | wc -c`
	echo "Calling for build candidates: $BUILD_CANDIDATE $BUILD_COUNTER"
	if [ $BUILD_COUNTER -gt 2 ]; then
	    # this is non-empty module name, so it's probably needs to be built
	    BUILD_COUNTER=`echo "$DEP_BUILT" | grep -c $BUILD_CANDIDATE`
	    if [ $BUILD_COUNTER -lt 1 ]; then
		EN_COUNTER=`echo "$BLOCKED_MODULES" | grep -c $BUILD_CANDIDATE`
		if [ $EN_COUNTER -eq 0 ]; then
		    # Module is not built yet, so we need to build it
		    BUILD_FUNCTION=${BUILD_CANDIDATE}_build
		    echo "[$MODULE_NAME][$BUILD_COUNTER] calling $BUILD_FUNCTION Built list is [$DEP_BUILT]"
		    $BUILD_FUNCTION $BUILD_CANDIDATE
		fi
	    else
		echo "[$MODULE_NAME] discarding $BUILD_CANDIDATE because it's alredy been built"
	    fi
	else
	    WFLAG=1
	fi
    done
}

# Usage remove_from_list <list_name> <token>
function remove_from_list {
    local LIST_NAME=$1
    local TOKEN=$2
    local TMP_LIST=""
    local TMP_COPY=${!LIST_NAME}
    for i in $TMP_COPY ; do
	if [ "$i" == "$TOKEN" ]; then
	    echo "Excluding $TOKEN from $LIST_NAME list"
	else
	    TMP_LIST="$i $TMP_LIST"
	fi
    done
    eval $LIST_NAME="\"$TMP_LIST\""
}

# Usage: add_to_list <list_name> <token> - add a token to list avoiding duplicates
function add_to_list_helper {
    logger "adding $2 to $1"
    local LIST_NAME=$1
    local TOKEN=$2
    local FLAG=1
    local TMP_COPY=${!LIST_NAME}
    if [ -z "$TMP_COPY" ]; then
	eval $LIST_NAME="$TOKEN"
    else
	for i in $TMP_COPY ; do
	    if [ "$i" == "$TOKEN" ]; then
		FLAG=0
	    fi
	done
	if [ $FLAG -eq 1 ]; then
	    eval $LIST_NAME="\"$TMP_COPY $TOKEN\""
	fi
    fi
    echo "Adding+help $2 to $1 [${!LIST_NAME}] $FLAG" >> /tmp/addlog
    echo $FLAG
}

function add_to_list {
    local LIST_NAME=$1
    local TOKEN=$2
    local FLAG=1
    local TMP_COPY=${!LIST_NAME}
    if [ -z "$TMP_COPY" ]; then
	eval $LIST_NAME=$TOKEN
    else
	for i in $TMP_COPY ; do
	    if [ "$i" == "$TOKEN" ]; then
		FLAG=0
	    fi
	done
	if [ $FLAG -eq 1 ]; then
	    eval $LIST_NAME="\"$TMP_COPY $TOKEN\""
	fi
    fi
    echo "Adding $2 to $1 [${!LIST_NAME}]" >> /tmp/addlog
}

# Usage: get_dependents_recursive <module_name> - return all the modules that are hierarchically depend on this one
function get_dependents_recursive {
    local MODULE_NAME=$1
    local C=1
    local CT=0
    local CZ=0
    local XT=""

    local TEMPORARY_LIST=$(get_dependents $MODULE_NAME )
    echo "[$MODULE_NAME] TEMPORARY_LIST is $TEMPORARY_LIST " >> /tmp/recdep
    while [ $C -gt 0 ]; do
	CT=0
	for i in $TEMPORARY_LIST; do
	    XT=$(get_dependents $i )
	    echo "[$MODULE_NAME] $i : XT is $XT " >> /tmp/recdep
	    for j in $XT; do
		CZ=$(add_to_list_helper TEMPORARY_LIST $j)
		# CT=$(( $CT + $CZ ))
	    done
	    if [ $CZ -eq 0 ]; then
		C=0
	    else
		C=1
	    fi
	    echo "[$MODULE_NAME] $i : CT is $CT " >> /tmp/recdep
	done
	echo "[$MODULE_NAME] end for : TEMPORARY_LIST is $TEMPORARY_LIST " >> /tmp/recdep
    done
    echo $TEMPORARY_LIST
}

# Usage: init_module_by_name <module_name> - do module initialization
function init_module_by_name {
    local MODULE_NAME=$1

	INIT_FUNC=${MODULE_NAME}_init
	# Perform first-hand initialization process
	INIT_RESULT=$($INIT_FUNC $MODULE_NAME)
	echo "[$MODULE_NAME] init result $INIT_RESULT"
	if [ $INIT_RESULT -eq 1 ]; then
	    REINIT_LIST="$REINIT_LIST $MODULE_NAME"
	fi
	# fetch it
	INIT_FUNC=${MODULE_NAME}_fetch
	$INIT_FUNC $MODULE_NAME
	MOD_LIST="$MOD_LIST $MODULE_NAME"

}


# Making some preparations - scanning for module definitions in modules.d folder

if [ "$PTH" == "." ]; then
    MPATH=`pwd`/modules.d
    TPATH=`pwd`/targets.d
    CPATH=`pwd`/toolchains
    PTH=`pwd`
else
    MPATH="$PTH/modules.d"
    TPATH="$PTH/targets.d"
    CPATH="$PTH/toolchains"
fi

# Adding extensions support
if [ -d $PTH/extensions ]; then
    if [ -d $PTH/extensions/modules.d ]; then
	MPATH="$MPATH $PTH/extensions/modules.d"
    fi
    if [ -d $PTH/extensions/targets.d ]; then
	TPATH="$MPATH $PTH/extensions/targets.d"
    fi
    if [ -d $PTH/extensions/toolchains ]; then
	CPATH="$MPATH $PTH/extensions/toolchains"
    fi
fi

for TOOLCHAIN_SUBDIRS in $CPATH; do
    tlist=`ls -C -1 $TOOLCHAIN_SUBDIRS | grep .toolchain`
    for i in $tlist; do
	TOOLCHAIN_NAME=`echo $i | sed 's/\.toolchain//'`
	echo "toolchain name: $TOOLCHAIN_NAME file: $i "
	if [ "$TOOLCHAIN_NAME" == "target" ]; then
	    echo "\"module\" is a reserved word, not for toolchains!"
	    exit 0
	fi
	if [ "$TOOLCHAIN_NAME" == "target" ]; then
	    echo "\"target\" is a reserved word, not for toolchains!"
	    exit 0
	fi
	source $TOOLCHAIN_SUBDIRS/$i
	INIT_FUNC=${TOOLCHAIN_NAME}_lock
	$INIT_FUNC $TOOLCHAIN_NAME
	TOOLCHAINS="$TOOLCHAIN_NAME $TOOLCHAINS"
    done
done
echo "[general] Available toolchains are $TOOLCHAINS"

for MODULE_SUBDIRS in $MPATH; do
    modlist=`ls -C -1 $MODULE_SUBDIRS  | grep .module`
    for i in $modlist; do
	MOD_NAME=`echo $i | sed 's/\.module//'`
	echo "module name: $MOD_NAME file: $i "
	if [ "$MOD_NAME" == "target" ]; then
	    echo "\"target\" is a reserved word, not for module names!"
	    exit 0
	fi
	if [ "$MOD_NAME" == "toolchain" ]; then
	    echo "\"toolchain\" is a reserved word, not for module names!"
	    exit 0
	fi
	source $MODULE_SUBDIRS/$i
	EN_COUNTER=`echo "$BLOCKED_MODULES" | grep -c $MOD_NAME`
	if [ $EN_COUNTER -eq 0 ]; then
	    init_module_by_name $MOD_NAME
	else
	    echo "Blocked module skipped: $MOD_NAME"
	fi
    done
done
echo "[general] Modules discovered are: $MOD_LIST"


echo "[general] Examining targets"
for TARGET_SUBDIRS in $TPATH; do
    targetlist=`ls -C -1 $TPATH | grep .target`
    for i in $targetlist; do
	TARGET_NAME=`echo $i | sed 's/\.target//'`
	echo "target name: $TARGET_NAME file: $i "
	if [ "$TARGET_NAME" == "target" ]; then
	    echo "\"module\" is a reserved word, not for target names!"
	    exit 0
	fi
	if [ "$TARGET_NAME" == "toolchain" ]; then
	    echo "\"toolchain\" is a reserved word, not for target names!"
	    exit 0
	fi
	source $TPATH/$i
	TARGET_LIST="$TARGET_NAME $TARGET_LIST"
    done
done
echo "[general] Available targets are $TARGET_LIST"

# Parsing arguments
for i in $@; do
    DT=`echo $i | awk -F "=" '{ print NF; }'`
    if [ $DT -eq 2 ]; then
	# We do have var=val statement
	VAR=`echo $i | awk -F "=" '{ print $1; }'`
	VAL=`echo $i | awk -F "=" '{ print $2; }'`
	case "$VAR" in
	    target)
		if [ $IGNORE_TARGET -eq 0 ]; then
		    TARGET_FUNC=${VAL}_execute
		    echo "Target is set to $VAL"
		fi
		;;
	    module)
		BUILD_TARGET_MODULE=$VAL
		echo "We will be building a module $VAL and target will be ignored"
		IGNORE_TARGET=1
		;;
	    modulechain)
		BUILD_TARGET_MODULE=$VAL
		MODULE_RECURSIVE=1
		echo "We will be building up toward a module $VAL and target will be ignored"
		IGNORE_TARGET=1
		;;
	    toolchain)
		EN_COUNTER=`echo $TOOLCHAINS | grep -c $VAL`
		if [ $VAL -gt 0 ]; then
		    TOOLCHAIN=$VAL
		    echo "Explicit toolchain $VAL specified, using it"
		fi
		;;
	    trace)
		TRACE_RUN=$VAL
		;;
	    noscm)
		NO_SCM=$VAL
		;;
	esac
    fi
done

if [ -z $TOOLCHAIN ]; then
    echo "[general] no toolchains specified, using gnu"
    # Don't change it here, or you'll be expelled from Hogwards! Use --target=xxx instead
    TOOLCHAIN=gnu
fi

if [ $IGNORE_TARGET -lt 1 ]; then
    if [ -z $TARGET_FUNC ]; then
	TARGET_FUNC=fullcycle_execute
    fi
fi

INIT_FUNC=${TOOLCHAIN}_toolchain
$INIT_FUNC

if [ -d ${WORK_ROOT}/build ]; then
    if [ $TRACE_RUN -eq 0 ]; then
	echo "Build directory exists, destroying ${WORK_ROOT}/build"
	#rm -fr ${WORK_ROOT}/build
    else
	echo "Trace run, no build directory cleanup performed"
    fi
fi

echo "We have [$BLOCKED_MODULES] modules blocked so far"

for i in $MOD_LIST; do
    echo "[general] Processing $i module"
    EN_COUNTER=`echo "$BLOCKED_MODULES" | grep -c $i`
    if [ $EN_COUNTER -eq 0 ]; then
	INIT_FUNC=${i}_actual
	ACT_RESULT=$( $INIT_FUNC $i )
	if [ $ACT_RESULT -eq 2 ]; then
	    echo "[$i] Actualization is not supported for the module"
	else
	    echo "[$i] Actualization is supported for the module: $ACT_RESULT "
	    if [ $ACT_RESULT -eq 0 ]; then
		echo "[$i] Looking for upward dependencies"
		DEP_UP_LIST=$(get_dependents_recursive $i )
		echo "[$i] Actualization requrement, dependents are : $DEP_UP_LIST "
		for j in $DEP_UP_LIST; do
		    echo "[$i] Removing dep $j"
		    remove_from_list DEP_BUILT $j
		done
	    else
		echo "[$i] Module is up-to-date"
	    fi
	fi
	if [ $TRACE_RUN -eq 0 ]; then
	    # do the extraction
	    INIT_FUNC=${i}_extract
	    $INIT_FUNC $i
	    echo "[$i] extracted"
	fi
    else
	echo "Blocked module skipped: $MOD_NAME"
    fi
done
if [ -z $REINIT_LIST ]; then
    echo "[general] No need to reinitialize any of the modules"
else
    echo "[general] Reinitialization is needed for $REINIT_LIST"
fi

if [ -z $BUILD_TARGET_MODULE ]; then
    echo "no target modules available, using build target $TARGET_FUNC"
    if [ $IGNORE_TARGET -lt 1 ]; then
	$TARGET_FUNC
    fi
else
    echo "building precisely the module named $BUILD_TARGET_MODULE"
    if [ MODULE_RECURSIVE -lt 1 ]; then
	INIT_FUNC=${BUILD_TARGET_MODULE}_build
	$INIT_FUNC $BUILD_TARGET_MODULE
    else
	build_module_recursive ${BUILD_TARGET_MODULE}
    fi
fi
echo "[general] Modules built: $DEP_BUILT"
echo "[general] Finishing"
