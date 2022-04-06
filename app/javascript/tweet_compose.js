import { API, broadcast } from "./util";

export default class TweetCompose {
  constructor(formEl) {
    this.formEl = formEl;
    this.submitButton = formEl.querySelector("button[type=submit]");
    this.errorsEl = document.querySelector("ul.errors");
    this.bodyTextArea = formEl.querySelector("textarea");
    this.mentionedUserSelect = formEl.querySelector("select");
    this.charsRemainingEl = formEl.querySelector(".chars-remaining");

    this.bodyTextArea.addEventListener("input", this.handleInput.bind(this));
    this.formEl.addEventListener("submit", this.handleSubmit.bind(this));

    this.bodyTextArea.value = "";
    this.charsRemainingEl.innerText = 280;
  }

  // Handles input events on the textarea
  handleInput() {
    const charsRemaining = 280 /* REPLACE */;
    // Your code here
    if (charsRemaining >= 0 && !this.loading) {
      this.submitButton.disabled = false;
      this.setErrors([]);
    }
  }

  // Handles submit events on the form
  async handleSubmit(event) {
    event.preventDefault();
    // Your code here

    try {
      // Your code here
    } catch (errorResponse) {
      if (!(errorResponse instanceof Response)) throw errorResponse;
      const data = await errorResponse.json();
      this.setErrors(data);
    }

    // Your code here
  }

  // If the tweet body has too many chars; set errors and return `false`
  validate() {
    if (this.bodyTextArea.value.length > 280) {
      this.setErrors(["Tweet cannot be more than 280 characters."]);
      this.submitButton.disabled = true;
      return false;
    } else {
      return true;
    }
  }

  // Takes array of error messages; creates corresponding `li`s in errors `ul`
  setErrors(errors) {
    const errorLis = errors.map((message) => {
      const li = document.createElement("li");
      li.innerText = message;
      return li;
    });

    this.errorsEl.replaceChildren(...errorLis);
  }

  // Reset the form to its initial state (empty body, no errors, no mention)
  clear() {
    this.setErrors([]);
    this.charsRemainingEl.innerText = 280;
    this.bodyTextArea.value = "";
    this.mentionedUserSelect.selectedIndex = 0;
  }

  // Set `this.loading` to true / false, and update submit button UI accordingly
  setLoading(state) {
    this.loading = state;
    this.submitButton.innerText = this.loading ? "Posting..." : "Post Tweet!";
    this.submitButton.disabled = this.loading;
  }

  // Returns an object representing the tweet to be created
  get tweetData() {
    return {
      body: this.bodyTextArea.value,
      mentionedUserId: this.mentionedUserSelect.value
    };
  }
}