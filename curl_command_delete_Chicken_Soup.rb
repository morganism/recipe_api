#!/bin/bash

export HTTP_HOST=localhost
# curl command to delete a "Chicken Soup" recipe
curl -i -X DELETE -H "Content-Type: application/json" http://localhost:4567/api/v1/recipes/Chicken%20Soup
