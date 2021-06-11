//assets/js/chart.js
let ChartHook = {
  mounted() {
    console.log("mounted", this.el)
  },
  updated() {
    let price = this.el.dataset.price;
    let timestamp = parseInt(this.el.dataset.tradedAt);
    let tradedAt = new Date(timestamp)

    console.log(tradedAt, price)
  }
}

export { ChartHook }