import { API, debounce } from "./util";
import FollowToggle from "./follow_toggle";

export default class UsersSearch {
  constructor(rootEl) {
    this.rootEl = rootEl;
    this.input = this.rootEl.querySelector("input[name=query]");
    this.usersUl = rootEl.querySelector("ul.users");
    this.loadingSpan = this.rootEl.querySelector(".loading-indicator");

    this.debouncedSearch = debounce(this.search.bind(this), 300);

    this.input.addEventListener("input", this.handleInput.bind(this));
    rootEl.querySelector(".search-form").addEventListener("submit", (e) => {
      e.preventDefault();
    });
  }

  async handleInput() {
    // Your code here
  }

  async search(query) {
    if (query) {
      // Your code here
    } else {
      // Your code here
    }
  }

  renderResults(users) {
    const userLis = users.map((user) => {
      const li = document.createElement("li");
      const userAnchor = this.createUserAnchor(user);
      const followButton = this.createFollowButton(user);

      li.append(userAnchor, followButton);
      return li;
    });

    this.usersUl.replaceChildren(...userLis);
  }

  // Helper methods...

  createUserAnchor({ id, username }) {
    const anchor = document.createElement("a");
    anchor.innerText = "@" + username;
    // Your code here
    return anchor;
  }

  createFollowButton({ id, following }) {
    const followButton = document.createElement("button");
    // Your code here
    return followButton;
  }
}