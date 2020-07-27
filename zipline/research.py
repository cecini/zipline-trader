from zipline.data.data_portal import DataPortal
from zipline.finance.trading import TradingEnvironment

import pandas as pd
from functools import partial

from zipline.data.bundles.core import load
from zipline.data.data_portal import DataPortal
from zipline.finance.trading import TradingEnvironment
from zipline.pipeline.data import USEquityPricing
from zipline.pipeline.loaders import USEquityPricingLoader
from zipline.utils.calendars import get_calendar
from zipline.utils.factory import create_simulation_parameters
from zipline.gens.brokers.broker import Broker
from zipline.data.data_portal_live import DataPortalLive

from zipline.data.cn_loader import load_market_data
from zipline.algorithm_live import LiveTradingAlgorithm
from zipline.algorithm import TradingAlgorithm

import os
import re
import sys
import warnings
from runpy import run_path

environ = os.environ
bundle_data = load('tdx')
prefix, connstr = re.split(
    r'sqlite:///',
    str(bundle_data.asset_finder.engine.url),
    maxsplit=1,
)
first_trading_day = \
    bundle_data.equity_minute_bar_reader.first_trading_day
env = TradingEnvironment(load=load_market_data, bm_symbol='000300', asset_db_path=connstr, environ=environ)
calendar = get_calendar('SHSZ')
data = DataPortal(
    env.asset_finder, calendar,
    first_trading_day=first_trading_day,
    equity_minute_reader=bundle_data.equity_minute_bar_reader,
    equity_daily_reader=bundle_data.equity_daily_bar_reader,
    adjustment_reader=bundle_data.adjustment_reader,
)


def run_pipeline(pipeline, start_date, end_date, chunksize=None):
    pass


def lookup_symbols(symbols, symbol_reference_date=calendar.last_session, handle_missing='log'):
    return data.asset_finder.lookup_symbol(symbols, symbol_reference_date)


def prices(assets, start, end, frequency='daily', price_field='price', symbol_reference_date=calendar.last_session,
           start_offset=0):
    return get_pricing(assets, start, end, symbol_reference_date, frequency, price_field, start_offset=start_offset)


def returns(assets, start, end, periods=1, frequency='daily', price_field='price',
            symbol_reference_date=calendar.last_session):
    pass


def volumes(assets, start, end, frequency='daily', symbol_reference_date=calendar.last_session, start_offset=0):
    pass


def log_prices(assets, start, end, frequency='daily', price_field='price', symbol_reference_date=calendar.last_session,
               start_offset=0):
    pass


def log_returns(assets, start, end, periods=1, frequency='daily', price_field='price',
                symbol_reference_date=calendar.last_session):
    pass


def get_pricing(symbols, start_date='2013-01-03', end_date='2014-01-03', symbol_reference_date=calendar.last_session,
                frequency='daily',
                fields='close', handle_missing='raise', start_offset=0):
    if not isinstance(symbols, list):
        symbols = [symbols]

    if isinstance(symbols[0], str):
        symbols = [lookup_symbols(symbol, symbol_reference_date) for symbol in symbols]

    if isinstance(start_date, str):
        start_date = pd.to_datetime(start_date, utc=True)
        end_date = pd.to_datetime(end_date, utc=True)
    idx = calendar.all_sessions.searchsorted(end_date)
    end_date = calendar.all_sessions[idx - 1]

    if frequency in ['1d', 'daily']:
        frequency = '1d'
        data_frequency = 'daily'
        bar_count = calendar.session_distance(start_date, end_date)
    else:
        frequency = '1m'
        data_frequency = frequency
        bar_count = calendar.minutes_count_for_sessions_in_range(start_date, end_date)

    return data.get_history_window(symbols, end_date, bar_count, frequency, fields, data_frequency)
