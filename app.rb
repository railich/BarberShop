require 'rubygems'
require 'sinatra'
require 'sinatra/reloader'
require 'sqlite3'

configure do
  enable :sessions

  db = SQLite3::Database.new 'BarberShop.db'
  db.execute <<-SQL
    CREATE TABLE IF NOT EXISTS 'Users' (
        'id' INTEGER PRIMARY KEY AUTOINCREMENT,
        'name' TEXT,
        'phone' TEXT,
        'datestamp' TEXT,
        'barber' TEXT,
        'color' TEXT
      )
    SQL

  db.execute "CREATE TABLE IF NOT EXISTS 'Barbers' (
      'id' INTEGER PRIMARY KEY AUTOINCREMENT,
      'name' TEXT
    )
  "
  barbers = ['Walter White', 'Jessie Pinkman', 'Gus Fring']
  barbers.each.with_index do |barber, i|
  db.execute "INSERT OR REPLACE INTO 'Barbers' ('id', 'name')
    VALUES (?, ?)", [i += 1, barber]
  end

  db.close
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

get '/showusers' do
  @users = ''
  db = getdb
  db.results_as_hash = true
  db.execute "SELECT * FROM Users" do |row|
    @users << "
      <tr>
        <td>#{row['id']}</td>
        <td>#{row['name']}</td>
        <td>#{row['phone']}</td>
        <td>#{row['datestump']}</td>
        <td>#{row['barber']}</td>
        <td>#{row['color']}</td>
      </tr>
    "
  end
  db.close

  erb :showusers
end

get '/about' do
  erb :about
end

get '/vizit' do
  db = getdb
  db.results_as_hash = true
  @barbers = db.execute "SELECT * FROM Barbers"

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

  db = getdb
  db.execute "INSERT INTO 'Users' (
      'name',
      'phone',
      'datestamp',
      'barber',
      'color'
    )
    VALUES(?, ?, ?, ?, ?)", [@name, @phone, @datetime, @master, @head_color]

  db.close

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

def getdb
  return SQLite3::Database.new 'BarberShop.db'
end
