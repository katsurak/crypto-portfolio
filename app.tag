
<app>

    <h3>日本円で見れちゃうやつ</h3>
    <p>左のリストから保有している通貨を選んで、右の表に保有枚数を入れます<br>
    PoloniexとBittrexのみ対応です！</p>

    <div class="sidebar">
        <ul each={ markets }>
            <li each={ coins } class={ selected: selected } onclick={ toggleCoin }>
                { marketName } { symbol }
            </li>
        </ul>
    </div>
    <main class="main">
        <table>
            <thead>
                <tr>
                    <th>Market</th>
                    <th>通貨</th>
                    <th>Bid</th>
                    <th>Ask</th>
                    <th>Change(24h)</th>
                    <th>Balance</th>
                    <th>Total</th>
                    <th>Delete</th>
                </tr>
            </thead>
            <tbody each={ markets }>
                    <tr each={ coins } if={ selected }>
                        <td>{ parent.marketName }</td>
                        <td>{ symbol }</td>
                        <td>{ number_format(bid, 4) }円</td>
                        <td>{ number_format(ask, 4) }円</td>
                        <td>{ number_format(change, 2) }%</td>
                        <td><input type="text" ref="balance_{ symbol }" value="{ balance }" oninput="{ updateBalance }"></td>
                        <td><span class="total">{ number_format(balance * bid) }円</span></td>
                        <td><button onclick={ toggleCoin }>Delete</button></td>
                    </tr>
            </tbody>
        </table>
    </main>

    <style>
        .sidebar {
            float: left;
            width: 220px;
        }

        ul {
            list-style: none;
            margin: 0;
            padding: 0;
        }

        ul li {
            margin: 0;
            padding: 6px 10px;
            border-bottom: 1px solid #DDD;
            cursor: pointer;
        }

        ul li.selected {
            background: #444;
            color: #FFF;
        }

        .main {
            margin-left: 240px;
        }

        table {
            border-collapse: collapse;
            width: 100%;
        }

        table th,
        table td {
            padding: 5px 8px;
            border: 1px solid #DDD;
        }
    </style>

    <script>
        function sortBySymbol(a, b) {
            if (a.symbol < b.symbol) {
                return -1;
            } else if (a.symbol > b.symbol) {
                return 1;
            } else {
                return 0;
            }
        }

        function getPoloniexCoins(data, btc_rate) {
            var marketName = 'Poloniex';
            var coins = [];

            for (var symbol in data) {
                if (data.hasOwnProperty(symbol)) {
                    var item = data[symbol];

                    if (!startsWith(symbol, 'BTC_')) {
                        continue;
                    }

                    // BTC_XXX -> XXX
                    symbol = symbol.substr(4);

                    coins.push({
                        marketName: marketName,
                        symbol: symbol,
                        bid: item.highestBid * btc_rate,
                        ask: item.lowestAsk * btc_rate,
                        change: item.percentChange * 100,
                        balance: null,
                        total: 0,
                        selected: false
                    });
                }
            }

            return {
                marketName: marketName,
                coins: coins.sort(sortBySymbol)
            };
        }

        function getBittrexCoins(data, btc_rate) {
            var marketName = 'Bittrex';
            var coins = [];

            data.result.forEach(function (item) {
                if (!startsWith(item.MarketName, 'BTC-')) {
                    return;
                }

                // BTC-XXX -> XXX
                symbol = item.MarketName.substr(4);

                coins.push({
                    marketName: marketName,
                    symbol: symbol,
                    bid: item.Bid * btc_rate,
                    ask: item.Ask * btc_rate,
                    change: (item.Last - item.PrevDay) / item.Last * 100,
                    balance: null,
                    total: 0,
                    selected: false
                });
            });

            return {
                marketName: marketName,
                coins: coins.sort(sortBySymbol)
            };
        }

        function getStore() {
            var store = localStorage.getItem('store');
            return store ? JSON.parse(store) : {};
        }

        function saveStore(store) {
            localStorage.setItem('store', JSON.stringify(store));
        }

        function restore(markets, store) {
            markets.forEach(function (market) {
                if (store[market.marketName] !== undefined) {
                    market.coins.forEach(function (coin) {
                        if (store[market.marketName][coin.symbol] !== undefined) {
                            coin.selected = true;
                            coin.balance = store[market.marketName][coin.symbol];
                        }
                    });
                }
            });
        }

        this.updateBalance = function (e) {
            var item = e.item;
            var store = getStore();

            item.balance = e.target.value;

            if (store[item.marketName] === undefined) {
                store[item.marketName] = {};
            }
            store[item.marketName][item.symbol] = item.balance;

            saveStore(store);
        }

        this.toggleCoin = function (e) {
            var item = e.item;
            var store = getStore();

            if (item.selected) {
                item.selected = false;
                if (store[item.marketName] !== undefined && store[item.marketName][item.symbol] !== undefined) {
                    delete store[item.marketName][item.symbol];
                }
            } else {
                item.selected = true;
                console.log(store);
                if (store[item.marketName] === undefined) {
                    store[item.marketName] = {};
                }
                store[item.marketName][item.symbol] = item.balance;
            }

            saveStore(store);
        }

        this.markets = [];
        this.markets.push(getPoloniexCoins(opts.poloniex, opts.btc_rate.bid));
        this.markets.push(getBittrexCoins(opts.bittrex, opts.btc_rate.bid));

        restore(this.markets, getStore());
    </script>

</app>
