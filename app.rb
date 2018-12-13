require "sinatra"
require_relative "authentication.rb"

enable :sessions

set :session_secret, "super secret"

# need install dm-sqlite-adapter
# if on heroku, use Postgres database
# if not use sqlite3 database I gave you

if ENV['DATABASE_URL']
  DataMapper::setup(:default, ENV['DATABASE_URL'] || 'postgres://localhost/mydb')
else
  DataMapper::setup(:default, "sqlite3://#{Dir.pwd}/app.db")
end


DataMapper.finalize
User.auto_upgrade!

#make an admin user if one doesn't exist!
if User.all(tutor: true).count == 0
	u = User.new
	u.first_name = "Tutor"
	u.last_name = "Rotut"
	u.city = "Coolest City"
	u.state = "CO"
	u.email = "tutor@tutor.com"
	u.description = "I can teach you ruby!"
	u.tag1 = "Ruby"
	u.tag2 = "HTML"
	u.tag3 = "CSS"
	u.password = "tutor"
	u.tutor = true
	u.save
end

if User.all(administrator: true).count == 0
	u = User.new
	u.email = "admin@admin.com"
	u.password = "admin"
	u.administrator = true
	u.save
end

#the following urls are included in authentication.rb
# GET /login
# GET /logout
# GET /sign_up

# authenticate! will make sure that the user is signed in, if they are not they will be redirected to the login page
# if the user is signed in, current_user will refer to the signed in user object.
# if they are not signed in, current_user will be nil

get "/" do
	erb :index
end

get "/tutor_list" do
	authenticate!

	if current_user.administrator == false && current_user.pro == false
		@tutor_list = User.all(tutor: true)
		erb :tutor_list	
	else
		authenticate!
		@tutor_list = User.all(tutor: true)
		erb :tutor_list_pro
	end
end


require 'stripe'

set :publishable_key, 'pk_test_OeiFF0y42AzooJNLxo5mjwsg'
set :secret_key, 'sk_test_PytyAA5Ud7xWuCWSv3A7DlyM'


Stripe.api_key = settings.secret_key

get "/upgrade" do
authenticate!

	if current_user.administrator == false && current_user.pro == false
		erb:upgrade
	else
		redirect "/"
	end
end

post "/charge" do
authenticate!

current_user.pro = true
current_user.save

	@amount = 500

  customer = Stripe::Customer.create(
    :email => 'customer@example.com',
    :source  => params[:stripeToken]
  )

  charge = Stripe::Charge.create(
    :amount      => @amount,
    :description => 'Sinatra Charge',
    :currency    => 'usd',
    :customer    => customer.id
  )

  erb :charge

end

error Stripe::CardError do
  env['sinatra.error'].message
end

