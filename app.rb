require 'rubygems'
require 'sinatra'
require 'sinatra/reloader'
require 'sqlite3'

configure do
  enable :sessions

  @db = SQLite3::Datebase.new('BarberShop.db')
end

helpers do
  def username
    session[:user] ? session[:user] : 'Не авторизованный пользователь'
  end

  def selected(name, value)
    'selected' if name == value
  end
end

get '/' do
  erb 'Hello!
  <a href="https://github.com/bootstrap-ruby/sinatra-bootstrap">Original</a>
   pattern has been modified for <a href="http://rubyschool.us/">
   Ruby School</a>'
end

get '/about' do
  erb :about
end

get '/vizit' do
  erb :vizit
end

get '/contacts' do
  erb :contacts
end

get '/login' do
  erb :login
end

get '/logout' do
  session.delete(:user)
  erb :logout
end

post '/login' do
  @login = params['login']
  @password = params['password']

  if @login == 'admin' && @password == 'secret'
    session[:user] = 'Администратор (admin)'
    erb :auth_success
  else
    erb :not_auth
  end
end

post '/vizit' do
  @name = params[:name]
  @phone = params[:phone]
  @datetime = params[:datetime]
  @master = params[:master]
  @head_color = params[:head_color]

  @error = ''

  messages = {
    name: 'Введите Имя',
    phone: 'Введите телефон',
    datetime: 'Вветие дату',
    master: 'Выберите Мастера',
    head_color: 'Выберите цвет'
  }

  @error = empty_params? messages

  return erb :vizit unless @error == ''

  output = File.open './public/users.txt', 'a'
  output.write "#{@name}, #{@phone}, #{@datetime}, master: #{@master}, select color: #{@head_color}\n"
  output.close

  @db.execute <<-SQL
    INSERT INTO 'Users' (
      'name',
      'phone',
      'datestamp',
      'barber',
      'color'
    )
    VALUES(
      '#{@name}',
      '#{@phone}',
      '#{@datetime}',
      '#{@master}',
      '#{@head_color}'
    )
  SQL
  @db.close

  @message = "#{@name}! Вы записаны на дату: #{@datetime}, к мастеру #{@master}"
  erb :welcome
end

def empty_params?(messages)
  messages.select { |key| params[key] == '' }.values.join(', ')
end

post '/contacts' do
  @contact_email = params['contact_email'].strip
  @contact_message = params['contact_message'].strip
  output = File.open('./public/contacts.txt', 'a')
  output.write "#{@contact_email}: #{@contact_message}\n"
  output.close

  @message = 'Ваш контакт сохранен!'
  erb :contacts
end
