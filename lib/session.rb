require 'json'

class Session

  attr_reader :cookies
  # find the cookie for this app
  # deserialize the cookie into a hash
  def initialize(req)
    json_cookies = req.cookies['_rails_lite_app']
    cookies = json_cookies ? JSON.parse(json_cookies) : {}

    result = {}

    cookies.each do |key, value|
      result[key.to_sym] = value
    end

    @cookies = result

  end

  def [](key)
    cookies[key]
  end

  def []=(key, val)
    cookies[key] = val
  end

  # serialize the hash into json and save in a cookie
  # add to the responses cookies
  def store_session(res)
    res.set_cookie(
      '_rails_lite_app',
      {
        path: '/',
        value: cookies.to_json
      }
    )
  end
end
