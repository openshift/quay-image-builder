#!/bin/bash

aws imagebuilder list-image-recipes
aws imagebuilder delete-image-recipe --image-recipe-arn $IMAGE_RECIPE_ARN
 
## Delete the custom component
aws imagebuilder delete-component --component-build-version-arn $COMPONENT_BUILD_VERSION_ARN
 
## Delete the S3 bucket with objects
#aws s3 rb s3://cloudaffaire-image-builder --force
 
