require "kemal"

module Shorty
  VERSION = "0.1.0"


  get "/" do |env|
    "Hello world!"
  end

  port = (ENV["PORT"]? || 8080).to_i
  Kemal.run port
end
