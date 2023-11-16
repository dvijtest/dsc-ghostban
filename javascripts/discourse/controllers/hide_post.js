import Controller from "@ember/controller";
import ModalFunctionality from "discourse/mixins/modal-functionality";

export default Controller.extend(ModalFunctionality, {
  hidePost: null,
  loading: true,

  init() {
    this._super(...arguments);
    this.addObserver("model.shareUrl", () => {
      this._resetRaw();
      this._setRaw();
    });
  },

  _setRaw() {
    const httpRequest = new XMLHttpRequest();
    if (!httpRequest) return;

    httpRequest.onreadystatechange = () => {
      if (httpRequest.readyState !== XMLHttpRequest.DONE) return;

      if (httpRequest.status === 200) {
        this.setProperties({
          loading: false,
          hidePost: httpRequest.responseText
        });
      } else {
        this.setProperties({
          loading: false,
          hidePost: I18n.t(themePrefix("loading_error_message"))
        });
      }
    };

    const withoutShareParam = this.model.shareUrl.split("?").shift();
    const splitUrl = withoutShareParam.split("/");
    let hideLink;

    if (splitUrl.length === 4) {
      hideLink = splitUrl.pop();
    } else {
      hideLink = splitUrl.slice(-2).join("/");
    }

    httpRequest.open("GET", `/hide/${hideLink}`);
    httpRequest.send();
  },

  _resetRaw() {
    this.setProperties({
      loading: true,
      hidePost: null
    });
  }
});