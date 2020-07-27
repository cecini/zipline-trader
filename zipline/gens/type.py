# encoding: UTF-8

from collections import namedtuple

### Order Category
BUY = 0									#买入
SELL = 1								#卖出
LEVERAGE_BUY = 2						#融资买入
RENT_COUPONS_TO_SELL = 3				#融券卖出
BUY_COUPONS_TO_RETURN_COUPONS = 4		#买券还券
SELL_COUPONS_TO_RETURN_MONEY = 5		#卖券还款
USE_COUPONS_TO_RETURN_COUPONS = 6		#现券还券

### Order Price Type
LIMIT_CHARGE = 0						#上海限价委托,深圳限价委托
SZ_OTHER_OPTIMAL = 1					#(市价委托)深圳对方最优价格
SZ_SELF_OPTIMAL = 2						#(市价委托)深圳本方最优价格
SZ_MARKET_ORDER = 3						#(市价委托)深圳即时成交剩余撤销
FIVE_LEVEL_MARKET_ORDER = 4				#(市价委托)上海五档即成剩撤,深圳五档即成剩撤
SZ_DEAL_ALL_OR_CANCEL = 5				#(市价委托)深圳全额成交或撤销
SH_REAL_DEAL_TO_LIMIT = 6				#(市价委托)上海五档即成转限价

### Data Category
BALANCE = 0								#资金
SHARES = 1								#股份
TODAY_ENTRUSTMENT = 2					#当日委托
TODAY_TRANSACTION = 3					#当日成交
CAN_CANCEL = 4							#可撤单
GDDM = 5								#股东代码
MARGIN_DEBT = 6							#融资余额
MARGIN_BALANCE = 7						#融券余额
FINANCING_STOCKS = 8					#可融证券

### History Data Category
HISTORY_ENTRUST = 0						#历史委托
HISTORY_TRANSACTION = 1					#历史成交
DELIVERY_ORDER = 2						#交割单


Order = namedtuple("Order", [
    'dt',
    'symbol',
    'name',
    'status',
    'price',
    'amount',
    'order_id',
    'average_cost',
    'filled',
])

OrderRt = namedtuple("OrderRt",[
    "order_id",
    "message",
])

Transaction = namedtuple("Transaction", [
    "id",
    'asset',
    'amount',
    'dt',
    'price',
    'order_id',
    'commission',
])

Position = namedtuple("Position",[
    'sid',
    'available',
    'amount',
    'cost_basis',
    'last_sale_date',
    'last_sale_price'
])

Portfolio = namedtuple("Portfolio",[
    'portfolio_value',
    'cash',
    'positions_value'
])
