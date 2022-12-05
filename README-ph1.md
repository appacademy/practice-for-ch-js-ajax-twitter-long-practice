# AJAX Twitter (Phase 1)

[Live Demo]

[Live Demo]: https://aa-twitter-ajax.herokuapp.com/

## Phase 1: `FollowToggle`

You will start by filling out the `FollowToggle` component, which takes a
provided follow/unfollow toggle button. When you click the button, the
`FollowToggle` will send the corresponding follow or unfollow AJAX request--no
page refresh!--and appropriately update the button's text. Between sending a
request and receiving the backend's response, the button's UI will reflect its
pending state: it will be disabled and display `Following...` or
`Unfollowing...`.

### Backend: `follow_toggle` partial

First, you'll modify the Rails partial for the follow/unfollow button to
accommodate frontend manipulation. Specifically, your frontend needs to know
which user to follow/unfollow and whether or not they start out followed or
unfollowed.

Head to __app/views/users/_follow_toggle.html.erb__. Notice that there are two
branches of logic differentiated by whether or not the `current_user` is
following the `user` associated with the toggle (represented by the
`is_following` variable):

1. If `current_user` is following `user`:
   1. Form `method`: `DELETE` (default `POST` method overwritten by hidden
      `input`)
   2. Button text: `Unfollow!`
2. If `current_user` is not following `user`:
   1. Form `method`: `POST` (default method)
   2. Button text: `Follow!`

Now, your frontend **could** figure out the user associated with this button via
the `form`'s `action` (a URL with the user's `id` at the end). You also
**could** figure out the follow state by checking for the presence/absence of a
hidden `input`. However, to make things a bit easier on yourself, you should
attach some [`data-*`] attributes to the button:

- `data-user-id` (`id` of `user`)
- `data-follow-state` (`"followed"` or `"unfollowed"`)

Fill these in, then head to any user's `show` page in your browser. Inspect the
follow/unfollow button in your browser's DevTools. Do you see the data
attributes attached? Does the `id` match the `id` of the user in the URL? If the
`data-follow-state` is `"followed"`, do you see the current user in the
`Followers` list on the right side of the page?

### Frontend: Entry file

Head to **app/javascript/application.js**. Now that you know what the `button`
elements look like that you need to select and pass to the `FollowToggle`
constructor, change the `followToggleSelector` variable from an empty string to
a CSS selector which selects these buttons. You can make sure the selector is
working by adding `console.log(el)` to the `forEach` callback.

### Frontend: `FollowToggle`

Open **app/javascript/follow_toggle.js**. In the constructor, save the
`toggleButton` element--provided as an argument--to a property
`this.toggleButton`.

Take a look at the rest of the `FollowToggle` skeleton. Two helper methods
have been provided: `get followState()` and `set followState(newState)`. These
define `followState` getter and setter methods, which, like getters and setters
in Ruby, allow you to use the syntax of accessing or assigning a property to
in fact call methods:

```js
// calls `get followState()`
// > returns `this.toggleButton.dataset.followState`
this.followState; 

// calls `set followState("banana")`
// > sets `this.toggleButton.dataset.followState` to "banana"
// > calls `this.render()`
this.followState = "banana"; 
```

Follow these MDN links to learn more: [`get`] and [`set`].

By using a getter and setter, you can easily access and change the value of the
`followState` data attribute stored on the follow toggle button as if it were an
instance property of the `FollowToggle` component. As a bonus, whenever you
change a button's `followState`, `this.render()` runs, which will eventually
update the button in accordance with the new `followState`.

Next, head back to the constructor and attach the `handleClick` method
to`toggleButton` as a `click` event handler. Don't forget to bind `this`! Inside
`handleClick`, start by calling `event.preventDefault()`. This is to prevent the
surrounding `form` from submitting; you'll be replacing this form submission
with an AJAX request shortly. Then, simply `console.log(this.followState)`.

Once you've done this, test that it's working by opening a user show page in the
browser and clicking on a follow toggle button. Do you see `followed` or
`unfollowed` logged in the browser console? Pretty cool!

> Ignore the invalid selector errors in the console; you will fill in the
> remaining selectors as you go through the practice.

Next, fill out the logic of `handleClick`:

- If `followState` is `"followed"`, call the `unfollow` method
- If `followState` is `"unfollowed"`, call the `follow` method

The next step is to submit requests to the backend in these methods to actually
follow or unfollow the user associated with the button.

### Frontend: API util

To separate the code for talking to your backend from the code related to
manipulating the DOM, a separate file, **app/javascript/util/api.js**, has been
included where you can define functions that generate AJAX requests to
particular endpoints (routes) in your backend. If you look at
**app/javascript/util/index.js**, you'll see the following line:

```js
export * as API from "./api";
```

This takes every named export from **api.js** and re-exports them as properties
of an object called `API`.

Meanwhile, Node allows you to import from any **index.js** file using the name
of its parent directory. Thus, you can import `API` in your top level files from
`./util` instead of `./util/index`. In fact, it is already imported in your
entry file, **app/javascript/application.js**, and assigned as a property of the
`window` so you can access and test your `API` functions from your browser
console.

Try adding the following to **app/javascript/util/api.js**:

```js
// ...

export const foo = "bar";
```

Refresh your browser and look at `API` in the console to see how you can access
named exports--such as `foo`--from **api.js**. After this, you can remove the
`foo` export.

If you look at the top of **api.js**, you will see a function `customFetch`
defined. Just like [`fetch`], it takes in a `url` string and `options` object as
arguments. For now, it starts by simply cloning `options.headers` using
JavaScript's [spread syntax][spread]. This structure is set up to allow you to
easily add default header properties to be merged with the provided
`options.headers`, something that you will be tasked with doing shortly.

After making any necessary adjustments to `options.headers`, the function
passes along the `url` and `options` to the real `fetch`, returning the result.
Eventually, you will modify this behavior as well; for now, `customFetch`
behaves just like `fetch`.

Below `customFetch`, define and export two functions from **api.js**:
`followUser(id)` and `unfollowUser(id)`. The `id` argument for each is the `id`
of the user to follow or unfollow. Inside each, return a call to
`customFetch`, supplying the appropriate relative URL and HTTP method to hit the
`follows#create` and `follows#destroy` backend routes. Run `rails routes` in
your terminal to determine the path and method combinations you need.

> **Note**: While you could make `followUser` and `unfollowUser` `async`
> functions that `await` their return values, doing so would not serve any
> useful purpose. Remember that `await` only pauses the **internal** execution
> of an `async` function until the specified promise resolves. These two
> functions do nothing but return the result of a call to `customFetch`. With no
> other asynchronous calls to sequence and no need to use or manipulate the
> value returned by `customFetch`, these functions have no need for `await`.
> What's more, since these functions have no need for `await`, they really don't
> need the `async` either.
>
> (Potential exception: you should still use `async` if you want synchronous
> exceptions rendered as rejected promises, but don't worry about that now.)

Test that your functions are hitting the right backend routes by calling
`API.followUser(<some-id>)` and `API.unfollowUser(<some-id>)` in your browser
console. Check your **server log** to ensure you're hitting the right controller
actions. You should see `Processing by FollowsController#create` and `Processing
by FollowsController#destroy` in your server log for follow and unfollow
requests, respectively. And you should see a `user_id` parameter pointing to the
`id` argument you supplied.

If you do--great, you got the right URL and HTTP method! However, you'll also
see an error:

```text
ActionController::InvalidAuthenticityToken - Can't verify CSRF token authenticity
```

This is because you haven't supplied an authenticity token in your headers.
Thankfully, Rails includes an authenticity token in each HTML response within a
`meta` tag in the page's `head` element. This value has been retrieved already
and saved to the variable `csrfToken` at the top of **api.js**. You must simply
add a header of `X-CSRF-Token` in `customFetch` whose value is this retrieved
token. This is where the aforementioned ability to add default header values in
`customFetch` comes in handy!

After adding this header, refresh your browser and test your `API` functions in
the browser console again. (Be sure to submit requests to follow users you
currently don't, and vice versa!) The requests should now be valid and the
`create` and `destroy` actions executed--nice! If you refresh a user's show page
after following/unfollowing them, you should see the text content of the follow
toggle button change!

However, if you look in your server log, you'll see that the server's response
in `create` and `destroy` is to redirect to the page from which the request was
sent (effectively forcing a refresh). This is good for a regular form
submission, where a refresh will update the contents of the page. However,
you'll be updating the contents of the page via JavaScript to avoid a full page
refresh (otherwise, why use AJAX?). Your backend is doing unnecessary work.

It'd be easier in this case if the backend simply responded with JSON data
containing details about the follow that was created or destroyed. Is there some
way to tell your backend to provide a different response for AJAX requests? Yes,
via the `Accept` header!

### Frontend and backend: `Accept` header

When you make an HTTP request to a server, you can request a specific format--or
rank a list of acceptable formats--that you'd like the server to respond with.
Examples includes `text/html` if you want an HTML response or `application/json`
if you want a JSON response.

By default, browser-generated requests, such as those created by clicking a
link, refreshing the page, or submitting a form, rank `text/html` as their top
preference in the [`Accept`] header. Meanwhile, `fetch` defaults to a value of
`*/*` for `Accept`, indicating it will take any kind of response from the
server. If, however, you supply a value of `application/json` in your `fetch`
request, the server will then know to treat the request differently than a
browser-generated request. Go ahead and add such a header to `customFetch`.

In Rails, you can create custom responses for different requested formats using
the [`respond_to`] method, which looks at the `Accept` header under the hood.
Right now, you only have a response set for requests that will accept an HTML
response. Add the following to your `create` action:

```rb
# app/controllers/follows_controller.rb

def create
  # ...
  respond_to do |format|
    # ...html response
    format.json { render json: current_user.slice(:id, :username) }
  end
end
```

> Note that this uses the Ruby [`slice`][ruby-slice] method, not the JavaScript
> version!

Do the same in `destroy`, but send back only the `id` of the `current_user`:

```rb
# app/controllers/follows_controller.rb

def destroy
  # ...
  respond_to do |format|
    # ...html response
    format.json { render json: current_user.slice(:id) }
  end
end
```

Supposing you are not already following the user with the `id` of 5, test
`followUser` in your browser console:

```js
res = await API.followUser(5)
await res.json()
```

You should see an object with the properties of the newly created `follow`! And
if you look in your server log, you should see `Processing by
FollowsController#create as JSON`.

Now you can make your final changes (for now) to `customFetch` in
**app/javascript/util/api.js**. First, instead of returning `await fetch(url,
options)`, save the response to a variable (`response`), and then return
`response.json()`.

However, you only want to return JSON data if the request was successful. Thus,
only return `response.json()` when `response.ok` is true--i.e., when
`response.status` is 200-level. If `response.ok` is not true, then `throw` the
`response` object (thereby rejecting the Promise returned from `customFetch`).

> `response.json()` is an asynchronous function call, so you could `await` the
> result. Once again, however, doing so would not serve any purpose here. In
> contrast, you **do** need to `await` the result of `fetch(url, options)` when
> assigning it to `response` because the function's subsequent logic depends on
> the value of `response`. (Question: Was the `await` necessary in the original
> `return await fetch(url, options)`?)

Go ahead and test `await API.followUser(<id>)` and `await
API.unfollowUser(<id>)` in your browser console. You should see a JSON response
when making a valid request and an `Uncaught (in promise)` error when making an
invalid request.

### Frontend: Completing `FollowToggle`

Your API functions are now complete! Time to call them from `follow` and
`unfollow` in `FollowToggle` (**app/javascript/follow_toggle.js**). In each,
call and `await` the appropriate `API` function, supplying the user id stored in
the button's data attributes. Before making the request, set `followState` to
`following` or `unfollowing`, as appropriate. After the request is
completed, set `followState` to `unfollowed` or `followed`, as appropriate.

Since your `followState` setter calls `this.render`, you can update the UI
appropriately there to reflect the current `followState`. For now, just
`console.log(this.followState)`, and then test in the browser by visiting a
user's show page and clicking the follow toggle. Supposing you start out not
following a given user, you should see `following` logged, and then about a
second later (due to some artificial latency on the backend), `followed`. Nice!

Finally, fill out the `case` statements in `render`. In each, you will set the
`disabled` property of `this.toggleButton`, as well as its `innerText`, like so:

- `"followed"`:
  - not disabled
  - text: `"Unfollow!"`
- `"unfollowed"`:
  - not disabled
  - text: `"Follow!"`
- `"following"`:
  - disabled
  - text: `"Following..."`
- `"unfollowing"`:
  - disabled
  - text: `"Unfollowing..."`

Some CSS has already been defined which greys out a button when it has the
`disabled` property. Go ahead and test your pending UI in the browser! Pretty
cool, huh?

**Now is a good time to commit and ask for a code review.**

## Note on upcoming phases

In the upcoming phases, you will follow a similar pattern to that of
`FollowToggle`:

1. Investigate the existing backend implementation of a feature.
2. Adjust the backend as needed to accommodate new frontend functionality (such
   as by adding data attributes to elements or by adding custom `format.json`
   responses in controllers).
3. Select the right elements in your entry file to pass to the constructor of
   the corresponding component.
4. Write a `constructor` that, among other things, attaches event listener(s) to
   the provided element and/or its children.
5. In these event handlers, make AJAX requests, implement a pending UI where
   warranted, and update the DOM after the request is complete.

You might add additional JavaScript interactivity on top of the basic structure
outlined here. But you will follow this general course for each phase.

[`data-*`]: https://developer.mozilla.org/en-US/docs/Web/HTML/Global_attributes/data-*
[`get`]: https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Functions/get
[`set`]: https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Functions/set
[`fetch`]: https://developer.mozilla.org/en-US/docs/Web/API/fetch
[spread]: https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Operators/Spread_syntax#spread_in_object_literals
[`Accept`]: https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Accept
[`respond_to`]: https://api.rubyonrails.org/classes/ActionController/MimeResponds.html#method-i-respond_to
[ruby-slice]: https://ruby-doc.org/core-3.1.1/Hash.html#method-i-slice