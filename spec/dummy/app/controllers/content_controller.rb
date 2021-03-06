# frozen_string_literal: true

class ContentController < ApplicationController
  # Validate access token on all actions
  before_action :validate_access_token

  # Require token for protected actions
  before_action :require_token, :only => :authenticated

  ##
  # GET /unauthenticated
  #
  # This endpoint is not protected, performing a request without a token, or with a valid token will succeed
  # Performing a request with an invalid token will raise an UnauthorizedError
  #
  def unauthenticated
    head :no_content
  end

  ##
  # GET /unauthenticated
  #
  # This endpoint is protected, performing a request with a valid access token will succeed
  # Performing a request without a token, with an invalid token or with a refresh token will raise an UnauthorizedError
  #
  def authenticated
    head :no_content
  end
end
