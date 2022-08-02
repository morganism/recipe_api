# server.rb
require 'sinatra'
require "sinatra/namespace"
require 'mongoid'
# DB Setup
Mongoid.load! "mongoid.config"

# Models
class Recipe
  include Mongoid::Document

  field :description, type: String
  field :author, type: String
  field :ingredients, type: String
  field :process, type: String
  field :title, type: String

  validates :description, presence: true
  validates :author, presence: true
  validates :ingredients, presence: true
  validates :process, presence: true
  validates :title, presence: true

  index({ description: 'text' })
  index({ title:1 }, { unique: true, name: "title_index" })

  scope :title, -> (title) { where(title: /#{title}/) }
  scope :author, -> (author) { where(author: author) }
end

# Serializers
class RecipeSerializer
  def initialize(recipe)
    @recipe = recipe
  end

  def as_json(*)
    data = {
      description:@recipe.description,
      author:@recipe.author,
      ingredients:@recipe.ingredients,
      process:@recipe.process,
      title:@recipe.title,
    }
    data[:errors] = @recipe.errors if@recipe.errors.any?
    data
  end
end


# Endpoints
get '/ ' do
  'Welcome to Recipe!'
end

get '/recipes' do
  recipes = Recipe.all

  [:title, :author].each do |filter|
    recipes = recipes.send(filter, params[filter]) if params[filter]
  end

  recipes.to_json
end

#let's add a namespace
namespace '/api/v1' do
  before do
    content_type 'application/json'
  end

  helpers do
    def base_url
      @base_url ||= "#{request.env['rack.url_scheme']}://{request.env['HTTP_HOST']}"
    end

    def json_params
      begin
        JSON.parse(request.body.read)
      rescue
        halt 400, { message:'Invalid JSON' }.to_json
      end
    end
  end

  # Using a method to access the recipe can save us
  # from a lot of repetitions and can be used
  # anywhere in the endpoints during the same
  # request
  def recipe
    @recipe ||= Recipe.where(title: params[:title]).first
  end

  # Since we used this code in both show and update
  # extracting it to a method make it easier and
  # less redundant
  def halt_if_not_found!
    halt(404, { message:'Recipe Not Found'}.to_json) unless recipe
  end

  def serialize(recipe)
    RecipeSerializer.new(recipe).to_json
  end

  get '/recipes' do
    recipes = Recipe.all
    [:title, :author].each do |filter|
      recipes = recipes.send(filter, params[filter]) if params[filter]
    end

    # We just change this from recipe.to_json to the following
    recipes.map { |recipe| RecipeSerializer.new(recipe) }.to_json
  end

  post '/recipes' do
    recipe = Recipe.new(json_params)
    if recipe.save
      response.headers['Location'] = "#{base_url}/api/v1/recipes/#{recipe.title}"
      status 201
    else
      status 422
      body RecipeSerializer.new(recipe).to_json
    end
  end

  # Just like for the create endpoint,
  # we switched to a guard clause style to
  # check if the book is not found or if
  # the data is not valid
  patch '/recipes/:title' do |title|
    halt_if_not_found!
    halt 422, serialize(recipe) unless recipe.update_attributes(json_params)
    serialize(recipe)
  end

  patch '/recipes/:title ' do |title|
    recipe = Recipe.where(title: title).first
    halt(404, { message:'Recipe Not Found'}.to_json) unless recipe
    if recipe.update_attributes(json_params)
      RecipeSerializer.new(recipe).to_json
    else
      status 422
      body RecipeSerializer.new(recipe).to_json
    end
  end

  delete '/recipes/:title' do |title|
    recipe = Recipe.where(title: title).first
    recipe.destroy if recipe
    status 204
  end
end
