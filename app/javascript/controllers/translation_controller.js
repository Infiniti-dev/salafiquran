import { Controller } from "stimulus";
import Tooltip from "bootstrap/js/src/tooltip";

var PRE_DEFINED_FOOTNOTES = {
  sg: "Singular",
  pl: "Plural",
  dl:
    "<b>Dual</b> <br/> A form for verbs and pronouns in Arabic language when addressing two people" //A form for verbs and pronouns in Arabic language when addressing two people
};

export default class extends Controller {
  connect() {
    this.bindFootnotes();
  }

  bindFootnotes() {
    let el = $(this.element);
    let foodnotes = el.find("sup");
    foodnotes.click(e => {
      e.preventDefault();
      e.stopImmediatePropagation();

      var target = e.target;

      var id = target.getAttribute("foot_note");

      if (id && id.length > 0) {
        let existing = el.find(`#footnote-${id}`);
        if (existing.length > 0) {
          return existing.toggleClass("d-none");
        }

        fetch(`/foot_note/${id}`, {
          headers: { "X-Requested-With": "XMLHttpRequest" }
        })
          .then(resp => resp.text())
          .then(text => {
            el.find("#footnotes").html(text);
          });
      }
    });

    foodnotes.each((i, dom) => {
      let text = dom.innerText.replace(" ", "");

      if (PRE_DEFINED_FOOTNOTES[text]) {
        new Tooltip(dom, {
          title: PRE_DEFINED_FOOTNOTES[text],
          html: true,
          direction: "top",
          sanitize: false
        });
      }
    });
  }

  disconnect() {}
}
