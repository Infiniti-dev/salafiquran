import { Controller } from "stimulus";

export default class extends Controller {
  connect() {
    this.bindRemoteSelect2();
  }

  bindRemoteSelect2() {
    let el = $(this.element);

    // reading from data allows <input data-searchable_select='{"tags": ['some']}'>
    // to be passed to select2
    let options = {
      multiple: el.data("multiple") || false,
      tags: el.data("tags") || false // for adding items on the fly
    };

    if (el.data("parent")) {
      options["dropdownParent"] = $(el.data("parent"));
    }

    const url = el.data("ajaxUrl");
    const that = this;

    if (url) {
      $.extend(options, {
        minimumInputLength: 0,
        ajax: {
          url: url,
          dataType: "json",
          cache: true,

          data: function(params) {
            return {
              query: params.term,
              page: that.pageParamWithBaseZero(params)
            };
          }
        },
        escapeMarkup: function(text) {
          return text;
        }
      });
    }

    options["templateResult"] = item => {
      return this.dropdownItemTemplate(item);
    };
    /*
        options["templateSelection"] = item => {
            return this.resultTemplate(item);
        };*/

    this.select = el.select2(options);
  }

  dropdownItemTemplate(item) {
    if (item.loading) return item.text;

    if (!item.description) {
      return item.text;
    }

    let container = $(`
        <div class='select2-result'>
          <div class='select2-result__title'>${item.description}</div>
      </div>`);

    return container;
  }

  resultTemplate(item) {
    return item.text;
  }

  disconnect() {
    const select = this.select.data("select2");
    if (select) select.destroy();
  }

  pageParamWithBaseZero(params) {
    return params.page ? params.page - 1 : undefined;
  }
}
