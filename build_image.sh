#!/bin/bash


# Exit if a command fails
set -e

########
# Help #
########
_help() {
    echo "Generate the required files for the Edgar Judge0 Docker image."
    echo "Constructs the Dockerfile and Ruby files for importing languages."
    echo "Can be used to update images or create new ones."
    usage
}

#########
# Usage #
#########
usage() {
    echo
    echo "Usage: $0 [-j JUDGE_VERSION] [-r REGISTRY_NAME] [-o OUTPUT_DIR] [-g GROUP_NAME] [-h]"
    echo "-j     - Use the specified judge version. Format: <MAJOR>.<MINOR>.<PATCH>. Default is 1.13.0"
    echo "-r     - Registry name, Default: 'registry.gitlab.com'."
    echo "-o     - Output directory where the judge0 zip is downloaded and unzipped."
    echo "-g     - Registry group name. Default: 'edgar-group'."
    echo "-h     - Display help."
    echo "-c     - Clean the directory."
}

#####################
# Get Judge0        #
#                   #
# Args:             #
#   judge_version   #
#   output_dir      #
#   docker_img_name #
#                   #
# Downloads judge0  #
# release, copies   #
# the .conf file,   #
# modifies the      #
# docker-compose    #
# file and outputs  #
# to $output_dir    #
#####################
get_judge0() {
    echo "Downloading and setting up Judge0 $1."
    mkdir -p /tmp/judge0
    JUDGE_NAME="judge0-v$1"
    wget https://github.com/judge0/judge0/releases/download/v${1}/${JUDGE_NAME}.zip -P /tmp/judge0
    unzip /tmp/judge0/${JUDGE_NAME}.zip -d /tmp/judge0/
#    cp /tmp/judge0/${JUDGE_NAME}/judge0.conf $2
    cat /tmp/judge0/${JUDGE_NAME}/docker-compose.yml | sed "s;judge0/judge0:${1};${3};g" > $2/docker-compose.yml
    rm -rf /tmp/judge0
}

#####################
# Create DB update  #
# Ruby files        #
#                   #
# Args:             #
#   judge_version   #
#                   #
# Gathers all       #
# JSON files in     #
# subdirectories    #
# and creates Ruby  #
# files for import. #
#####################
create_ruby_files() {
    IMP_FILES=(**/*.json)
    if [ "${#IMP_FILES[@]}" -eq 0 ]; then
        return -1
    fi
    echo "Creating the Ruby files."
    mkdir -p lang_imports
    mkdir -p lang_imports/edgar_langs
    echo "require_relative 'edgar_langs/edg_lang_id_start'" > lang_imports/imp_edgar_langs.rb
    for lang_file in $IMP_FILES; do
        FNAME=$(basename ${lang_file} .json)
        FPATH="lang_imports/edgar_langs/${FNAME}.rb"
        echo "@edgar_langs ||= []" > ${FPATH}
        echo "@edgar_langs += " >> ${FPATH}
        cat $lang_file >> ${FPATH}
        echo "require_relative 'edgar_langs/${FNAME}'" >> lang_imports/imp_edgar_langs.rb
    done
    echo "" >> lang_imports/imp_edgar_langs.rb
    echo "@languages ||= []" >> lang_imports/imp_edgar_langs.rb
    echo "" >> lang_imports/imp_edgar_langs.rb
    echo "@edgar_langs.each_with_index do |lang, index|
        @languages << {id: @start + index + 1, name: lang[:name], is_archived: lang[:is_archived], source_file: lang[:source_file], compile_cmd: lang[:compile_cmd], run_cmd: lang[:run_cmd]}" >> lang_imports/imp_edgar_langs.rb
    echo "end" >> lang_imports/imp_edgar_langs.rb
    return 0
}

#####################
# Create Dockerfile #
#                   #
# Args:             #
#   judge_version   #
#   ruby_file_count #
#                   #
# First creates     #
# the initial       #
# Dockerfile and    #
# then extends with #
# all               #
# 'Dockerfile.ext'  #
# files in subdirs. #
#####################
create_docker_file() {
    echo "Creating the Dockerfile."
    echo "ARG JUDGE_VERSION=$1 # Specify with --build-arg defaults to $1" > Dockerfile
    echo "FROM judge0/judge0:$1 as judge0_builder" >> Dockerfile
    for ext_file in **/Dockerfile.ext; do
        echo >> Dockerfile
        cat $ext_file  >> Dockerfile
    done
    if [ "$2" -eq "0" ]; then
        cat Dockerfile.langs >> Dockerfile
    fi
}

######################
# Build Docker Image #
#                    #
# Args:              #
#   docker_img_name  #
#   judge_version    #
#                    #
# Runs docker build  #
# with the generated #
# Dockerfile.        #
######################
build_docker_image() {
    echo "Building image $1"
    if docker build -t $1 --build-arg JUDGE_VERSION=$2 . ; then
        echo "Finished building docker image: $1"
    else
        echo "Failed docker build!"
        exit
    fi
}

######################
# Push docker image  #
#                    #
# Args:              #
#   docker_img_name  #
#                    #
# Tries to login to  #
# the registry and   #
# pushes the docker  #
# image.             #
######################
push_image() {
    echo "Log in to the Gitlab registry"
    docker login registry.gitlab.com
    docker push $1
}

clean_lang_imports() {
    rm -rf lang_imports
}

##############
# Clean      #
#            #
# Remove all #
# of the     #
# generated  #
# files      #
##############
clean() {
    rm -f Dockerfile
    clean_lang_imports
    rm -f docker-compose.yml # judge0.conf
}

########
# Main #
########
while getopts hcj:r:o: option; do
    case $option in
        h) # display _help
            _help
            exit
            ;;
        j) # Expect Judge version
            JUDGE_VERSION=${OPTARG}
            if [[ ! $JUDGE_VERSION =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
                echo "Invalid JUDGE_VERSION specified!"
                usage
                exit
            fi
            ;;
        r) # Registry name
            REGISTRY_NAME=${OPTARG}
            ;;
        g) # Group name
            GROUP_NAME=${OPTARG}
            ;;
        o) # Output directory
            OUTPUT_DIR=${OPTARG}
            if [ "." != "${OUTPUT_DIR}" ] && [ ".." != "${OUTPUT_DIR}" ]; then
                mkdir -p $OUTPUT_DIR
            fi
            ;;
        c) # Clean directory
            clean
            exit
            ;;
        *) # Invalid option
            echo "Error: invalid option"

            exit
            ;;
    esac
done

# Get required variables, or default to a value
JUDGE_VERSION="${JUDGE_VERSION:-1.13.0}"
GROUP_NAME="${GROUP_NAME:-edgar-group}"
REGISTRY_NAME="${REGISTRY_NAME:-registry.gitlab.com}"
DOCKER_IMG_NAME="${REGISTRY_NAME}/${GROUP_NAME}/judge0:${JUDGE_VERSION}"
OUTPUT_DIR="${OUTPUT_DIR:-.}"

if [ -z $JUDGE_VERSION ]; then
    echo "Must specify judge0 version!"
    usage
    exit
fi

echo
echo "Using judge0 version: ${JUDGE_VERSION}."
echo "Using registry: ${REGISTRY_NAME}."
echo "Using group: ${GROUP_NAME}."
echo "Creating/Updating image: ${DOCKER_IMG_NAME}."
echo

get_judge0 $JUDGE_VERSION $OUTPUT_DIR $DOCKER_IMG_NAME
echo
create_ruby_files $JUDGE_VERSION $OUTPUT_DIR
RUBY_FILE_RES=$?
echo
create_docker_file $JUDGE_VERSION $RUBY_FILE_RES
echo
build_docker_image $DOCKER_IMG_NAME $JUDGE_VERSION
echo
# clean_lang_imports

echo "Image built and ready to be pushed to the registry"
