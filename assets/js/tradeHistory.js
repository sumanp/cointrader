// assets/js/tradeHistory.js

let TradeHistoryHook = {
  updated() {
    if (this.el.rows.length > 10) {
      this.el.deleteRow(-1);
      // The updated callback is invoked every time the table is updated and we cap the number of rows to 10.
    }
  }
}

export { TradeHistoryHook }