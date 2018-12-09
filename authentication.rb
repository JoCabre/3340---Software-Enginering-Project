require 'sinatra'
require_relative "user.rb"

enable :sessions

get "/login" do
	erb :"authentication/login"
end


post "/process_login" do
	email = params[:email]
	password = params[:password]

	user = User.first(email: email.downcase)

	if(user && user.login(password))
		session[:user_id] = user.id
		redirect "/"
	else
		erb :"authentication/invalid_login"
	end
end

get "/logout" do
	session[:user_id] = nil
	redirect "/"
end

get "/sign_up" do
	erb :"authentication/sign_up"
end

get "/sign_up_student" do
	erb :"authentication/sign_up_student"
end

get "/sign_up_tutor" do
	erb :"authentication/sign_up_tutor"
end

post "/register_student" do

	first_name = params[:first_name]
	last_name = params[:last_name]
	email = params[:email]
	password = params[:password]

	if email && password && User.first(email: email.downcase).nil?
		s = User.new
		s.first_name = first_name.capitalize
		s.last_name = last_name.capitalize
		s.email = email.downcase
		s.password =  password
		s.student = true
		s.save

		session[:user_id] = s.id

		erb :"authentication/successful_signup"
	else
		erb :"authentication/failed_signup"
	end

end

post "/register_tutor" do

	first_name = params[:first_name]
	last_name = params[:last_name]
	email = params[:email]
	password = params[:password]
	description = params[:description]

	if email && password && User.first(email: email.downcase).nil?
		t = User.new
		t.first_name = first_name.capitalize
		t.last_name = last_name.capitalize
		t.email = email.downcase
		t.description = description
		t.password =  password
		t.tutor = true
		t.save

		session[:user_id] = t.id

		erb :"authentication/successful_signup"
	else
		erb :"authentication/failed_signup"
	end

end

#This method will return the user object of the currently signed in user
#Returns nil if not signed in
def current_user
	if(session[:user_id])
		@u ||= User.first(id: session[:user_id])
		return @u
	else
		return nil
	end
end

#if the user is not signed in, will redirect to login page
def authenticate!
	if !current_user
		redirect "/login"
	end
end

