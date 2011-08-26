require 'rubygems'
require 'sinatra'

class App < Sinatra::Base
  get "/" do
    erb :index
  end

  get "/form" do
    erb :form
  end
end

run App
