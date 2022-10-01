#!/bin/bash

aws imagebuilder list-image-recipes \
--owner Self
 
## Get image recipe details
IMAGE_RECIPE_ARN=$(aws imagebuilder list-image-recipes \
--owner Self | jq -r .imageRecipeSummaryList[].arn ) &&
aws imagebuilder get-image-recipe \
--image-recipe-arn $IMAGE_RECIPE_ARN
