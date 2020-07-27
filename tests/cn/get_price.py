from zipline.research import get_pricing

df = get_pricing('000001',start_date='20171001', end_date='2017-12-28',fields='close',frequency='daily')
print(df)
df = get_pricing('000001',start_date='20171001', end_date='2017-12-28',fields='close',frequency='minute')
print(df)