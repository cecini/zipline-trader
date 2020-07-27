from zipline.gens.tdx_client import TdxClient
import zerorpc

import logging

logging.basicConfig()


def orders():
    client = TdxClient('config.json')
    client.login()
    str(client.transactions())
    str(client.orders())


def rpc_server():
    s = zerorpc.Server(TdxClient('config.json').login())
    s.bind("tcp://0.0.0.0:4242")
    s.run()


def rpc_client():
    client = zerorpc.Client()
    client.connect("tcp://127.0.0.1:4242")


rpc_server()
