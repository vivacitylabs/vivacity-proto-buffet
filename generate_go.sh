#!/bin/bash

ROOT_FOLDER=$PWD
PROTOBUFFET_FOLDER=$(cd "$(dirname "$0")" && pwd -P)
echo "Found proto-buffet folder at '$PROTOBUFFET_FOLDER'"

GENERATED_FOLDER=$PROTOBUFFET_FOLDER/vivacity
echo "Generating go protobuf meta classes in '$GENERATED_FOLDER'"

if [ -d $GENERATED_FOLDER ]; then
  rm -r $GENERATED_FOLDER
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
    protoc -I=$PROTOBUFFET_FOLDER --go_opt=paths=source_relative --go_out=plugins=grpc:$PROTOBUFFET_FOLDER ${PROTO_FOLDER}/*.proto
done