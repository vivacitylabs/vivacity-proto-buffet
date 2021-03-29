#!/bin/bash

ROOT_FOLDER=$PWD
PROTOBUFFET_FOLDER=$(cd "$(dirname "$0")" && pwd -P)
echo "Found proto-buffet folder at '$PROTOBUFFET_FOLDER'"

if [ -z $1 ]; then
  CPP_FOLDER=${ROOT_FOLDER}
else
  CPP_FOLDER=$1
fi

GENERATED_FOLDER=$CPP_FOLDER/vivacity
echo "Generating cpp protobuf meta classes in '$GENERATED_FOLDER'"

if [ -d $GENERATED_FOLDER ]; then
  find $GENERATED_FOLDER -name "*.pb.h" -type f -exec rm {} \;
  find $GENERATED_FOLDER -name "*.pb.cc" -type f -exec rm {} \;
fi
mkdir -p $GENERATED_FOLDER

PROTO_FILES=($(find ${PROTOBUFFET_FOLDER} -type f -name "*.proto" ! -path "${PROTOBUFFET_FOLDER}/vivacity/*"))

for PROTO_FILE in "${PROTO_FILES[@]}"
do
  DESTINATION="${PROTO_FILE/$PROTOBUFFET_FOLDER/$GENERATED_FOLDER}"
  mkdir -p $(dirname $DESTINATION) && cp $PROTO_FILE $DESTINATION
done

PROTO_FOLDERS=($(find ${GENERATED_FOLDER} -type f -name "*.proto" -exec dirname {} \; | sort | uniq))

for PROTO_FOLDER in "${PROTO_FOLDERS[@]}"
do
    echo $PROTO_FOLDER
    protoc -I=$CPP_FOLDER --cpp_out=$CPP_FOLDER ${PROTO_FOLDER}/*.proto
done