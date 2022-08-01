#!/bin/bash

export HTTP_HOST=localhost
# curl command to patch/update our cherry pie recipe
curl -i -X PATCH -H "Content-Type: application/json" -d '{"title":"Cherry Pie", "description":"A cherry pie recipe that has been updated via PATCH"}' http://localhost:4567/api/v1/recipes/Cherry%20Pie

