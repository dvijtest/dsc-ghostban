import { withPluginApi } from "discourse/lib/plugin-api";
import { ajax } from "discourse/lib/ajax";
import { popupAjaxError } from "discourse/lib/ajax-error";
import I18n from "I18n";

export default {
    name: "hide-post-button",
    initialize() {
      withPluginApi("0.11.0", api => {
        const currentUser = api.getCurrentUser();
        if (!currentUser) return;
  
        if (
          currentUser.staff
        ) {
          api.attachWidgetAction("post-menu", "toggleHide", function() {
            const model = this.attrs;
          });
  
          api.addPostMenuButton("toggle-hide", () => {
            return {
              action: "toggleHide",
              icon: "file-alt",
              //className: "raw-post",
              title: themePrefix("button_title"),
              position: "second-last-hidden"
            };
          });
        }
      });
    }
  };