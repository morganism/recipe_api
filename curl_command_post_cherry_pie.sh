#!/bin/bash

export HTTP_HOST=localhost
# curl command to post a cherry pie recipe to our database
curl -i -X POST -H "Content-Type: application/json" -d'{"title":"Cherry Pie", "author":"Morgan", "process":"Add all ingredients", "ingredients":"Flour,water,salt,cherries", "description":"A cherry pie recipe"}' http://localhost:4567/api/v1/recipes
