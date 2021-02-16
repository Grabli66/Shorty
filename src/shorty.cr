require "kemal"
require "html_builder"
require "cryomongo"

# https://cloud.mongodb.com/
# https://appshorty.herokuapp.com/

module Shorty
  VERSION = "0.1.0"

  HOST_URL = "https://appshorty.herokuapp.com"

  mongo_client = Mongo::Client.new "mongodb://Grabli66:NONE66@cluster0-shard-00-01.jfzer.mongodb.net:27017/shorty?authSource=admin&compressors=disabled&gssapiServiceName=mongodb&replicaSet=atlas-pqtx6g-shard-0&ssl=true"
  database = mongo_client["shorty"]
  link_collection = database["links"]

  # Возвращает короткую ссылку
  def self.get_short_link(oid : String) : String
    "#{HOST_URL}/#{oid}"
  end

  # Возвращает все ссылки
  get "/list" do
    cursor = link_collection.find
    html = HTML.build do
      table do
        tr do
          td do
            text "Short Link"
          end
          td do
            text "Long Link"
          end
          td do
            text "Show Count"
          end
        end
        cursor.each do |link|
          tr do
            id = link["_id"]?.try &.to_s            
            next unless id
            long_link = link["long_link"]?.try &.to_s
            next unless long_link
            show_count = link["show_count"]?.try &.as(Int32) || 0

            td do
              a(href: long_link) do
                text get_short_link(id)
              end
            end
            td do
              a(href: long_link) do
                text long_link
              end
            end
            td do              
                text show_count.to_s
            end
          end
        end
      end
    end
    # json = link.to_json
    next html
  end

  # Добавляет ссылку
  # Получает json с длинной ссылкой
  # Возвращает json с короткой ссылкой
  post "/add" do |env|
    long_link = env.params.json["link"].as(String)
    # Получает типа уникальный идентификатор
    # TODO: сделать другой механизм короткой ссылки
    id = BSON::ObjectId.new
    id_str = id.to_s
    link_collection.insert_one({_id: id, long_link: long_link, show_count: 0})

    next {
      "short_link" => get_short_link(id_str),
    }.to_json
  end

  # Получает идентификатор короткой ссылки от браузера
  # В базе ищет по короткой ссылке длинную
  # Перенаправляет браузер на длинную ссылку
  get "/:short_link_id" do |env|
    short_link_id_str = env.params.url["short_link_id"]
    short_link_id = BSON::ObjectId.new(short_link_id_str)

    document = link_collection.find_one({_id: short_link_id})
    long_link = (document.try &.["long_link"]?).try &.to_s
    unless long_link
      halt env, status_code: 404, response: "Not found"
    end
    show_count = document.try &.["show_count"]?.try &.as(Int32) || 0
    show_count += 1
    link_collection.update_one({_id: short_link_id}, { "$set": { show_count: show_count }})    

    env.redirect long_link
  end

  error 404 do
    "Not found"
  end

  port = (ENV["PORT"]? || 8080).to_i
  Kemal.run port
end
