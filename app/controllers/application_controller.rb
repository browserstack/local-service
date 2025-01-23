class ApplicationController < ActionController::Base
  protect_from_forgery unless: :ignore_csrf_verification?, prepend: true
end
