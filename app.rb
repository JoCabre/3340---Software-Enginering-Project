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

class Video
	include DataMapper::Resource

	property :id, Serial
	property :title, Text
	property :description, Text
	property :video_url, Text
	property :pro, Boolean, :default => false
	#fill in the rest
end

DataMapper.finalize
User.auto_upgrade!
Video.auto_upgrade!

#make an admin user if one doesn't exist!
if User.all(tutor: true).count == 0
	u = User.new
	u.first_name = "Tutor"
	u.last_name = "Rotut"
	u.email = "tutor@tutor.com"
	u.description = "I can teach you ruby!"
	u.password = "tutor"
	u.tutor = true
	u.save
end

def youtube_embed(youtube_url)
  if youtube_url[/youtu\.be\/([^\?]*)/]
    youtube_id = $1
  else
    # Regex from # http://stackoverflow.com/questions/3452546/javascript-regex-how-to-get-youtube-video-id-from-url/4811367#4811367
    youtube_url[/^.*((v\/)|(embed\/)|(watch\?))\??v?=?([^\&\?]*).*/]
    youtube_id = $5
  end

  %Q{<iframe title="YouTube video player" width="640" height="390" src="http://www.youtube.com/embed/#{ youtube_id }" frameborder="0" allowfullscreen></iframe>}
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

get "/videos" do
	authenticate!

	if current_user.administrator == false && current_user.pro == false
		@videos = Video.all(pro: false)
		erb :videos		
	else
		@videos = Video.all
		erb :videos
	end

end

post "/videos/create" do
	authenticate!

	if current_user.administrator == true
		if params["title"] && params["video_url"] && params["description"]
			v = Video.new
			v.title = params["title"]
			v.description = params["description"]
			v.video_url = params["video_url"]

			if params["pro"]
				if params["pro"] == "on"
					v.pro = true
				end
			end
			v.save
		end
	else
		redirect "/"
	end
end

get "/videos/new" do
	authenticate!

	if current_user.administrator == true
		erb :new_videos
	else
		redirect "/"
	end
end

###########################################################################################################

get "/tutor_list" do
	@tutor_list = User.all(tutor: true)
	erb :tutor_list
end

get "/tutor_profile" do
	erb :tutor_profile
	
end



############################################################################################################
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

