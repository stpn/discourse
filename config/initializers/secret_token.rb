# We have had lots of config issues with SECRET_TOKEN to avoid this mess we are moving it to redis
#  if you feel strongly that it does not belong there use ENV['SECRET_TOKEN']
#
token = '63b2f647249a5289a4d6f5d1425af0b09dfc44f1d8246f2ceacdf705d14e4e87363413438ca48b9ed8745fa0455338a60aed99fc04552e8fc7f4b8489c29b63d'  #ENV['SECRET_TOKEN']
unless token
  token = $redis.get('SECRET_TOKEN')
  unless token && token.length == 128
    token = SecureRandom.hex(64)
    $redis.set('SECRET_TOKEN',token)
  end
end

Discourse::Application.config.secret_token = token
