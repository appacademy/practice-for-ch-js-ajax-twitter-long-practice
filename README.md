# AJAX Twitter

Today you will be creating a clone of Twitter called AJAX Twitter. You will
start with a static Twitter clone without JavaScript. Step by step, you'll
replace traditional form submissions with AJAX requests that do not cause a full
page refresh, sprinkling in some extra JavaScript interactivity while you're at
it!

[Live Demo]

[Live Demo]: https://aa-twitter-ajax.herokuapp.com/

## Learning goals

By the end of today's practice, you should be able to:

- Explain how AJAX requests allow the frontend and backend to communicate
- Submit valid AJAX requests from the frontend in response to user actions
- Respond to AJAX requests with JSON from the backend
- Manipulate the DOM on the frontend after receiving JSON data from the backend
- Implement loading state UI while the server is responding to AJAX requests

## Phase 0: Setup

Clone the project starter. (You can access the starter repo by clicking the
`Download Project` button at the bottom of this page.)

Start by running `bundle install`. To set up the database, run `rails db:setup`,
which creates the database, loads the schema, and runs your seeds file. Finally,
run `npm install` to install `webpack`, `sass`, and related packages for
building your frontend assets.

Run `./bin/dev` in your terminal (if you get an error regarding permissions, run
`chmod +x ./bin/*`). This uses [`foreman`] to run multiple processes in a single
terminal, with output from each accompanied by color-coded labels. The processes
it will run are determined by the file passed to `foreman` in __bin/dev__, which
in this case is __Procfile.dev__:

```text
web: bin/rails server -p 3000
js: npm run build -- --watch
css: npm run build:css -- --watch
```

Here you can see three processes will run: the Rails server, the `build`
(webpack), and `build:css` (sass) scripts defined in `package.json`. Use `^c`
(CTRL-c) to end all three processes and exit `foreman`.

### Debugging

A drawback of `foreman` is that you cannot use the same terminal to debug with
`debug` or `byebug`. Instead, you'll need to create a remote debugging session;
you can then connect to this remote session from a different terminal, where
you'll get your typical `debug`/`byebug` console / REPL.

Below are instructions to set this up for `debug` and `byebug`--pick whichever
you prefer.

#### Option A: `debug`

Change the first line of __Procfile.dev__ from:

```text
web: bin/rails server -p 3000
```

to:

```text
web: rdbg --open --nonstop -c -- bin/rails server -p 3000
```

Let's break this down:

- `rdbg -c -- <cmd>` -- run `<cmd>` in debugging mode (lets you hit `debugger`s)
- `--open` -- make debugging session remote (accessible from another terminal)
- `--nonstop` -- don't stop at the beginning of code execution (i.e., wait for a
  `debugger`)

Now if you ever want to hit any backend `debugger`s, first open a new terminal
and run `rdbg -A`. Then when your codes halts at a `debugger`, you'll see your
debugging console there!

#### Option B: `byebug`

If you haven't already, head to your __Gemfile__ and change the `debug` gem to
`byebug` inside `group :development, :test`. Then `bundle install`.

```rb
# Gemfile

group :development, :test do
  gem "byebug", platforms: %i[ mri mingw x64_mingw ]
end
```

Next, head to __config/environments/development.rb__ and add the following at
the end of the configuration block:

```rb
# config/environments/development.rb

Rails.application.configure do
  # ... a bunch of configuration stuff

  require "byebug/core"
  Byebug.start_server("localhost", 3001)
end
```

This will start a debugging session at `localhost:3001` whenever you start your
server.

Now if you ever want to hit any backend `debugger`s, first open a new terminal
and run `byebug -R 3001`. (Make sure `foreman` is running first or you will get
a `Connection refused` error.) Then when your code halts at a `debugger`,
you'll see your debugging console there!

> **Note:** You must run `byebug -R 3001` **before** executing the code that
> contains a `debugger`. If you accidentally hit a `debugger` before opening the
> debugging console, your code will still halt, you just won't see a debugging
> console. To continue, simply type `c` and hit `Enter` in your `foreman`
> terminal. Then try again after running `byebug -R 3001`.

### Entry file

Take a quick look at the __webpack.config.js__. Note that your entry file is
__app/javascript/application.js__. Webpack will transpile and bundle all the
files your entry file depends on (files it imports, files those files import,
etc.), creating the file __app/assets/builds/application.js__. This file is then
loaded by __app/views/layouts/application.html.erb__:

```rb
<%= javascript_include_tag "application", defer: true %>
```

Notice this tag includes `defer: true` by default. This tells the browser to run
the script after the page has loaded. Because of this, you do not need to use a
`DOMContentLoaded` callback in your entry file.

If you look at your entry file, __app/javascript/application.js__, you'll notice
five classes have been imported:

```js
import FollowToggle from "./follow_toggle";
import InfiniteTweets from "./infinite_tweets";
import TweetCompose from "./tweet_compose";
import UsersSearch from "./users_search";
import Followers from "./followers";
```

Each one expects a DOM element as an argument to its constructor, and its job is
to bring that element to life via JavaScript by adding event listeners which
trigger DOM changes, AJAX requests, or both.

> *Note*: To make referring to these classes easier throughout this project,
> these instructions will call them _components_.

For each component, there is a corresponding call to
`document.querySelectorAll`. For each element matching the provided CSS
selector, a new instance of the component is created. For example, the code
below will select every `p` element with a class of `cool` and pass it to the
`CoolParagraph` component constructor. What interactivity does it bring to any
`p.cool` elements on the page?

```js
class CoolParagraph {
  constructor(paragraphEl) {
    paragraphEl.addEventListener("click", () => alert("I'm a cool paragraph!"));
  }
}

let coolParagraphSelector = "p.cool";

document.querySelectorAll(coolParagraphSelector).forEach((el) => {
  new CoolParagraph(el);
});
```

It's your job to provide the selectors and fill out the functionality of each
component.

Before moving to Phase 1 / writing any code, though, open [localhost:3000] and
familiarize yourself with the application. Also look through the source code,
including the routes, views, and database schema!

[`foreman`]: https://github.com/ddollar/foreman
[localhost:3000]: http://localhost:3000