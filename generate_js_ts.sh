#!/bin/bash

ROOT_FOLDER=$PWD
PROTOBUFFET_FOLDER=$(cd "$(dirname "$0")" && pwd -P)
echo "Found proto-buffet folder at '$PROTOBUFFET_FOLDER'"

GENERATED_FOLDER=$PROTOBUFFET_FOLDER/vivacity
echo "Generating protobuf meta classes in '$GENERATED_FOLDER'"

if [ -d $GENERATED_FOLDER ]; then
  rm -r $GENERATED_FOLDER
fi
mkdir -p $GENERATED_FOLDER

PROTO_FILES=($(find ${PROTOBUFFET_FOLDER} -type f -name "*.proto"))

for PROTO_FILE in "${PROTO_FILES[@]}"
do
  DESTINATION="${PROTO_FILE/$PROTOBUFFET_FOLDER/$GENERATED_FOLDER}"
  mkdir -p $(dirname $DESTINATION) && cp $PROTO_FILE $DESTINATION
done

PROTO_FOLDERS=($(find ${GENERATED_FOLDER} -type f -name "*.proto" -exec dirname {} \; | sort | uniq))
NODE_MODULES_BINS=$PROTOBUFFET_FOLDER/../node_modules/.bin

if [ -z $1 ]; then
  OUTPUT_FOLDER=$PROTOBUFFET_FOLDER/..
else
  OUTPUT_FOLDER=$1
fi

for PROTO_FOLDER in "${PROTO_FOLDERS[@]}"
do
    echo $PROTO_FOLDER
    protoc -I=$PROTOBUFFET_FOLDER --plugin=protoc-gen-ts=$NODE_MODULES_BINS/protoc-gen-ts --js_out=import_style=commonjs,binary:$OUTPUT_FOLDER --ts_out=$OUTPUT_FOLDER ${PROTO_FOLDER}/*.proto

done

GENERATED_FILES=$(find $OUTPUT_FOLDER/vivacity -name "*.js" -type f)
for f in $GENERATED_FILES; do
    echo '/* eslint-disable */' | cat - "${f}" > temp && mv temp "${f}"''
done
