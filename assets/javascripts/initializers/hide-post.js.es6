import I18n from "I18n";
import { withPluginApi } from "discourse/lib/plugin-api";
import { ajax } from "discourse/lib/ajax";
import { popupAjaxError } from "discourse/lib/ajax-error";

export default {
  name: "dsc-ghostban",
  initialize() {
    withPluginApi("0.11.0", api => {
      const currentUser = api.getCurrentUser();
      if (!currentUser) return;

      //if (
        //currentUser.staff
      //) //{
        api.attachWidgetAction("post-menu", "hidePost", function () {
          const model = this.attrs;
        });

        api.addPostMenuButton("hide-post", () => {
          let icon = "far-eye";
          return {
            action: "hidePost",
            icon: icon,
            title: themePrefix("Hide Post"),
            position: "second-last-hidden"
          };
        });
      //}
    });
  }
};