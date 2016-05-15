# Ruby on Tracks

This was an application that was inspired by Ruby on Rails. It has a controller base, a router, cookies, and exception pages, and uses the Rack gem as the middleware and server.
```ruby
app = Proc.new do |env|
  req = Rack::Request.new(env)
  res = Rack::Response.new
  MyController.new(req, res).go
  res.finish
end

Rack::Server.start(
  app: app,
  Port: 3000
)
```
## Starting the Servers
To run the app, clone the repo and `cd` into the directory. There are four servers available to demonstrate the different features of this application. To start a server, run `ruby bin/[name of file]`.

## ControllerBase
  Initialization of ControllerBase takes in a `Rack::Request` and a `Rack::Response` as arguments, as well as any route params. There are several methods that were implemented in this class.

### `render` and `render_content`
  The `render` method takes in a template name, which is used to search for the html.erb file that corresponds to the controller action. The file is read, and is converted to a ERB instance. The ERB content is then converted into a html to be rendered.

```ruby
file_path = "views/#{self.class.name.underscore}/#{template_name}.html.erb"
lines = File.read(file_path)
template = ERB.new(lines)
result = template.result(binding)
```

  The `render_content` takes in the content generated by render and writes it to the `Rack::Response` of the controller instance
  To ensure that there is no double rendering, the `@already_built_response` is set to be true. An exception is raised if `@already_built_response` has previously been set to true. It also stores the information in the session into the `Rack::Response`.

```ruby
raise if already_built_response?

res['Content-Type'] = content_type
res.write(content)

@already_built_response = true

session.store_session(res)
```

### `session` and `flash`
  Either creates an instance of `Session` or `Flash`, or if one exists, returns it.

```ruby
def session
  @session ||= Session.new(req)
end
```

### `invoke_action`
  Invokes the method of the given name, and renders its corresponding view unless it has already been built.

```ruby
def invoke_action(name)
  send(name)
  render(name) unless already_built_response?
end
```

## Routes
  The route has a `@pattern` and checks if the current path matches. If it does, it creates an instance of the `@controller_class` and invokes the `@action_name`. Because the pattern includes wildcard params, such as a `id`, it also passes those parameters into the route_params of the controller.

```ruby  
# Creates a route with a pattern, controller, action, and HTTP method
get Regexp.new("^/cats/(?<id>\\d+)$"), CatsController, :show
```  

## Router
  The router is stores the routes that have been defined in `@routes`.

```ruby
def add_route(pattern, method, controller_class, action_name)
  routes << Route.new(pattern, method, controller_class, action_name)
end
```

### `get`, `post`, `put`, and `delete`
  These methods are created through `define_method`. Each of these methods calls `add_route` with its appropriate arguments.

```ruby
[:get, :post, :put, :delete].each do |http_method|
  define_method(http_method) do |pattern, controller_class, action_name|
    add_route(pattern, http_method, controller_class, action_name)
  end
end
```

### `draw`
  The draw method uses `instance_eval(proc)` to evaluates a proc in the context of the instance, which is the router. This is for syntactic sugar, allowing for many routes to be defined easily.

```ruby
router.draw do
  get Regexp.new("^/cats$"), CatsController, :index
  get Regexp.new("^/cats/(?<cat_id>\\d+)/statuses$"), StatusesController, :index
end
```

### `run`
The router loops through its routes to see if there is a match. If there is, it calls the routes `run` method. If not, it returns a 404 status to the `Rack::Response`.

```ruby
def run(req, res)
  route = match(req)
  route ? route.run(req, res) : res.status = 404
end
```

## Session
`Session` has `@cookies`, which is information provided by the request cookies. If there is no cookie by the name `session_cookie`, an empty hash is assigned to `@cookies`. There are the `[]` and `[]=` methods, which provide access to the `@cookies`. The `store_session` method saves the information in `@cookies` into `Rack::Request`.

## Flash
`Flash` is similar to the `Session` in the sense that they both set the cookies to the `Rack::Response`, and also pulls information from `Rack::Request`. The difference is that the flash cookies only last the current and next cycle, so it has to be reset after it loads the data. This is done through `reset_flash`, which stores an empty hash as the cookies.

```ruby
def reset_flash
  store_flash({})
end

def store_flash(value)
  res.set_cookie(
    '_flash_cookie',
    {
      path: '/',
      value: value
    }
  )
end
```

When a flash value is stored, it saves it into the cookies.
```ruby
def []=(key, value)
  cookies[key.to_sym] = value
  store_flash(cookies.to_json)
```
end

### `flash.now`
  While flash persists for the current and next cycle, `flash.now` only lasts a the current cycle. This is accomplished by storing the information in `@now`, which isn't saved into the `Rack::Response` cookie.

### Accessing `flash` values
  To access both the flash and the flash.now values, the two hashes are temporarily merged together into a single hash

```ruby
def [](key)
  cookies.merge(now)[key.to_sym] || cookies.merge(now)[key.to_s]
end
```

## Exceptions

## Assets
