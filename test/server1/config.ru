require 'rubygems'
require 'sinatra'

class App < Sinatra::Base
  get "/" do
    erb :index
  end

  get "/form" do
    erb :form
  end

  get "/slow" do
    erb :slow
  end

  get "/slow-index" do
    sleep 2
    erb :index
  end

  get "/very-slow-index" do
    sleep 7
    erb :index
  end
end

run App
