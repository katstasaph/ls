require "sinatra"
require "sinatra/reloader"
require "tilt/erubis"
require 'yaml'

before do
  USER_DATA = YAML.load_file('data/users.yml')
  @names = names(USER_DATA)
end

helpers do
  def tally_users
    [count_users, count_interests]
  end

  def count_users
    @names.length
  end
  
  def count_interests
    interests = 0
    USER_DATA.each { |_, record| interests += record[:interests].length }
    interests
  end

  def names(users)
    users.keys.map { |key| key.to_s.capitalize }
  end
  
  def join_with_comma(interests)
    interests.join(", ")
  end
end

not_found do
  redirect "/"
end

get "/" do
  @total_users, @total_interests = tally_users
  erb :users
end

get "/users/:name" do
  @username = params[:name]
  data = USER_DATA[@username.to_sym]
  @email = data[:email]
  @interests = join_with_comma(data[:interests])
  @other_users = @names.reject { |name| name == @username.capitalize }
  erb :userpage
end