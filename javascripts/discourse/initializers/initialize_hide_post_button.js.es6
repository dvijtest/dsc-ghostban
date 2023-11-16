import I18n from "I18n";
import { withPluginApi } from "discourse/lib/plugin-api";
import showModal from "discourse/lib/show-modal";

export default {
  name: "hide-post-button",
  initialize() {
    withPluginApi("0.8.7", api => {
      const currentUser = api.getCurrentUser();
      if (!currentUser) return;

      if (
        currentUser.staff ||
        currentUser.trust_level >= settings.min_trust_level
      ) {
        api.attachWidgetAction("post-menu", "showHide", function() {
          const model = this.attrs;
          showModal("hidePost", {
            model,
            title: themePrefix("modal_title")
          });
        });

        api.addPostMenuButton("show-hide", () => {
          return {
            action: "showHide",
            icon: "file-alt",
            className: "hide-post",
            title: themePrefix("button_title"),
            position: "second-last-hidden"
          };
        });
      }
    });
  }
};