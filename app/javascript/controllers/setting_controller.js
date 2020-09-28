// Visit The Stimulus Handbook for more details
// https://stimulusjs.org/handbook/introduction
//
// This example controller works with specially annotated HTML like:
//
// <div data-controller="hello">
//   <h1 data-target="hello.output"></h1>
// </div>

import { Controller } from "stimulus";
import LocalStore from "../utility/local-store";
import DeviceDetector from "../utility/deviceDetector";

let settings = {};

export default class extends Controller {
  connect() {
    this.store = new LocalStore();
    this.loadSettings();
    this.device = new DeviceDetector();

    window.addEventListener("resize", () => this.resizeHandler());

    this.bindTooltip();
    this.bindFontSize();
    this.updateFontSize();
    this.bindReset();

    this.element[this.identifier] = this;
  }

  resizeHandler() {
    this.mobile = this.device.isMobile();
    this.updateFontSize();
  }

  loadSettings() {
    let saved;

    try {
      saved = JSON.parse(this.store.get("setting") || "{}");
    } catch {
      saved = {};
    }

    let defaultsSettings = this.defaultSetting();
    this.settings = Object.assign(defaultsSettings, saved);

    if (this.settings.translations.length == 0) {
      this.settings.translations = defaultsSettings.translations;
    }
  }

  bindTooltip() {
    $(`[data-value=${this.get("tooltip")}]`).attr("checked", "checked");

    $("[name=tooltip-display]").on("change", event => {
      this.set("tooltip", $(event.target).data("value"));
    });
  }

  bindReset() {
    $("#reset-settings").on("click", event => this.resetSetting(event));
  }

  bindFontSize() {
    $("[data-trigger=font-size]").on("click", e => this.handleFontSize(e));
  }

  getTooltipType() {
    return this.get("tooltip");
  }

  saveSettings() {
    let setting = JSON.stringify(this.settings);
    this.store.set("setting", setting);
  }

  defaultSetting() {
    return {
      font: "v1",
      tooltip: "t",
      recitation: 7,
      nightMode: false,
      readingMode: false,
      translations: [131],
      repeatType: "single",
      repeatCount: 1,
      repeatFrom: null,
      repeatTo: null,
      repeatIteration: 1,
      autoScroll: true,
      wordFontSize: {
        mobile: 30,
        desktop: 30
      },
      translationFontSize: {
        mobile: 16,
        desktop: 16
      }
    };
  }

  updateFontSize() {
    $("style.setting").remove();

    let fontStylesheet = document.createElement("style");
    fontStylesheet.classList.add("setting");
    document.head.appendChild(fontStylesheet);

    let device = this.mobile ? "mobile" : "desktop";

    let wordFontSize = this.get("wordFontSize")[device];
    let translationFontSize = this.get("translationFontSize")[device];

    fontStylesheet.sheet.insertRule(
      `.w {font-size: ${wordFontSize}px !important}`
    );

    fontStylesheet.sheet.insertRule(
      `.translation {font-size: ${translationFontSize}px !important}`
    );
  }

  get(key) {
    return this.settings[key];
  }

  set(key, value) {
    this.settings[key] = value;
    this.saveSettings();
    document.body.setting = this;
  }

  setAudioSetting(e) {
    let value = Number(e.target.value);
    if(e.target.type === 'checkbox') {
        value = e.target.value === 'on' ? 'range' : 'single';
    }
    const setting = e.target.dataset.setting;
    this.set(setting, value);
  }

  handleFontSize(e) {
    e.preventDefault();

    const data = e.target.dataset;
    const targetDom = $(data.target);
    const increment = +data.increment;

    let size = parseInt(targetDom.css("font-size"), 10);
    size = size + increment;

    let device = this.mobile ? "mobile" : "desktop";

    if (".word" == data.target) {
      let sizes = this.get("wordFontSize");
      sizes[device] = size;
      this.set("wordFontSize", sizes);
    } else {
      let sizes = this.get("translationFontSize");
      sizes[device] = size;
      this.set("translationFontSize", sizes);
    }

    this.updateFontSize();
  }

  resetSetting(e) {
    $("body").removeClass("night");
    this.settings = this.defaultSetting();
    this.saveSettings();

    this.resetPage();
  }

  resetPage() {
    $("style.setting").remove();
  }
}
