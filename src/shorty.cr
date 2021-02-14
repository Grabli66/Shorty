require "kemal"
require "cryomongo"

# https://cloud.mongodb.com/
# https://appshorty.herokuapp.com/

module Shorty
  VERSION = "0.1.0"

  mongo_client = Mongo::Client.new "mongodb://Grabli66:NONE66@cluster0-shard-00-01.jfzer.mongodb.net:27017/shorty?authSource=admin&compressors=disabled&gssapiServiceName=mongodb&replicaSet=atlas-pqtx6g-shard-0&ssl=true"
  database = mongo_client["shorty"]
  link_collection = database["links"]  

  # Добавляет ссылку
  # Получает json с длинной ссылкой
  # Возвращает json с короткой ссылкой
  post "/add" do |env|
    long_link = env.params.json["link"].as(String)
    # Получает типа уникальный идентификатор
    # TODO: сделать другой механизм короткой ссылки
    id = BSON::ObjectId.new
    id_str = id.to_s
    link_collection.insert_one({_id: id, long_link: long_link})
    
    next {
      "short_link" => "https://appshorty.herokuapp.com/#{id_str}"
    }.to_json
  end

  # Получает идентификатор короткой ссылки от браузера
  # В базе ищет по короткой ссылке длинную
  # Перенаправляет браузер на длинную ссылку
  get "/:short_link_id" do |env|
    short_link_id = env.params.url["short_link_id"]
    document = link_collection.find_one({_id: short_link_id})
    long_link = (document.try &.["long_link"]?).try &.to_s
    unless long_link
      halt env, status_code: 404, response: "Not found"
    end
    env.redirect long_link
  end

  error 404 do
    "Not found"
  end

  port = (ENV["PORT"]? || 8080).to_i
  Kemal.run port
end
