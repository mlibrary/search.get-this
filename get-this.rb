require "sinatra"
require "sinatra/reloader" if development?
require "alma_rest_client"
require "debug" if development?
require "active_support/all"
require "sinatra/flash"
require "faraday/follow_redirects"
require "ostruct"

Time.zone = "Eastern Time (US & Canada)"

require_relative "lib/styled_flash"
require_relative "lib/utility"
require_relative "models/patron"
require_relative "models/item"
require_relative "models/options/media_booking"
require_relative "models/options"
require_relative "lib/closed_days"

helpers StyledFlash
enable :sessions
set :session_secret, ENV["RACK_COOKIE_SECRET"]
set server: "puma", connections: []

def dev_login?
  settings.environment == :development
end

def set_patron
  uniqname = request.get_header("HTTP_X_AUTH_REQUEST_USER")
  halt 401, "Unauthorized" if uniqname.nil?
  session[:uniqname] = uniqname
end

get "/logout" do
  session.clear
  weblogin_logout_url = URI.encode_www_form_component("https://shibboleth.umich.edu/cgi-bin/logout?https://lib.umich.edu/")
  log_out_url = "/oauth2/sign_out?rd=#{weblogin_logout_url}"
  redirect log_out_url
end

before do
  Time.zone = "Eastern Time (US & Canada)"
  pass if ["session_switcher", "logout", "login", "-", "favicon.svg"].include? request.path_info.split("/")[1]

  if dev_login?
    session[:uniqname] = "mlibrary.acct.testing1@gmail.com" unless session[:uniqname]
    pass
  end

  set_patron
end

# simplecov:disable
if dev_login?
  post "/session_switcher" do
    session[:uniqname] = params[:uniqname]
    redirect "/#{params[:item]}"
  end
end
# :simplecov:enable

get "/confirmation" do
  erb :confirmation
end

get "/:barcode" do
  barcode = params["barcode"] # need to check that this is valid barcode
  patron = Patron.for(session[:uniqname])
  item = Item.for(barcode)
  options = Options.for(patron: patron, item: item)
  erb :index, locals: {patron: patron, item: item, options: options}
end

get "/" do
  if dev_login?
    erb :dev_home
  else
    redirect "https://www.lib.umich.edu/find-borrow-request"
  end
end

post "/booking" do
  barcode = ""
  barcode = URI.parse(request.referrer).path.delete("/") if request.referrer
  begin
    logger.info "Requesting barcode: #{barcode}; for pickup on #{params[:date]}; for pickup at #{params["pickup-location"]}"
    response = Option::MediaBooking.book(uniqname: session[:uniqname], barcode: barcode, booking_date: params[:date], pickup_location: params["pickup-location"])
  rescue
    response = OpenStruct.new(code: 500, body: "rejected before sent to Alma")
  end
  if response.status != 200
    logger.error response.body
    flash[:critical] = "Item was not able to be scheduled for pickup"
    redirect request.referrer
  else
    data = response.body
    title = data["title"]
    pickup_date = Time.zone.parse(data["booking_start_date"]).to_date.strftime("%A, %B %-d, %Y")
    pickup_location = data["pickup_location"]
    logger.info "Barcode: #{data["barcode"]}; Title: #{title}; Booked for #{pickup_date}; for pickup at #{pickup_location}"
    flash[:success] = "Your pickup of <strong>#{title}</strong> has been scheduled for <strong>#{pickup_date}</strong> at <strong>#{pickup_location}</strong>"
    redirect "/confirmation"
  end
end
get "/-/live" do
  200
end
