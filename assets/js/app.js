import css from "../css/app.css";
import "phoenix_html"
import { Socket } from "phoenix"
import { LiveSocket, debug, View } from "phoenix_live_view"

let Hooks = {}

Hooks.PhoneNumber = {
  mounted() {
    let pattern = /^(\d{3})(\d{3})(\d{4})$/
    this.el.addEventListener("input", e => {
      let match = this.el.value.replace(/\D/g, "").match(pattern)
      if (match) {
        this.el.value = `${match[1]}-${match[2]}-${match[3]}`
      }
    })
  }
}

let scrollAt = () => {
  let scrollTop = document.documentElement.scrollTop || document.body.scrollTop
  let scrollHeight = document.documentElement.scrollHeight || document.body.scrollHeight
  let clientHeight = document.documentElement.clientHeight

  return scrollTop / (scrollHeight - clientHeight) * 100
}

Hooks.InfiniteScroll = {
  page() { return this.el.dataset.page },
  mounted() {
    this.pending = this.page()
    window.addEventListener("scroll", e => {
      if (this.pending == this.page() && scrollAt() > 90) {
        this.pending = this.page() + 1
        this.pushEvent("load-more", {})
      }
    })
  },
  updated() { this.pending = this.page() }
}

let serializeForm = (form) => {
  let formData = new FormData(form)
  let params = new URLSearchParams()
  for (let [key, val] of formData.entries()) { params.append(key, val) }

  return params.toString()
}

let Params = {
  data: {},
  set(namespace, key, val) {
    if (!this.data[namespace]) { this.data[namespace] = {} }
    this.data[namespace][key] = val
  },
  get(namespace) { return this.data[namespace] || {} }
}

Hooks.SavedForm = {
  mounted() {
    this.el.addEventListener("input", e => {
      Params.set(this.viewName, "stashed_form", serializeForm(this.el))
    })
  }
}

window.googletag = window.googletag || { cmd: [] };

const adModule = {
  destroySlotById(id) {
    if (window.googletag && googletag.pubadsReady) {
      const allSlots = googletag.pubads().getSlots();
      const foundSlotReference = allSlots.find(slot => slot.getSlotElementId() === id);

      const destroyResult = googletag.destroySlots([foundSlotReference]);
      console.log(`destroySlots("${id}") result`, destroyResult);

      if (destroyResult) {
        document.getElementById(id).dataset.loaded = false;
      }
      return destroyResult;
    }
    return false;
  },
  setupSlotById(id) {
    const adContainer = document.getElementById(id);
    if (adContainer.dataset.loaded === "true") return

    // use the DOM to maintain state around if the ad was loaded or not
    // also, this protects against both mounted() and updated() firing on page load
    adContainer.dataset.loaded = true;

    googletag.cmd.push(() => {
      const adUnitPath = adContainer.dataset.adUnitPath;

      googletag
        .defineSlot(adUnitPath, [300, 250], adContainer.id)
        .addService(googletag.pubads());

      googletag.enableServices();
      googletag.display(adContainer.id);
    });
  }
}

Hooks.Ads = {
  mounted() {
    console.log('mounted() hook')

    adModule.setupSlotById('ad-1');
    adModule.setupSlotById('ad-2');
  },
  updated() {
    console.log('updated() hook');

    // only set up the second ad slot since it gets destroyed every time the list updates
    adModule.setupSlotById('ad-2');
  },
  beforeUpdate() {
    console.log('beforeUpdate() hook')
    // only destroy the second ad slot since it's inside a dynamic list
    // and can't be ignored by phx-update="ignore"
    adModule.destroySlotById('ad-2');
  }
}

let csrfToken = document.querySelector("meta[name='csrf-token']").getAttribute("content");
let liveSocket = new LiveSocket("/live", Socket, { hooks: Hooks, params: { _csrf_token: csrfToken } })

liveSocket.connect()

